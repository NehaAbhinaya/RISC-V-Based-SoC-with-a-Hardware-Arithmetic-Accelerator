/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : SPI VIP
 * File           : spi_monitor.sv
 * Description    : Functional SPI Monitor. Passively observes SPI bus frames
 *                  (SCLK, CS_N, MOSI, MISO) and publishes reconstructed bytes.
 * ============================================================================== */

`ifndef SPI_MONITOR_SV
`define SPI_MONITOR_SV

class spi_monitor extends uvm_monitor;
  virtual spi_if vif;
  uvm_analysis_port #(spi_item) ap;

  `uvm_component_utils(spi_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual spi_if)::get(this, "", "vif", vif) || vif == null) begin
      `uvm_fatal("NOVIF", {"Virtual interface vif must be set for ", get_full_name(), ".vif"});
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    bit [7:0] mosi_byte;
    bit [7:0] miso_byte;
    spi_item item;

    if (vif != null && !vif.rst_n)
      @(posedge vif.rst_n);

    forever begin
      // Wait for CS_N assertion (active-low)
      wait (vif.spi_cs_n === 1'b0);

      mosi_byte = 8'h00;
      miso_byte = 8'h00;

      // Sample 8 bits of MOSI on posedge SCLK and MISO on negedge SCLK
      for (int i = 7; i >= 0; i--) begin
        @(posedge vif.spi_sclk or posedge vif.spi_cs_n);
        if (vif.spi_cs_n === 1'b1) break;
        mosi_byte[i] = vif.spi_mosi;
        miso_byte[i] = vif.spi_miso;
      end

      if (vif.spi_cs_n === 1'b0) begin
        item = spi_item::type_id::create("item");
        item.rx_data = mosi_byte; // Transmitted from Master
        item.tx_data = miso_byte; // Responded by Slave
        item.spi_cs_n = 1'b0;

        `uvm_info("SPI_MON", $sformatf("Monitored SPI 8-bit frame: MOSI=0x%02X, MISO=0x%02X", mosi_byte, miso_byte), UVM_LOW)
        ap.write(item);
      end

      wait (vif.spi_cs_n === 1'b1);
    end
  endtask

endclass

`endif // SPI_MONITOR_SV
