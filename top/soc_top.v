`timescale 1ns / 1ps

/* -------------------------------------------------------------------------------
 * Project        : RISC-V SoC with Hardware Arithmetic Accelerator
 * File           : soc_top.v
 * Description    : Top-Level SoC Module containing All IPs, Interconnect, and RISC-V
 *                  Instantiates:
 *                  1.  RISC-V VeeR EL2 Core Complex (riscv_core_top with IFU/LSU bridges)
 *                  2.  AXI4-Lite Interconnect Fabric (soc_axil_fabric, 3M x 8S)
 *                  3.  Instruction Memory (imem_axil, 64 KB @ 0x0000_0000, m00)
 *                  4.  Data Memory (dmem_axil, 64 KB @ 0x1000_0000, m01)
 *                  5.  UART Controller (soc_uart / axi_uart_top, 4 KB @ 0x4000_0000, m02)
 *                  6.  Timer Controller (soc_timer, 4 KB @ 0x4000_1000, m03)
 *                  7.  GPIO Controller (soc_gpio, 4 KB @ 0x4000_2000, m04)
 *                  8.  Arithmetic Accelerator (arithmetic_accelerator, 4 KB @ 0x4000_3000, m05)
 *                  9.  DMA Controller (dma_controller, 4 KB @ 0x4000_4000, m06 + Master s02)
 *                  10. SPI Controller (soc_spi / axi_spi_top, 4 KB @ 0x4000_5000, m07)
 *                  11. Interrupt routing: 6 peripheral IRQ lines to VeeR PIC
 * -------------------------------------------------------------------------------*/

`default_nettype none

module soc_top #(
  parameter IMEM_INIT_FILE = "soc_firmware.hex",
  parameter GPIO_WIDTH     = 8
)(
  // System Clock and Active-Low Reset
  input  wire                    clk,
  input  wire                    rst_n,

  // =========================================================================
  // External Peripheral Pins
  // =========================================================================
  // UART Pins
  output wire                    uart_tx,
  input  wire                    uart_rx,

  // SPI Pins
  output wire                    spi_sclk,
  output wire                    spi_cs_n,
  output wire                    spi_mosi,
  input  wire                    spi_miso,

  // GPIO Pins
  input  wire [GPIO_WIDTH-1:0]   gpio_in,
  output wire [GPIO_WIDTH-1:0]   gpio_out,

  // =========================================================================
  // Interrupt Vector to Core (VeeR PIC Sources 1-6)
  // =========================================================================
  output wire [5:0]              pic_interrupts, // [0] Acc, [1] DMA, [2] SPI, [3] UART, [4] Timer, [5] GPIO
  output wire                    irq_core,       // Composite interrupt request

  // =========================================================================
  // RISC-V Core Instruction Execution Trace Outputs (Debug / Verification)
  // =========================================================================
  output wire [31:0]             rv_trace_insn,
  output wire [31:0]             rv_trace_address,
  output wire                    rv_trace_valid,

  // =========================================================================
  // Testbench Host / Direct Bus Injection Interface (Optional)
  // When ext_host_en=1, enables testbench LSU driver for verifying peripherals
  // When ext_host_en=0, core LSU autonomously drives the SoC bus fabric
  // =========================================================================
  input  wire                    ext_host_en,

  input  wire [31:0]             ext_lsu_awaddr,
  input  wire [2:0]              ext_lsu_awprot,
  input  wire                    ext_lsu_awvalid,
  output wire                    ext_lsu_awready,
  input  wire [31:0]             ext_lsu_wdata,
  input  wire [3:0]              ext_lsu_wstrb,
  input  wire                    ext_lsu_wvalid,
  output wire                    ext_lsu_wready,
  output wire [1:0]              ext_lsu_bresp,
  output wire                    ext_lsu_bvalid,
  input  wire                    ext_lsu_bready,

  input  wire [31:0]             ext_lsu_araddr,
  input  wire [2:0]              ext_lsu_arprot,
  input  wire                    ext_lsu_arvalid,
  output wire                    ext_lsu_arready,
  output wire [31:0]             ext_lsu_rdata,
  output wire [1:0]              ext_lsu_rresp,
  output wire                    ext_lsu_rvalid,
  input  wire                    ext_lsu_rready
);

  // Active-high reset for interconnect fabric
  wire rst_sync = ~rst_n;

  // =========================================================================
  // Master Port Signals (sNN_axil_*)
  // =========================================================================
  // s00: CPU Instruction Fetch Unit (IFU - Read-Only)
  wire [31:0] s00_axil_awaddr  = 32'h0;
  wire [2:0]  s00_axil_awprot  = 3'b100;
  wire        s00_axil_awvalid = 1'b0;
  wire        s00_axil_awready;
  wire [31:0] s00_axil_wdata   = 32'h0;
  wire [3:0]  s00_axil_wstrb   = 4'h0;
  wire        s00_axil_wvalid  = 1'b0;
  wire        s00_axil_wready;
  wire [1:0]  s00_axil_bresp;
  wire        s00_axil_bvalid;
  wire        s00_axil_bready  = 1'b0;

  wire [31:0] s00_axil_araddr;
  wire [2:0]  s00_axil_arprot;
  wire        s00_axil_arvalid;
  wire        s00_axil_arready;
  wire [31:0] s00_axil_rdata;
  wire [1:0]  s00_axil_rresp;
  wire        s00_axil_rvalid;
  wire        s00_axil_rready;

  // s01: CPU Load/Store Unit (LSU - Read/Write)
  wire [31:0] s01_axil_awaddr;
  wire [2:0]  s01_axil_awprot;
  wire        s01_axil_awvalid;
  wire        s01_axil_awready;
  wire [31:0] s01_axil_wdata;
  wire [3:0]  s01_axil_wstrb;
  wire        s01_axil_wvalid;
  wire        s01_axil_wready;
  wire [1:0]  s01_axil_bresp;
  wire        s01_axil_bvalid;
  wire        s01_axil_bready;

  wire [31:0] s01_axil_araddr;
  wire [2:0]  s01_axil_arprot;
  wire        s01_axil_arvalid;
  wire        s01_axil_arready;
  wire [31:0] s01_axil_rdata;
  wire [1:0]  s01_axil_rresp;
  wire        s01_axil_rvalid;
  wire        s01_axil_rready;

  // s02: DMA Controller Master Port
  wire [31:0] s02_axil_awaddr;
  wire [2:0]  s02_axil_awprot;
  wire        s02_axil_awvalid;
  wire        s02_axil_awready;
  wire [31:0] s02_axil_wdata;
  wire [3:0]  s02_axil_wstrb;
  wire        s02_axil_wvalid;
  wire        s02_axil_wready;
  wire [1:0]  s02_axil_bresp;
  wire        s02_axil_bvalid;
  wire        s02_axil_bready;

  wire [31:0] s02_axil_araddr;
  wire [2:0]  s02_axil_arprot;
  wire        s02_axil_arvalid;
  wire        s02_axil_arready;
  wire [31:0] s02_axil_rdata;
  wire [1:0]  s02_axil_rresp;
  wire        s02_axil_rvalid;
  wire        s02_axil_rready;

  // =========================================================================
  // Slave Port Signals (mNN_axil_*)
  // =========================================================================
  // m00: Instruction Memory
  wire [31:0] m00_axil_awaddr;
  wire [2:0]  m00_axil_awprot;
  wire        m00_axil_awvalid;
  wire        m00_axil_awready;
  wire [31:0] m00_axil_wdata;
  wire [3:0]  m00_axil_wstrb;
  wire        m00_axil_wvalid;
  wire        m00_axil_wready;
  wire [1:0]  m00_axil_bresp;
  wire        m00_axil_bvalid;
  wire        m00_axil_bready;
  wire [31:0] m00_axil_araddr;
  wire [2:0]  m00_axil_arprot;
  wire        m00_axil_arvalid;
  wire        m00_axil_arready;
  wire [31:0] m00_axil_rdata;
  wire [1:0]  m00_axil_rresp;
  wire        m00_axil_rvalid;
  wire        m00_axil_rready;

  // m01: Data Memory
  wire [31:0] m01_axil_awaddr;
  wire [2:0]  m01_axil_awprot;
  wire        m01_axil_awvalid;
  wire        m01_axil_awready;
  wire [31:0] m01_axil_wdata;
  wire [3:0]  m01_axil_wstrb;
  wire        m01_axil_wvalid;
  wire        m01_axil_wready;
  wire [1:0]  m01_axil_bresp;
  wire        m01_axil_bvalid;
  wire        m01_axil_bready;
  wire [31:0] m01_axil_araddr;
  wire [2:0]  m01_axil_arprot;
  wire        m01_axil_arvalid;
  wire        m01_axil_arready;
  wire [31:0] m01_axil_rdata;
  wire [1:0]  m01_axil_rresp;
  wire        m01_axil_rvalid;
  wire        m01_axil_rready;

  // m02: UART Controller
  wire [31:0] m02_axil_awaddr;
  wire [2:0]  m02_axil_awprot;
  wire        m02_axil_awvalid;
  wire        m02_axil_awready;
  wire [31:0] m02_axil_wdata;
  wire [3:0]  m02_axil_wstrb;
  wire        m02_axil_wvalid;
  wire        m02_axil_wready;
  wire [1:0]  m02_axil_bresp;
  wire        m02_axil_bvalid;
  wire        m02_axil_bready;
  wire [31:0] m02_axil_araddr;
  wire [2:0]  m02_axil_arprot;
  wire        m02_axil_arvalid;
  wire        m02_axil_arready;
  wire [31:0] m02_axil_rdata;
  wire [1:0]  m02_axil_rresp;
  wire        m02_axil_rvalid;
  wire        m02_axil_rready;

  // m03: Timer Controller
  wire [31:0] m03_axil_awaddr;
  wire [2:0]  m03_axil_awprot;
  wire        m03_axil_awvalid;
  wire        m03_axil_awready;
  wire [31:0] m03_axil_wdata;
  wire [3:0]  m03_axil_wstrb;
  wire        m03_axil_wvalid;
  wire        m03_axil_wready;
  wire [1:0]  m03_axil_bresp;
  wire        m03_axil_bvalid;
  wire        m03_axil_bready;
  wire [31:0] m03_axil_araddr;
  wire [2:0]  m03_axil_arprot;
  wire        m03_axil_arvalid;
  wire        m03_axil_arready;
  wire [31:0] m03_axil_rdata;
  wire [1:0]  m03_axil_rresp;
  wire        m03_axil_rvalid;
  wire        m03_axil_rready;

  // m04: GPIO Controller
  wire [31:0] m04_axil_awaddr;
  wire [2:0]  m04_axil_awprot;
  wire        m04_axil_awvalid;
  wire        m04_axil_awready;
  wire [31:0] m04_axil_wdata;
  wire [3:0]  m04_axil_wstrb;
  wire        m04_axil_wvalid;
  wire        m04_axil_wready;
  wire [1:0]  m04_axil_bresp;
  wire        m04_axil_bvalid;
  wire        m04_axil_bready;
  wire [31:0] m04_axil_araddr;
  wire [2:0]  m04_axil_arprot;
  wire        m04_axil_arvalid;
  wire        m04_axil_arready;
  wire [31:0] m04_axil_rdata;
  wire [1:0]  m04_axil_rresp;
  wire        m04_axil_rvalid;
  wire        m04_axil_rready;

  // m05: Arithmetic Accelerator
  wire [31:0] m05_axil_awaddr;
  wire [2:0]  m05_axil_awprot;
  wire        m05_axil_awvalid;
  wire        m05_axil_awready;
  wire [31:0] m05_axil_wdata;
  wire [3:0]  m05_axil_wstrb;
  wire        m05_axil_wvalid;
  wire        m05_axil_wready;
  wire [1:0]  m05_axil_bresp;
  wire        m05_axil_bvalid;
  wire        m05_axil_bready;
  wire [31:0] m05_axil_araddr;
  wire [2:0]  m05_axil_arprot;
  wire        m05_axil_arvalid;
  wire        m05_axil_arready;
  wire [31:0] m05_axil_rdata;
  wire [1:0]  m05_axil_rresp;
  wire        m05_axil_rvalid;
  wire        m05_axil_rready;

  // m06: DMA Controller Registers
  wire [31:0] m06_axil_awaddr;
  wire [2:0]  m06_axil_awprot;
  wire        m06_axil_awvalid;
  wire        m06_axil_awready;
  wire [31:0] m06_axil_wdata;
  wire [3:0]  m06_axil_wstrb;
  wire        m06_axil_wvalid;
  wire        m06_axil_wready;
  wire [1:0]  m06_axil_bresp;
  wire        m06_axil_bvalid;
  wire        m06_axil_bready;
  wire [31:0] m06_axil_araddr;
  wire [2:0]  m06_axil_arprot;
  wire        m06_axil_arvalid;
  wire        m06_axil_arready;
  wire [31:0] m06_axil_rdata;
  wire [1:0]  m06_axil_rresp;
  wire        m06_axil_rvalid;
  wire        m06_axil_rready;

  // m07: SPI Controller
  wire [31:0] m07_axil_awaddr;
  wire [2:0]  m07_axil_awprot;
  wire        m07_axil_awvalid;
  wire        m07_axil_awready;
  wire [31:0] m07_axil_wdata;
  wire [3:0]  m07_axil_wstrb;
  wire        m07_axil_wvalid;
  wire        m07_axil_wready;
  wire [1:0]  m07_axil_bresp;
  wire        m07_axil_bvalid;
  wire        m07_axil_bready;
  wire [31:0] m07_axil_araddr;
  wire [2:0]  m07_axil_arprot;
  wire        m07_axil_arvalid;
  wire        m07_axil_arready;
  wire [31:0] m07_axil_rdata;
  wire [1:0]  m07_axil_rresp;
  wire        m07_axil_rvalid;
  wire        m07_axil_rready;

  // Dedicated Streaming Interface (DMA <-> Accelerator)
  wire        dma_op_valid;
  wire [31:0] dma_op_data_a;
  wire [31:0] dma_op_data_b;
  wire        dma_op_ready;
  wire        dma_res_valid;
  wire [31:0] dma_res_data;
  wire        dma_res_ready;
  wire        dma_last;

  // Interrupt Lines
  wire        irq_acc;
  wire        irq_dma;
  wire        irq_spi;
  wire        irq_uart;
  wire        irq_timer;
  wire        irq_gpio;

  assign pic_interrupts = {irq_gpio, irq_timer, irq_uart, irq_spi, irq_dma, irq_acc};
  assign irq_core       = |pic_interrupts;

  // =========================================================================
  // 1. RISC-V VeeR EL2 Core Complex (with IFU and LSU AXI Bridges)
  // =========================================================================
  riscv_core_top u_riscv_core (
    .clk              (clk),
    .rst_n            (rst_n),

    // Interrupt Lines to Core PIC
    .irq_acc          (irq_acc),
    .irq_dma          (irq_dma),
    .irq_spi          (irq_spi),
    .irq_uart         (irq_uart),
    .irq_timer        (irq_timer),
    .irq_gpio         (irq_gpio),

    // Master Port s00 (IFU)
    .ifu_axil_araddr  (s00_axil_araddr),
    .ifu_axil_arprot  (s00_axil_arprot),
    .ifu_axil_arvalid (s00_axil_arvalid),
    .ifu_axil_arready (s00_axil_arready),
    .ifu_axil_rdata   (s00_axil_rdata),
    .ifu_axil_rresp   (s00_axil_rresp),
    .ifu_axil_rvalid  (s00_axil_rvalid),
    .ifu_axil_rready  (s00_axil_rready),

    // Master Port s01 (LSU)
    .lsu_axil_awaddr  (s01_axil_awaddr),
    .lsu_axil_awprot  (s01_axil_awprot),
    .lsu_axil_awvalid (s01_axil_awvalid),
    .lsu_axil_awready (s01_axil_awready),
    .lsu_axil_wdata   (s01_axil_wdata),
    .lsu_axil_wstrb   (s01_axil_wstrb),
    .lsu_axil_wvalid  (s01_axil_wvalid),
    .lsu_axil_wready  (s01_axil_wready),
    .lsu_axil_bresp   (s01_axil_bresp),
    .lsu_axil_bvalid  (s01_axil_bvalid),
    .lsu_axil_bready  (s01_axil_bready),

    .lsu_axil_araddr  (s01_axil_araddr),
    .lsu_axil_arprot  (s01_axil_arprot),
    .lsu_axil_arvalid (s01_axil_arvalid),
    .lsu_axil_arready (s01_axil_arready),
    .lsu_axil_rdata   (s01_axil_rdata),
    .lsu_axil_rresp   (s01_axil_rresp),
    .lsu_axil_rvalid  (s01_axil_rvalid),
    .lsu_axil_rready  (s01_axil_rready),

    // External Host / Testbench Driver
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
    .ext_lsu_rready   (ext_lsu_rready),

    // Trace signals
    .rv_trace_insn    (rv_trace_insn),
    .rv_trace_address (rv_trace_address),
    .rv_trace_valid   (rv_trace_valid)
  );

  // =========================================================================
  // 2. AXI4-Lite Interconnect Fabric (soc_axil_fabric)
  // =========================================================================
  soc_axil_fabric u_fabric (
    .clk              (clk),
    .rst              (rst_sync),

    // Master Ports
    // s00: IFU
    .s00_axil_awaddr  (s00_axil_awaddr),
    .s00_axil_awprot  (s00_axil_awprot),
    .s00_axil_awvalid (s00_axil_awvalid),
    .s00_axil_awready (s00_axil_awready),
    .s00_axil_wdata   (s00_axil_wdata),
    .s00_axil_wstrb   (s00_axil_wstrb),
    .s00_axil_wvalid  (s00_axil_wvalid),
    .s00_axil_wready  (s00_axil_wready),
    .s00_axil_bresp   (s00_axil_bresp),
    .s00_axil_bvalid  (s00_axil_bvalid),
    .s00_axil_bready  (s00_axil_bready),
    .s00_axil_araddr  (s00_axil_araddr),
    .s00_axil_arprot  (s00_axil_arprot),
    .s00_axil_arvalid (s00_axil_arvalid),
    .s00_axil_arready (s00_axil_arready),
    .s00_axil_rdata   (s00_axil_rdata),
    .s00_axil_rresp   (s00_axil_rresp),
    .s00_axil_rvalid  (s00_axil_rvalid),
    .s00_axil_rready  (s00_axil_rready),

    // s01: LSU
    .s01_axil_awaddr  (s01_axil_awaddr),
    .s01_axil_awprot  (s01_axil_awprot),
    .s01_axil_awvalid (s01_axil_awvalid),
    .s01_axil_awready (s01_axil_awready),
    .s01_axil_wdata   (s01_axil_wdata),
    .s01_axil_wstrb   (s01_axil_wstrb),
    .s01_axil_wvalid  (s01_axil_wvalid),
    .s01_axil_wready  (s01_axil_wready),
    .s01_axil_bresp   (s01_axil_bresp),
    .s01_axil_bvalid  (s01_axil_bvalid),
    .s01_axil_bready  (s01_axil_bready),
    .s01_axil_araddr  (s01_axil_araddr),
    .s01_axil_arprot  (s01_axil_arprot),
    .s01_axil_arvalid (s01_axil_arvalid),
    .s01_axil_arready (s01_axil_arready),
    .s01_axil_rdata   (s01_axil_rdata),
    .s01_axil_rresp   (s01_axil_rresp),
    .s01_axil_rvalid  (s01_axil_rvalid),
    .s01_axil_rready  (s01_axil_rready),

    // s02: DMA Master
    .s02_axil_awaddr  (s02_axil_awaddr),
    .s02_axil_awprot  (s02_axil_awprot),
    .s02_axil_awvalid (s02_axil_awvalid),
    .s02_axil_awready (s02_axil_awready),
    .s02_axil_wdata   (s02_axil_wdata),
    .s02_axil_wstrb   (s02_axil_wstrb),
    .s02_axil_wvalid  (s02_axil_wvalid),
    .s02_axil_wready  (s02_axil_wready),
    .s02_axil_bresp   (s02_axil_bresp),
    .s02_axil_bvalid  (s02_axil_bvalid),
    .s02_axil_bready  (s02_axil_bready),
    .s02_axil_araddr  (s02_axil_araddr),
    .s02_axil_arprot  (s02_axil_arprot),
    .s02_axil_arvalid (s02_axil_arvalid),
    .s02_axil_arready (s02_axil_arready),
    .s02_axil_rdata   (s02_axil_rdata),
    .s02_axil_rresp   (s02_axil_rresp),
    .s02_axil_rvalid  (s02_axil_rvalid),
    .s02_axil_rready  (s02_axil_rready),

    // Slave Ports
    // m00: IMEM
    .m00_axil_awaddr  (m00_axil_awaddr),
    .m00_axil_awprot  (m00_axil_awprot),
    .m00_axil_awvalid (m00_axil_awvalid),
    .m00_axil_awready (m00_axil_awready),
    .m00_axil_wdata   (m00_axil_wdata),
    .m00_axil_wstrb   (m00_axil_wstrb),
    .m00_axil_wvalid  (m00_axil_wvalid),
    .m00_axil_wready  (m00_axil_wready),
    .m00_axil_bresp   (m00_axil_bresp),
    .m00_axil_bvalid  (m00_axil_bvalid),
    .m00_axil_bready  (m00_axil_bready),
    .m00_axil_araddr  (m00_axil_araddr),
    .m00_axil_arprot  (m00_axil_arprot),
    .m00_axil_arvalid (m00_axil_arvalid),
    .m00_axil_arready (m00_axil_arready),
    .m00_axil_rdata   (m00_axil_rdata),
    .m00_axil_rresp   (m00_axil_rresp),
    .m00_axil_rvalid  (m00_axil_rvalid),
    .m00_axil_rready  (m00_axil_rready),

    // m01: DMEM
    .m01_axil_awaddr  (m01_axil_awaddr),
    .m01_axil_awprot  (m01_axil_awprot),
    .m01_axil_awvalid (m01_axil_awvalid),
    .m01_axil_awready (m01_axil_awready),
    .m01_axil_wdata   (m01_axil_wdata),
    .m01_axil_wstrb   (m01_axil_wstrb),
    .m01_axil_wvalid  (m01_axil_wvalid),
    .m01_axil_wready  (m01_axil_wready),
    .m01_axil_bresp   (m01_axil_bresp),
    .m01_axil_bvalid  (m01_axil_bvalid),
    .m01_axil_bready  (m01_axil_bready),
    .m01_axil_araddr  (m01_axil_araddr),
    .m01_axil_arprot  (m01_axil_arprot),
    .m01_axil_arvalid (m01_axil_arvalid),
    .m01_axil_arready (m01_axil_arready),
    .m01_axil_rdata   (m01_axil_rdata),
    .m01_axil_rresp   (m01_axil_rresp),
    .m01_axil_rvalid  (m01_axil_rvalid),
    .m01_axil_rready  (m01_axil_rready),

    // m02: UART
    .m02_axil_awaddr  (m02_axil_awaddr),
    .m02_axil_awprot  (m02_axil_awprot),
    .m02_axil_awvalid (m02_axil_awvalid),
    .m02_axil_awready (m02_axil_awready),
    .m02_axil_wdata   (m02_axil_wdata),
    .m02_axil_wstrb   (m02_axil_wstrb),
    .m02_axil_wvalid  (m02_axil_wvalid),
    .m02_axil_wready  (m02_axil_wready),
    .m02_axil_bresp   (m02_axil_bresp),
    .m02_axil_bvalid  (m02_axil_bvalid),
    .m02_axil_bready  (m02_axil_bready),
    .m02_axil_araddr  (m02_axil_araddr),
    .m02_axil_arprot  (m02_axil_arprot),
    .m02_axil_arvalid (m02_axil_arvalid),
    .m02_axil_arready (m02_axil_arready),
    .m02_axil_rdata   (m02_axil_rdata),
    .m02_axil_rresp   (m02_axil_rresp),
    .m02_axil_rvalid  (m02_axil_rvalid),
    .m02_axil_rready  (m02_axil_rready),

    // m03: Timer
    .m03_axil_awaddr  (m03_axil_awaddr),
    .m03_axil_awprot  (m03_axil_awprot),
    .m03_axil_awvalid (m03_axil_awvalid),
    .m03_axil_awready (m03_axil_awready),
    .m03_axil_wdata   (m03_axil_wdata),
    .m03_axil_wstrb   (m03_axil_wstrb),
    .m03_axil_wvalid  (m03_axil_wvalid),
    .m03_axil_wready  (m03_axil_wready),
    .m03_axil_bresp   (m03_axil_bresp),
    .m03_axil_bvalid  (m03_axil_bvalid),
    .m03_axil_bready  (m03_axil_bready),
    .m03_axil_araddr  (m03_axil_araddr),
    .m03_axil_arprot  (m03_axil_arprot),
    .m03_axil_arvalid (m03_axil_arvalid),
    .m03_axil_arready (m03_axil_arready),
    .m03_axil_rdata   (m03_axil_rdata),
    .m03_axil_rresp   (m03_axil_rresp),
    .m03_axil_rvalid  (m03_axil_rvalid),
    .m03_axil_rready  (m03_axil_rready),

    // m04: GPIO
    .m04_axil_awaddr  (m04_axil_awaddr),
    .m04_axil_awprot  (m04_axil_awprot),
    .m04_axil_awvalid (m04_axil_awvalid),
    .m04_axil_awready (m04_axil_awready),
    .m04_axil_wdata   (m04_axil_wdata),
    .m04_axil_wstrb   (m04_axil_wstrb),
    .m04_axil_wvalid  (m04_axil_wvalid),
    .m04_axil_wready  (m04_axil_wready),
    .m04_axil_bresp   (m04_axil_bresp),
    .m04_axil_bvalid  (m04_axil_bvalid),
    .m04_axil_bready  (m04_axil_bready),
    .m04_axil_araddr  (m04_axil_araddr),
    .m04_axil_arprot  (m04_axil_arprot),
    .m04_axil_arvalid (m04_axil_arvalid),
    .m04_axil_arready (m04_axil_arready),
    .m04_axil_rdata   (m04_axil_rdata),
    .m04_axil_rresp   (m04_axil_rresp),
    .m04_axil_rvalid  (m04_axil_rvalid),
    .m04_axil_rready  (m04_axil_rready),

    // m05: Accelerator
    .m05_axil_awaddr  (m05_axil_awaddr),
    .m05_axil_awprot  (m05_axil_awprot),
    .m05_axil_awvalid (m05_axil_awvalid),
    .m05_axil_awready (m05_axil_awready),
    .m05_axil_wdata   (m05_axil_wdata),
    .m05_axil_wstrb   (m05_axil_wstrb),
    .m05_axil_wvalid  (m05_axil_wvalid),
    .m05_axil_wready  (m05_axil_wready),
    .m05_axil_bresp   (m05_axil_bresp),
    .m05_axil_bvalid  (m05_axil_bvalid),
    .m05_axil_bready  (m05_axil_bready),
    .m05_axil_araddr  (m05_axil_araddr),
    .m05_axil_arprot  (m05_axil_arprot),
    .m05_axil_arvalid (m05_axil_arvalid),
    .m05_axil_arready (m05_axil_arready),
    .m05_axil_rdata   (m05_axil_rdata),
    .m05_axil_rresp   (m05_axil_rresp),
    .m05_axil_rvalid  (m05_axil_rvalid),
    .m05_axil_rready  (m05_axil_rready),

    // m06: DMA Registers
    .m06_axil_awaddr  (m06_axil_awaddr),
    .m06_axil_awprot  (m06_axil_awprot),
    .m06_axil_awvalid (m06_axil_awvalid),
    .m06_axil_awready (m06_axil_awready),
    .m06_axil_wdata   (m06_axil_wdata),
    .m06_axil_wstrb   (m06_axil_wstrb),
    .m06_axil_wvalid  (m06_axil_wvalid),
    .m06_axil_wready  (m06_axil_wready),
    .m06_axil_bresp   (m06_axil_bresp),
    .m06_axil_bvalid  (m06_axil_bvalid),
    .m06_axil_bready  (m06_axil_bready),
    .m06_axil_araddr  (m06_axil_araddr),
    .m06_axil_arprot  (m06_axil_arprot),
    .m06_axil_arvalid (m06_axil_arvalid),
    .m06_axil_arready (m06_axil_arready),
    .m06_axil_rdata   (m06_axil_rdata),
    .m06_axil_rresp   (m06_axil_rresp),
    .m06_axil_rvalid  (m06_axil_rvalid),
    .m06_axil_rready  (m06_axil_rready),

    // m07: SPI
    .m07_axil_awaddr  (m07_axil_awaddr),
    .m07_axil_awprot  (m07_axil_awprot),
    .m07_axil_awvalid (m07_axil_awvalid),
    .m07_axil_awready (m07_axil_awready),
    .m07_axil_wdata   (m07_axil_wdata),
    .m07_axil_wstrb   (m07_axil_wstrb),
    .m07_axil_wvalid  (m07_axil_wvalid),
    .m07_axil_wready  (m07_axil_wready),
    .m07_axil_bresp   (m07_axil_bresp),
    .m07_axil_bvalid  (m07_axil_bvalid),
    .m07_axil_bready  (m07_axil_bready),
    .m07_axil_araddr  (m07_axil_araddr),
    .m07_axil_arprot  (m07_axil_arprot),
    .m07_axil_arvalid (m07_axil_arvalid),
    .m07_axil_arready (m07_axil_arready),
    .m07_axil_rdata   (m07_axil_rdata),
    .m07_axil_rresp   (m07_axil_rresp),
    .m07_axil_rvalid  (m07_axil_rvalid),
    .m07_axil_rready  (m07_axil_rready)
  );

  // =========================================================================
  // 3. Instruction Memory (m00 @ 0x0000_0000, 64 KB, Read-Only)
  // =========================================================================
  imem_axil #(
    .INIT_FILE (IMEM_INIT_FILE)
  ) u_imem (
    .clk     (clk),
    .rst_n   (rst_n),
    .awaddr  (m00_axil_awaddr),
    .awprot  (m00_axil_awprot),
    .awvalid (m00_axil_awvalid),
    .awready (m00_axil_awready),
    .wdata   (m00_axil_wdata),
    .wstrb   (m00_axil_wstrb),
    .wvalid  (m00_axil_wvalid),
    .wready  (m00_axil_wready),
    .bresp   (m00_axil_bresp),
    .bvalid  (m00_axil_bvalid),
    .bready  (m00_axil_bready),
    .araddr  (m00_axil_araddr),
    .arprot  (m00_axil_arprot),
    .arvalid (m00_axil_arvalid),
    .arready (m00_axil_arready),
    .rdata   (m00_axil_rdata),
    .rresp   (m00_axil_rresp),
    .rvalid  (m00_axil_rvalid),
    .rready  (m00_axil_rready)
  );

  // =========================================================================
  // 4. Data Memory (m01 @ 0x1000_0000, 64 KB, Read/Write with Byte Strobes)
  // =========================================================================
  dmem_axil u_dmem (
    .clk     (clk),
    .rst_n   (rst_n),
    .awaddr  (m01_axil_awaddr),
    .awprot  (m01_axil_awprot),
    .awvalid (m01_axil_awvalid),
    .awready (m01_axil_awready),
    .wdata   (m01_axil_wdata),
    .wstrb   (m01_axil_wstrb),
    .wvalid  (m01_axil_wvalid),
    .wready  (m01_axil_wready),
    .bresp   (m01_axil_bresp),
    .bvalid  (m01_axil_bvalid),
    .bready  (m01_axil_bready),
    .araddr  (m01_axil_araddr),
    .arprot  (m01_axil_arprot),
    .arvalid (m01_axil_arvalid),
    .arready (m01_axil_arready),
    .rdata   (m01_axil_rdata),
    .rresp   (m01_axil_rresp),
    .rvalid  (m01_axil_rvalid),
    .rready  (m01_axil_rready)
  );

  // =========================================================================
  // 5. UART Controller (m02 @ 0x4000_0000, 4 KB)
  // =========================================================================
  soc_uart u_uart (
    .clk             (clk),
    .rst_n           (rst_n),
    .m02_axil_awaddr (m02_axil_awaddr),
    .m02_axil_awprot (m02_axil_awprot),
    .m02_axil_awvalid(m02_axil_awvalid),
    .m02_axil_awready(m02_axil_awready),
    .m02_axil_wdata  (m02_axil_wdata),
    .m02_axil_wstrb  (m02_axil_wstrb),
    .m02_axil_wvalid (m02_axil_wvalid),
    .m02_axil_wready (m02_axil_wready),
    .m02_axil_bresp  (m02_axil_bresp),
    .m02_axil_bvalid (m02_axil_bvalid),
    .m02_axil_bready (m02_axil_bready),
    .m02_axil_araddr (m02_axil_araddr),
    .m02_axil_arprot (m02_axil_arprot),
    .m02_axil_arvalid(m02_axil_arvalid),
    .m02_axil_arready(m02_axil_arready),
    .m02_axil_rdata  (m02_axil_rdata),
    .m02_axil_rresp  (m02_axil_rresp),
    .m02_axil_rvalid (m02_axil_rvalid),
    .m02_axil_rready (m02_axil_rready),
    .uart_tx         (uart_tx),
    .uart_rx         (uart_rx),
    .irq_uart        (irq_uart)
  );

  // =========================================================================
  // 6. Timer Controller (m03 @ 0x4000_1000, 4 KB)
  // =========================================================================
  soc_timer u_timer (
    .clk       (clk),
    .rst_n     (rst_n),
    .awaddr    (m03_axil_awaddr),
    .awprot    (m03_axil_awprot),
    .awvalid   (m03_axil_awvalid),
    .awready   (m03_axil_awready),
    .wdata     (m03_axil_wdata),
    .wstrb     (m03_axil_wstrb),
    .wvalid    (m03_axil_wvalid),
    .wready    (m03_axil_wready),
    .bresp     (m03_axil_bresp),
    .bvalid    (m03_axil_bvalid),
    .bready    (m03_axil_bready),
    .araddr    (m03_axil_araddr),
    .arprot    (m03_axil_arprot),
    .arvalid   (m03_axil_arvalid),
    .arready   (m03_axil_arready),
    .rdata     (m03_axil_rdata),
    .rresp     (m03_axil_rresp),
    .rvalid    (m03_axil_rvalid),
    .rready    (m03_axil_rready),
    .irq_timer (irq_timer)
  );

  // =========================================================================
  // 7. GPIO Controller (m04 @ 0x4000_2000, 4 KB)
  // =========================================================================
  soc_gpio #(
    .N (GPIO_WIDTH)
  ) u_gpio (
    .clk      (clk),
    .rst_n    (rst_n),
    .awaddr   (m04_axil_awaddr),
    .awprot   (m04_axil_awprot),
    .awvalid  (m04_axil_awvalid),
    .awready  (m04_axil_awready),
    .wdata    (m04_axil_wdata),
    .wstrb    (m04_axil_wstrb),
    .wvalid   (m04_axil_wvalid),
    .wready   (m04_axil_wready),
    .bresp    (m04_axil_bresp),
    .bvalid   (m04_axil_bvalid),
    .bready   (m04_axil_bready),
    .araddr   (m04_axil_araddr),
    .arprot   (m04_axil_arprot),
    .arvalid  (m04_axil_arvalid),
    .arready  (m04_axil_arready),
    .rdata    (m04_axil_rdata),
    .rresp    (m04_axil_rresp),
    .rvalid   (m04_axil_rvalid),
    .rready   (m04_axil_rready),
    .gpio_in  (gpio_in),
    .gpio_out (gpio_out),
    .irq_gpio (irq_gpio)
  );

  // =========================================================================
  // 8. Arithmetic Accelerator (m05 @ 0x4000_3000, 4 KB)
  // =========================================================================
  arithmetic_accelerator u_accelerator (
    .clk           (clk),
    .rst_n         (rst_n),
    .awaddr        (m05_axil_awaddr),
    .awprot        (m05_axil_awprot),
    .awvalid       (m05_axil_awvalid),
    .awready       (m05_axil_awready),
    .wdata         (m05_axil_wdata),
    .wstrb         (m05_axil_wstrb),
    .wvalid        (m05_axil_wvalid),
    .wready        (m05_axil_wready),
    .bresp         (m05_axil_bresp),
    .bvalid        (m05_axil_bvalid),
    .bready        (m05_axil_bready),
    .araddr        (m05_axil_araddr),
    .arprot        (m05_axil_arprot),
    .arvalid       (m05_axil_arvalid),
    .arready       (m05_axil_arready),
    .rdata         (m05_axil_rdata),
    .rresp         (m05_axil_rresp),
    .rvalid        (m05_axil_rvalid),
    .rready        (m05_axil_rready),

    // Streaming point-to-point interface to DMA
    .dma_op_valid  (dma_op_valid),
    .dma_op_data_a (dma_op_data_a),
    .dma_op_data_b (dma_op_data_b),
    .dma_op_ready  (dma_op_ready),
    .dma_res_valid (dma_res_valid),
    .dma_res_data  (dma_res_data),
    .dma_res_ready (dma_res_ready),
    .dma_last      (dma_last),

    .irq_acc       (irq_acc)
  );

  // =========================================================================
  // 9. DMA Controller (m06 @ 0x4000_4000, 4 KB + Master s02)
  // =========================================================================
  dma_controller u_dma (
    .clk           (clk),
    .rst_n         (rst_n),

    // Configuration Slave Port (m06)
    .awaddr        (m06_axil_awaddr),
    .awprot        (m06_axil_awprot),
    .awvalid       (m06_axil_awvalid),
    .awready       (m06_axil_awready),
    .wdata         (m06_axil_wdata),
    .wstrb         (m06_axil_wstrb),
    .wvalid        (m06_axil_wvalid),
    .wready        (m06_axil_wready),
    .bresp         (m06_axil_bresp),
    .bvalid        (m06_axil_bvalid),
    .bready        (m06_axil_bready),
    .araddr        (m06_axil_araddr),
    .arprot        (m06_axil_arprot),
    .arvalid       (m06_axil_arvalid),
    .arready       (m06_axil_arready),
    .rdata         (m06_axil_rdata),
    .rresp         (m06_axil_rresp),
    .rvalid        (m06_axil_rvalid),
    .rready        (m06_axil_rready),

    // Fabric Master Port (s02)
    .m_awaddr      (s02_axil_awaddr),
    .m_awprot      (s02_axil_awprot),
    .m_awvalid     (s02_axil_awvalid),
    .m_awready     (s02_axil_awready),
    .m_wdata       (s02_axil_wdata),
    .m_wstrb       (s02_axil_wstrb),
    .m_wvalid      (s02_axil_wvalid),
    .m_wready      (s02_axil_wready),
    .m_bresp       (s02_axil_bresp),
    .m_bvalid      (s02_axil_bvalid),
    .m_bready      (s02_axil_bready),
    .m_araddr      (s02_axil_araddr),
    .m_arprot      (s02_axil_arprot),
    .m_arvalid     (s02_axil_arvalid),
    .m_arready     (s02_axil_arready),
    .m_rdata       (s02_axil_rdata),
    .m_rresp       (s02_axil_rresp),
    .m_rvalid      (s02_axil_rvalid),
    .m_rready      (s02_axil_rready),

    // Streaming point-to-point interface to Accelerator
    .dma_op_valid  (dma_op_valid),
    .dma_op_data_a (dma_op_data_a),
    .dma_op_data_b (dma_op_data_b),
    .dma_op_ready  (dma_op_ready),
    .dma_res_valid (dma_res_valid),
    .dma_res_data  (dma_res_data),
    .dma_res_ready (dma_res_ready),
    .dma_last      (dma_last),

    .irq_dma       (irq_dma)
  );

  // =========================================================================
  // 10. SPI Controller (m07 @ 0x4000_5000, 4 KB)
  // =========================================================================
  soc_spi u_spi (
    .clk             (clk),
    .rst_n           (rst_n),
    .m07_axil_awaddr (m07_axil_awaddr),
    .m07_axil_awprot (m07_axil_awprot),
    .m07_axil_awvalid(m07_axil_awvalid),
    .m07_axil_awready(m07_axil_awready),
    .m07_axil_wdata  (m07_axil_wdata),
    .m07_axil_wstrb  (m07_axil_wstrb),
    .m07_axil_wvalid (m07_axil_wvalid),
    .m07_axil_wready (m07_axil_wready),
    .m07_axil_bresp  (m07_axil_bresp),
    .m07_axil_bvalid (m07_axil_bvalid),
    .m07_axil_bready (m07_axil_bready),
    .m07_axil_araddr (m07_axil_araddr),
    .m07_axil_arprot (m07_axil_arprot),
    .m07_axil_arvalid(m07_axil_arvalid),
    .m07_axil_arready(m07_axil_arready),
    .m07_axil_rdata  (m07_axil_rdata),
    .m07_axil_rresp  (m07_axil_rresp),
    .m07_axil_rvalid (m07_axil_rvalid),
    .m07_axil_rready (m07_axil_rready),
    .spi_sclk        (spi_sclk),
    .spi_cs_n        (spi_cs_n),
    .spi_mosi        (spi_mosi),
    .spi_miso        (spi_miso),
    .irq_spi         (irq_spi)
  );

endmodule

`default_nettype wire
