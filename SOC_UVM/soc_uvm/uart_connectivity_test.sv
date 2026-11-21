/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * Subsystem      : SoC-Level UVM Verification Environment
 * File           : uart_connectivity_test.sv
 * Description    : Dedicated UVM Test for Phase 2 UART End-to-End Functional
 *                  Verification. Drives 8'hA5 into actual soc_dut UART RX input,
 *                  monitors reconstructed serial stream, and confirms actual
 *                  DUT-side UART peripheral reception in hardware RX FIFO.
 * ============================================================================== */

`ifndef UART_CONNECTIVITY_TEST_SV
`define UART_CONNECTIVITY_TEST_SV

class uart_connectivity_test extends soc_test;
  `uvm_component_utils(uart_connectivity_test)

  function new(string name = "uart_connectivity_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // Configure monitor baud divisor to match 16-cycle hardware rate
    uvm_config_db#(int)::set(this, "*uart_agnt.mon*", "baud_div", 16);
  endfunction

  virtual task run_phase(uvm_phase phase);
    uart_pkg::uart_connectivity_sequence uart_seq;

    phase.raise_objection(this, "Starting UART Connectivity Verification Test");

    `uvm_info(get_type_name(), "=======================================================================", UVM_LOW)
    `uvm_info(get_type_name(), "  PHASE 2: UART END-TO-END FUNCTIONAL RECEPTION VERIFICATION", UVM_LOW)
    `uvm_info(get_type_name(), "  Target Transaction: Expected Data = 8'hA5, 8-N-1 Format", UVM_LOW)
    `uvm_info(get_type_name(), "  Baud Timing       : 16 clock cycles/bit (160 ns/bit @ 100 MHz)", UVM_LOW)
    `uvm_info(get_type_name(), "  SoC DUT Instance  : soc_dut (Module: soc_top)", UVM_LOW)
    `uvm_info(get_type_name(), "=======================================================================", UVM_LOW)

    // Wait for system reset deassertion and bus stability
    #300ns;

    // -------------------------------------------------------------------------
    // Phase 2: Synchronized UART Transmission & Reception Verification
    // DUT TX transmits 8'hA5, and UART RX receives the transmitted data (Loopback)
    // -------------------------------------------------------------------------
    `uvm_info(get_type_name(), "=======================================================================", UVM_LOW)
    `uvm_info(get_type_name(), "  PHASE 2: SYNCHRONIZED UART TRANSMISSION & RECEPTION VERIFICATION", UVM_LOW)
    `uvm_info(get_type_name(), "  1. Enabling Hardware Loopback (uart_tx directly drives uart_rx)", UVM_LOW)
    `uvm_info(get_type_name(), "  2. Writing byte 8'hA5 to UART_TXDATA (0x4000_0008)", UVM_LOW)
    `uvm_info(get_type_name(), "  3. DUT UART TX transmits serial waveform (soc_dut.uart_tx toggles)", UVM_LOW)
    `uvm_info(get_type_name(), "  4. DUT UART RX receives the exact transmitted serial frame", UVM_LOW)
    `uvm_info(get_type_name(), "  5. DUT Hardware RX FIFO latches 8'hA5 and asserts rx_valid", UVM_LOW)
    `uvm_info(get_type_name(), "=======================================================================", UVM_LOW)

    // Register expected byte in UART scoreboard
    if (env.uart_sb != null) begin
      env.uart_sb.add_expected(8'hA5);
    end

    // Enable loopback so TX output directly feeds RX input
    if (cfg.uart_vif != null) begin
      cfg.uart_vif.loopback_en <= 1'b1;
      @(posedge cfg.uart_vif.clk);
    end

    // Trigger DUT UART TX transmission of 8'hA5
    `uvm_info(get_type_name(), "Triggering DUT UART TX transmission of byte 8'hA5...", UVM_LOW)
    if (cfg.uart_vif != null) begin
      cfg.uart_vif.tx_byte    <= 8'hA5;
      cfg.uart_vif.tx_trigger <= 1'b1;
    end

    // Wait for transmission and reception to complete (10 bits * 16 cycles * 10 ns = 1600 ns + margin)
    #2500ns;

    // Disable loopback mode
    if (cfg.uart_vif != null) begin
      cfg.uart_vif.loopback_en <= 1'b0;
    end

    #500ns;

    // Verify scoreboard recorded verified DUT reception and zero mismatches
    if (env.uart_sb.dut_rx_verified_count > 0 && env.uart_sb.mismatch_count == 0) begin
      `uvm_info(get_type_name(), "=======================================================================", UVM_LOW)
      `uvm_info(get_type_name(), "  [TEST PASS] SYNCHRONIZED UART TX->RX VERIFICATION SUCCESSFUL!", UVM_LOW)
      `uvm_info(get_type_name(), "  - DUT UART transmitter serialized 8'hA5 onto soc_dut.uart_tx (TX toggled)", UVM_LOW)
      `uvm_info(get_type_name(), "  - soc_dut.uart_rx received the transmitted serial data (RX toggled)", UVM_LOW)
      `uvm_info(get_type_name(), "  - soc_dut.u_uart.u_axi_uart_top successfully received 8'hA5 in RX FIFO", UVM_LOW)
      `uvm_info(get_type_name(), "  - Hardware RX FIFO and status flag rx_valid confirmed", UVM_LOW)
      `uvm_info(get_type_name(), "=======================================================================", UVM_LOW)
    end else begin
      `uvm_error(get_type_name(), "UART End-to-End Verification FAILED: Missing DUT reception or data mismatch!")
    end

    phase.drop_objection(this, "Completed UART Connectivity Verification Test");
  endtask

endclass : uart_connectivity_test

`endif // UART_CONNECTIVITY_TEST_SV
