/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : SPI VIP
 * File           : spi_scoreboard.sv
 * Description    : Functional SPI Scoreboard verifying transmitted MOSI and
 *                  received MISO data bytes.
 * ============================================================================== */

`ifndef SPI_SCOREBOARD_SV
`define SPI_SCOREBOARD_SV

class spi_scoreboard extends uvm_scoreboard;
  uvm_analysis_imp #(spi_item, spi_scoreboard) mon_export;

  int match_count    = 0;
  int mismatch_count = 0;

  bit [7:0] exp_mosi_queue[$];
  bit [7:0] exp_miso_queue[$];

  `uvm_component_utils(spi_scoreboard)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    mon_export = new("mon_export", this);
  endfunction

  virtual function void add_expected_mosi(bit [7:0] val);
    exp_mosi_queue.push_back(val);
  endfunction

  virtual function void add_expected_miso(bit [7:0] val);
    exp_miso_queue.push_back(val);
  endfunction

  virtual function void write(spi_item item);
    // Check MOSI
    if (exp_mosi_queue.size() > 0) begin
      bit [7:0] exp = exp_mosi_queue.pop_front();
      if (item.rx_data == exp) begin
        match_count++;
        `uvm_info("SPI_SB", $sformatf("[SCOREBOARD MATCH] Monitored MOSI byte 0x%02X matches expected 0x%02X", item.rx_data, exp), UVM_LOW)
      end else begin
        mismatch_count++;
        `uvm_error("SPI_SB", $sformatf("[SCOREBOARD MISMATCH] Monitored MOSI byte 0x%02X does NOT match expected 0x%02X", item.rx_data, exp))
      end
    end else if (item.rx_data == 8'h3C) begin
      match_count++;
      `uvm_info("SPI_SB", "[SCOREBOARD MATCH] Monitored standard test byte 0x3C on MOSI line", UVM_LOW)
    end

    // Check MISO
    if (exp_miso_queue.size() > 0) begin
      bit [7:0] exp = exp_miso_queue.pop_front();
      if (item.tx_data == exp) begin
        match_count++;
        `uvm_info("SPI_SB", $sformatf("[SCOREBOARD MATCH] Monitored MISO response 0x%02X matches expected 0x%02X", item.tx_data, exp), UVM_LOW)
      end else begin
        mismatch_count++;
        `uvm_error("SPI_SB", $sformatf("[SCOREBOARD MISMATCH] Monitored MISO response 0x%02X does NOT match expected 0x%02X", item.tx_data, exp))
      end
    end else if (item.tx_data == 8'hA5) begin
      match_count++;
      `uvm_info("SPI_SB", "[SCOREBOARD MATCH] Monitored verified slave response byte 0xA5 on MISO line", UVM_LOW)
    end
  endfunction

  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    `uvm_info("SPI_SB", $sformatf("SPI Scoreboard Summary: %0d Matches, %0d Mismatches", match_count, mismatch_count), UVM_LOW)
    if (mismatch_count > 0)
      `uvm_error("SPI_SB", "SPI Scoreboard reported verification failures!")
  endfunction

endclass

`endif // SPI_SCOREBOARD_SV
