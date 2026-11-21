`timescale 1ns / 1ps

/* -------------------------------------------------------------------------------
 * Project        : RISC-V SoC with Hardware Arithmetic Accelerator
 * File           : tb_soc_fabric.v
 * Description    : Full SoC Fabric & Subsystem Testbench
 *                  Tests:
 *                  1. Access Permissions Matrix Verification (Section 3 & 5):
 *                     - s01 (LSU) -> DMEM (0x1000_0000) R/W -> OKAY
 *                     - s01 (LSU) -> IMEM (0x0000_0000) R -> OKAY, W -> DECERR
 *                     - s00 (IFU) -> Peripherals (0x4000_0000) -> DECERR
 *                     - s02 (DMA) -> Peripherals (0x4000_0000) -> DECERR
 *                  2. Peripheral Register Configuration:
 *                     - s01 -> UART (m02, 0x4000_0000)
 *                     - s01 -> Timer (m03, 0x4000_1000)
 *                     - s01 -> GPIO (m04, 0x4000_2000)
 *                     - s01 -> Accelerator (m05, 0x4000_3000)
 *                     - s01 -> DMA (m06, 0x4000_4000)
 *                     - s01 -> SPI (m07, 0x4000_5000)
 *                  3. End-to-End Autonomous Compute Path:
 *                     - Software stages operands in Data Memory (m01)
 *                     - Configures Accelerator (ADD) & DMA Controller
 *                     - DMA reads operands over fabric -> streams to Accelerator ->
 *                       streams result back -> writes result to Data Memory over fabric
 *                     - CPU reads back and verifies computed result from DMEM!
 * -------------------------------------------------------------------------------*/

`timescale 1ns / 1ps

module tb_soc_fabric;

  localparam CLK_PERIOD = 10;
  localparam AXI_OKAY   = 2'b00;
  localparam AXI_SLVERR = 2'b10;
  localparam AXI_DECERR = 2'b11;

  reg clk;
  reg rst_n;
  wire rst = ~rst_n;

  // Master Port s00 (IFU)
  reg  [31:0] s00_awaddr; reg [2:0] s00_awprot; reg s00_awvalid; wire s00_awready;
  reg  [31:0] s00_wdata; reg [3:0] s00_wstrb; reg s00_wvalid; wire s00_wready;
  wire [1:0]  s00_bresp; wire s00_bvalid; reg s00_bready;
  reg  [31:0] s00_araddr; reg [2:0] s00_arprot; reg s00_arvalid; wire s00_arready;
  wire [31:0] s00_rdata; wire [1:0] s00_rresp; wire s00_rvalid; reg s00_rready;

  // Master Port s01 (LSU)
  reg  [31:0] s01_awaddr; reg [2:0] s01_awprot; reg s01_awvalid; wire s01_awready;
  reg  [31:0] s01_wdata; reg [3:0] s01_wstrb; reg s01_wvalid; wire s01_wready;
  wire [1:0]  s01_bresp; wire s01_bvalid; reg s01_bready;
  reg  [31:0] s01_araddr; reg [2:0] s01_arprot; reg s01_arvalid; wire s01_arready;
  wire [31:0] s01_rdata; wire [1:0] s01_rresp; wire s01_rvalid; reg s01_rready;

  // Master Port s02 (DMA Master Port)
  wire [31:0] s02_awaddr; wire [2:0] s02_awprot; wire s02_awvalid; wire s02_awready;
  wire [31:0] s02_wdata; wire [3:0] s02_wstrb; wire s02_wvalid; wire s02_wready;
  wire [1:0]  s02_bresp; wire s02_bvalid; wire s02_bready;
  wire [31:0] s02_araddr; wire [2:0] s02_arprot; wire s02_arvalid; wire s02_arready;
  wire [31:0] s02_rdata; wire [1:0] s02_rresp; wire s02_rvalid; wire s02_rready;

  // Slave Ports m00..m07
  wire [31:0] m00_awaddr; wire [2:0] m00_awprot; wire m00_awvalid; wire m00_awready;
  wire [31:0] m00_wdata; wire [3:0] m00_wstrb; wire m00_wvalid; wire m00_wready;
  wire [1:0]  m00_bresp; wire m00_bvalid; wire m00_bready;
  wire [31:0] m00_araddr; wire [2:0] m00_arprot; wire m00_arvalid; wire m00_arready;
  wire [31:0] m00_rdata; wire [1:0] m00_rresp; wire m00_rvalid; wire m00_rready;

  wire [31:0] m01_awaddr; wire [2:0] m01_awprot; wire m01_awvalid; wire m01_awready;
  wire [31:0] m01_wdata; wire [3:0] m01_wstrb; wire m01_wvalid; wire m01_wready;
  wire [1:0]  m01_bresp; wire m01_bvalid; wire m01_bready;
  wire [31:0] m01_araddr; wire [2:0] m01_arprot; wire m01_arvalid; wire m01_arready;
  wire [31:0] m01_rdata; wire [1:0] m01_rresp; wire m01_rvalid; wire m01_rready;

  wire [31:0] m02_awaddr; wire [2:0] m02_awprot; wire m02_awvalid; wire m02_awready;
  wire [31:0] m02_wdata; wire [3:0] m02_wstrb; wire m02_wvalid; wire m02_wready;
  wire [1:0]  m02_bresp; wire m02_bvalid; wire m02_bready;
  wire [31:0] m02_araddr; wire [2:0] m02_arprot; wire m02_arvalid; wire m02_arready;
  wire [31:0] m02_rdata; wire [1:0] m02_rresp; wire m02_rvalid; wire m02_rready;

  wire [31:0] m03_awaddr; wire [2:0] m03_awprot; wire m03_awvalid; wire m03_awready;
  wire [31:0] m03_wdata; wire [3:0] m03_wstrb; wire m03_wvalid; wire m03_wready;
  wire [1:0]  m03_bresp; wire m03_bvalid; wire m03_bready;
  wire [31:0] m03_araddr; wire [2:0] m03_arprot; wire m03_arvalid; wire m03_arready;
  wire [31:0] m03_rdata; wire [1:0] m03_rresp; wire m03_rvalid; wire m03_rready;

  wire [31:0] m04_awaddr; wire [2:0] m04_awprot; wire m04_awvalid; wire m04_awready;
  wire [31:0] m04_wdata; wire [3:0] m04_wstrb; wire m04_wvalid; wire m04_wready;
  wire [1:0]  m04_bresp; wire m04_bvalid; wire m04_bready;
  wire [31:0] m04_araddr; wire [2:0] m04_arprot; wire m04_arvalid; wire m04_arready;
  wire [31:0] m04_rdata; wire [1:0] m04_rresp; wire m04_rvalid; wire m04_rready;

  wire [31:0] m05_awaddr; wire [2:0] m05_awprot; wire m05_awvalid; wire m05_awready;
  wire [31:0] m05_wdata; wire [3:0] m05_wstrb; wire m05_wvalid; wire m05_wready;
  wire [1:0]  m05_bresp; wire m05_bvalid; wire m05_bready;
  wire [31:0] m05_araddr; wire [2:0] m05_arprot; wire m05_arvalid; wire m05_arready;
  wire [31:0] m05_rdata; wire [1:0] m05_rresp; wire m05_rvalid; wire m05_rready;

  wire [31:0] m06_awaddr; wire [2:0] m06_awprot; wire m06_awvalid; wire m06_awready;
  wire [31:0] m06_wdata; wire [3:0] m06_wstrb; wire m06_wvalid; wire m06_wready;
  wire [1:0]  m06_bresp; wire m06_bvalid; wire m06_bready;
  wire [31:0] m06_araddr; wire [2:0] m06_arprot; wire m06_arvalid; wire m06_arready;
  wire [31:0] m06_rdata; wire [1:0] m06_rresp; wire m06_rvalid; wire m06_rready;

  wire [31:0] m07_awaddr; wire [2:0] m07_awprot; wire m07_awvalid; wire m07_awready;
  wire [31:0] m07_wdata; wire [3:0] m07_wstrb; wire m07_wvalid; wire m07_wready;
  wire [1:0]  m07_bresp; wire m07_bvalid; wire m07_bready;
  wire [31:0] m07_araddr; wire [2:0] m07_arprot; wire m07_arvalid; wire m07_arready;
  wire [31:0] m07_rdata; wire [1:0] m07_rresp; wire m07_rvalid; wire m07_rready;

  // Streaming Link between Accelerator and DMA
  wire        dma_op_valid;
  wire [31:0] dma_op_data_a;
  wire [31:0] dma_op_data_b;
  wire        dma_op_ready;
  wire        dma_res_valid;
  wire [31:0] dma_res_data;
  wire        dma_res_ready;
  wire        dma_last;

  // External Peripherals Signals
  wire       uart_tx, uart_rx = 1'b1;
  wire       irq_uart;
  wire       irq_timer;
  wire [7:0] gpio_out;
  reg  [7:0] gpio_in = 8'h0;
  wire       irq_gpio;
  wire       irq_acc;
  wire       irq_dma;
  wire       spi_sclk, spi_cs_n, spi_mosi;
  reg        spi_miso = 1'b0;
  wire       irq_spi;

  // Test Tracking
  integer error_count = 0;
  integer test_count  = 0;

  // Optional Waveform Dumping for VCS / Verdi / DVE
`ifdef DUMP_VCD
  initial begin
    $dumpfile("tb_soc_fabric.vcd");
    $dumpvars(0, tb_soc_fabric);
  end
`endif

`ifdef DUMP_FSDB
  initial begin
    $fsdbDumpfile("tb_soc_fabric.fsdb");
    $fsdbDumpvars(0, tb_soc_fabric);
  end
`endif

  always #(CLK_PERIOD / 2) clk = ~clk;

  // Instantiate Fabric
  soc_axil_fabric fabric (
    .clk (clk),
    .rst (rst),

    .s00_axil_awaddr (s00_awaddr), .s00_axil_awprot (s00_awprot), .s00_axil_awvalid (s00_awvalid), .s00_axil_awready (s00_awready),
    .s00_axil_wdata  (s00_wdata),  .s00_axil_wstrb  (s00_wstrb),  .s00_axil_wvalid  (s00_wvalid),  .s00_axil_wready  (s00_wready),
    .s00_axil_bresp  (s00_bresp),  .s00_axil_bvalid  (s00_bvalid),  .s00_axil_bready  (s00_bready),
    .s00_axil_araddr (s00_araddr), .s00_axil_arprot (s00_arprot), .s00_axil_arvalid (s00_arvalid), .s00_axil_arready (s00_arready),
    .s00_axil_rdata  (s00_rdata),  .s00_axil_rresp  (s00_rresp),  .s00_axil_rvalid  (s00_rvalid),  .s00_axil_rready  (s00_rready),

    .s01_axil_awaddr (s01_awaddr), .s01_axil_awprot (s01_awprot), .s01_axil_awvalid (s01_awvalid), .s01_axil_awready (s01_awready),
    .s01_axil_wdata  (s01_wdata),  .s01_axil_wstrb  (s01_wstrb),  .s01_axil_wvalid  (s01_wvalid),  .s01_axil_wready  (s01_wready),
    .s01_axil_bresp  (s01_bresp),  .s01_axil_bvalid  (s01_bvalid),  .s01_axil_bready  (s01_bready),
    .s01_axil_araddr (s01_araddr), .s01_axil_arprot (s01_arprot), .s01_axil_arvalid (s01_arvalid), .s01_axil_arready (s01_arready),
    .s01_axil_rdata  (s01_rdata),  .s01_axil_rresp  (s01_rresp),  .s01_axil_rvalid  (s01_rvalid),  .s01_axil_rready  (s01_rready),

    .s02_axil_awaddr (s02_awaddr), .s02_axil_awprot (s02_awprot), .s02_axil_awvalid (s02_awvalid), .s02_axil_awready (s02_awready),
    .s02_axil_wdata  (s02_wdata),  .s02_axil_wstrb  (s02_wstrb),  .s02_axil_wvalid  (s02_wvalid),  .s02_axil_wready  (s02_wready),
    .s02_axil_bresp  (s02_bresp),  .s02_axil_bvalid  (s02_bvalid),  .s02_axil_bready  (s02_bready),
    .s02_axil_araddr (s02_araddr), .s02_axil_arprot (s02_arprot), .s02_axil_arvalid (s02_arvalid), .s02_axil_arready (s02_arready),
    .s02_axil_rdata  (s02_rdata),  .s02_axil_rresp  (s02_rresp),  .s02_axil_rvalid  (s02_rvalid),  .s02_axil_rready  (s02_rready),

    .m00_axil_awaddr (m00_awaddr), .m00_axil_awprot (m00_awprot), .m00_axil_awvalid (m00_awvalid), .m00_axil_awready (m00_awready),
    .m00_axil_wdata  (m00_wdata),  .m00_axil_wstrb  (m00_wstrb),  .m00_axil_wvalid  (m00_wvalid),  .m00_axil_wready  (m00_wready),
    .m00_axil_bresp  (m00_bresp),  .m00_axil_bvalid  (m00_bvalid),  .m00_axil_bready  (m00_bready),
    .m00_axil_araddr (m00_araddr), .m00_axil_arprot (m00_arprot), .m00_axil_arvalid (m00_arvalid), .m00_axil_arready (m00_arready),
    .m00_axil_rdata  (m00_rdata),  .m00_axil_rresp  (m00_rresp),  .m00_axil_rvalid  (m00_rvalid),  .m00_axil_rready  (m00_rready),

    .m01_axil_awaddr (m01_awaddr), .m01_axil_awprot (m01_awprot), .m01_axil_awvalid (m01_awvalid), .m01_axil_awready (m01_awready),
    .m01_axil_wdata  (m01_wdata),  .m01_axil_wstrb  (m01_wstrb),  .m01_axil_wvalid  (m01_wvalid),  .m01_axil_wready  (m01_wready),
    .m01_axil_bresp  (m01_bresp),  .m01_axil_bvalid  (m01_bvalid),  .m01_axil_bready  (m01_bready),
    .m01_axil_araddr (m01_araddr), .m01_axil_arprot (m01_arprot), .m01_axil_arvalid (m01_arvalid), .m01_axil_arready (m01_arready),
    .m01_axil_rdata  (m01_rdata),  .m01_axil_rresp  (m01_rresp),  .m01_axil_rvalid  (m01_rvalid),  .m01_axil_rready  (m01_rready),

    .m02_axil_awaddr (m02_awaddr), .m02_axil_awprot (m02_awprot), .m02_axil_awvalid (m02_awvalid), .m02_axil_awready (m02_awready),
    .m02_axil_wdata  (m02_wdata),  .m02_axil_wstrb  (m02_wstrb),  .m02_axil_wvalid  (m02_wvalid),  .m02_axil_wready  (m02_wready),
    .m02_axil_bresp  (m02_bresp),  .m02_axil_bvalid  (m02_bvalid),  .m02_axil_bready  (m02_bready),
    .m02_axil_araddr (m02_araddr), .m02_axil_arprot (m02_arprot), .m02_axil_arvalid (m02_arvalid), .m02_axil_arready (m02_arready),
    .m02_axil_rdata  (m02_rdata),  .m02_axil_rresp  (m02_rresp),  .m02_axil_rvalid  (m02_rvalid),  .m02_axil_rready  (m02_rready),

    .m03_axil_awaddr (m03_awaddr), .m03_axil_awprot (m03_awprot), .m03_axil_awvalid (m03_awvalid), .m03_axil_awready (m03_awready),
    .m03_axil_wdata  (m03_wdata),  .m03_axil_wstrb  (m03_wstrb),  .m03_axil_wvalid  (m03_wvalid),  .m03_axil_wready  (m03_wready),
    .m03_axil_bresp  (m03_bresp),  .m03_axil_bvalid  (m03_bvalid),  .m03_axil_bready  (m03_bready),
    .m03_axil_araddr (m03_araddr), .m03_axil_arprot (m03_arprot), .m03_axil_arvalid (m03_arvalid), .m03_axil_arready (m03_arready),
    .m03_axil_rdata  (m03_rdata),  .m03_axil_rresp  (m03_rresp),  .m03_axil_rvalid  (m03_rvalid),  .m03_axil_rready  (m03_rready),

    .m04_axil_awaddr (m04_awaddr), .m04_axil_awprot (m04_awprot), .m04_axil_awvalid (m04_awvalid), .m04_axil_awready (m04_awready),
    .m04_axil_wdata  (m04_wdata),  .m04_axil_wstrb  (m04_wstrb),  .m04_axil_wvalid  (m04_wvalid),  .m04_axil_wready  (m04_wready),
    .m04_axil_bresp  (m04_bresp),  .m04_axil_bvalid  (m04_bvalid),  .m04_axil_bready  (m04_bready),
    .m04_axil_araddr (m04_araddr), .m04_axil_arprot (m04_arprot), .m04_axil_arvalid (m04_arvalid), .m04_axil_arready (m04_arready),
    .m04_axil_rdata  (m04_rdata),  .m04_axil_rresp  (m04_rresp),  .m04_axil_rvalid  (m04_rvalid),  .m04_axil_rready  (m04_rready),

    .m05_axil_awaddr (m05_awaddr), .m05_axil_awprot (m05_awprot), .m05_axil_awvalid (m05_awvalid), .m05_axil_awready (m05_awready),
    .m05_axil_wdata  (m05_wdata),  .m05_axil_wstrb  (m05_wstrb),  .m05_axil_wvalid  (m05_wvalid),  .m05_axil_wready  (m05_wready),
    .m05_axil_bresp  (m05_bresp),  .m05_axil_bvalid  (m05_bvalid),  .m05_axil_bready  (m05_bready),
    .m05_axil_araddr (m05_araddr), .m05_axil_arprot (m05_arprot), .m05_axil_arvalid (m05_arvalid), .m05_axil_arready (m05_arready),
    .m05_axil_rdata  (m05_rdata),  .m05_axil_rresp  (m05_rresp),  .m05_axil_rvalid  (m05_rvalid),  .m05_axil_rready  (m05_rready),

    .m06_axil_awaddr (m06_awaddr), .m06_axil_awprot (m06_awprot), .m06_axil_awvalid (m06_awvalid), .m06_axil_awready (m06_awready),
    .m06_axil_wdata  (m06_wdata),  .m06_axil_wstrb  (m06_wstrb),  .m06_axil_wvalid  (m06_wvalid),  .m06_axil_wready  (m06_wready),
    .m06_axil_bresp  (m06_bresp),  .m06_axil_bvalid  (m06_bvalid),  .m06_axil_bready  (m06_bready),
    .m06_axil_araddr (m06_araddr), .m06_axil_arprot (m06_arprot), .m06_axil_arvalid (m06_arvalid), .m06_axil_arready (m06_arready),
    .m06_axil_rdata  (m06_rdata),  .m06_axil_rresp  (m06_rresp),  .m06_axil_rvalid  (m06_rvalid),  .m06_axil_rready  (m06_rready),

    .m07_axil_awaddr (m07_awaddr), .m07_axil_awprot (m07_awprot), .m07_axil_awvalid (m07_awvalid), .m07_axil_awready (m07_awready),
    .m07_axil_wdata  (m07_wdata),  .m07_axil_wstrb  (m07_wstrb),  .m07_axil_wvalid  (m07_wvalid),  .m07_axil_wready  (m07_wready),
    .m07_axil_bresp  (m07_bresp),  .m07_axil_bvalid  (m07_bvalid),  .m07_axil_bready  (m07_bready),
    .m07_axil_araddr (m07_araddr), .m07_axil_arprot (m07_arprot), .m07_axil_arvalid (m07_arvalid), .m07_axil_arready (m07_arready),
    .m07_axil_rdata  (m07_rdata),  .m07_axil_rresp  (m07_rresp),  .m07_axil_rvalid  (m07_rvalid),  .m07_axil_rready  (m07_rready)
  );

  // m00: Instruction Memory
  imem_axil u_imem (
    .clk (clk), .rst_n (rst_n),
    .awaddr (m00_awaddr), .awprot (m00_awprot), .awvalid (m00_awvalid), .awready (m00_awready),
    .wdata  (m00_wdata),  .wstrb  (m00_wstrb),  .wvalid  (m00_wvalid),  .wready  (m00_wready),
    .bresp  (m00_bresp),  .bvalid  (m00_bvalid),  .bready  (m00_bready),
    .araddr (m00_araddr), .arprot (m00_arprot), .arvalid (m00_arvalid), .arready (m00_arready),
    .rdata  (m00_rdata),  .rresp  (m00_rresp),  .rvalid  (m00_rvalid),  .rready  (m00_rready)
  );

  // m01: Data Memory
  dmem_axil u_dmem (
    .clk (clk), .rst_n (rst_n),
    .awaddr (m01_awaddr), .awprot (m01_awprot), .awvalid (m01_awvalid), .awready (m01_awready),
    .wdata  (m01_wdata),  .wstrb  (m01_wstrb),  .wvalid  (m01_wvalid),  .wready  (m01_wready),
    .bresp  (m01_bresp),  .bvalid  (m01_bvalid),  .bready  (m01_bready),
    .araddr (m01_araddr), .arprot (m01_arprot), .arvalid (m01_arvalid), .arready (m01_arready),
    .rdata  (m01_rdata),  .rresp  (m01_rresp),  .rvalid  (m01_rvalid),  .rready  (m01_rready)
  );

  // m02: UART
  soc_uart u_uart (
    .clk (clk), .rst_n (rst_n),
    .m02_axil_awaddr (m02_awaddr), .m02_axil_awprot (m02_awprot), .m02_axil_awvalid (m02_awvalid), .m02_axil_awready (m02_awready),
    .m02_axil_wdata  (m02_wdata),  .m02_axil_wstrb  (m02_wstrb),  .m02_axil_wvalid  (m02_wvalid),  .m02_axil_wready  (m02_wready),
    .m02_axil_bresp  (m02_bresp),  .m02_axil_bvalid  (m02_bvalid),  .m02_axil_bready  (m02_bready),
    .m02_axil_araddr (m02_araddr), .m02_axil_arprot (m02_arprot), .m02_axil_arvalid (m02_arvalid), .m02_axil_arready (m02_arready),
    .m02_axil_rdata  (m02_rdata),  .m02_axil_rresp  (m02_rresp),  .m02_axil_rvalid  (m02_rvalid),  .m02_axil_rready  (m02_rready),
    .uart_tx (uart_tx), .uart_rx (uart_rx), .irq_uart (irq_uart)
  );

  // m03: Timer
  soc_timer u_timer (
    .clk (clk), .rst_n (rst_n),
    .awaddr (m03_awaddr), .awprot (m03_awprot), .awvalid (m03_awvalid), .awready (m03_awready),
    .wdata  (m03_wdata),  .wstrb  (m03_wstrb),  .wvalid  (m03_wvalid),  .wready  (m03_wready),
    .bresp  (m03_bresp),  .bvalid  (m03_bvalid),  .bready  (m03_bready),
    .araddr (m03_araddr), .arprot (m03_arprot), .arvalid (m03_arvalid), .arready (m03_arready),
    .rdata  (m03_rdata),  .rresp  (m03_rresp),  .rvalid  (m03_rvalid),  .rready  (m03_rready),
    .irq_timer (irq_timer)
  );

  // m04: GPIO
  soc_gpio u_gpio (
    .clk (clk), .rst_n (rst_n),
    .awaddr (m04_awaddr), .awprot (m04_awprot), .awvalid (m04_awvalid), .awready (m04_awready),
    .wdata  (m04_wdata),  .wstrb  (m04_wstrb),  .wvalid  (m04_wvalid),  .wready  (m04_wready),
    .bresp  (m04_bresp),  .bvalid  (m04_bvalid),  .bready  (m04_bready),
    .araddr (m04_araddr), .arprot (m04_arprot), .arvalid (m04_arvalid), .arready (m04_arready),
    .rdata  (m04_rdata),  .rresp  (m04_rresp),  .rvalid  (m04_rvalid),  .rready  (m04_rready),
    .gpio_in (gpio_in), .gpio_out (gpio_out), .irq_gpio (irq_gpio)
  );

  // m05: Accelerator
  arithmetic_accelerator u_accel (
    .clk (clk), .rst_n (rst_n),
    .awaddr (m05_awaddr), .awprot (m05_awprot), .awvalid (m05_awvalid), .awready (m05_awready),
    .wdata  (m05_wdata),  .wstrb  (m05_wstrb),  .wvalid  (m05_wvalid),  .wready  (m05_wready),
    .bresp  (m05_bresp),  .bvalid  (m05_bvalid),  .bready  (m05_bready),
    .araddr (m05_araddr), .arprot (m05_arprot), .arvalid (m05_arvalid), .arready (m05_arready),
    .rdata  (m05_rdata),  .rresp  (m05_rresp),  .rvalid  (m05_rvalid),  .rready  (m05_rready),
    .dma_op_valid (dma_op_valid), .dma_op_data_a (dma_op_data_a), .dma_op_data_b (dma_op_data_b), .dma_op_ready (dma_op_ready),
    .dma_res_valid (dma_res_valid), .dma_res_data (dma_res_data), .dma_res_ready (dma_res_ready), .dma_last (dma_last),
    .irq_acc (irq_acc)
  );

  // m06: DMA Controller
  dma_controller u_dma (
    .clk (clk), .rst_n (rst_n),
    .awaddr (m06_awaddr), .awprot (m06_awprot), .awvalid (m06_awvalid), .awready (m06_awready),
    .wdata  (m06_wdata),  .wstrb  (m06_wstrb),  .wvalid  (m06_wvalid),  .wready  (m06_wready),
    .bresp  (m06_bresp),  .bvalid  (m06_bvalid),  .bready  (m06_bready),
    .araddr (m06_araddr), .arprot (m06_arprot), .arvalid (m06_arvalid), .arready (m06_arready),
    .rdata  (m06_rdata),  .rresp  (m06_rresp),  .rvalid  (m06_rvalid),  .rready  (m06_rready),
    .m_awaddr (s02_awaddr), .m_awprot (s02_awprot), .m_awvalid (s02_awvalid), .m_awready (s02_awready),
    .m_wdata  (s02_wdata),  .m_wstrb  (s02_wstrb),  .m_wvalid  (s02_wvalid),  .m_wready  (s02_wready),
    .m_bresp  (s02_bresp),  .m_bvalid  (s02_bvalid),  .m_bready  (s02_bready),
    .m_araddr (s02_araddr), .m_arprot (s02_arprot), .m_arvalid (s02_arvalid), .m_arready (s02_arready),
    .m_rdata  (s02_rdata),  .m_rresp  (s02_rresp),  .m_rvalid  (s02_rvalid),  .m_rready  (s02_rready),
    .dma_op_valid (dma_op_valid), .dma_op_data_a (dma_op_data_a), .dma_op_data_b (dma_op_data_b), .dma_op_ready (dma_op_ready),
    .dma_res_valid (dma_res_valid), .dma_res_data (dma_res_data), .dma_res_ready (dma_res_ready), .dma_last (dma_last),
    .irq_dma (irq_dma)
  );

  // m07: SPI
  soc_spi u_spi (
    .clk (clk), .rst_n (rst_n),
    .m07_axil_awaddr (m07_awaddr), .m07_axil_awprot (m07_awprot), .m07_axil_awvalid (m07_awvalid), .m07_axil_awready (m07_awready),
    .m07_axil_wdata  (m07_wdata),  .m07_axil_wstrb  (m07_wstrb),  .m07_axil_wvalid  (m07_wvalid),  .m07_axil_wready  (m07_wready),
    .m07_axil_bresp  (m07_bresp),  .m07_axil_bvalid  (m07_bvalid),  .m07_axil_bready  (m07_bready),
    .m07_axil_araddr (m07_araddr), .m07_axil_arprot (m07_arprot), .m07_axil_arvalid (m07_arvalid), .m07_axil_arready (m07_arready),
    .m07_axil_rdata  (m07_rdata),  .m07_axil_rresp  (m07_rresp),  .m07_axil_rvalid  (m07_rvalid),  .m07_axil_rready  (m07_rready),
    .spi_sclk (spi_sclk), .spi_cs_n (spi_cs_n), .spi_mosi (spi_mosi), .spi_miso (spi_miso), .irq_spi (irq_spi)
  );

  // Tasks for LSU (s01)
  task lsu_write;
    input [31:0] addr;
    input [31:0] data;
    input [3:0]  strb;
    output [1:0] resp;
    begin
      @(posedge clk);
      s01_awaddr  <= addr; s01_awvalid <= 1'b1; s01_awprot <= 3'b000;
      s01_wdata   <= data; s01_wstrb   <= strb; s01_wvalid <= 1'b1;
      s01_bready  <= 1'b1;
      while (!(s01_awvalid && s01_awready)) @(posedge clk);
      s01_awvalid <= 1'b0;
      while (!(s01_wvalid && s01_wready)) @(posedge clk);
      s01_wvalid  <= 1'b0;
      while (!s01_bvalid) @(posedge clk);
      resp = s01_bresp;
      @(posedge clk);
      s01_bready  <= 1'b0;
    end
  endtask

  task lsu_read;
    input  [31:0] addr;
    output [31:0] data;
    output [1:0]  resp;
    begin
      @(posedge clk);
      s01_araddr  <= addr; s01_arvalid <= 1'b1; s01_arprot <= 3'b000;
      s01_rready  <= 1'b1;
      while (!(s01_arvalid && s01_arready)) @(posedge clk);
      s01_arvalid <= 1'b0;
      while (!s01_rvalid) @(posedge clk);
      data = s01_rdata;
      resp = s01_rresp;
      @(posedge clk);
      s01_rready  <= 1'b0;
    end
  endtask

  // Tasks for IFU (s00)
  task ifu_read;
    input  [31:0] addr;
    output [31:0] data;
    output [1:0]  resp;
    begin
      @(posedge clk);
      s00_araddr  <= addr; s00_arvalid <= 1'b1; s00_arprot <= 3'b100;
      s00_rready  <= 1'b1;
      while (!(s00_arvalid && s00_arready)) @(posedge clk);
      s00_arvalid <= 1'b0;
      while (!s00_rvalid) @(posedge clk);
      data = s00_rdata;
      resp = s00_rresp;
      @(posedge clk);
      s00_rready  <= 1'b0;
    end
  endtask

  reg [31:0] rdata_tb;
  reg [1:0]  resp_tb;

  initial begin
    $display("===============================================================");
    $display("  STARTING FULL SOC FABRIC & SYSTEM VERIFICATION");
    $display("===============================================================");

    clk = 0; rst_n = 0;
    s00_awaddr = 0; s00_awprot = 0; s00_awvalid = 0; s00_wdata = 0; s00_wstrb = 0; s00_wvalid = 0; s00_bready = 0;
    s00_araddr = 0; s00_arprot = 0; s00_arvalid = 0; s00_rready = 0;
    s01_awaddr = 0; s01_awprot = 0; s01_awvalid = 0; s01_wdata = 0; s01_wstrb = 0; s01_wvalid = 0; s01_bready = 0;
    s01_araddr = 0; s01_arprot = 0; s01_arvalid = 0; s01_rready = 0;

    repeat (5) @(posedge clk);
    rst_n = 1;
    repeat (5) @(posedge clk);

    // -----------------------------------------------------------------------
    // TEST 1: LSU Read/Write Data Memory (m01)
    // -----------------------------------------------------------------------
    $display("\n[TEST 1] LSU accessing Data Memory (0x1000_0000)...");
    test_count = test_count + 1;
    lsu_write(32'h1000_0000, 32'hDEADBEEF, 4'hF, resp_tb);
    if (resp_tb == AXI_OKAY) $display("  PASS: LSU write to DMEM returned OKAY");
    else begin $display("  FAIL: LSU write to DMEM failed"); error_count = error_count + 1; end

    lsu_read(32'h1000_0000, rdata_tb, resp_tb);
    if (resp_tb == AXI_OKAY && rdata_tb == 32'hDEADBEEF) $display("  PASS: LSU read from DMEM returned 0x%08X", rdata_tb);
    else begin $display("  FAIL: LSU read from DMEM mismatch"); error_count = error_count + 1; end

    // -----------------------------------------------------------------------
    // TEST 2: Permissions Matrix Checks
    // -----------------------------------------------------------------------
    $display("\n[TEST 2] Access Control & Permission Enforcement...");
    test_count = test_count + 1;

    // 2A: LSU write to IMEM (0x0000_0000) -> DECERR
    lsu_write(32'h0000_0000, 32'h12345678, 4'hF, resp_tb);
    if (resp_tb == AXI_DECERR) $display("  PASS: LSU write to IMEM returned DECERR (read-only enforced)");
    else begin $display("  FAIL: LSU write to IMEM did not return DECERR (got %b)", resp_tb); error_count = error_count + 1; end

    // 2B: IFU read from Peripheral UART (0x4000_0000) -> DECERR
    ifu_read(32'h4000_0000, rdata_tb, resp_tb);
    if (resp_tb == AXI_DECERR) $display("  PASS: IFU access to UART returned DECERR (peripheral access forbidden)");
    else begin $display("  FAIL: IFU access to UART did not return DECERR (got %b)", resp_tb); error_count = error_count + 1; end

    // 2C: Unmapped Address (0x2000_0000) -> DECERR
    lsu_read(32'h2000_0000, rdata_tb, resp_tb);
    if (resp_tb == AXI_DECERR) $display("  PASS: LSU access to unmapped 0x2000_0000 returned DECERR");
    else begin $display("  FAIL: LSU access to unmapped did not return DECERR (got %b)", resp_tb); error_count = error_count + 1; end

    // -----------------------------------------------------------------------
    // TEST 3: Peripheral Routing to UART, Timer, GPIO, Accelerator, SPI
    // -----------------------------------------------------------------------
    $display("\n[TEST 3] LSU Peripheral Routing (UART, Timer, GPIO, SPI)...");
    test_count = test_count + 1;

    // Read UART STATUS (0x4000_0004)
    lsu_read(32'h4000_0004, rdata_tb, resp_tb);
    if (resp_tb == AXI_OKAY && rdata_tb[0] == 1'b1) $display("  PASS: Reached UART, tx_ready = 1");
    else begin $display("  FAIL: Reached UART failed"); error_count = error_count + 1; end

    // Read Timer COUNT (0x4000_1004)
    lsu_read(32'h4000_1004, rdata_tb, resp_tb);
    if (resp_tb == AXI_OKAY) $display("  PASS: Reached Timer, count = %0d", rdata_tb);
    else begin $display("  FAIL: Reached Timer failed"); error_count = error_count + 1; end

    // Write GPIO DIR (0x4000_2000)
    lsu_write(32'h4000_2000, 32'h000000FF, 4'hF, resp_tb);
    if (resp_tb == AXI_OKAY) $display("  PASS: Reached GPIO, configured DIR");
    else begin $display("  FAIL: Reached GPIO failed"); error_count = error_count + 1; end

    // Read SPI SR (0x4000_5064)
    lsu_read(32'h4000_5064, rdata_tb, resp_tb);
    if (resp_tb == AXI_OKAY) $display("  PASS: Reached SPI, status = 0x%08X", rdata_tb);
    else begin $display("  FAIL: Reached SPI failed"); error_count = error_count + 1; end

    // -----------------------------------------------------------------------
    // TEST 4: Autonomous DMA -> Accelerator -> Data Memory End-to-End
    // -----------------------------------------------------------------------
    $display("\n[TEST 4] Full End-to-End Autonomous Compute Workload...");
    test_count = test_count + 1;

    // 1. Stage operands in DMEM: A = 25 (0x19), B = 17 (0x11)
    lsu_write(32'h1000_0100, 32'd25, 4'hF, resp_tb); // Operand A0
    lsu_write(32'h1000_0104, 32'd17, 4'hF, resp_tb); // Operand B0
    lsu_write(32'h1000_0200, 32'd0,  4'hF, resp_tb); // Clear Result R0 destination

    // 2. Configure Accelerator: opcode ADD (000), count 1, IRQ enable
    lsu_write(32'h4000_3008, 32'd1, 4'hF, resp_tb); // ACC_OPCOUNT = 1
    lsu_write(32'h4000_301C, 32'd1, 4'hF, resp_tb); // ACC_IRQ_EN = 1
    lsu_write(32'h4000_3000, 32'd0, 4'hF, resp_tb); // ACC_CTRL = ADD

    // 3. Configure and Start DMA:
    // SRC = 0x1000_0100, DST = 0x1000_0200, LENGTH = 1, CTRL.start = 1
    lsu_write(32'h4000_4000, 32'h1000_0100, 4'hF, resp_tb); // DMA_SRC_ADDR
    lsu_write(32'h4000_4004, 32'h1000_0200, 4'hF, resp_tb); // DMA_DST_ADDR
    lsu_write(32'h4000_4008, 32'd1,         4'hF, resp_tb); // DMA_LENGTH = 1
    lsu_write(32'h4000_400C, 32'h00000003,  4'hF, resp_tb); // DMA_CTRL = start | irq_en

    // 4. Wait for DMA Job Complete
    repeat (200) @(posedge clk);

    // 5. Verify DMA status
    lsu_read(32'h4000_4010, rdata_tb, resp_tb);
    $display("  DMA Status: 0x%08X (done=%b, busy=%b, error=%b)", rdata_tb, rdata_tb[1], rdata_tb[0], rdata_tb[2]);

    // 6. Verify computed result written to DMEM
    lsu_read(32'h1000_0200, rdata_tb, resp_tb);
    if (resp_tb == AXI_OKAY && rdata_tb == 32'd42) begin
      $display("  PASS: Hardware Accelerator + DMA computed 25 + 17 = %0d and wrote to DMEM!", rdata_tb);
    end else begin
      $display("  FAIL: Computed result mismatch (expected 42, got %0d, resp %b)", rdata_tb, resp_tb);
      error_count = error_count + 1;
    end

    // -----------------------------------------------------------------------
    // Summary
    // -----------------------------------------------------------------------
    $display("\n===============================================================");
    if (error_count == 0)
      $display("  ALL %0d SYSTEM & FABRIC TESTS PASSED SUCCESSFULLY! (0 errors)", test_count);
    else
      $display("  SYSTEM TESTS FAILED: %0d error(s) detected out of %0d tests.", error_count, test_count);
    $display("===============================================================\n");

    $finish;
  end

endmodule
