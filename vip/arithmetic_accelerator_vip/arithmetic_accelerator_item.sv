/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : Arithmetic Accelerator VIP
 * File           : arithmetic_accelerator_item.sv
 * Description    : Transaction item for Arithmetic Accelerator VIP supporting
 *                  Direct Mode (AXI4-Lite) and Streaming Mode (DMA handshakes).
 * ============================================================================== */

`ifndef ARITHMETIC_ACCELERATOR_ITEM_SV
`define ARITHMETIC_ACCELERATOR_ITEM_SV

class arithmetic_accelerator_item extends uvm_sequence_item;

  bit             irq_acc;

  // Streaming handshake signals
  rand bit        dma_op_valid;
  rand bit [31:0] dma_op_data_a;
  rand bit [31:0] dma_op_data_b;
  bit             dma_op_ready;
  bit             dma_res_valid;
  bit [31:0]      dma_res_data;
  rand bit        dma_res_ready;
  rand bit        dma_last;

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
  rand bit [2:0]  op;           // 0: ADD, 1: SUB, 2: MUL, 3: DIV, 4: MAC
  rand bit [31:0] op_a;
  rand bit [31:0] op_b;
  bit [31:0]      res_val;
  bit             error_flag;
  rand bit        is_direct;    // 1: Direct register mode test
  rand bit        is_streaming; // 1: Streaming DMA mode handshake
  rand bit        is_write;

  `uvm_object_utils_begin(arithmetic_accelerator_item)
    `uvm_field_int(irq_acc,        UVM_ALL_ON)
    `uvm_field_int(dma_op_valid,   UVM_ALL_ON)
    `uvm_field_int(dma_op_data_a,  UVM_ALL_ON)
    `uvm_field_int(dma_op_data_b,  UVM_ALL_ON)
    `uvm_field_int(dma_res_valid,  UVM_ALL_ON)
    `uvm_field_int(dma_res_data,   UVM_ALL_ON)
    `uvm_field_int(op,             UVM_ALL_ON)
    `uvm_field_int(op_a,           UVM_ALL_ON)
    `uvm_field_int(op_b,           UVM_ALL_ON)
    `uvm_field_int(res_val,        UVM_ALL_ON)
    `uvm_field_int(error_flag,     UVM_ALL_ON)
    `uvm_field_int(is_direct,      UVM_ALL_ON)
    `uvm_field_int(is_streaming,   UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="arithmetic_accelerator_item");
    super.new(name);
    s_axil_wstrb  = 4'hF;
    s_axil_bready = 1'b1;
    s_axil_rready = 1'b1;
    dma_res_ready = 1'b1;
    is_direct     = 1'b0;
    is_streaming  = 1'b0;
    is_write      = 1'b0;
  endfunction

endclass

`endif // ARITHMETIC_ACCELERATOR_ITEM_SV
