/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : UART VIP
 * File           : uart_seq.sv
 * Description    : UVM Sequences for UART verification including:
 *                  - uart_connectivity_sequence (dedicated Phase 2 test sequence)
 *                  - uart_transmit_seq
 *                  - uart_receive_seq
 *                  - uart_smoke_seq
 * ============================================================================== */

`ifndef UART_SEQ_SV
`define UART_SEQ_SV

// ------------------------------------------------------------------------------
// Dedicated Phase 2 End-to-End UART Connectivity Sequence
// ------------------------------------------------------------------------------
class uart_connectivity_sequence extends uvm_sequence #(uart_item);
  `uvm_object_utils(uart_connectivity_sequence)

  rand bit [7:0] tx_data;
  rand int       baud_div;

  function new(string name = "uart_connectivity_sequence");
    super.new(name);
    tx_data  = 8'hA5; // Primary expected transaction data
    baud_div = 16;   // Actual SoC hardware baud divisor (16 cycles/bit)
  endfunction

  virtual task body();
    uart_item req;

    `uvm_info(get_type_name(), "=======================================================================", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Starting UART Connectivity Sequence: Data=0x%02X, BaudDiv=%0d cycles/bit", tx_data, baud_div), UVM_LOW)
    `uvm_info(get_type_name(), "  Configuration: 8 Data Bits, 1 Stop Bit, No Parity (8-N-1)", UVM_LOW)
    `uvm_info(get_type_name(), "=======================================================================", UVM_LOW)

    // 1. Create UART sequence item
    req = uart_item::type_id::create("req");

    // 2. Configure transaction parameters
    start_item(req);
    req.data        = tx_data;  // 8'hA5
    req.is_rx       = 1'b1;     // Serial RX frame into DUT uart_rx input
    req.is_axil     = 1'b0;
    req.baud_div    = baud_div; // 16 clock cycles/bit
    req.data_bits   = 4'd8;     // 8 data bits
    req.stop_bits   = 2'd1;     // 1 stop bit
    req.parity_en   = 1'b0;     // No parity
    req.parity_type = 1'b0;

    // 3. Send item through existing UART sequencer to driver
    finish_item(req);

    // 4. Wait for monitor and scoreboard completion window
    #500ns;

    `uvm_info(get_type_name(), $sformatf("=== [UART_SEQ] UART Connectivity Sequence finished driving 0x%02X ===", tx_data), UVM_LOW)
  endtask
endclass

// Transmit Sequence: Configures UART and sends 8'hA5 to TXDATA
class uart_transmit_seq extends uvm_sequence #(uart_item);
  `uvm_object_utils(uart_transmit_seq)

  function new(string name="uart_transmit_seq");
    super.new(name);
  endfunction

  virtual task body();
    uart_item item;

    item = uart_item::type_id::create("item");
    start_item(item);
    item.is_axil        = 1'b1;
    item.is_write       = 1'b1;
    item.s_axil_awaddr  = 32'h4000_0000;
    item.s_axil_wdata   = 32'h0000_0101; // Divisor = 16, Enable = 1
    item.s_axil_wstrb   = 4'hF;
    finish_item(item);

    item = uart_item::type_id::create("item");
    start_item(item);
    item.is_axil        = 1'b1;
    item.is_write       = 1'b1;
    item.s_axil_awaddr  = 32'h4000_0008;
    item.s_axil_wdata   = 32'h0000_00A5;
    item.s_axil_wstrb   = 4'hF;
    finish_item(item);

    `uvm_info("UART_SEQ", "Triggered transmission of byte 0xA5 via UART_TXDATA", UVM_LOW)
  endtask
endclass

// Receive Sequence: Injects 8'hA5 serially into uart_rx
class uart_receive_seq extends uvm_sequence #(uart_item);
  `uvm_object_utils(uart_receive_seq)

  function new(string name="uart_receive_seq");
    super.new(name);
  endfunction

  virtual task body();
    uart_item item;

    item = uart_item::type_id::create("item");
    start_item(item);
    item.is_rx    = 1'b1;
    item.data     = 8'hA5;
    item.baud_div = 16;
    finish_item(item);

    `uvm_info("UART_SEQ", "Injected serial test byte 0xA5 onto uart_rx line", UVM_LOW)
  endtask
endclass

// Master Smoke Sequence running both transmit and receive tests
class uart_smoke_seq extends uvm_sequence #(uart_item);
  `uvm_object_utils(uart_smoke_seq)

  function new(string name="uart_smoke_seq");
    super.new(name);
  endfunction

  virtual task body();
    uart_transmit_seq tx_seq;
    uart_receive_seq  rx_seq;

    `uvm_info("UART_SEQ", "Starting UART Smoke Sequence (Transmit 0xA5 + Receive 0xA5)...", UVM_LOW)
    `uvm_do(tx_seq)
    `uvm_do(rx_seq)
    `uvm_info("UART_SEQ", "UART Smoke Sequence completed successfully.", UVM_LOW)
  endtask
endclass

`endif // UART_SEQ_SV
