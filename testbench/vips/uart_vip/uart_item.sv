/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : UART VIP
 * File           : uart_item.sv
 * Description    : Transaction item for UART VIP supporting both pin-level serial
 *                  frames (TX/RX) and memory-mapped AXI4-Lite register access.
 *                  Includes comprehensive UART protocol configuration fields:
 *                  8-N-1 format, configurable baud divisor, and error indicators.
 * ============================================================================== */

`ifndef UART_ITEM_SV
`define UART_ITEM_SV

class uart_item extends uvm_sequence_item;

  // Pin-level signals
  bit uart_tx;
  rand bit uart_rx;
  bit irq_uart;

  // AXI4-Lite slave channel signals
  rand bit [31:0] s_axil_awaddr;
  rand bit [2:0]  s_axil_awprot;
  rand bit        s_axil_awvalid;
  bit             s_axil_awready;
  rand bit [31:0] s_axil_wdata;
  rand bit [3:0]  s_axil_wstrb;
  rand bit        s_axil_wvalid;
  bit             s_axil_wready;
  bit [1:0]       s_axil_bresp;
  bit             s_axil_bvalid;
  rand bit        s_axil_bready;
  rand bit [31:0] s_axil_araddr;
  rand bit [2:0]  s_axil_arprot;
  rand bit        s_axil_arvalid;
  bit             s_axil_arready;
  bit [31:0]      s_axil_rdata;
  bit [1:0]       s_axil_rresp;
  bit             s_axil_rvalid;
  rand bit        s_axil_rready;

  // Functional protocol fields
  rand bit [7:0]  data;         // 8-bit payload (e.g. 8'hA5)
  rand bit        is_rx;        // 1: drive serial RX line
  rand bit        is_tx;        // 1: monitored TX line
  rand bit        is_axil;      // 1: AXI4-Lite register access
  rand bit        is_write;     // 1: write, 0: read
  rand int        baud_div;     // Clock cycles per bit (default: 16 matching SoC RTL)
  rand bit [3:0]  data_bits;    // Supported: 8 bits
  rand bit [1:0]  stop_bits;    // Supported: 1 bit
  rand bit        parity_en;    // 0: None, 1: Enabled
  rand bit        parity_type;  // 0: Odd, 1: Even

  // Status and checking indicators
  bit             framing_error;
  bit             parity_error;

  `uvm_object_utils_begin(uart_item)
    `uvm_field_int(uart_tx,        UVM_ALL_ON)
    `uvm_field_int(uart_rx,        UVM_ALL_ON)
    `uvm_field_int(irq_uart,       UVM_ALL_ON)
    `uvm_field_int(s_axil_awaddr,  UVM_ALL_ON)
    `uvm_field_int(s_axil_wdata,   UVM_ALL_ON)
    `uvm_field_int(s_axil_araddr,  UVM_ALL_ON)
    `uvm_field_int(s_axil_rdata,   UVM_ALL_ON)
    `uvm_field_int(data,           UVM_ALL_ON)
    `uvm_field_int(is_rx,          UVM_ALL_ON)
    `uvm_field_int(is_tx,          UVM_ALL_ON)
    `uvm_field_int(is_axil,        UVM_ALL_ON)
    `uvm_field_int(is_write,       UVM_ALL_ON)
    `uvm_field_int(baud_div,       UVM_ALL_ON)
    `uvm_field_int(data_bits,      UVM_ALL_ON)
    `uvm_field_int(stop_bits,      UVM_ALL_ON)
    `uvm_field_int(parity_en,      UVM_ALL_ON)
    `uvm_field_int(parity_type,    UVM_ALL_ON)
    `uvm_field_int(framing_error,  UVM_ALL_ON)
    `uvm_field_int(parity_error,   UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="uart_item");
    super.new(name);
    baud_div      = 16;   // Matches SoC RTL default baud divisor
    data_bits     = 4'd8; // 8-bit data
    stop_bits     = 2'd1; // 1 stop bit
    parity_en     = 1'b0; // No parity
    parity_type   = 1'b0;
    framing_error = 1'b0;
    parity_error  = 1'b0;
    uart_rx       = 1'b1; // Idle state high
    s_axil_wstrb  = 4'hF;
    s_axil_bready = 1'b1;
    s_axil_rready = 1'b1;
    is_rx         = 1'b0;
    is_tx         = 1'b0;
    is_axil       = 1'b0;
    is_write      = 1'b0;
  endfunction

endclass

`endif // UART_ITEM_SV
