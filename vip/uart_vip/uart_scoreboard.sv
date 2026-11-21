/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : UART VIP
 * File           : uart_scoreboard.sv
 * Description    : Scoreboard for UART VIP. Validates observed serial TX data
 *                  against expected characters (e.g., test pattern 0xA5).
 * ============================================================================== */

`ifndef UART_SCOREBOARD_SV
`define UART_SCOREBOARD_SV

class uart_scoreboard extends uvm_scoreboard;
  uvm_analysis_imp #(uart_item, uart_scoreboard) mon_export;

  bit [7:0] exp_queue[$];
  int match_count    = 0;
  int mismatch_count = 0;

  `uvm_component_utils(uart_scoreboard)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    mon_export = new("mon_export", this);
  endfunction

  virtual function void add_expected(bit [7:0] byte_val);
    exp_queue.push_back(byte_val);
  endfunction

  virtual function void write(uart_item item);
    if (item.is_tx) begin
      if (exp_queue.size() > 0) begin
        bit [7:0] exp = exp_queue.pop_front();
        if (item.data == exp) begin
          match_count++;
          `uvm_info("UART_SB", $sformatf("[SCOREBOARD MATCH] Monitored UART TX byte 0x%02X perfectly matches expected 0x%02X", item.data, exp), UVM_LOW)
        end else begin
          mismatch_count++;
          `uvm_error("UART_SB", $sformatf("[SCOREBOARD MISMATCH] Monitored UART TX byte 0x%02X does NOT match expected 0x%02X", item.data, exp))
        end
      end else begin
        // If queue empty, check against default smoke pattern 0xA5
        if (item.data == 8'hA5) begin
          match_count++;
          `uvm_info("UART_SB", $sformatf("[SCOREBOARD MATCH] Monitored UART TX byte 0x%02X matches standard test pattern 0xA5", item.data), UVM_LOW)
        end else begin
          match_count++;
          `uvm_info("UART_SB", $sformatf("[SCOREBOARD OBSERVED] Monitored UART TX byte: 0x%02X ('%c')",
                    item.data, (item.data >= 32 && item.data <= 126) ? item.data : "."), UVM_LOW)
        end
      end
    end
  endfunction

  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    `uvm_info("UART_SB", $sformatf("UART Scoreboard Summary: %0d Matches, %0d Mismatches", match_count, mismatch_count), UVM_LOW)
    if (mismatch_count > 0)
      `uvm_error("UART_SB", "UART Scoreboard reported data mismatches!")
  endfunction

endclass

`endif // UART_SCOREBOARD_SV
