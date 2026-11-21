/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : UART VIP
 * File           : uart_monitor.sv
 * Description    : Functional UART Monitor observing both serial RX frames
 *                  entering the DUT and serial TX frames exiting the DUT.
 *                  Performs center-aligned bit sampling, framing error checks,
 *                  byte reconstruction, and analysis port broadcasting.
 * ============================================================================== */

`ifndef UART_MONITOR_SV
`define UART_MONITOR_SV

class uart_monitor extends uvm_monitor;
  virtual uart_if vif;
  uvm_analysis_port #(uart_item) ap;

  int baud_div = 16; // Default: 16 clock cycles/bit matching SoC hardware

  `uvm_component_utils(uart_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif) || vif == null) begin
      `uvm_fatal("NOVIF", {"Virtual interface vif must be set for ", get_full_name(), ".vif"});
    end
    void'(uvm_config_db#(int)::get(this, "", "baud_div", baud_div));
  endfunction

  virtual task run_phase(uvm_phase phase);
    // Wait for reset release
    if (vif != null && !vif.rst_n)
      @(posedge vif.rst_n);

    // Fork independent monitoring threads for RX (into DUT) and TX (from DUT)
    fork
      monitor_rx_line();
      monitor_tx_line();
    join
  endtask

  // --------------------------------------------------------------------------
  // Thread 1: Monitor UART RX Serial Input to DUT
  // --------------------------------------------------------------------------
  task monitor_rx_line();
    bit [7:0] captured_byte;
    uart_item item;
    int div;

    forever begin
      div = (baud_div > 0) ? baud_div : 16;

      // 1. Detect start bit: falling edge on uart_rx while line was idle high
      @(negedge vif.uart_rx);

      // 2. Center align on Start Bit: wait 0.5 bit duration and verify still LOW
      repeat (div / 2) @(posedge vif.clk);
      if (vif.uart_rx !== 1'b0) begin
        `uvm_warning("UART_MON_RX", "Glitch detected on uart_rx (start bit not held low). Ignoring.")
        continue;
      end

      `uvm_info("UART_MON_RX", $sformatf("=== [UART_MON_RX] Start bit detected on uart_rx at %0t ps (Divisor=%0d) ===", $time, div), UVM_LOW)

      // 3. Sample 8 Data Bits at Bit Centers (LSB first)
      for (int i = 0; i < 8; i++) begin
        repeat (div) @(posedge vif.clk);
        captured_byte[i] = vif.uart_rx;
        `uvm_info("UART_MON_RX", $sformatf("  [DATA BIT %0d] Sampled bit: %b at %0t ps", i, captured_byte[i], $time), UVM_HIGH)
      end

      // 4. Sample and Verify Stop Bit at Bit Center
      repeat (div) @(posedge vif.clk);
      item = uart_item::type_id::create("item");
      item.data          = captured_byte;
      item.uart_rx       = 1'b1;
      item.is_rx         = 1'b1;
      item.baud_div      = div;
      item.data_bits     = 4'd8;
      item.stop_bits     = 2'd1;

      if (vif.uart_rx !== 1'b1) begin
        item.framing_error = 1'b1;
        `uvm_error("UART_MON_RX", $sformatf("Framing error on uart_rx: Stop bit is %b (expected 1'b1) at %0t ps", vif.uart_rx, $time))
      end else begin
        item.framing_error = 1'b0;
        `uvm_info("UART_MON_RX", $sformatf("=== [UART_MON_RX] Successfully decoded RX frame: 0x%02X at %0t ps (Stop bit valid) ===", captured_byte, $time), UVM_LOW)
      end

      // 5. Broadcast decoded transaction to Scoreboard
      ap.write(item);
    end
  endtask

  // --------------------------------------------------------------------------
  // Thread 2: Monitor UART TX Serial Output from DUT
  // --------------------------------------------------------------------------
  task monitor_tx_line();
    bit [7:0] captured_byte;
    uart_item item;
    int div;

    forever begin
      div = (baud_div > 0) ? baud_div : 16;

      @(negedge vif.uart_tx);
      repeat (div + (div / 2)) @(posedge vif.clk);

      for (int i = 0; i < 8; i++) begin
        captured_byte[i] = vif.uart_tx;
        repeat (div) @(posedge vif.clk);
      end

      item = uart_item::type_id::create("tx_item");
      item.data    = captured_byte;
      item.uart_tx = 1'b1;
      item.is_tx   = 1'b1;
      item.baud_div = div;

      if (vif.uart_tx !== 1'b1)
        item.framing_error = 1'b1;

      `uvm_info("UART_MON_TX", $sformatf("Monitored UART TX frame from DUT: 0x%02X ('%c')",
                captured_byte, (captured_byte >= 32 && captured_byte <= 126) ? captured_byte : "."), UVM_HIGH)

      ap.write(item);
    end
  endtask

endclass

`endif // UART_MONITOR_SV
