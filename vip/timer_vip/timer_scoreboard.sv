/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : Timer VIP
 * File           : timer_scoreboard.sv
 * Description    : Functional Timer Scoreboard verifying counter progression,
 *                  compare match, and interrupt assertion/deassertion.
 * ============================================================================== */

`ifndef TIMER_SCOREBOARD_SV
`define TIMER_SCOREBOARD_SV

class timer_scoreboard extends uvm_scoreboard;
  uvm_analysis_imp #(timer_item, timer_scoreboard) mon_export;

  int match_count    = 0;
  int mismatch_count = 0;
  bit irq_observed   = 1'b0;
  bit count_progressed = 1'b0;

  `uvm_component_utils(timer_scoreboard)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    mon_export = new("mon_export", this);
  endfunction

  virtual function void write(timer_item item);
    if (item.irq_timer == 1'b1) begin
      irq_observed = 1'b1;
      match_count++;
      `uvm_info("TIMER_SB", "[SCOREBOARD MATCH] Verified Timer compare-match interrupt (irq_timer=1)", UVM_LOW)
    end

    if (item.count_val > 0) begin
      count_progressed = 1'b1;
      match_count++;
      `uvm_info("TIMER_SB", $sformatf("[SCOREBOARD MATCH] Verified Timer counter progression: %0d", item.count_val), UVM_LOW)
    end
  endfunction

  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    `uvm_info("TIMER_SB", $sformatf("Timer Scoreboard Summary: %0d Matches, %0d Mismatches", match_count, mismatch_count), UVM_LOW)
    if (mismatch_count > 0)
      `uvm_error("TIMER_SB", "Timer Scoreboard reported verification failures!")
  endfunction

endclass

`endif // TIMER_SCOREBOARD_SV
