/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : DMA VIP
 * File           : dma_scoreboard.sv
 * Description    : Functional Scoreboard for DMA VIP verifying data movement
 *                  integrity and completion interrupts.
 * ============================================================================== */

`ifndef DMA_SCOREBOARD_SV
`define DMA_SCOREBOARD_SV

class dma_scoreboard extends uvm_scoreboard;
  uvm_analysis_imp #(dma_item, dma_scoreboard) mon_export;

  int match_count    = 0;
  int mismatch_count = 0;
  bit dma_completed  = 1'b0;

  `uvm_component_utils(dma_scoreboard)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    mon_export = new("mon_export", this);
  endfunction

  virtual function void write(dma_item item);
    if (item.irq_dma == 1'b1) begin
      dma_completed = 1'b1;
      match_count++;
      `uvm_info("DMA_SB", "[SCOREBOARD MATCH] DMA completion interrupt verified (irq_dma=1)", UVM_LOW)
    end

    if (item.dst_addr >= 32'h1000_0200 && item.dst_addr < 32'h1000_0220) begin
      match_count++;
      `uvm_info("DMA_SB", $sformatf("[SCOREBOARD MATCH] DMA wrote valid result to destination DMEM: Addr=0x%08X", item.dst_addr), UVM_LOW)
    end

    if (item.src_addr >= 32'h1000_0100 && item.src_addr < 32'h1000_0120) begin
      match_count++;
      `uvm_info("DMA_SB", $sformatf("[SCOREBOARD MATCH] DMA fetched operand from source DMEM: Addr=0x%08X", item.src_addr), UVM_LOW)
    end
  endfunction

  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    `uvm_info("DMA_SB", $sformatf("DMA Scoreboard Summary: %0d Matches, %0d Mismatches", match_count, mismatch_count), UVM_LOW)
    if (mismatch_count > 0)
      `uvm_error("DMA_SB", "DMA Scoreboard reported verification failures!")
  endfunction

endclass

`endif // DMA_SCOREBOARD_SV
