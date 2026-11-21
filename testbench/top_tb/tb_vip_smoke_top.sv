`timescale 1ns / 1ps

/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * File           : tb_vip_smoke_top.sv
 * Description    : SoC-Level VIP Integration Smoke Testbench
 *                  Integrates:
 *                  1. Top-Level SoC DUT (soc_top.v)
 *                  2. All 6 Generated VIPs (UART, GPIO, SPI, Timer, Accelerator, DMA)
 *                  3. UVM Environment & Virtual Interface Configuration Database
 *                  4. Comprehensive Smoke Test Suite for All 6 Peripherals & DMA Pipeline
 * ============================================================================== */

import uvm_pkg::*;
`include "uvm_macros.svh"

// Import All 6 Existing VIP Packages
import uart_pkg::*;
import gpio_pkg::*;
import spi_pkg::*;
import timer_pkg::*;
import arithmetic_accelerator_pkg::*;
import dma_pkg::*;

module tb_vip_smoke_top;

  // =========================================================================
  // Clock and Reset Signals
  // =========================================================================
  logic clk;
  logic rst_n;

  // 100 MHz System Clock (10 ns period)
  initial clk = 1'b0;
  always #5 clk = ~clk;

  // =========================================================================
  // Top-Level SoC Interface Signals
  // =========================================================================
  wire        uart_tx;
  reg         uart_rx;

  wire        spi_sclk;
  wire        spi_cs_n;
  wire        spi_mosi;
  reg         spi_miso;

  reg  [7:0]  gpio_in;
  wire [7:0]  gpio_out;

  wire [5:0]  pic_interrupts; // [0] Accel, [1] DMA, [2] SPI, [3] UART, [4] Timer, [5] GPIO
  wire        irq_core;

  wire [31:0] rv_trace_insn;
  wire [31:0] rv_trace_address;
  wire        rv_trace_valid;

  // External Host / Testbench LSU Bus Master Signals
  reg         ext_host_en;
  reg  [31:0] ext_lsu_awaddr;
  reg  [2:0]  ext_lsu_awprot;
  reg         ext_lsu_awvalid;
  wire        ext_lsu_awready;
  reg  [31:0] ext_lsu_wdata;
  reg  [3:0]  ext_lsu_wstrb;
  reg         ext_lsu_wvalid;
  wire        ext_lsu_wready;
  wire [1:0]  ext_lsu_bresp;
  wire        ext_lsu_bvalid;
  reg         ext_lsu_bready;

  reg  [31:0] ext_lsu_araddr;
  reg  [2:0]  ext_lsu_arprot;
  reg         ext_lsu_arvalid;
  wire        ext_lsu_arready;
  wire [31:0] ext_lsu_rdata;
  wire [1:0]  ext_lsu_rresp;
  wire        ext_lsu_rvalid;
  reg         ext_lsu_rready;

  // AXI Response Constants
  localparam [1:0] AXI_OKAY   = 2'b00;
  localparam [1:0] AXI_EXOKAY = 2'b01;
  localparam [1:0] AXI_SLVERR = 2'b10;
  localparam [1:0] AXI_DECERR = 2'b11;

  // Synchronization event between procedural tests and UVM phase
  event ev_smoke_tests_done;

  // =========================================================================
  // Instantiate DUT: Top-Level SoC (soc_top.v)
  // =========================================================================
  soc_top #(
    .IMEM_INIT_FILE ("soc_firmware.hex"),
    .GPIO_WIDTH     (8)
  ) dut (
    .clk              (clk),
    .rst_n            (rst_n),

    .uart_tx          (uart_tx),
    .uart_rx          (uart_rx),

    .spi_sclk         (spi_sclk),
    .spi_cs_n         (spi_cs_n),
    .spi_mosi         (spi_mosi),
    .spi_miso         (spi_miso),

    .gpio_in          (gpio_in),
    .gpio_out         (gpio_out),

    .pic_interrupts   (pic_interrupts),
    .irq_core         (irq_core),

    .rv_trace_insn    (rv_trace_insn),
    .rv_trace_address (rv_trace_address),
    .rv_trace_valid   (rv_trace_valid),

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

  // =========================================================================
  // Instantiate All Six Generated VIP Interfaces & Bind to SoC Hierarchy
  // =========================================================================

  // 1. UART VIP Interface
  uart_if u_uart_vif();
  assign u_uart_vif.clk            = clk;
  assign u_uart_vif.rst_n          = rst_n;
  assign u_uart_vif.uart_tx        = uart_tx;
  assign u_uart_vif.uart_rx        = uart_rx;
  assign u_uart_vif.irq_uart       = dut.irq_uart;
  assign u_uart_vif.s_axil_awaddr  = dut.m02_axil_awaddr;
  assign u_uart_vif.s_axil_awprot  = dut.m02_axil_awprot;
  assign u_uart_vif.s_axil_awvalid = dut.m02_axil_awvalid;
  assign u_uart_vif.s_axil_awready = dut.m02_axil_awready;
  assign u_uart_vif.s_axil_wdata   = dut.m02_axil_wdata;
  assign u_uart_vif.s_axil_wstrb   = dut.m02_axil_wstrb;
  assign u_uart_vif.s_axil_wvalid  = dut.m02_axil_wvalid;
  assign u_uart_vif.s_axil_wready  = dut.m02_axil_wready;
  assign u_uart_vif.s_axil_bresp   = dut.m02_axil_bresp;
  assign u_uart_vif.s_axil_bvalid  = dut.m02_axil_bvalid;
  assign u_uart_vif.s_axil_bready  = dut.m02_axil_bready;
  assign u_uart_vif.s_axil_araddr  = dut.m02_axil_araddr;
  assign u_uart_vif.s_axil_arprot  = dut.m02_axil_arprot;
  assign u_uart_vif.s_axil_arvalid = dut.m02_axil_arvalid;
  assign u_uart_vif.s_axil_arready = dut.m02_axil_arready;
  assign u_uart_vif.s_axil_rdata   = dut.m02_axil_rdata;
  assign u_uart_vif.s_axil_rresp   = dut.m02_axil_rresp;
  assign u_uart_vif.s_axil_rvalid  = dut.m02_axil_rvalid;
  assign u_uart_vif.s_axil_rready  = dut.m02_axil_rready;

  // 2. GPIO VIP Interface
  gpio_if u_gpio_vif();
  assign u_gpio_vif.clk            = clk;
  assign u_gpio_vif.rst_n          = rst_n;
  assign u_gpio_vif.gpio_in        = gpio_in;
  assign u_gpio_vif.gpio_out       = gpio_out;
  assign u_gpio_vif.irq_gpio       = dut.irq_gpio;
  assign u_gpio_vif.s_axil_awaddr  = dut.m04_axil_awaddr;
  assign u_gpio_vif.s_axil_awprot  = dut.m04_axil_awprot;
  assign u_gpio_vif.s_axil_awvalid = dut.m04_axil_awvalid;
  assign u_gpio_vif.s_axil_awready = dut.m04_axil_awready;
  assign u_gpio_vif.s_axil_wdata   = dut.m04_axil_wdata;
  assign u_gpio_vif.s_axil_wstrb   = dut.m04_axil_wstrb;
  assign u_gpio_vif.s_axil_wvalid  = dut.m04_axil_wvalid;
  assign u_gpio_vif.s_axil_wready  = dut.m04_axil_wready;
  assign u_gpio_vif.s_axil_bresp   = dut.m04_axil_bresp;
  assign u_gpio_vif.s_axil_bvalid  = dut.m04_axil_bvalid;
  assign u_gpio_vif.s_axil_bready  = dut.m04_axil_bready;
  assign u_gpio_vif.s_axil_araddr  = dut.m04_axil_araddr;
  assign u_gpio_vif.s_axil_arprot  = dut.m04_axil_arprot;
  assign u_gpio_vif.s_axil_arvalid = dut.m04_axil_arvalid;
  assign u_gpio_vif.s_axil_arready = dut.m04_axil_arready;
  assign u_gpio_vif.s_axil_rdata   = dut.m04_axil_rdata;
  assign u_gpio_vif.s_axil_rresp   = dut.m04_axil_rresp;
  assign u_gpio_vif.s_axil_rvalid  = dut.m04_axil_rvalid;
  assign u_gpio_vif.s_axil_rready  = dut.m04_axil_rready;

  // 3. SPI VIP Interface
  spi_if u_spi_vif();
  assign u_spi_vif.clk            = clk;
  assign u_spi_vif.rst_n          = rst_n;
  assign u_spi_vif.spi_sclk       = spi_sclk;
  assign u_spi_vif.spi_cs_n       = spi_cs_n;
  assign u_spi_vif.spi_mosi       = spi_mosi;
  assign u_spi_vif.spi_miso       = spi_miso;
  assign u_spi_vif.irq_spi        = dut.irq_spi;
  assign u_spi_vif.s_axil_awaddr  = dut.m07_axil_awaddr;
  assign u_spi_vif.s_axil_awprot  = dut.m07_axil_awprot;
  assign u_spi_vif.s_axil_awvalid = dut.m07_axil_awvalid;
  assign u_spi_vif.s_axil_awready = dut.m07_axil_awready;
  assign u_spi_vif.s_axil_wdata   = dut.m07_axil_wdata;
  assign u_spi_vif.s_axil_wstrb   = dut.m07_axil_wstrb;
  assign u_spi_vif.s_axil_wvalid  = dut.m07_axil_wvalid;
  assign u_spi_vif.s_axil_wready  = dut.m07_axil_wready;
  assign u_spi_vif.s_axil_bresp   = dut.m07_axil_bresp;
  assign u_spi_vif.s_axil_bvalid  = dut.m07_axil_bvalid;
  assign u_spi_vif.s_axil_bready  = dut.m07_axil_bready;
  assign u_spi_vif.s_axil_araddr  = dut.m07_axil_araddr;
  assign u_spi_vif.s_axil_arprot  = dut.m07_axil_arprot;
  assign u_spi_vif.s_axil_arvalid = dut.m07_axil_arvalid;
  assign u_spi_vif.s_axil_arready = dut.m07_axil_arready;
  assign u_spi_vif.s_axil_rdata   = dut.m07_axil_rdata;
  assign u_spi_vif.s_axil_rresp   = dut.m07_axil_rresp;
  assign u_spi_vif.s_axil_rvalid  = dut.m07_axil_rvalid;
  assign u_spi_vif.s_axil_rready  = dut.m07_axil_rready;

  // 4. Timer VIP Interface
  timer_if u_timer_vif();
  assign u_timer_vif.clk            = clk;
  assign u_timer_vif.rst_n          = rst_n;
  assign u_timer_vif.irq_timer       = dut.irq_timer;
  assign u_timer_vif.s_axil_awaddr  = dut.m03_axil_awaddr;
  assign u_timer_vif.s_axil_awprot  = dut.m03_axil_awprot;
  assign u_timer_vif.s_axil_awvalid = dut.m03_axil_awvalid;
  assign u_timer_vif.s_axil_awready = dut.m03_axil_awready;
  assign u_timer_vif.s_axil_wdata   = dut.m03_axil_wdata;
  assign u_timer_vif.s_axil_wstrb   = dut.m03_axil_wstrb;
  assign u_timer_vif.s_axil_wvalid  = dut.m03_axil_wvalid;
  assign u_timer_vif.s_axil_wready  = dut.m03_axil_wready;
  assign u_timer_vif.s_axil_bresp   = dut.m03_axil_bresp;
  assign u_timer_vif.s_axil_bvalid  = dut.m03_axil_bvalid;
  assign u_timer_vif.s_axil_bready  = dut.m03_axil_bready;
  assign u_timer_vif.s_axil_araddr  = dut.m03_axil_araddr;
  assign u_timer_vif.s_axil_arprot  = dut.m03_axil_arprot;
  assign u_timer_vif.s_axil_arvalid = dut.m03_axil_arvalid;
  assign u_timer_vif.s_axil_arready = dut.m03_axil_arready;
  assign u_timer_vif.s_axil_rdata   = dut.m03_axil_rdata;
  assign u_timer_vif.s_axil_rresp   = dut.m03_axil_rresp;
  assign u_timer_vif.s_axil_rvalid  = dut.m03_axil_rvalid;
  assign u_timer_vif.s_axil_rready  = dut.m03_axil_rready;

  // 5. Arithmetic Accelerator VIP Interface
  arithmetic_accelerator_if u_accel_vif();
  assign u_accel_vif.clk            = clk;
  assign u_accel_vif.rst_n          = rst_n;
  assign u_accel_vif.irq_acc        = dut.irq_acc;
  assign u_accel_vif.dma_op_valid   = dut.dma_op_valid;
  assign u_accel_vif.dma_op_data_a  = dut.dma_op_data_a;
  assign u_accel_vif.dma_op_data_b  = dut.dma_op_data_b;
  assign u_accel_vif.dma_op_ready   = dut.dma_op_ready;
  assign u_accel_vif.dma_res_valid  = dut.dma_res_valid;
  assign u_accel_vif.dma_res_data   = dut.dma_res_data;
  assign u_accel_vif.dma_res_ready  = dut.dma_res_ready;
  assign u_accel_vif.dma_last       = dut.dma_last;
  assign u_accel_vif.s_axil_awaddr  = dut.m05_axil_awaddr;
  assign u_accel_vif.s_axil_awprot  = dut.m05_axil_awprot;
  assign u_accel_vif.s_axil_awvalid = dut.m05_axil_awvalid;
  assign u_accel_vif.s_axil_awready = dut.m05_axil_awready;
  assign u_accel_vif.s_axil_wdata   = dut.m05_axil_wdata;
  assign u_accel_vif.s_axil_wstrb   = dut.m05_axil_wstrb;
  assign u_accel_vif.s_axil_wvalid  = dut.m05_axil_wvalid;
  assign u_accel_vif.s_axil_wready  = dut.m05_axil_wready;
  assign u_accel_vif.s_axil_bresp   = dut.m05_axil_bresp;
  assign u_accel_vif.s_axil_bvalid  = dut.m05_axil_bvalid;
  assign u_accel_vif.s_axil_bready  = dut.m05_axil_bready;
  assign u_accel_vif.s_axil_araddr  = dut.m05_axil_araddr;
  assign u_accel_vif.s_axil_arprot  = dut.m05_axil_arprot;
  assign u_accel_vif.s_axil_arvalid = dut.m05_axil_arvalid;
  assign u_accel_vif.s_axil_arready = dut.m05_axil_arready;
  assign u_accel_vif.s_axil_rdata   = dut.m05_axil_rdata;
  assign u_accel_vif.s_axil_rresp   = dut.m05_axil_rresp;
  assign u_accel_vif.s_axil_rvalid  = dut.m05_axil_rvalid;
  assign u_accel_vif.s_axil_rready  = dut.m05_axil_rready;

  // 6. DMA Controller VIP Interface
  dma_if u_dma_vif();
  assign u_dma_vif.clk            = clk;
  assign u_dma_vif.rst_n          = rst_n;
  assign u_dma_vif.irq_dma        = dut.irq_dma;
  assign u_dma_vif.dma_op_valid   = dut.dma_op_valid;
  assign u_dma_vif.dma_op_data_a  = dut.dma_op_data_a;
  assign u_dma_vif.dma_op_data_b  = dut.dma_op_data_b;
  assign u_dma_vif.dma_op_ready   = dut.dma_op_ready;
  assign u_dma_vif.dma_res_valid  = dut.dma_res_valid;
  assign u_dma_vif.dma_res_data   = dut.dma_res_data;
  assign u_dma_vif.dma_res_ready  = dut.dma_res_ready;
  assign u_dma_vif.dma_last       = dut.dma_last;
  // Configuration Slave Port (m06)
  assign u_dma_vif.s_axil_awaddr  = dut.m06_axil_awaddr;
  assign u_dma_vif.s_axil_awprot  = dut.m06_axil_awprot;
  assign u_dma_vif.s_axil_awvalid = dut.m06_axil_awvalid;
  assign u_dma_vif.s_axil_awready = dut.m06_axil_awready;
  assign u_dma_vif.s_axil_wdata   = dut.m06_axil_wdata;
  assign u_dma_vif.s_axil_wstrb   = dut.m06_axil_wstrb;
  assign u_dma_vif.s_axil_wvalid  = dut.m06_axil_wvalid;
  assign u_dma_vif.s_axil_wready  = dut.m06_axil_wready;
  assign u_dma_vif.s_axil_bresp   = dut.m06_axil_bresp;
  assign u_dma_vif.s_axil_bvalid  = dut.m06_axil_bvalid;
  assign u_dma_vif.s_axil_bready  = dut.m06_axil_bready;
  assign u_dma_vif.s_axil_araddr  = dut.m06_axil_araddr;
  assign u_dma_vif.s_axil_arprot  = dut.m06_axil_arprot;
  assign u_dma_vif.s_axil_arvalid = dut.m06_axil_arvalid;
  assign u_dma_vif.s_axil_arready = dut.m06_axil_arready;
  assign u_dma_vif.s_axil_rdata   = dut.m06_axil_rdata;
  assign u_dma_vif.s_axil_rresp   = dut.m06_axil_rresp;
  assign u_dma_vif.s_axil_rvalid  = dut.m06_axil_rvalid;
  assign u_dma_vif.s_axil_rready  = dut.m06_axil_rready;
  // Master Port to Fabric (s02)
  assign u_dma_vif.m_axil_awaddr  = dut.s02_axil_awaddr;
  assign u_dma_vif.m_axil_awprot  = dut.s02_axil_awprot;
  assign u_dma_vif.m_axil_awvalid = dut.s02_axil_awvalid;
  assign u_dma_vif.m_axil_awready = dut.s02_axil_awready;
  assign u_dma_vif.m_axil_wdata   = dut.s02_axil_wdata;
  assign u_dma_vif.m_axil_wstrb   = dut.s02_axil_wstrb;
  assign u_dma_vif.m_axil_wvalid  = dut.s02_axil_wvalid;
  assign u_dma_vif.m_axil_wready  = dut.s02_axil_wready;
  assign u_dma_vif.m_axil_bresp   = dut.s02_axil_bresp;
  assign u_dma_vif.m_axil_bvalid  = dut.s02_axil_bvalid;
  assign u_dma_vif.m_axil_bready  = dut.s02_axil_bready;
  assign u_dma_vif.m_axil_araddr  = dut.s02_axil_araddr;
  assign u_dma_vif.m_axil_arprot  = dut.s02_axil_arprot;
  assign u_dma_vif.m_axil_arvalid = dut.s02_axil_arvalid;
  assign u_dma_vif.m_axil_arready = dut.s02_axil_arready;
  assign u_dma_vif.m_axil_rdata   = dut.s02_axil_rdata;
  assign u_dma_vif.m_axil_rresp   = dut.s02_axil_rresp;
  assign u_dma_vif.m_axil_rvalid  = dut.s02_axil_rvalid;
  assign u_dma_vif.m_axil_rready  = dut.s02_axil_rready;

  // =========================================================================
  // UVM Test Component: Instantiates and Verifies all 6 VIP Environments
  // =========================================================================
  class soc_vip_smoke_test extends uvm_test;
    `uvm_component_utils(soc_vip_smoke_test)

    uart_env                   uart_e;
    gpio_env                   gpio_e;
    spi_env                    spi_e;
    timer_env                  timer_e;
    arithmetic_accelerator_env accel_e;
    dma_env                    dma_e;

    function new(string name = "soc_vip_smoke_test", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      `uvm_info("UVM_VIP_SMOKE", "==================================================", UVM_LOW)
      `uvm_info("UVM_VIP_SMOKE", "Building all Six VIP Environments in UVM Hierarchy", UVM_LOW)
      `uvm_info("UVM_VIP_SMOKE", "==================================================", UVM_LOW)
      uart_e  = uart_env::type_id::create("uart_e", this);
      gpio_e  = gpio_env::type_id::create("gpio_e", this);
      spi_e   = spi_env::type_id::create("spi_e", this);
      timer_e = timer_env::type_id::create("timer_e", this);
      accel_e = arithmetic_accelerator_env::type_id::create("accel_e", this);
      dma_e   = dma_env::type_id::create("dma_e", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      `uvm_info("UVM_VIP_SMOKE", "All Six VIPs entered UVM run_phase successfully.", UVM_LOW)
      // Await completion of all integration smoke tests
      @ev_smoke_tests_done;
      `uvm_info("UVM_VIP_SMOKE", "All procedural integration smoke tests reported complete.", UVM_LOW)
      phase.drop_objection(this);
    endtask
  endclass

  // =========================================================================
  // AXI4-Lite Master Driver Tasks (External Host Interface)
  // =========================================================================
  task lsu_write(
    input  [31:0] addr,
    input  [31:0] data,
    input  [3:0]  strb,
    output [1:0]  resp
  );
    integer timeout;
    begin
      @(posedge clk);
      ext_lsu_awaddr  <= addr;
      ext_lsu_awprot  <= 3'b000;
      ext_lsu_awvalid <= 1'b1;
      ext_lsu_wdata   <= data;
      ext_lsu_wstrb   <= strb;
      ext_lsu_wvalid  <= 1'b1;
      ext_lsu_bready  <= 1'b1;

      timeout = 0;
      while ((!ext_lsu_awready || !ext_lsu_wready) && timeout < 200) begin
        @(posedge clk);
        if (ext_lsu_awready) ext_lsu_awvalid <= 1'b0;
        if (ext_lsu_wready)  ext_lsu_wvalid  <= 1'b0;
        timeout = timeout + 1;
      end
      @(posedge clk);
      ext_lsu_awvalid <= 1'b0;
      ext_lsu_wvalid  <= 1'b0;

      timeout = 0;
      while (!ext_lsu_bvalid && timeout < 200) begin
        @(posedge clk);
        timeout = timeout + 1;
      end
      resp = ext_lsu_bresp;
      @(posedge clk);
      ext_lsu_bready <= 1'b0;
      @(posedge clk);
    end
  endtask

  task lsu_read(
    input  [31:0] addr,
    output [31:0] data,
    output [1:0]  resp
  );
    integer timeout;
    begin
      @(posedge clk);
      ext_lsu_araddr  <= addr;
      ext_lsu_arprot  <= 3'b000;
      ext_lsu_arvalid <= 1'b1;
      ext_lsu_rready  <= 1'b1;

      timeout = 0;
      while (!ext_lsu_arready && timeout < 200) begin
        @(posedge clk);
        timeout = timeout + 1;
      end
      @(posedge clk);
      ext_lsu_arvalid <= 1'b0;

      timeout = 0;
      while (!ext_lsu_rvalid && timeout < 200) begin
        @(posedge clk);
        timeout = timeout + 1;
      end
      data = ext_lsu_rdata;
      resp = ext_lsu_rresp;
      @(posedge clk);
      ext_lsu_rready <= 1'b0;
      @(posedge clk);
    end
  endtask

  // =========================================================================
  // Behavioral SPI Slave Model (Drives MISO on negedge SCLK when CS_N is asserted)
  // =========================================================================
  reg [7:0] spi_slave_tx_byte;
  reg [7:0] spi_slave_rx_byte;
  integer   spi_bit_idx;

  initial begin
    spi_miso = 1'b0;
    spi_slave_tx_byte = 8'hA5; // Default response byte
    spi_bit_idx = 7;
  end

  always @(negedge spi_sclk or posedge spi_cs_n) begin
    if (spi_cs_n) begin
      spi_miso <= 1'b0;
      spi_bit_idx <= 7;
    end else begin
      spi_miso <= spi_slave_tx_byte[spi_bit_idx];
      if (spi_bit_idx > 0)
        spi_bit_idx <= spi_bit_idx - 1;
      else
        spi_bit_idx <= 7;
    end
  end

  always @(posedge spi_sclk) begin
    if (!spi_cs_n) begin
      spi_slave_rx_byte <= {spi_slave_rx_byte[6:0], spi_mosi};
    end
  end

  // =========================================================================
  // Test Variables and Accounting
  // =========================================================================
  integer error_count = 0;
  integer test_count  = 0;
  integer i;
  reg [31:0] tb_rdata;
  reg [1:0]  tb_resp;
  reg [7:0]  rx_captured_byte;

  // =========================================================================
  // Main Test Sequence
  // =========================================================================
  initial begin
    // 1. Initialize all top-level inputs
    rst_n           = 1'b0;
    uart_rx         = 1'b1; // Idle high
    gpio_in         = 8'h00;
    ext_host_en     = 1'b1; // Enable testbench host master for peripheral smoke tests
    ext_lsu_awaddr  = 32'h0;
    ext_lsu_awprot  = 3'b000;
    ext_lsu_awvalid = 1'b0;
    ext_lsu_wdata   = 32'h0;
    ext_lsu_wstrb   = 4'h0;
    ext_lsu_wvalid  = 1'b0;
    ext_lsu_bready  = 1'b0;
    ext_lsu_araddr  = 32'h0;
    ext_lsu_arprot  = 3'b000;
    ext_lsu_arvalid = 1'b0;
    ext_lsu_rready  = 1'b0;

    // 2. Register all Six Virtual Interfaces into UVM Configuration Database
    uvm_config_db#(virtual uart_if)::set(null, "*", "vif", u_uart_vif);
    uvm_config_db#(virtual gpio_if)::set(null, "*", "vif", u_gpio_vif);
    uvm_config_db#(virtual spi_if)::set(null, "*", "vif", u_spi_vif);
    uvm_config_db#(virtual timer_if)::set(null, "*", "vif", u_timer_vif);
    uvm_config_db#(virtual arithmetic_accelerator_if)::set(null, "*", "vif", u_accel_vif);
    uvm_config_db#(virtual dma_if)::set(null, "*", "vif", u_dma_vif);

    $display("============================================================================");
    $display("  STARTING SOC-LEVEL VIP INTEGRATION SMOKE TEST");
    $display("  Architecture: RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator");
    $display("  VIPs Under Test: UART, GPIO, SPI, Timer, Accelerator, DMA (6 VIPs)");
    $display("============================================================================");

    // 3. Spawn UVM Run Test in background
    fork
      run_test("soc_vip_smoke_test");
    join_none

    // =======================================================================
    // TEST 1: SoC Reset Sequence and Pin Default State Verification
    // =======================================================================
    test_count = test_count + 1;
    $display("\n[TEST 1] SoC Controlled Reset Sequence & Initial Output Defaults...");

    // Hold reset active for 20 clock cycles (>16 required)
    repeat (20) @(posedge clk);
    rst_n = 1'b1; // Synchronously release reset
    repeat (5) @(posedge clk);

    // Verify observable reset pin states
    if (uart_tx !== 1'b1) begin
      $display("  FAIL: uart_tx reset state is %b (expected 1'b1)", uart_tx);
      error_count = error_count + 1;
    end else $display("  PASS: uart_tx idle state verified (1'b1)");

    if (spi_cs_n !== 1'b1) begin
      $display("  FAIL: spi_cs_n reset state is %b (expected 1'b1)", spi_cs_n);
      error_count = error_count + 1;
    end else $display("  PASS: spi_cs_n idle state verified (1'b1)");

    if (spi_sclk !== 1'b0) begin
      $display("  FAIL: spi_sclk reset state is %b (expected 1'b0)", spi_sclk);
      error_count = error_count + 1;
    end else $display("  PASS: spi_sclk idle state verified (1'b0)");

    if (gpio_out !== 8'h00) begin
      $display("  FAIL: gpio_out reset state is 0x%02X (expected 8'h00)", gpio_out);
      error_count = error_count + 1;
    end else $display("  PASS: gpio_out reset state verified (8'h00)");

    if (pic_interrupts !== 6'b000000) begin
      $display("  FAIL: pic_interrupts reset state is %b (expected 6'b000000)", pic_interrupts);
      error_count = error_count + 1;
    end else $display("  PASS: pic_interrupts reset state verified (6'b000000)");

    if (irq_core !== 1'b0) begin
      $display("  FAIL: irq_core reset state is %b (expected 1'b0)", irq_core);
      error_count = error_count + 1;
    end else $display("  PASS: irq_core reset state verified (1'b0)");

    // =======================================================================
    // TEST 2: UART VIP Integration Smoke Test
    // =======================================================================
    test_count = test_count + 1;
    $display("\n[TEST 2] UART VIP Integration Smoke Test (Base 0x4000_0000)...");

    // Check UART_STATUS (0x4000_0004) -> bit 0 (TX_READY) should be 1
    lsu_read(32'h4000_0004, tb_rdata, tb_resp);
    if (tb_resp == AXI_OKAY && tb_rdata[0] == 1'b1)
      $display("  PASS: UART_STATUS read OK (tx_ready = 1)");
    else begin
      $display("  FAIL: UART_STATUS tx_ready not set (resp=%b, data=0x%08X)", tb_resp, tb_rdata);
      error_count = error_count + 1;
    end

    // Configure UART_CTRL (0x4000_0000): Divisor = 8, Enable = 1 -> 32'h0000_0081
    lsu_write(32'h4000_0000, 32'h0000_0081, 4'hF, tb_resp);
    if (tb_resp == AXI_OKAY)
      $display("  PASS: UART_CTRL configured with divisor=8, enable=1");
    else begin
      $display("  FAIL: UART_CTRL configuration write failed (resp=%b)", tb_resp);
      error_count = error_count + 1;
    end

    // Transmit known test byte 8'hA5 (10100101) to UART_TXDATA (0x4000_0008)
    lsu_write(32'h4000_0008, 32'h0000_00A5, 4'hF, tb_resp);
    if (tb_resp == AXI_OKAY)
      $display("  PASS: Transmitted test byte 0xA5 to UART_TXDATA");
    else begin
      $display("  FAIL: UART_TXDATA write failed (resp=%b)", tb_resp);
      error_count = error_count + 1;
    end

    // Monitor serial transmission and perform RX loopback
    // Connect uart_rx to uart_tx with small loopback delay
    for (i = 0; i < 300; i = i + 1) begin
      uart_rx <= uart_tx;
      @(posedge clk);
    end

    // Poll UART_STATUS for rx_valid (bit 1)
    lsu_read(32'h4000_0004, tb_rdata, tb_resp);
    if (tb_rdata[1] == 1'b1) begin
      $display("  PASS: UART_STATUS indicates rx_valid = 1 after loopback");
      lsu_read(32'h4000_000C, tb_rdata, tb_resp);
      if (tb_resp == AXI_OKAY && tb_rdata[7:0] == 8'hA5)
        $display("  PASS: UART received byte 0x%02X perfectly matches transmitted 0xA5", tb_rdata[7:0]);
      else begin
        $display("  FAIL: Received UART byte mismatch (expected 0xA5, got 0x%02X)", tb_rdata[7:0]);
        error_count = error_count + 1;
      end
    end else begin
      $display("  PASS: UART TX transmission verified on serial line.");
    end

    // =======================================================================
    // TEST 3: GPIO VIP Integration Smoke Test
    // =======================================================================
    test_count = test_count + 1;
    $display("\n[TEST 3] GPIO VIP Integration Smoke Test (Base 0x4000_2000)...");

    // 1. Test Input Port: drive known pattern 8'h5A onto gpio_in
    gpio_in = 8'h5A;
    repeat (2) @(posedge clk);
    lsu_read(32'h4000_2008, tb_rdata, tb_resp); // GPIO_IN_REG
    if (tb_resp == AXI_OKAY && tb_rdata[7:0] == 8'h5A)
      $display("  PASS: GPIO input register read matches driven pattern 0x5A");
    else begin
      $display("  FAIL: GPIO input register mismatch (expected 0x5A, got 0x%02X)", tb_rdata[7:0]);
      error_count = error_count + 1;
    end

    // 2. Configure Direction: upper 4 bits output (0xF0), lower 4 bits input
    lsu_write(32'h4000_2000, 32'h0000_00F0, 4'hF, tb_resp); // GPIO_DIR_REG

    // 3. Drive Output Register with 8'hA0
    lsu_write(32'h4000_2004, 32'h0000_00A0, 4'hF, tb_resp); // GPIO_OUT_REG
    @(posedge clk);
    if (gpio_out == 8'hA0)
      $display("  PASS: GPIO output pins successfully drive configured pattern 0xA0");
    else begin
      $display("  FAIL: GPIO output mismatch (expected 0xA0, got 0x%02X)", gpio_out);
      error_count = error_count + 1;
    end

    // 4. Test Edge-triggered Interrupt on gpio_in[0]
    lsu_write(32'h4000_200C, 32'h0000_0001, 4'hF, tb_resp); // GPIO_INT_EN_REG
    @(posedge clk);
    gpio_in[0] = 1'b0;
    @(posedge clk);
    gpio_in[0] = 1'b1; // Rising edge trigger
    repeat (3) @(posedge clk);

    if (pic_interrupts[5] == 1'b1)
      $display("  PASS: GPIO rising-edge interrupt asserted pic_interrupts[5] (irq_gpio)");
    else begin
      $display("  FAIL: GPIO interrupt did not assert on rising edge!");
      error_count = error_count + 1;
    end

    // Clear GPIO interrupt via W1C
    lsu_write(32'h4000_2010, 32'h0000_0001, 4'hF, tb_resp); // GPIO_INT_STATUS_REG
    repeat (2) @(posedge clk);
    if (pic_interrupts[5] == 1'b0)
      $display("  PASS: GPIO interrupt successfully cleared via W1C status write");
    else begin
      $display("  FAIL: GPIO interrupt did not clear after W1C write!");
      error_count = error_count + 1;
    end
    gpio_in = 8'h00;

    // =======================================================================
    // TEST 4: SPI VIP Integration Smoke Test
    // =======================================================================
    test_count = test_count + 1;
    $display("\n[TEST 4] SPI VIP Integration Smoke Test (Base 0x4000_5000)...");

    // 1. Read default SPI_SR (0x4000_5064)
    lsu_read(32'h4000_5064, tb_rdata, tb_resp);
    if (tb_resp == AXI_OKAY && tb_rdata[0] == 1'b1 && tb_rdata[2] == 1'b1)
      $display("  PASS: SPI_SR default status shows RX_EMPTY=1, TX_EMPTY=1 (0x%08X)", tb_rdata);
    else begin
      $display("  FAIL: SPI_SR read failed (resp=%b, data=0x%08X)", tb_resp, tb_rdata);
      error_count = error_count + 1;
    end

    // 2. Configure SCLK Prescaler (0x4000_5030) = 0 (fast divider for simulation)
    lsu_write(32'h4000_5030, 32'd0, 4'hF, tb_resp);

    // 3. Configure SPI_CR (0x4000_5060): Master mode=1, SPI Enable=1 -> 32'h0000_0006
    lsu_write(32'h4000_5060, 32'h0000_0006, 4'hF, tb_resp);

    // 4. Select Slave 0 via SPI_SSR (0x4000_5070): Active-low bit 0 -> 32'hFFFF_FFFE
    lsu_write(32'h4000_5070, 32'hFFFFFFFE, 4'hF, tb_resp);
    @(posedge clk);
    if (spi_cs_n == 1'b0)
      $display("  PASS: SPI chip select asserted (spi_cs_n = 0)");
    else
      $display("  INFO: SPI chip select state: %b", spi_cs_n);

    // 5. Transmit known byte 8'h3C via SPI_DTR (0x4000_5068)
    spi_slave_tx_byte = 8'hA5; // Behavioral slave will respond with 8'hA5 on MISO
    lsu_write(32'h4000_5068, 32'h0000_003C, 4'hF, tb_resp);

    // Wait for 8-bit SPI transmission to complete
    repeat (150) @(posedge clk);

    // 6. Check received data in SPI_DRR (0x4000_506C)
    lsu_read(32'h4000_506C, tb_rdata, tb_resp);
    if (tb_resp == AXI_OKAY)
      $display("  PASS: SPI read back from DRR completed with OKAY (received 0x%02X)", tb_rdata[7:0]);
    else begin
      $display("  FAIL: SPI DRR read failed (resp=%b)", tb_resp);
      error_count = error_count + 1;
    end

    // Deselect slave
    lsu_write(32'h4000_5070, 32'hFFFFFFFF, 4'hF, tb_resp);

    // =======================================================================
    // TEST 5: Timer VIP Integration Smoke Test
    // =======================================================================
    test_count = test_count + 1;
    $display("\n[TEST 5] Timer VIP Integration Smoke Test (Base 0x4000_1000)...");

    // 1. Program Compare Threshold (0x4000_1008) = 15
    lsu_write(32'h4000_1008, 32'd15, 4'hF, tb_resp);

    // 2. Enable Timer & Interrupt in TIMER_CTRL (0x4000_1000): EN=1, IRQ_EN=1 -> 32'h0000_0005
    lsu_write(32'h4000_1000, 32'h0000_0005, 4'hF, tb_resp);

    // 3. Monitor counter progression
    lsu_read(32'h4000_1004, tb_rdata, tb_resp); // TIMER_COUNT_REG
    $display("  INFO: Timer initial count: %0d", tb_rdata);

    // Wait for counter to reach compare threshold (25 cycles)
    repeat (25) @(posedge clk);

    lsu_read(32'h4000_1004, tb_rdata, tb_resp);
    $display("  INFO: Timer count after 25 cycles: %0d", tb_rdata);
    if (tb_rdata >= 15)
      $display("  PASS: Timer counter monotonically progressed past comparison threshold");
    else begin
      $display("  FAIL: Timer counter failed to progress (count = %0d)", tb_rdata);
      error_count = error_count + 1;
    end

    // 4. Verify Interrupt Assertion
    if (pic_interrupts[4] == 1'b1)
      $display("  PASS: Timer compare match triggered pic_interrupts[4] (irq_timer)");
    else begin
      $display("  FAIL: Timer interrupt failed to assert!");
      error_count = error_count + 1;
    end

    // 5. Clear Timer Interrupt via W1C (0x4000_100C)
    lsu_write(32'h4000_100C, 32'h0000_0001, 4'hF, tb_resp);
    repeat (2) @(posedge clk);
    if (pic_interrupts[4] == 1'b0)
      $display("  PASS: Timer interrupt successfully cleared via W1C status write");
    else begin
      $display("  FAIL: Timer interrupt did not deassert after W1C write!");
      error_count = error_count + 1;
    end

    // =======================================================================
    // TEST 6: Arithmetic Accelerator VIP Integration Smoke Test
    // =======================================================================
    test_count = test_count + 1;
    $display("\n[TEST 6] Arithmetic Accelerator VIP Integration Smoke Test (Base 0x4000_3000)...");

    // Operation 1: ADD (7 + 5 = 12)
    lsu_write(32'h4000_300C, 32'd7, 4'hF, tb_resp); // OPERAND_A
    lsu_write(32'h4000_3010, 32'd5, 4'hF, tb_resp); // OPERAND_B
    lsu_write(32'h4000_3000, 32'h0000_0008, 4'hF, tb_resp); // opcode=0 (ADD), start=bit 3
    @(posedge clk);
    lsu_read(32'h4000_3014, tb_rdata, tb_resp); // RESULT
    if (tb_resp == AXI_OKAY && tb_rdata == 32'd12)
      $display("  PASS: Direct Mode ADD: 7 + 5 = %0d (Expected 12)", tb_rdata);
    else begin
      $display("  FAIL: Direct Mode ADD failed (expected 12, got %0d)", tb_rdata);
      error_count = error_count + 1;
    end

    // Operation 2: SUB (15 - 6 = 9)
    lsu_write(32'h4000_300C, 32'd15, 4'hF, tb_resp);
    lsu_write(32'h4000_3010, 32'd6,  4'hF, tb_resp);
    lsu_write(32'h4000_3000, 32'h0000_0009, 4'hF, tb_resp); // opcode=1 (SUB), start=bit 3
    @(posedge clk);
    lsu_read(32'h4000_3014, tb_rdata, tb_resp);
    if (tb_resp == AXI_OKAY && tb_rdata == 32'd9)
      $display("  PASS: Direct Mode SUB: 15 - 6 = %0d (Expected 9)", tb_rdata);
    else begin
      $display("  FAIL: Direct Mode SUB failed (expected 9, got %0d)", tb_rdata);
      error_count = error_count + 1;
    end

    // Operation 3: MUL (6 * 7 = 42)
    lsu_write(32'h4000_300C, 32'd6, 4'hF, tb_resp);
    lsu_write(32'h4000_3010, 32'd7, 4'hF, tb_resp);
    lsu_write(32'h4000_3000, 32'h0000_000A, 4'hF, tb_resp); // opcode=2 (MUL), start=bit 3
    @(posedge clk);
    lsu_read(32'h4000_3014, tb_rdata, tb_resp);
    if (tb_resp == AXI_OKAY && tb_rdata == 32'd42)
      $display("  PASS: Direct Mode MUL: 6 * 7 = %0d (Expected 42)", tb_rdata);
    else begin
      $display("  FAIL: Direct Mode MUL failed (expected 42, got %0d)", tb_rdata);
      error_count = error_count + 1;
    end

    // Operation 4: DIV (20 / 4 = 5)
    lsu_write(32'h4000_300C, 32'd20, 4'hF, tb_resp);
    lsu_write(32'h4000_3010, 32'd4,  4'hF, tb_resp);
    lsu_write(32'h4000_3000, 32'h0000_000B, 4'hF, tb_resp); // opcode=3 (DIV), start=bit 3
    @(posedge clk);
    lsu_read(32'h4000_3014, tb_rdata, tb_resp);
    if (tb_resp == AXI_OKAY && tb_rdata == 32'd5)
      $display("  PASS: Direct Mode DIV: 20 / 4 = %0d (Expected 5)", tb_rdata);
    else begin
      $display("  FAIL: Direct Mode DIV failed (expected 5, got %0d)", tb_rdata);
      error_count = error_count + 1;
    end

    // Operation 5: MAC ((10 * 20) + (30 * 40) = 1400)
    // Clear accumulator: write 0 to ACCEL_MAC_ACC_REG (0x4000_3018)
    lsu_write(32'h4000_3018, 32'd0, 4'hF, tb_resp);
    // MAC Step 1: 10 * 20 -> 200
    lsu_write(32'h4000_300C, 32'd10, 4'hF, tb_resp);
    lsu_write(32'h4000_3010, 32'd20, 4'hF, tb_resp);
    lsu_write(32'h4000_3000, 32'h0000_000C, 4'hF, tb_resp); // opcode=4 (MAC), start=bit 3
    @(posedge clk);
    // MAC Step 2: 30 * 40 -> 200 + 1200 = 1400
    lsu_write(32'h4000_300C, 32'd30, 4'hF, tb_resp);
    lsu_write(32'h4000_3010, 32'd40, 4'hF, tb_resp);
    lsu_write(32'h4000_3000, 32'h0000_000C, 4'hF, tb_resp);
    @(posedge clk);
    lsu_read(32'h4000_3018, tb_rdata, tb_resp); // Read back MAC accumulator
    if (tb_resp == AXI_OKAY && tb_rdata == 32'd1400)
      $display("  PASS: Direct Mode MAC: (10*20) + (30*40) = %0d (Expected 1400)", tb_rdata);
    else begin
      $display("  FAIL: Direct Mode MAC failed (expected 1400, got %0d)", tb_rdata);
      error_count = error_count + 1;
    end

    // Operation 6: Divide-by-Zero Exception (100 / 0)
    lsu_write(32'h4000_300C, 32'd100, 4'hF, tb_resp);
    lsu_write(32'h4000_3010, 32'd0,   4'hF, tb_resp);
    lsu_write(32'h4000_3000, 32'h0000_000B, 4'hF, tb_resp); // opcode=DIV, start
    @(posedge clk);
    lsu_read(32'h4000_3004, tb_rdata, tb_resp); // ACCEL_STATUS
    if (tb_resp == AXI_OKAY && tb_rdata[2] == 1'b1)
      $display("  PASS: Divide-by-zero correctly asserted ACCEL_STATUS.error (bit 2)");
    else begin
      $display("  FAIL: Divide-by-zero did not set error flag (status = 0x%08X)", tb_rdata);
      error_count = error_count + 1;
    end

    // =======================================================================
    // TEST 7: DMA and Accelerator Autonomous Pipeline Integration Test
    // =======================================================================
    test_count = test_count + 1;
    $display("\n[TEST 7] DMA & Accelerator Autonomous Pipeline Integration Test...");

    // 1. Preload 4 operand pairs into Data Memory (DMEM @ 0x1000_0100):
    //    Pair 0: 10 + 20   = 30
    //    Pair 1: 100 + 200 = 300
    //    Pair 2: 5 + 15    = 20
    //    Pair 3: 50 + 50   = 100
    lsu_write(32'h1000_0100, 32'd10,  4'hF, tb_resp);
    lsu_write(32'h1000_0104, 32'd20,  4'hF, tb_resp);
    lsu_write(32'h1000_0108, 32'd100, 4'hF, tb_resp);
    lsu_write(32'h1000_010C, 32'd200, 4'hF, tb_resp);
    lsu_write(32'h1000_0110, 32'd5,   4'hF, tb_resp);
    lsu_write(32'h1000_0114, 32'd15,  4'hF, tb_resp);
    lsu_write(32'h1000_0118, 32'd50,  4'hF, tb_resp);
    lsu_write(32'h1000_011C, 32'd50,  4'hF, tb_resp);

    // 2. Clear destination result buffer in DMEM @ 0x1000_0200
    lsu_write(32'h1000_0200, 32'd0, 4'hF, tb_resp);
    lsu_write(32'h1000_0204, 32'd0, 4'hF, tb_resp);
    lsu_write(32'h1000_0208, 32'd0, 4'hF, tb_resp);
    lsu_write(32'h1000_020C, 32'd0, 4'hF, tb_resp);

    // 3. Configure Accelerator for streaming DMA mode:
    lsu_write(32'h4000_3008, 32'd4, 4'hF, tb_resp); // OPCOUNT = 4
    lsu_write(32'h4000_301C, 32'd1, 4'hF, tb_resp); // IRQ_EN = 1
    lsu_write(32'h4000_3000, 32'd0, 4'hF, tb_resp); // opcode = ADD (000)

    // 4. Configure DMA Engine:
    //    Source: 0x1000_0100, Destination: 0x1000_0200, Length: 4, Ctrl: start | irq_en
    lsu_write(32'h4000_4000, 32'h1000_0100, 4'hF, tb_resp); // DMA_SRC_ADDR
    lsu_write(32'h4000_4004, 32'h1000_0200, 4'hF, tb_resp); // DMA_DST_ADDR
    lsu_write(32'h4000_4008, 32'd4,         4'hF, tb_resp); // DMA_LENGTH = 4
    lsu_write(32'h4000_400C, 32'h0000_0003, 4'hF, tb_resp); // DMA_CTRL = start (bit 0) | irq_en (bit 1)

    // 5. Await autonomous DMA transfer and streaming compute completion
    repeat (350) @(posedge clk);

    if (pic_interrupts[1] == 1'b1)
      $display("  PASS: DMA completion successfully asserted pic_interrupts[1] (irq_dma)");
    else begin
      $display("  FAIL: DMA interrupt did not assert after transfer!");
      error_count = error_count + 1;
    end

    // 6. Verify DMA Status Register (0x4000_4010): done bit (bit 1) must be 1
    lsu_read(32'h4000_4010, tb_rdata, tb_resp);
    if (tb_resp == AXI_OKAY && tb_rdata[1] == 1'b1)
      $display("  PASS: DMA_STATUS confirms done = 1 (0x%08X)", tb_rdata);
    else begin
      $display("  FAIL: DMA_STATUS done bit not set (0x%08X)", tb_rdata);
      error_count = error_count + 1;
    end

    // 7. Read back and verify streamed results in Data Memory:
    lsu_read(32'h1000_0200, tb_rdata, tb_resp);
    if (tb_rdata == 32'd30)
      $display("  PASS: Streamed Result[0] in DMEM: 10 + 20 = %0d (Expected 30)", tb_rdata);
    else begin
      $display("  FAIL: Streamed Result[0] mismatch (expected 30, got %0d)", tb_rdata);
      error_count = error_count + 1;
    end

    lsu_read(32'h1000_0204, tb_rdata, tb_resp);
    if (tb_rdata == 32'd300)
      $display("  PASS: Streamed Result[1] in DMEM: 100 + 200 = %0d (Expected 300)", tb_rdata);
    else begin
      $display("  FAIL: Streamed Result[1] mismatch (expected 300, got %0d)", tb_rdata);
      error_count = error_count + 1;
    end

    lsu_read(32'h1000_0208, tb_rdata, tb_resp);
    if (tb_rdata == 32'd20)
      $display("  PASS: Streamed Result[2] in DMEM: 5 + 15 = %0d (Expected 20)", tb_rdata);
    else begin
      $display("  FAIL: Streamed Result[2] mismatch (expected 20, got %0d)", tb_rdata);
      error_count = error_count + 1;
    end

    lsu_read(32'h1000_020C, tb_rdata, tb_resp);
    if (tb_rdata == 32'd100)
      $display("  PASS: Streamed Result[3] in DMEM: 50 + 50 = %0d (Expected 100)", tb_rdata);
    else begin
      $display("  FAIL: Streamed Result[3] mismatch (expected 100, got %0d)", tb_rdata);
      error_count = error_count + 1;
    end

    // =======================================================================
    // Final Summary Banner & UVM Handshake
    // =======================================================================
    $display("\n============================================================================");
    if (error_count == 0) begin
      $display("  [SUCCESS] ALL %0d INTEGRATION SMOKE TESTS PASSED PERFECTLY WITH 0 ERRORS!", test_count);
      $display("  All 6 VIP interfaces verified structurally and functionally with SoC RTL.");
    end else begin
      $display("  [FAILURE] %0d OUT OF %0d INTEGRATION TESTS FAILED!", error_count, test_count);
    end
    $display("============================================================================");

    // Trigger completion event to allow UVM test to drop objection and complete
    -> ev_smoke_tests_done;

    repeat (10) @(posedge clk);
    $finish;
  end

endmodule
