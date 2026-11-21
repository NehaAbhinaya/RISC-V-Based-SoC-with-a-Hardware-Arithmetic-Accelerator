/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : DMA VIP
 * File           : dma_seq.sv
 * Description    : UVM Sequences for DMA Controller verification (Source/Destination
 *                  programming, length configuration, and transfer initiation).
 * ============================================================================== */

`ifndef DMA_SEQ_SV
`define DMA_SEQ_SV

class dma_smoke_seq extends uvm_sequence #(dma_item);
  `uvm_object_utils(dma_smoke_seq)

  function new(string name="dma_smoke_seq");
    super.new(name);
  endfunction

  virtual task body();
    dma_item item;

    `uvm_info("DMA_SEQ", "Starting DMA Smoke Configuration Sequence...", UVM_LOW)

    // Program DMA Transfer:
    // Source: 0x1000_0100 (DMEM operand buffer)
    // Destination: 0x1000_0200 (DMEM result buffer)
    // Length: 4 pairs
    // Control: 0x03 (start=1, irq_en=1)
    item = dma_item::type_id::create("item");
    start_item(item);
    item.is_dma_config = 1'b1;
    item.src_addr      = 32'h1000_0100;
    item.dst_addr      = 32'h1000_0200;
    item.transfer_len  = 16'd4;
    item.ctrl_reg      = 32'h0000_0003;
    finish_item(item);

    #3500; // Allow DMA autonomous data movement cycles

    // Read DMA_STATUS (0x4000_4010)
    item = dma_item::type_id::create("item");
    start_item(item);
    item.is_write       = 1'b0;
    item.s_axil_araddr  = 32'h4000_4010;
    finish_item(item);

    `uvm_info("DMA_SEQ", $sformatf("Read DMA_STATUS = 0x%08X (done bit = %b)", item.s_axil_rdata, item.s_axil_rdata[1]), UVM_LOW)
    `uvm_info("DMA_SEQ", "DMA Configuration Sequence finished.", UVM_LOW)
  endtask
endclass

`endif // DMA_SEQ_SV
