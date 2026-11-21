/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : SPI VIP
 * File           : spi_driver.sv
 * Description    : Functional SPI Driver. Acts as SPI Slave responding on MISO
 *                  upon CS_N assertion, while supporting AXI4-Lite master programming.
 * ============================================================================== */

`ifndef SPI_DRIVER_SV
`define SPI_DRIVER_SV

class spi_driver extends uvm_driver #(spi_item);
  virtual spi_if vif;

  bit [7:0] slave_resp_byte = 8'hA5;

  `uvm_component_utils(spi_driver)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual spi_if)::get(this, "", "vif", vif) || vif == null) begin
      `uvm_fatal("NOVIF", {"Virtual interface vif must be set for ", get_full_name(), ".vif"});
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    if (vif != null) begin
      vif.spi_miso       <= 1'b0;
      vif.s_axil_awaddr  <= 32'h0;
      vif.s_axil_awprot  <= 3'b000;
      vif.s_axil_awvalid <= 1'b0;
      vif.s_axil_wdata   <= 32'h0;
      vif.s_axil_wstrb   <= 4'h0;
      vif.s_axil_wvalid  <= 1'b0;
      vif.s_axil_bready  <= 1'b0;
      vif.s_axil_araddr  <= 32'h0;
      vif.s_axil_arprot  <= 3'b000;
      vif.s_axil_arvalid <= 1'b0;
      vif.s_axil_rready  <= 1'b0;
    end

    if (vif != null && !vif.rst_n)
      @(posedge vif.rst_n);

    // Fork off continuous slave MISO driver thread and sequence item processor
    fork
      slave_miso_thread();
      seq_item_thread();
    join
  endtask

  // Thread to automatically drive MISO when DUT acts as SPI Master
  task slave_miso_thread();
    int bit_idx;
    forever begin
      // Wait for CS_N falling edge
      @(negedge vif.spi_cs_n);
      // Drive MSB immediately upon CS assertion for Mode 0
      vif.spi_miso <= slave_resp_byte[7];
      bit_idx = 6;

      while (vif.spi_cs_n === 1'b0) begin
        @(negedge vif.spi_sclk or posedge vif.spi_cs_n);
        if (vif.spi_cs_n === 1'b0) begin
          vif.spi_miso <= slave_resp_byte[bit_idx];
          if (bit_idx > 0)
            bit_idx--;
          else
            bit_idx = 7;
        end
      end
      vif.spi_miso <= 1'b0;
    end
  endtask

  // Sequence Item Thread
  task seq_item_thread();
    forever begin
      seq_item_port.get_next_item(req);

      if (req.is_slave_resp) begin
        slave_resp_byte = req.tx_data;
        `uvm_info("SPI_DRV", $sformatf("Updated SPI slave response byte to: 0x%02X", slave_resp_byte), UVM_MEDIUM)
      end else if (req.is_axil) begin
        if (req.is_write)
          axil_write(req.s_axil_awaddr, req.s_axil_wdata, req.s_axil_wstrb);
        else
          axil_read(req.s_axil_araddr, req.s_axil_rdata);
      end else begin
        @(posedge vif.clk);
      end

      seq_item_port.item_done();
    end
  endtask

  task axil_write(input [31:0] addr, input [31:0] data, input [3:0] strb);
    int timeout;
    @(posedge vif.clk);
    vif.s_axil_awaddr  <= addr;
    vif.s_axil_awprot  <= 3'b000;
    vif.s_axil_awvalid <= 1'b1;
    vif.s_axil_wdata   <= data;
    vif.s_axil_wstrb   <= (strb != 4'h0) ? strb : 4'hF;
    vif.s_axil_wvalid  <= 1'b1;
    vif.s_axil_bready  <= 1'b1;

    timeout = 0;
    while ((!vif.s_axil_awready || !vif.s_axil_wready) && timeout < 200) begin
      @(posedge vif.clk);
      if (vif.s_axil_awready) vif.s_axil_awvalid <= 1'b0;
      if (vif.s_axil_wready)  vif.s_axil_wvalid  <= 1'b0;
      timeout++;
    end
    @(posedge vif.clk);
    vif.s_axil_awvalid <= 1'b0;
    vif.s_axil_wvalid  <= 1'b0;

    timeout = 0;
    while (!vif.s_axil_bvalid && timeout < 200) begin
      @(posedge vif.clk);
      timeout++;
    end
    @(posedge vif.clk);
    vif.s_axil_bready <= 1'b0;
    @(posedge vif.clk);
  endtask

  task axil_read(input [31:0] addr, output [31:0] data);
    int timeout;
    @(posedge vif.clk);
    vif.s_axil_araddr  <= addr;
    vif.s_axil_arprot  <= 3'b000;
    vif.s_axil_arvalid <= 1'b1;
    vif.s_axil_rready  <= 1'b1;

    timeout = 0;
    while (!vif.s_axil_arready && timeout < 200) begin
      @(posedge vif.clk);
      timeout++;
    end
    @(posedge vif.clk);
    vif.s_axil_arvalid <= 1'b0;

    timeout = 0;
    while (!vif.s_axil_rvalid && timeout < 200) begin
      @(posedge vif.clk);
      timeout++;
    end
    data = vif.s_axil_rdata;
    @(posedge vif.clk);
    vif.s_axil_rready <= 1'b0;
    @(posedge vif.clk);
  endtask

endclass

`endif // SPI_DRIVER_SV
