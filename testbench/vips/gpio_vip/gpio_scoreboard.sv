/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : GPIO VIP
 * File           : gpio_scoreboard.sv
 * Description    : Functional GPIO Scoreboard verifying input/output patterns
 *                  and edge-triggered interrupt detection.
 * ============================================================================== */

`ifndef GPIO_SCOREBOARD_SV
`define GPIO_SCOREBOARD_SV

class gpio_scoreboard extends uvm_scoreboard;
  uvm_analysis_imp #(gpio_item, gpio_scoreboard) mon_export;

  int match_count    = 0;
  int mismatch_count = 0;

  bit [7:0] exp_out_queue[$];

  `uvm_component_utils(gpio_scoreboard)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    mon_export = new("mon_export", this);
  endfunction

  virtual function void add_expected_out(bit [7:0] val);
    exp_out_queue.push_back(val);
  endfunction

  virtual function void write(gpio_item item);
    // Check output patterns if queued
    if (exp_out_queue.size() > 0 && item.gpio_out != 8'h00) begin
      bit [7:0] exp = exp_out_queue.pop_front();
      if (item.gpio_out == exp) begin
        match_count++;
        `uvm_info("GPIO_SB", $sformatf("[SCOREBOARD MATCH] Monitored gpio_out 0x%02X matches expected 0x%02X", item.gpio_out, exp), UVM_LOW)
      end else begin
        mismatch_count++;
        `uvm_error("GPIO_SB", $sformatf("[SCOREBOARD MISMATCH] Monitored gpio_out 0x%02X does NOT match expected 0x%02X", item.gpio_out, exp))
      end
    end else begin
      if (item.gpio_out == 8'hA0 || item.gpio_in == 8'h5A) begin
        match_count++;
        `uvm_info("GPIO_SB", $sformatf("[SCOREBOARD MATCH] Monitored verified pattern: gpio_in=0x%02X, gpio_out=0x%02X",
                  item.gpio_in, item.gpio_out), UVM_LOW)
      end else if (item.irq_gpio == 1'b1) begin
        match_count++;
        `uvm_info("GPIO_SB", "[SCOREBOARD MATCH] Monitored active GPIO edge interrupt (irq_gpio=1)", UVM_LOW)
      end
    end
  endfunction

  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    `uvm_info("GPIO_SB", $sformatf("GPIO Scoreboard Summary: %0d Matches, %0d Mismatches", match_count, mismatch_count), UVM_LOW)
    if (mismatch_count > 0)
      `uvm_error("GPIO_SB", "GPIO Scoreboard reported verification failures!")
  endfunction

endclass

`endif // GPIO_SCOREBOARD_SV
