`timescale 1ns / 1ps

/* -------------------------------------------------------------------------------
 * Project        : RISC-V SoC with Hardware Arithmetic Accelerator
 * File           : tb_soc_ctest.v
 * Description    : Dedicated SoC Bare-Metal C-Test Verification Testbench
 *                  - Loads firmware hex file into processor Instruction Memory
 *                  - RISC-V VeeR EL2 boots directly from reset (0x0000_0000)
 *                  - Pure autonomous CPU execution (no external bus injection)
 *                  - Real-time UART transmitter monitor & ASCII display
 *                  - Dumps FSDB waveform for Verdi visualization
 *                  - Passes when C firmware asserts gpio_out = 0x81
 * -------------------------------------------------------------------------------*/

`default_nettype none

module tb_soc_ctest;

  // Parameters
  localparam CLK_PERIOD = 10; // 100 MHz clock (10 ns period)
  parameter  IMEM_INIT_FILE = "soc_firmware.hex";

  // Clock and Reset
  reg         clk;
  reg         rst_n;

  // External UART Serial Pins
  wire        uart_tx;
  reg         uart_rx;

  // External SPI Pins
  wire        spi_sclk;
  wire        spi_cs_n;
  wire        spi_mosi;
  wire        spi_miso;

  // External GPIO Pins
  reg  [7:0]  gpio_in;
  wire [7:0]  gpio_out;

  // Interrupt Signals
  wire [5:0]  pic_interrupts;
  wire        irq_core;

  // RISC-V Core Instruction Execution Trace Outputs
  wire [31:0] rv_trace_insn;
  wire [31:0] rv_trace_address;
  wire        rv_trace_valid;

  // External Host Interface - tied off for pure autonomous C-test
  wire        ext_host_en = 1'b0;
  wire [31:0] ext_lsu_awaddr  = 32'h0;
  wire [2:0]  ext_lsu_awprot  = 3'b0;
  wire        ext_lsu_awvalid = 1'b0;
  wire        ext_lsu_awready;
  wire [31:0] ext_lsu_wdata   = 32'h0;
  wire [3:0]  ext_lsu_wstrb   = 4'h0;
  wire        ext_lsu_wvalid  = 1'b0;
  wire        ext_lsu_wready;
  wire [1:0]  ext_lsu_bresp;
  wire        ext_lsu_bvalid;
  wire        ext_lsu_bready  = 1'b0;
  wire [31:0] ext_lsu_araddr  = 32'h0;
  wire [2:0]  ext_lsu_arprot  = 3'b0;
  wire        ext_lsu_arvalid = 1'b0;
  wire        ext_lsu_arready;
  wire [31:0] ext_lsu_rdata;
  wire [1:0]  ext_lsu_rresp;
  wire        ext_lsu_rvalid;
  wire        ext_lsu_rready  = 1'b0;

  // Real-time UART monitor for firmware console output
  reg [7:0]   uart_rx_char;
  integer     uart_bit_cnt;
  integer     total_chars_received = 0;

  // SPI MISO loopback to MOSI
  assign spi_miso = spi_mosi;

  // Optional Waveform Dumping for Synopsys Verdi (FSDB)
`ifdef DUMP_FSDB
  initial begin
    $fsdbDumpfile("tb_soc_ctest.fsdb");
    $fsdbDumpvars(0, tb_soc_ctest);
    $display(">> [VERDI] Waveform dumping active: tb_soc_ctest.fsdb");
  end
`endif

`ifdef DUMP_VCD
  initial begin
    $dumpfile("tb_soc_ctest.vcd");
    $dumpvars(0, tb_soc_ctest);
  end
`endif

  // Clock Generation (100 MHz)
  initial clk = 0;
  always #(CLK_PERIOD / 2) clk = ~clk;

  // Real-time UART Transmitter Monitor (deserializes serial data stream from uart_tx)
  always @(negedge uart_tx) begin
    if (rst_n) begin
      // Sample half-bit period into start bit to verify stability
      #(CLK_PERIOD * 8);
      if (uart_tx == 1'b0) begin
        uart_rx_char = 8'h00;
        // Sample 8 data bits (LSB first) at mid-bit intervals (16 clock cycles per bit)
        for (uart_bit_cnt = 0; uart_bit_cnt < 8; uart_bit_cnt = uart_bit_cnt + 1) begin
          #(CLK_PERIOD * 16);
          uart_rx_char[uart_bit_cnt] = uart_tx;
        end
        // Stop bit interval
        #(CLK_PERIOD * 12);
        $write("%c", uart_rx_char);
        $fflush();
        total_chars_received = total_chars_received + 1;
      end
    end
  end

  // Instantiate Top Module
  soc_top #(
    .IMEM_INIT_FILE (IMEM_INIT_FILE),
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

  // Simulation Sequence
  initial begin
    $display("=======================================================================");
    $display("  STARTING SOC BARE-METAL C-TEST VERIFICATION SUITE");
    $display("  Target Firmware: %0s", IMEM_INIT_FILE);
    $display("=======================================================================");

    // Initialize inputs
    rst_n    = 1'b0;
    uart_rx  = 1'b1; // Idle high
    gpio_in  = 8'h00;

    // Apply active-low reset for 5 clock cycles
    repeat (5) @(posedge clk);
    rst_n = 1'b1;
    $display(">> [%0t ns] Reset released. RISC-V VeeR EL2 booting from 0x0000_0000...", $time);

    // Watchdog and Completion Monitor
    fork : ctest_monitor
      begin
        // Watchdog timeout limit: 1,000,000 clock cycles (~10 ms simulation time)
        repeat (1000000) begin
          @(posedge clk);
          if (gpio_out == 8'h81 || gpio_out == 8'hEE) begin
            // Allow remaining UART transmission characters to flush
            repeat (2000) @(posedge clk);
            disable ctest_monitor;
          end
        end
        $display("\n[TIMEOUT] C-Test simulation timed out! (gpio_out = 0x%02X)", gpio_out);
        disable ctest_monitor;
      end
    join

    $display("\n=======================================================================");
    if (gpio_out == 8'h81) begin
      $display("  >>> [PASS] BARE-METAL C-TEST COMPLETED SUCCESSFULLY! <<<");
      $display("  RISC-V VeeR EL2 Core executed firmware from '%0s'", IMEM_INIT_FILE);
      $display("  Total ASCII Characters Emitted by UART: %0d", total_chars_received);
      $display("  Final GPIO Status: 0x%02X (Bit 7 & Bit 0 ON)", gpio_out);
    end else if (gpio_out == 8'hEE) begin
      $display("  >>> [FAIL] C-TEST REPORTED TEST ERROR! (gpio_out = 0xEE) <<<");
    end else begin
      $display("  >>> [INCOMPLETE] Simulation ended with gpio_out = 0x%02X <<<", gpio_out);
    end
    $display("=======================================================================\n");

    $finish;
  end

endmodule

`default_nettype wire
