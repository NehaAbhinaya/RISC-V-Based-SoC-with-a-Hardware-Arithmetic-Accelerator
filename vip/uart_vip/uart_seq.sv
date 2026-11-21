/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : UART VIP
 * File           : uart_seq.sv
 * Description    : UVM Sequences for UART verification (Transmit 8'hA5,
 *                  receive and verify test byte).
 * ============================================================================== */

`ifndef UART_SEQ_SV
`define UART_SEQ_SV

// Transmit Sequence: Configures UART and sends 8'hA5 to TXDATA
class uart_transmit_seq extends uvm_sequence #(uart_item);
  `uvm_object_utils(uart_transmit_seq)

  function new(string name="uart_transmit_seq");
    super.new(name);
  endfunction

  virtual task body();
    uart_item item;

    // 1. Configure UART_CTRL: Divisor = 8, Enable = 1 -> 32'h0000_0081
    item = uart_item::type_id::create("item");
    start_item(item);
    item.is_axil        = 1'b1;
    item.is_write       = 1'b1;
    item.s_axil_awaddr  = 32'h4000_0000;
    item.s_axil_wdata   = 32'h0000_0081;
    item.s_axil_wstrb   = 4'hF;
    finish_item(item);

    // 2. Transmit byte 8'hA5 to UART_TXDATA (0x4000_0008)
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

// Receive Sequence: Injects 8'hA5 serially into uart_rx and reads back via UART_RXDATA
class uart_receive_seq extends uvm_sequence #(uart_item);
  `uvm_object_utils(uart_receive_seq)

  function new(string name="uart_receive_seq");
    super.new(name);
  endfunction

  virtual task body();
    uart_item item;

    // 1. Inject serial frame 8'hA5 on uart_rx
    item = uart_item::type_id::create("item");
    start_item(item);
    item.is_rx    = 1'b1;
    item.data     = 8'hA5;
    item.baud_div = 8;
    finish_item(item);

    `uvm_info("UART_SEQ", "Injected serial test byte 0xA5 onto uart_rx line", UVM_LOW)

    // 2. Read back from UART_RXDATA (0x4000_000C)
    item = uart_item::type_id::create("item");
    start_item(item);
    item.is_axil        = 1'b1;
    item.is_write       = 1'b0;
    item.s_axil_araddr  = 32'h4000_000C;
    finish_item(item);

    `uvm_info("UART_SEQ", $sformatf("Read UART_RXDATA returned: 0x%02X", item.s_axil_rdata[7:0]), UVM_LOW)
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
