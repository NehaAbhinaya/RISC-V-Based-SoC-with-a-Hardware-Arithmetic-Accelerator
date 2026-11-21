/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : Timer VIP
 * File           : timer_item.sv
 * Description    : Transaction item for Timer VIP supporting AXI4-Lite register
 *                  access and interrupt/counter progression verification.
 * ============================================================================== */

`ifndef TIMER_ITEM_SV
`define TIMER_ITEM_SV

class timer_item extends uvm_sequence_item;

  bit             irq_timer;

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
  rand bit        is_write;
  bit [31:0]      count_val;
  bit             compare_match;

  `uvm_object_utils_begin(timer_item)
    `uvm_field_int(irq_timer,      UVM_ALL_ON)
    `uvm_field_int(s_axil_awaddr,  UVM_ALL_ON)
    `uvm_field_int(s_axil_wdata,   UVM_ALL_ON)
    `uvm_field_int(s_axil_araddr,  UVM_ALL_ON)
    `uvm_field_int(s_axil_rdata,   UVM_ALL_ON)
    `uvm_field_int(is_write,       UVM_ALL_ON)
    `uvm_field_int(count_val,      UVM_ALL_ON)
    `uvm_field_int(compare_match,  UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="timer_item");
    super.new(name);
    s_axil_wstrb  = 4'hF;
    s_axil_bready = 1'b1;
    s_axil_rready = 1'b1;
    is_write      = 1'b0;
  endfunction

endclass

`endif // TIMER_ITEM_SV
