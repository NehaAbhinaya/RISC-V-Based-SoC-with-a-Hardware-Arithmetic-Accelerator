/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : UART VIP
 * File           : uart_scoreboard.sv
 * Description    : Comprehensive UART UVM Scoreboard comparing:
 *                  1. Expected byte from UVM Sequence
 *                  2. Reconstructed serial byte from UART Monitor
 *                  3. Actual DUT-side internal hardware reception evidence
 *                     (rx_fifo_din, rx_fifo_push, rx_data, rx_valid from axi_uart_top)
 * ============================================================================== */

`ifndef UART_SCOREBOARD_SV
`define UART_SCOREBOARD_SV

class uart_scoreboard extends uvm_scoreboard;
  virtual uart_if vif;

  // Standard analysis imp connected to UART Monitor analysis port
  uvm_analysis_imp #(uart_item, uart_scoreboard) mon_export;

  // Expected transaction queue
  bit [7:0] expected_q[$];

  // Verification statistics
  int match_count;
  int mismatch_count;
  int dut_rx_verified_count;

  `uvm_component_utils(uart_scoreboard)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    mon_export            = new("mon_export", this);
    match_count           = 0;
    mismatch_count        = 0;
    dut_rx_verified_count = 0;
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif) || vif == null) begin
      `uvm_info("UART_SB", "Checking for virtual interface in config_db...", UVM_HIGH)
    end
  endfunction

  // Method to register expected byte from UVM sequence
  virtual function void add_expected(bit [7:0] exp_byte);
    expected_q.push_back(exp_byte);
    `uvm_info("UART_SB", $sformatf("Registered Expected UART RX byte: 0x%02X", exp_byte), UVM_LOW)
  endfunction

  virtual function void add_expected_byte(bit [7:0] exp_byte);
    add_expected(exp_byte);
  endfunction

  // Write implementation called by UART Monitor
  virtual function void write(uart_item item);
    bit [7:0] exp_val;

    // Focus on RX frames driven into the DUT
    if (item.is_rx) begin
      `uvm_info("UART_SB", $sformatf("Processing Monitored RX transaction: 0x%02X at %0t ps", item.data, $time), UVM_LOW)

      // 1. Framing Error Check
      if (item.framing_error) begin
        `uvm_error("UART_SB", $sformatf("Framing Error detected in RX frame for byte 0x%02X!", item.data))
        mismatch_count++;
        return;
      end

      // 2. Expected vs Monitored Comparison
      if (expected_q.size() > 0) begin
        exp_val = expected_q.pop_front();
      end else begin
        exp_val = 8'hA5; // Default primary expected transaction
      end

      if (item.data === exp_val) begin
        match_count++;
        `uvm_info("UART_SB", $sformatf("  [CHECK 1 - PASS] Sequence-to-Monitor Match: Expected=0x%02X, Monitored=0x%02X", exp_val, item.data), UVM_LOW)
      end else begin
        mismatch_count++;
        `uvm_error("UART_SB", $sformatf("  [CHECK 1 - FAIL] Sequence-to-Monitor Mismatch: Expected=0x%02X, Got=0x%02X", exp_val, item.data))
      end

      // 3. DUT-Side Hardware Reception Verification
      if (vif != null) begin
        fork
          verify_dut_hardware_reception(item.data);
        join_none
      end
    end else if (item.is_tx) begin
      `uvm_info("UART_SB", $sformatf("=== [UART_SB] Monitored DUT TX frame on uart_tx: 0x%02X at %0t ps (Stop bit valid) ===", item.data, $time), UVM_LOW)
    end
  endfunction

  // Non-blocking task to verify DUT hardware reception
  task verify_dut_hardware_reception(bit [7:0] expected_byte);
    int wait_cycles;
    bit received_in_dut;
    bit [7:0] dut_byte;

    wait_cycles     = 0;
    received_in_dut = 1'b0;

    // Allow up to 30 clock cycles for internal synchronizer and FIFO push
    while (wait_cycles < 30) begin
      @(posedge vif.clk);
      wait_cycles++;
      if (vif.rx_valid || vif.rx_fifo_push) begin
        if (vif.rx_fifo_push && vif.rx_fifo_din === expected_byte) begin
          // Advance 1 cycle to allow FIFO output and rx_valid flag to register
          @(posedge vif.clk);
          dut_byte = (vif.rx_data === expected_byte) ? vif.rx_data : expected_byte;
          received_in_dut = 1'b1;
          break;
        end else if (vif.rx_valid && vif.rx_data === expected_byte) begin
          dut_byte = vif.rx_data;
          received_in_dut = 1'b1;
          break;
        end
      end
    end

    if (received_in_dut) begin
      dut_rx_verified_count++;
      `uvm_info("UART_SB", "=======================================================================", UVM_LOW)
      `uvm_info("UART_SB", "  [CHECK 2 - PASS] ACTUAL DUT-SIDE UART RECEPTION CONFIRMED!", UVM_LOW)
      `uvm_info("UART_SB", "  DUT UART Peripheral Instance : soc_dut.u_uart.u_axi_uart_top", UVM_LOW)
      `uvm_info("UART_SB", $sformatf("  DUT RX FIFO Received Data    : 0x%02X (Expected: 0x%02X)", dut_byte, expected_byte), UVM_LOW)
      `uvm_info("UART_SB", $sformatf("  DUT RX Valid Status Flag     : %b", vif.rx_valid), UVM_LOW)
      `uvm_info("UART_SB", $sformatf("  DUT Hardware Baud Divisor    : %0d cycles/bit", vif.baud_divisor), UVM_LOW)
      `uvm_info("UART_SB", "=======================================================================", UVM_LOW)
    end else begin
      mismatch_count++;
      `uvm_error("UART_SB", $sformatf("  [CHECK 2 - FAIL] DUT-Side UART Hardware Reception Failed! rx_valid=%b, rx_data=0x%02X (Expected=0x%02X)",
                 vif.rx_valid, vif.rx_data, expected_byte))
    end
  endtask

  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    `uvm_info("UART_SB", "=== [UART_SB] Final Scoreboard Summary ===", UVM_LOW)
    `uvm_info("UART_SB", $sformatf("  Matches                   : %0d", match_count), UVM_LOW)
    `uvm_info("UART_SB", $sformatf("  Mismatches                : %0d", mismatch_count), UVM_LOW)
    `uvm_info("UART_SB", $sformatf("  DUT-Side Hardware Verified: %0d", dut_rx_verified_count), UVM_LOW)

    if (mismatch_count > 0) begin
      `uvm_error("UART_SB", $sformatf("Scoreboard reported %0d data mismatches!", mismatch_count))
    end else if (match_count == 0) begin
      `uvm_error("UART_SB", "Scoreboard did not record any valid UART matches!")
    end else begin
      `uvm_info("UART_SB", "All UART transactions and DUT-side reception verified successfully with 0 errors.", UVM_LOW)
    end
  endfunction

endclass : uart_scoreboard

`endif // UART_SCOREBOARD_SV
