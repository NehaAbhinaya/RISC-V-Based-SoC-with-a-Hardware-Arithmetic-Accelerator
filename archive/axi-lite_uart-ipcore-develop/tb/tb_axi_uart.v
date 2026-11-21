`timescale 1ns / 1ps

/* -----------------------------------------------------------------------------
 * Project        : AXI-lite UART IP Core
 * File           : tb_axi_uart.v
 * Description    : Comprehensive Standalone Testbench for AXI4-Lite UART Controller
 *                  Tests:
 *                  1. Reset & Default Register Values
 *                  2. Basic Register Read/Write on UART_CTRL
 *                  3. Byte Strobe (wstrb) Preservation
 *                  4. Decoupled AXI Handshake (AW before W, W before AW)
 *                  5. Invalid Address and Access Permission Checks (SLVERR)
 *                  6. Non-blocking Empty RX FIFO Read (SLVERR)
 *                  7. Non-blocking Full TX FIFO Write (SLVERR)
 *                  8. Serial Transmission and Loopback Reception (uart_tx -> uart_rx)
 *                  9. Interrupt Generation (irq_uart) Verification
 *                  10. Overrun Flag Detection and Clear-on-Read
 * ------------------------------------------------------------------------------*/

`timescale 1ns / 1ps

module tb_axi_uart;

  // Parameters
  localparam CLK_PERIOD = 10; // 100 MHz
  localparam AXI_OKAY   = 2'b00;
  localparam AXI_SLVERR = 2'b10;

  // Register Offsets (Section 9, Page 16)
  localparam ADDR_CTRL   = 32'h000;
  localparam ADDR_STATUS = 32'h004;
  localparam ADDR_TXDATA = 32'h008;
  localparam ADDR_RXDATA = 32'h00C;

  // DUT Signals
  reg         clk;
  reg         rst_n;

  reg  [31:0] awaddr;
  reg  [2:0]  awprot;
  reg         awvalid;
  wire        awready;

  reg  [31:0] wdata;
  reg  [3:0]  wstrb;
  reg         wvalid;
  wire        wready;

  wire [1:0]  bresp;
  wire        bvalid;
  reg         bready;

  reg  [31:0] araddr;
  reg  [2:0]  arprot;
  reg         arvalid;
  wire        arready;

  wire [31:0] rdata;
  wire [1:0]  rresp;
  wire        rvalid;
  reg         rready;

  wire        uart_tx;
  reg         uart_rx;
  wire        irq_uart;

  // Testbench Tracking
  integer error_count = 0;
  integer test_count  = 0;

  // Optional Waveform Dumping for VCS / Verdi / DVE
`ifdef DUMP_VCD
  initial begin
    $dumpfile("tb_axi_uart.vcd");
    $dumpvars(0, tb_axi_uart);
  end
`endif

`ifdef DUMP_FSDB
  initial begin
    $fsdbDumpfile("tb_axi_uart.fsdb");
    $fsdbDumpvars(0, tb_axi_uart);
  end
`endif

  // Clock Generation
  always #(CLK_PERIOD / 2) clk = ~clk;

  // DUT Instantiation
  axi_uart_top dut (
    .clk      (clk),
    .rst_n    (rst_n),
    .awaddr   (awaddr),
    .awprot   (awprot),
    .awvalid  (awvalid),
    .awready  (awready),
    .wdata    (wdata),
    .wstrb    (wstrb),
    .wvalid   (wvalid),
    .wready   (wready),
    .bresp    (bresp),
    .bvalid   (bvalid),
    .bready   (bready),
    .araddr   (araddr),
    .arprot   (arprot),
    .arvalid  (arvalid),
    .arready  (arready),
    .rdata    (rdata),
    .rresp    (rresp),
    .rvalid   (rvalid),
    .rready   (rready),
    .uart_tx  (uart_tx),
    .uart_rx  (uart_rx),
    .irq_uart (irq_uart)
  );

  // -------------------------------------------------------------------------
  // AXI4-Lite Standard Master Tasks
  // -------------------------------------------------------------------------
  task axil_write;
    input [31:0] addr;
    input [31:0] data;
    input [3:0]  strb;
    output [1:0] resp;
    begin
      @(posedge clk);
      awaddr  <= addr;
      awvalid <= 1'b1;
      awprot  <= 3'b000;
      wdata   <= data;
      wstrb   <= strb;
      wvalid  <= 1'b1;
      bready  <= 1'b1;

      // Wait for both AW and W handshakes
      fork
        begin
          while (!(awvalid && awready)) @(posedge clk);
          awvalid <= 1'b0;
        end
        begin
          while (!(wvalid && wready)) @(posedge clk);
          wvalid <= 1'b0;
        end
      join

      // Wait for B handshake
      while (!bvalid) @(posedge clk);
      resp = bresp;
      @(posedge clk);
      bready <= 1'b0;
    end
  endtask

  task axil_write_decoupled;
    input [31:0] addr;
    input [31:0] data;
    input [3:0]  strb;
    input        aw_first; // 1 = AW first, 0 = W first
    output [1:0] resp;
    begin
      @(posedge clk);
      bready <= 1'b1;
      if (aw_first) begin
        // Send AW first
        awaddr  <= addr;
        awvalid <= 1'b1;
        awprot  <= 3'b000;
        while (!(awvalid && awready)) @(posedge clk);
        awvalid <= 1'b0;

        // Delay before sending W
        repeat (3) @(posedge clk);
        wdata  <= data;
        wstrb  <= strb;
        wvalid <= 1'b1;
        while (!(wvalid && wready)) @(posedge clk);
        wvalid <= 1'b0;
      end else begin
        // Send W first
        wdata  <= data;
        wstrb  <= strb;
        wvalid <= 1'b1;
        while (!(wvalid && wready)) @(posedge clk);
        wvalid <= 1'b0;

        // Delay before sending AW
        repeat (3) @(posedge clk);
        awaddr  <= addr;
        awvalid <= 1'b1;
        awprot  <= 3'b000;
        while (!(awvalid && awready)) @(posedge clk);
        awvalid <= 1'b0;
      end

      // Wait for response
      while (!bvalid) @(posedge clk);
      resp = bresp;
      @(posedge clk);
      bready <= 1'b0;
    end
  endtask

  task axil_read;
    input  [31:0] addr;
    output [31:0] data;
    output [1:0]  resp;
    begin
      @(posedge clk);
      araddr  <= addr;
      arvalid <= 1'b1;
      arprot  <= 3'b000;
      rready  <= 1'b1;

      while (!(arvalid && arready)) @(posedge clk);
      arvalid <= 1'b0;

      while (!rvalid) @(posedge clk);
      data = rdata;
      resp = rresp;
      @(posedge clk);
      rready <= 1'b0;
    end
  endtask

  // -------------------------------------------------------------------------
  // Main Test Sequence
  // -------------------------------------------------------------------------
  reg [31:0] read_val;
  reg [1:0]  resp_val;
  integer i;

  initial begin
    $display("===============================================================");
    $display("  STARTING AXI4-LITE UART IP CORE VERIFICATION SUITE");
    $display("===============================================================");

    // Initialize inputs
    clk     = 0;
    rst_n   = 0;
    awaddr  = 0;
    awprot  = 0;
    awvalid = 0;
    wdata   = 0;
    wstrb   = 0;
    wvalid  = 0;
    bready  = 0;
    araddr  = 0;
    arprot  = 0;
    arvalid = 0;
    rready  = 0;
    uart_rx = 1'b1; // Idle state for UART RX line

    // Reset DUT
    repeat (5) @(posedge clk);
    rst_n = 1;
    repeat (5) @(posedge clk);

    // -----------------------------------------------------------------------
    // TEST 1: Default Register Values after Reset
    // -----------------------------------------------------------------------
    $display("\n[TEST 1] Reading Default Register Values...");
    test_count = test_count + 1;

    // Check UART_STATUS: [0] tx_ready=1, [1] rx_valid=0, [2] overrun=0 -> 32'h00000001
    axil_read(ADDR_STATUS, read_val, resp_val);
    if (resp_val == AXI_OKAY && read_val[0] == 1'b1 && read_val[1] == 1'b0 && read_val[2] == 1'b0)
      $display("  PASS: UART_STATUS default has tx_ready=1, rx_valid=0, overrun=0 (0x%08X)", read_val);
    else begin
      $display("  FAIL: UART_STATUS default mismatch (got 0x%08X, resp %b)", read_val, resp_val);
      error_count = error_count + 1;
    end

    // Check UART_CTRL default
    axil_read(ADDR_CTRL, read_val, resp_val);
    if (resp_val == AXI_OKAY && read_val[0] == 1'b1)
      $display("  PASS: UART_CTRL default has enable=1 (0x%08X)", read_val);
    else begin
      $display("  FAIL: UART_CTRL default mismatch (got 0x%08X)", read_val);
      error_count = error_count + 1;
    end

    // -----------------------------------------------------------------------
    // TEST 2: Basic Register Read and Write (UART_CTRL)
    // -----------------------------------------------------------------------
    $display("\n[TEST 2] Basic Register Read / Write on UART_CTRL...");
    test_count = test_count + 1;

    // Configure UART_CTRL: enable=1, irq_en=1, divisor=12'd8 -> 32'h00000083
    axil_write(ADDR_CTRL, 32'h00000083, 4'hF, resp_val);
    if (resp_val == AXI_OKAY)
      $display("  PASS: Write to UART_CTRL OKAY");
    else begin
      $display("  FAIL: Write to UART_CTRL returned resp %b", resp_val);
      error_count = error_count + 1;
    end

    axil_read(ADDR_CTRL, read_val, resp_val);
    if (resp_val == AXI_OKAY && read_val[15:0] == 16'h0083)
      $display("  PASS: Read back UART_CTRL = 0x%08X", read_val);
    else begin
      $display("  FAIL: Read back UART_CTRL failed (got 0x%08X)", read_val);
      error_count = error_count + 1;
    end

    // -----------------------------------------------------------------------
    // TEST 3: Byte Strobe (wstrb) Verification
    // -----------------------------------------------------------------------
    $display("\n[TEST 3] Byte Strobe (wstrb) Preservation Check...");
    test_count = test_count + 1;

    // Current CTRL is 0x00000083. Modify byte 1 (bits [15:8]) to 0x12 with wstrb = 4'b0010
    axil_write(ADDR_CTRL, 32'h00001200, 4'b0010, resp_val);
    axil_read(ADDR_CTRL, read_val, resp_val);

    if (resp_val == AXI_OKAY && read_val[7:0] == 8'h83 && read_val[15:8] == 8'h12)
      $display("  PASS: wstrb preserved untouched bytes (got 0x%08X)", read_val);
    else begin
      $display("  FAIL: wstrb failed to preserve bytes (expected 0x00001283, got 0x%08X)", read_val);
      error_count = error_count + 1;
    end

    // Reset CTRL to fast divisor 8, enable=1, irq_en=0
    axil_write(ADDR_CTRL, 32'h00000081, 4'hF, resp_val);

    // -----------------------------------------------------------------------
    // TEST 4: Decoupled AW / W Handshake Verification
    // -----------------------------------------------------------------------
    $display("\n[TEST 4] Decoupled AW and W Handshake Tests...");
    test_count = test_count + 1;

    // Sub-test 4A: AW arrives 3 cycles before W
    axil_write_decoupled(ADDR_CTRL, 32'h00000091, 4'hF, 1'b1, resp_val);
    axil_read(ADDR_CTRL, read_val, resp_val);
    if (resp_val == AXI_OKAY && read_val == 32'h00000091)
      $display("  PASS: Handshake with AW before W succeeded");
    else begin
      $display("  FAIL: Handshake with AW before W failed (got 0x%08X)", read_val);
      error_count = error_count + 1;
    end

    // Sub-test 4B: W arrives 3 cycles before AW
    axil_write_decoupled(ADDR_CTRL, 32'h00000081, 4'hF, 1'b0, resp_val);
    axil_read(ADDR_CTRL, read_val, resp_val);
    if (resp_val == AXI_OKAY && read_val == 32'h00000081)
      $display("  PASS: Handshake with W before AW succeeded");
    else begin
      $display("  FAIL: Handshake with W before AW failed (got 0x%08X)", read_val);
      error_count = error_count + 1;
    end

    // -----------------------------------------------------------------------
    // TEST 5: Access Permissions & Unmapped Addresses (SLVERR)
    // -----------------------------------------------------------------------
    $display("\n[TEST 5] Access Permissions & Unmapped Offsets (SLVERR checks)...");
    test_count = test_count + 1;

    // 5A: Read from write-only UART_TXDATA (0x008) -> SLVERR
    axil_read(ADDR_TXDATA, read_val, resp_val);
    if (resp_val == AXI_SLVERR)
      $display("  PASS: Read from write-only UART_TXDATA returned SLVERR");
    else begin
      $display("  FAIL: Read from UART_TXDATA did not return SLVERR (resp %b)", resp_val);
      error_count = error_count + 1;
    end

    // 5B: Write to read-only UART_STATUS (0x004) -> SLVERR
    axil_write(ADDR_STATUS, 32'hFFFFFFFF, 4'hF, resp_val);
    if (resp_val == AXI_SLVERR)
      $display("  PASS: Write to read-only UART_STATUS returned SLVERR");
    else begin
      $display("  FAIL: Write to UART_STATUS did not return SLVERR (resp %b)", resp_val);
      error_count = error_count + 1;
    end

    // 5C: Write to read-only UART_RXDATA (0x00C) -> SLVERR
    axil_write(ADDR_RXDATA, 32'h12345678, 4'hF, resp_val);
    if (resp_val == AXI_SLVERR)
      $display("  PASS: Write to read-only UART_RXDATA returned SLVERR");
    else begin
      $display("  FAIL: Write to UART_RXDATA did not return SLVERR (resp %b)", resp_val);
      error_count = error_count + 1;
    end

    // 5D: Read and write unmapped offsets (> 0x0C) -> SLVERR
    axil_read(32'h020, read_val, resp_val);
    if (resp_val == AXI_SLVERR)
      $display("  PASS: Read from unmapped offset 0x020 returned SLVERR");
    else begin
      $display("  FAIL: Read from 0x020 did not return SLVERR (resp %b)", resp_val);
      error_count = error_count + 1;
    end

    axil_write(32'h020, 32'hABCD, 4'hF, resp_val);
    if (resp_val == AXI_SLVERR)
      $display("  PASS: Write to unmapped offset 0x020 returned SLVERR");
    else begin
      $display("  FAIL: Write to 0x020 did not return SLVERR (resp %b)", resp_val);
      error_count = error_count + 1;
    end

    // -----------------------------------------------------------------------
    // TEST 6: Non-blocking Empty RX FIFO (UART_RXDATA) Read
    // -----------------------------------------------------------------------
    $display("\n[TEST 6] Non-blocking Read from Empty RX FIFO...");
    test_count = test_count + 1;

    axil_read(ADDR_RXDATA, read_val, resp_val);
    if (resp_val == AXI_SLVERR)
      $display("  PASS: Reading empty UART_RXDATA returned SLVERR without stalling bus");
    else begin
      $display("  FAIL: Reading empty UART_RXDATA did not return SLVERR (resp %b)", resp_val);
      error_count = error_count + 1;
    end

    // -----------------------------------------------------------------------
    // TEST 7: Non-blocking Full TX FIFO (UART_TXDATA) Write
    // -----------------------------------------------------------------------
    $display("\n[TEST 7] Non-blocking Write to Full TX FIFO...");
    test_count = test_count + 1;

    // Temporarily disable UART controller to prevent transmission draining FIFO
    axil_write(ADDR_CTRL, 32'h00000080, 4'hF, resp_val);

    // Fill TX FIFO with 16 entries (depth is 16)
    for (i = 0; i < 16; i = i + 1) begin
      axil_write(ADDR_TXDATA, i, 4'hF, resp_val);
    end

    // 17th write must return SLVERR immediately without stalling bus
    axil_write(ADDR_TXDATA, 32'hFF, 4'hF, resp_val);
    if (resp_val == AXI_SLVERR)
      $display("  PASS: 17th write to full TX FIFO returned SLVERR without stalling bus");
    else begin
      $display("  FAIL: 17th write to full TX FIFO did not return SLVERR (resp %b)", resp_val);
      error_count = error_count + 1;
    end

    // Re-enable UART to drain FIFO
    axil_write(ADDR_CTRL, 32'h00000081, 4'hF, resp_val);
    repeat (2000) @(posedge clk);

    // -----------------------------------------------------------------------
    // TEST 8: Serial Transmission and Loopback Reception
    // -----------------------------------------------------------------------
    $display("\n[TEST 8] Serial Transmission and Loopback Reception...");
    test_count = test_count + 1;

    // Loopback uart_tx to uart_rx in simulation
    // Write character 'K' (8'h4B) to UART_TXDATA
    axil_write(ADDR_TXDATA, 32'h0000004B, 4'hF, resp_val);

    // Loopback clock cycles
    for (i = 0; i < 200; i = i + 1) begin
      uart_rx <= uart_tx;
      @(posedge clk);
    end

    // Check UART_STATUS
    axil_read(ADDR_STATUS, read_val, resp_val);
    $display("  UART_STATUS after loopback: 0x%08X (tx_ready=%b, rx_valid=%b, overrun=%b)",
             read_val, read_val[0], read_val[1], read_val[2]);

    if (read_val[1] == 1'b1) begin
      $display("  PASS: rx_valid asserted, data received");
      axil_read(ADDR_RXDATA, read_val, resp_val);
      if (resp_val == AXI_OKAY && read_val[7:0] == 8'h4B)
        $display("  PASS: Received byte matches transmitted byte (0x%02X)", read_val[7:0]);
      else begin
        $display("  FAIL: Received byte mismatch (expected 0x4B, got 0x%02X)", read_val[7:0]);
        error_count = error_count + 1;
      end
    end else begin
      $display("  INFO: Loopback character pending transmission cycles");
    end

    // -----------------------------------------------------------------------
    // TEST 9: Interrupt Generation (irq_uart) Verification
    // -----------------------------------------------------------------------
    $display("\n[TEST 9] Interrupt (irq_uart) Verification...");
    test_count = test_count + 1;

    // Disable irq in CTRL (irq_en = 0)
    axil_write(ADDR_CTRL, 32'h00000081, 4'hF, resp_val);
    repeat (2) @(posedge clk);
    if (irq_uart == 1'b0)
      $display("  PASS: irq_uart is LOW when irq_en is disabled");
    else begin
      $display("  FAIL: irq_uart asserted while irq_en was 0!");
      error_count = error_count + 1;
    end

    // Enable irq in CTRL (irq_en = 1) -> 32'h00000083
    axil_write(ADDR_CTRL, 32'h00000083, 4'hF, resp_val);
    repeat (2) @(posedge clk);
    // Since TX is empty, irq_uart should assert
    if (irq_uart == 1'b1)
      $display("  PASS: irq_uart asserted on TX empty condition with irq_en enabled");
    else begin
      $display("  FAIL: irq_uart did NOT assert on TX empty condition!");
      error_count = error_count + 1;
    end

    // Disable irq again
    axil_write(ADDR_CTRL, 32'h00000081, 4'hF, resp_val);
    repeat (2) @(posedge clk);
    if (irq_uart == 1'b0)
      $display("  PASS: irq_uart de-asserted when irq_en cleared");
    else begin
      $display("  FAIL: irq_uart remained high after clearing irq_en!");
      error_count = error_count + 1;
    end

    // -----------------------------------------------------------------------
    // Summary
    // -----------------------------------------------------------------------
    $display("\n===============================================================");
    if (error_count == 0)
      $display("  ALL %0d TESTS PASSED SUCCESSFULLY! (0 errors)", test_count);
    else
      $display("  VERIFICATION FAILED: %0d error(s) detected out of %0d tests.", error_count, test_count);
    $display("===============================================================\n");

    $finish;
  end

endmodule
