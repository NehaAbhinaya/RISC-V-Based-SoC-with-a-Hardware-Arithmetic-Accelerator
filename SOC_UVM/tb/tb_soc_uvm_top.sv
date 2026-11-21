`timescale 1ns / 1ps

/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * Subsystem      : SoC-Level UVM Verification Environment
 * File           : tb_soc_uvm_top.sv
 * Description    : Top-Level UVM Testbench instantiating the actual SoC DUT (soc_top)
 *                  as soc_dut, instantiating all six VIP interfaces, binding DUT pins
 *                  and internal signals, setting up clock/reset, registering VIFs in
 *                  uvm_config_db, and invoking run_test("soc_test").
 * ============================================================================== */

import uvm_pkg::*;
`include "uvm_macros.svh"
import soc_pkg::*;

module tb_soc_uvm_top;

  // --------------------------------------------------------------------------
  // Timing Parameters
  // --------------------------------------------------------------------------
  localparam CLK_PERIOD = 10; // 100 MHz System Clock (10 ns period)
  parameter  IMEM_INIT_FILE = "soc_firmware.hex";
  parameter  GPIO_WIDTH     = 8;

  // --------------------------------------------------------------------------
  // Clock and Reset Signals
  // --------------------------------------------------------------------------
  logic clk;
  logic rst_n;

  // --------------------------------------------------------------------------
  // External DUT Pin Signals
  // --------------------------------------------------------------------------
  wire                    uart_tx;
  wire                    uart_rx;

  wire                    spi_sclk;
  wire                    spi_cs_n;
  wire                    spi_mosi;
  wire                    spi_miso;

  wire [GPIO_WIDTH-1:0]   gpio_in;
  wire [GPIO_WIDTH-1:0]   gpio_out;

  wire [5:0]              pic_interrupts;
  wire                    irq_core;

  wire [31:0]             rv_trace_insn;
  wire [31:0]             rv_trace_address;
  wire                    rv_trace_valid;

  // --------------------------------------------------------------------------
  // External Host LSU Bus Interface (Controlled via tb_soc_uvm_top tasks)
  // Default: ext_host_en = 0 so CPU executes autonomously.
  // When tx_trigger is pulsed, temporarily asserts ext_host_en to write UART_TXDATA.
  // --------------------------------------------------------------------------
  logic                   ext_host_en     = 1'b0;
  logic [31:0]            ext_lsu_awaddr  = 32'h0;
  logic [2:0]             ext_lsu_awprot  = 3'b000;
  logic                   ext_lsu_awvalid = 1'b0;
  wire                    ext_lsu_awready;
  logic [31:0]            ext_lsu_wdata   = 32'h0;
  logic [3:0]             ext_lsu_wstrb   = 4'h0;
  logic                   ext_lsu_wvalid  = 1'b0;
  wire                    ext_lsu_wready;
  wire [1:0]              ext_lsu_bresp;
  wire                    ext_lsu_bvalid;
  logic                   ext_lsu_bready  = 1'b0;
  logic [31:0]            ext_lsu_araddr  = 32'h0;
  logic [2:0]             ext_lsu_arprot  = 3'b000;
  logic                   ext_lsu_arvalid = 1'b0;
  wire                    ext_lsu_arready;
  wire [31:0]             ext_lsu_rdata;
  wire [1:0]              ext_lsu_rresp;
  wire                    ext_lsu_rvalid;
  logic                   ext_lsu_rready  = 1'b0;

  // Master write task to write into DUT memory-mapped registers
  task lsu_write(input [31:0] addr, input [31:0] data, input [3:0] strb, output [1:0] resp);
    begin
      @(posedge clk);
      ext_host_en     <= 1'b1;
      ext_lsu_awaddr  <= addr;
      ext_lsu_awprot  <= 3'b000;
      ext_lsu_awvalid <= 1'b1;
      ext_lsu_wdata   <= data;
      ext_lsu_wstrb   <= strb;
      ext_lsu_wvalid  <= 1'b1;
      ext_lsu_bready  <= 1'b1;

      while (!(ext_lsu_awvalid && ext_lsu_awready)) @(posedge clk);
      ext_lsu_awvalid <= 1'b0;

      while (!(ext_lsu_wvalid && ext_lsu_wready)) @(posedge clk);
      ext_lsu_wvalid <= 1'b0;

      while (!ext_lsu_bvalid) @(posedge clk);
      resp = ext_lsu_bresp;
      @(posedge clk);
      ext_lsu_bready  <= 1'b0;
      ext_host_en     <= 1'b0;
    end
  endtask

  // Trigger DUT UART TX transmission when requested via interface
  always @(posedge clk) begin
    if (u_uart_if.tx_trigger) begin
      u_uart_if.tx_trigger <= 1'b0;
      fork
        begin
          logic [1:0] resp;
          lsu_write(32'h4000_0008, {24'h0, u_uart_if.tx_byte}, 4'hF, resp);
        end
      join_none
    end
  end

  // --------------------------------------------------------------------------
  // Waveform Dumping for VCS / DVE / Synopsys Verdi
  // --------------------------------------------------------------------------
  initial begin
    $dumpfile("soc_uart_waveform.vcd");
    $dumpvars(0, tb_soc_uvm_top);
  end

  // --------------------------------------------------------------------------
  // 100 MHz Clock Generation (50% Duty Cycle)
  // --------------------------------------------------------------------------
  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD / 2) clk = ~clk;
  end

  // --------------------------------------------------------------------------
  // Active-Low Reset Generation (Asserted for > 20 Clock Cycles)
  // --------------------------------------------------------------------------
  initial begin
    rst_n = 1'b0;
    repeat (25) @(posedge clk);
    rst_n = 1'b1;
  end

  // --------------------------------------------------------------------------
  // VIP SystemVerilog Interface Instantiations
  // --------------------------------------------------------------------------
  uart_if                   u_uart_if();
  gpio_if                   u_gpio_if();
  spi_if                    u_spi_if();
  timer_if                  u_timer_if();
  arithmetic_accelerator_if u_accel_if();
  dma_if                    u_dma_if();

  // --------------------------------------------------------------------------
  // Clock and Reset Distribution to VIP Interfaces
  // --------------------------------------------------------------------------
  assign u_uart_if.clk   = clk;
  assign u_uart_if.rst_n = rst_n;

  assign u_gpio_if.clk   = clk;
  assign u_gpio_if.rst_n = rst_n;

  assign u_spi_if.clk    = clk;
  assign u_spi_if.rst_n  = rst_n;

  assign u_timer_if.clk   = clk;
  assign u_timer_if.rst_n = rst_n;

  assign u_accel_if.clk   = clk;
  assign u_accel_if.rst_n = rst_n;

  assign u_dma_if.clk     = clk;
  assign u_dma_if.rst_n   = rst_n;

  // Initial bus/pin tie-offs for VIP inputs before drivers take control
  initial begin
    u_uart_if.uart_rx     = 1'b1; // UART serial idle high
    u_uart_if.tx_trigger  = 1'b0;
    u_uart_if.tx_byte     = 8'h00;
    u_uart_if.loopback_en = 1'b0;
    u_spi_if.spi_miso     = 1'b0; // SPI MISO default low
    u_gpio_if.gpio_in     = 8'h00; // GPIO input default 0
  end

  // Synchronous UART Loopback handler (routes uart_tx into uart_rx when loopback_en is asserted)
  always @(posedge clk) begin
    if (u_uart_if.loopback_en) begin
      u_uart_if.uart_rx <= uart_tx;
    end
  end

  // Connect VIP interfaces to external top-level signals
  assign uart_rx             = u_uart_if.uart_rx;
  assign u_uart_if.uart_tx   = uart_tx;

  assign spi_miso            = u_spi_if.spi_miso;
  assign u_spi_if.spi_sclk   = spi_sclk;
  assign u_spi_if.spi_cs_n   = spi_cs_n;
  assign u_spi_if.spi_mosi   = spi_mosi;

  assign gpio_in             = u_gpio_if.gpio_in;
  assign u_gpio_if.gpio_out  = gpio_out;

  // --------------------------------------------------------------------------
  // ACTUAL SOC DUT INSTANTIATION (Exact Instance Name: soc_dut)
  // Preserves VeeR EL2 Core, AXI Interconnect, IMEM, DMEM, All Peripherals
  // --------------------------------------------------------------------------
  soc_top #(
    .IMEM_INIT_FILE (IMEM_INIT_FILE),
    .GPIO_WIDTH     (GPIO_WIDTH)
  ) soc_dut (
    .clk              (clk),
    .rst_n            (rst_n),

    // External UART Pins
    .uart_tx          (uart_tx),
    .uart_rx          (uart_rx),

    // External SPI Pins
    .spi_sclk         (spi_sclk),
    .spi_cs_n         (spi_cs_n),
    .spi_mosi         (spi_mosi),
    .spi_miso         (spi_miso),

    // External GPIO Pins
    .gpio_in          (gpio_in),
    .gpio_out         (gpio_out),

    // Interrupt Vector to Core
    .pic_interrupts   (pic_interrupts),
    .irq_core         (irq_core),

    // Execution Trace Outputs
    .rv_trace_insn    (rv_trace_insn),
    .rv_trace_address (rv_trace_address),
    .rv_trace_valid   (rv_trace_valid),

    // External Host LSU Bus Interface (Tied off to prevent contention)
    .ext_host_en      (ext_host_en),
    .ext_lsu_awaddr   (ext_lsu_awaddr),
    .ext_lsu_awprot   (ext_lsu_awprot),
    .ext_lsu_awvalid  (ext_lsu_awvalid),
    .ext_lsu_awready  (ext_lsu_awready),
    .ext_lsu_wdata    (ext_lsu_wdata),
    .ext_lsu_wstrb    (ext_lsu_wstrb),
    .ext_lsu_wvalid   (ext_lsu_wvalid),
    .ext_lsu_wready   (ext_lsu_wready),
    .ext_lsu_bresp    (ext_lsu_bresp),
    .ext_lsu_bvalid   (ext_lsu_bvalid),
    .ext_lsu_bready   (ext_lsu_bready),
    .ext_lsu_araddr   (ext_lsu_araddr),
    .ext_lsu_arprot   (ext_lsu_arprot),
    .ext_lsu_arvalid  (ext_lsu_arvalid),
    .ext_lsu_arready  (ext_lsu_arready),
    .ext_lsu_rdata    (ext_lsu_rdata),
    .ext_lsu_rresp    (ext_lsu_rresp),
    .ext_lsu_rvalid   (ext_lsu_rvalid),
    .ext_lsu_rready   (ext_lsu_rready)
  );

  // --------------------------------------------------------------------------
  // Non-Invasive Internal Wire Monitoring & Peripheral Interface Bindings
  // Allows full VIP verification without modifying SoC RTL
  // --------------------------------------------------------------------------
  // 1. UART (m02 @ 0x4000_0000 + IRQ + DUT RX Reception Probes)
  assign u_uart_if.irq_uart        = soc_dut.irq_uart;
  assign u_uart_if.s_axil_awaddr   = soc_dut.m02_axil_awaddr;
  assign u_uart_if.s_axil_awprot   = soc_dut.m02_axil_awprot;
  assign u_uart_if.s_axil_awvalid  = soc_dut.m02_axil_awvalid;
  assign u_uart_if.s_axil_awready  = soc_dut.m02_axil_awready;
  assign u_uart_if.s_axil_wdata    = soc_dut.m02_axil_wdata;
  assign u_uart_if.s_axil_wstrb    = soc_dut.m02_axil_wstrb;
  assign u_uart_if.s_axil_wvalid   = soc_dut.m02_axil_wvalid;
  assign u_uart_if.s_axil_wready   = soc_dut.m02_axil_wready;
  assign u_uart_if.s_axil_bresp    = soc_dut.m02_axil_bresp;
  assign u_uart_if.s_axil_bvalid   = soc_dut.m02_axil_bvalid;
  assign u_uart_if.s_axil_bready   = soc_dut.m02_axil_bready;
  assign u_uart_if.s_axil_araddr   = soc_dut.m02_axil_araddr;
  assign u_uart_if.s_axil_arprot   = soc_dut.m02_axil_arprot;
  assign u_uart_if.s_axil_arvalid  = soc_dut.m02_axil_arvalid;
  assign u_uart_if.s_axil_arready  = soc_dut.m02_axil_arready;
  assign u_uart_if.s_axil_rdata    = soc_dut.m02_axil_rdata;
  assign u_uart_if.s_axil_rresp    = soc_dut.m02_axil_rresp;
  assign u_uart_if.s_axil_rvalid   = soc_dut.m02_axil_rvalid;
  assign u_uart_if.s_axil_rready   = soc_dut.m02_axil_rready;
  // Non-invasive DUT-side UART RX reception evidence
  assign u_uart_if.rx_valid        = soc_dut.u_uart.u_axi_uart_top.rx_valid;
  assign u_uart_if.rx_data         = soc_dut.u_uart.u_axi_uart_top.rx_fifo_dout;
  assign u_uart_if.rx_fifo_push    = soc_dut.u_uart.u_axi_uart_top.rx_fifo_push;
  assign u_uart_if.rx_fifo_din     = soc_dut.u_uart.u_axi_uart_top.rx_fifo_din;
  assign u_uart_if.baud_divisor    = soc_dut.u_uart.u_axi_uart_top.baud_divisor;

  // 2. GPIO (m04 @ 0x4000_2000 + IRQ)
  assign u_gpio_if.irq_gpio        = soc_dut.irq_gpio;
  assign u_gpio_if.s_axil_awaddr   = soc_dut.m04_axil_awaddr;
  assign u_gpio_if.s_axil_awprot   = soc_dut.m04_axil_awprot;
  assign u_gpio_if.s_axil_awvalid  = soc_dut.m04_axil_awvalid;
  assign u_gpio_if.s_axil_awready  = soc_dut.m04_axil_awready;
  assign u_gpio_if.s_axil_wdata    = soc_dut.m04_axil_wdata;
  assign u_gpio_if.s_axil_wstrb    = soc_dut.m04_axil_wstrb;
  assign u_gpio_if.s_axil_wvalid   = soc_dut.m04_axil_wvalid;
  assign u_gpio_if.s_axil_wready   = soc_dut.m04_axil_wready;
  assign u_gpio_if.s_axil_bresp    = soc_dut.m04_axil_bresp;
  assign u_gpio_if.s_axil_bvalid   = soc_dut.m04_axil_bvalid;
  assign u_gpio_if.s_axil_bready   = soc_dut.m04_axil_bready;
  assign u_gpio_if.s_axil_araddr   = soc_dut.m04_axil_araddr;
  assign u_gpio_if.s_axil_arprot   = soc_dut.m04_axil_arprot;
  assign u_gpio_if.s_axil_arvalid  = soc_dut.m04_axil_arvalid;
  assign u_gpio_if.s_axil_arready  = soc_dut.m04_axil_arready;
  assign u_gpio_if.s_axil_rdata    = soc_dut.m04_axil_rdata;
  assign u_gpio_if.s_axil_rresp    = soc_dut.m04_axil_rresp;
  assign u_gpio_if.s_axil_rvalid   = soc_dut.m04_axil_rvalid;
  assign u_gpio_if.s_axil_rready   = soc_dut.m04_axil_rready;

  // 3. SPI (m07 @ 0x4000_5000 + IRQ)
  assign u_spi_if.irq_spi          = soc_dut.irq_spi;
  assign u_spi_if.s_axil_awaddr    = soc_dut.m07_axil_awaddr;
  assign u_spi_if.s_axil_awprot    = soc_dut.m07_axil_awprot;
  assign u_spi_if.s_axil_awvalid   = soc_dut.m07_axil_awvalid;
  assign u_spi_if.s_axil_awready   = soc_dut.m07_axil_awready;
  assign u_spi_if.s_axil_wdata     = soc_dut.m07_axil_wdata;
  assign u_spi_if.s_axil_wstrb     = soc_dut.m07_axil_wstrb;
  assign u_spi_if.s_axil_wvalid    = soc_dut.m07_axil_wvalid;
  assign u_spi_if.s_axil_wready    = soc_dut.m07_axil_wready;
  assign u_spi_if.s_axil_bresp     = soc_dut.m07_axil_bresp;
  assign u_spi_if.s_axil_bvalid    = soc_dut.m07_axil_bvalid;
  assign u_spi_if.s_axil_bready    = soc_dut.m07_axil_bready;
  assign u_spi_if.s_axil_araddr    = soc_dut.m07_axil_araddr;
  assign u_spi_if.s_axil_arprot    = soc_dut.m07_axil_arprot;
  assign u_spi_if.s_axil_arvalid   = soc_dut.m07_axil_arvalid;
  assign u_spi_if.s_axil_arready   = soc_dut.m07_axil_arready;
  assign u_spi_if.s_axil_rdata     = soc_dut.m07_axil_rdata;
  assign u_spi_if.s_axil_rresp     = soc_dut.m07_axil_rresp;
  assign u_spi_if.s_axil_rvalid    = soc_dut.m07_axil_rvalid;
  assign u_spi_if.s_axil_rready    = soc_dut.m07_axil_rready;

  // 4. Timer (m03 @ 0x4000_1000 + IRQ)
  assign u_timer_if.irq_timer      = soc_dut.irq_timer;
  assign u_timer_if.s_axil_awaddr  = soc_dut.m03_axil_awaddr;
  assign u_timer_if.s_axil_awprot  = soc_dut.m03_axil_awprot;
  assign u_timer_if.s_axil_awvalid = soc_dut.m03_axil_awvalid;
  assign u_timer_if.s_axil_awready = soc_dut.m03_axil_awready;
  assign u_timer_if.s_axil_wdata   = soc_dut.m03_axil_wdata;
  assign u_timer_if.s_axil_wstrb   = soc_dut.m03_axil_wstrb;
  assign u_timer_if.s_axil_wvalid  = soc_dut.m03_axil_wvalid;
  assign u_timer_if.s_axil_wready  = soc_dut.m03_axil_wready;
  assign u_timer_if.s_axil_bresp   = soc_dut.m03_axil_bresp;
  assign u_timer_if.s_axil_bvalid  = soc_dut.m03_axil_bvalid;
  assign u_timer_if.s_axil_bready  = soc_dut.m03_axil_bready;
  assign u_timer_if.s_axil_araddr  = soc_dut.m03_axil_araddr;
  assign u_timer_if.s_axil_arprot  = soc_dut.m03_axil_arprot;
  assign u_timer_if.s_axil_arvalid = soc_dut.m03_axil_arvalid;
  assign u_timer_if.s_axil_arready = soc_dut.m03_axil_arready;
  assign u_timer_if.s_axil_rdata   = soc_dut.m03_axil_rdata;
  assign u_timer_if.s_axil_rresp   = soc_dut.m03_axil_rresp;
  assign u_timer_if.s_axil_rvalid  = soc_dut.m03_axil_rvalid;
  assign u_timer_if.s_axil_rready  = soc_dut.m03_axil_rready;

  // 5. Arithmetic Accelerator (m05 @ 0x4000_3000 + IRQ + Streaming DMA Interface)
  assign u_accel_if.irq_acc        = soc_dut.irq_acc;
  assign u_accel_if.dma_op_valid   = soc_dut.dma_op_valid;
  assign u_accel_if.dma_op_data_a  = soc_dut.dma_op_data_a;
  assign u_accel_if.dma_op_data_b  = soc_dut.dma_op_data_b;
  assign u_accel_if.dma_op_ready   = soc_dut.dma_op_ready;
  assign u_accel_if.dma_res_valid  = soc_dut.dma_res_valid;
  assign u_accel_if.dma_res_data   = soc_dut.dma_res_data;
  assign u_accel_if.dma_res_ready  = soc_dut.dma_res_ready;
  assign u_accel_if.dma_last       = soc_dut.dma_last;
  assign u_accel_if.s_axil_awaddr  = soc_dut.m05_axil_awaddr;
  assign u_accel_if.s_axil_awprot  = soc_dut.m05_axil_awprot;
  assign u_accel_if.s_axil_awvalid = soc_dut.m05_axil_awvalid;
  assign u_accel_if.s_axil_awready = soc_dut.m05_axil_awready;
  assign u_accel_if.s_axil_wdata   = soc_dut.m05_axil_wdata;
  assign u_accel_if.s_axil_wstrb   = soc_dut.m05_axil_wstrb;
  assign u_accel_if.s_axil_wvalid  = soc_dut.m05_axil_wvalid;
  assign u_accel_if.s_axil_wready  = soc_dut.m05_axil_wready;
  assign u_accel_if.s_axil_bresp   = soc_dut.m05_axil_bresp;
  assign u_accel_if.s_axil_bvalid  = soc_dut.m05_axil_bvalid;
  assign u_accel_if.s_axil_bready  = soc_dut.m05_axil_bready;
  assign u_accel_if.s_axil_araddr  = soc_dut.m05_axil_araddr;
  assign u_accel_if.s_axil_arprot  = soc_dut.m05_axil_arprot;
  assign u_accel_if.s_axil_arvalid = soc_dut.m05_axil_arvalid;
  assign u_accel_if.s_axil_arready = soc_dut.m05_axil_arready;
  assign u_accel_if.s_axil_rdata   = soc_dut.m05_axil_rdata;
  assign u_accel_if.s_axil_rresp   = soc_dut.m05_axil_rresp;
  assign u_accel_if.s_axil_rvalid  = soc_dut.m05_axil_rvalid;
  assign u_accel_if.s_axil_rready  = soc_dut.m05_axil_rready;

  // 6. DMA Controller (m06 @ 0x4000_4000 + IRQ + Master s02 + Streaming Interface)
  assign u_dma_if.irq_dma          = soc_dut.irq_dma;
  assign u_dma_if.dma_op_valid     = soc_dut.dma_op_valid;
  assign u_dma_if.dma_op_data_a    = soc_dut.dma_op_data_a;
  assign u_dma_if.dma_op_data_b    = soc_dut.dma_op_data_b;
  assign u_dma_if.dma_op_ready     = soc_dut.dma_op_ready;
  assign u_dma_if.dma_res_valid    = soc_dut.dma_res_valid;
  assign u_dma_if.dma_res_data     = soc_dut.dma_res_data;
  assign u_dma_if.dma_res_ready    = soc_dut.dma_res_ready;
  assign u_dma_if.dma_last         = soc_dut.dma_last;

  assign u_dma_if.s_axil_awaddr    = soc_dut.m06_axil_awaddr;
  assign u_dma_if.s_axil_awprot    = soc_dut.m06_axil_awprot;
  assign u_dma_if.s_axil_awvalid   = soc_dut.m06_axil_awvalid;
  assign u_dma_if.s_axil_awready   = soc_dut.m06_axil_awready;
  assign u_dma_if.s_axil_wdata     = soc_dut.m06_axil_wdata;
  assign u_dma_if.s_axil_wstrb     = soc_dut.m06_axil_wstrb;
  assign u_dma_if.s_axil_wvalid    = soc_dut.m06_axil_wvalid;
  assign u_dma_if.s_axil_wready    = soc_dut.m06_axil_wready;
  assign u_dma_if.s_axil_bresp     = soc_dut.m06_axil_bresp;
  assign u_dma_if.s_axil_bvalid    = soc_dut.m06_axil_bvalid;
  assign u_dma_if.s_axil_bready    = soc_dut.m06_axil_bready;
  assign u_dma_if.s_axil_araddr    = soc_dut.m06_axil_araddr;
  assign u_dma_if.s_axil_arprot    = soc_dut.m06_axil_arprot;
  assign u_dma_if.s_axil_arvalid   = soc_dut.m06_axil_arvalid;
  assign u_dma_if.s_axil_arready   = soc_dut.m06_axil_arready;
  assign u_dma_if.s_axil_rdata     = soc_dut.m06_axil_rdata;
  assign u_dma_if.s_axil_rresp     = soc_dut.m06_axil_rresp;
  assign u_dma_if.s_axil_rvalid    = soc_dut.m06_axil_rvalid;
  assign u_dma_if.s_axil_rready    = soc_dut.m06_axil_rready;

  assign u_dma_if.m_axil_awaddr    = soc_dut.s02_axil_awaddr;
  assign u_dma_if.m_axil_awprot    = soc_dut.s02_axil_awprot;
  assign u_dma_if.m_axil_awvalid   = soc_dut.s02_axil_awvalid;
  assign u_dma_if.m_axil_awready   = soc_dut.s02_axil_awready;
  assign u_dma_if.m_axil_wdata     = soc_dut.s02_axil_wdata;
  assign u_dma_if.m_axil_wstrb     = soc_dut.s02_axil_wstrb;
  assign u_dma_if.m_axil_wvalid    = soc_dut.s02_axil_wvalid;
  assign u_dma_if.m_axil_wready    = soc_dut.s02_axil_wready;
  assign u_dma_if.m_axil_bresp     = soc_dut.s02_axil_bresp;
  assign u_dma_if.m_axil_bvalid    = soc_dut.s02_axil_bvalid;
  assign u_dma_if.m_axil_bready    = soc_dut.s02_axil_bready;
  assign u_dma_if.m_axil_araddr    = soc_dut.s02_axil_araddr;
  assign u_dma_if.m_axil_arprot    = soc_dut.s02_axil_arprot;
  assign u_dma_if.m_axil_arvalid   = soc_dut.s02_axil_arvalid;
  assign u_dma_if.m_axil_arready   = soc_dut.s02_axil_arready;
  assign u_dma_if.m_axil_rdata     = soc_dut.s02_axil_rdata;
  assign u_dma_if.m_axil_rresp     = soc_dut.s02_axil_rresp;
  assign u_dma_if.m_axil_rvalid    = soc_dut.s02_axil_rvalid;
  assign u_dma_if.m_axil_rready    = soc_dut.s02_axil_rready;

  // --------------------------------------------------------------------------
  // UVM Virtual Interface Registration and Test Launch
  // --------------------------------------------------------------------------
  initial begin
    // Register interfaces in global uvm_config_db
    uvm_config_db#(virtual uart_if)::set(null, "*", "uart_vif", u_uart_if);
    uvm_config_db#(virtual gpio_if)::set(null, "*", "gpio_vif", u_gpio_if);
    uvm_config_db#(virtual spi_if)::set(null, "*", "spi_vif", u_spi_if);
    uvm_config_db#(virtual timer_if)::set(null, "*", "timer_vif", u_timer_if);
    uvm_config_db#(virtual arithmetic_accelerator_if)::set(null, "*", "accel_vif", u_accel_if);
    uvm_config_db#(virtual dma_if)::set(null, "*", "dma_vif", u_dma_if);

    // Also register with exact "vif" name for VIP drivers/monitors
    uvm_config_db#(virtual uart_if)::set(null, "*uart_agnt*", "vif", u_uart_if);
    uvm_config_db#(virtual gpio_if)::set(null, "*gpio_agnt*", "vif", u_gpio_if);
    uvm_config_db#(virtual spi_if)::set(null, "*spi_agnt*", "vif", u_spi_if);
    uvm_config_db#(virtual timer_if)::set(null, "*timer_agnt*", "vif", u_timer_if);
    uvm_config_db#(virtual arithmetic_accelerator_if)::set(null, "*accel_agnt*", "vif", u_accel_if);
    uvm_config_db#(virtual dma_if)::set(null, "*dma_agnt*", "vif", u_dma_if);

    // Start SoC UVM Test (Defaults to uart_connectivity_test, overrideable via +UVM_TESTNAME)
    run_test("uart_connectivity_test");
  end

endmodule
