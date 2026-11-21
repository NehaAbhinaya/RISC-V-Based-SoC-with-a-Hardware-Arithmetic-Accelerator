/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : DMA VIP
 * File           : dma_driver.sv
 * Description    : Functional Driver for DMA VIP supporting configuration register
 *                  programming (SRC, DST, LEN, CTRL), autonomous transfer monitoring,
 *                  and memory/accelerator peer emulation.
 * ============================================================================== */

`ifndef DMA_DRIVER_SV
`define DMA_DRIVER_SV

class dma_driver extends uvm_driver #(dma_item);
  virtual dma_if vif;

  `uvm_component_utils(dma_driver)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual dma_if)::get(this, "", "vif", vif) || vif == null) begin
      `uvm_fatal("NOVIF", {"Virtual interface vif must be set for ", get_full_name(), ".vif"});
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    if (vif != null) begin
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

    forever begin
      seq_item_port.get_next_item(req);

      if (req.is_dma_config) begin
        configure_dma_transfer(req.src_addr, req.dst_addr, req.transfer_len, req.ctrl_reg);
      end else if (req.is_write) begin
        axil_write(req.s_axil_awaddr, req.s_axil_wdata, req.s_axil_wstrb);
      end else begin
        axil_read(req.s_axil_araddr, req.s_axil_rdata);
      end

      seq_item_port.item_done();
    end
  endtask

  // Configure DMA Transfer registers
  task configure_dma_transfer(
    input [31:0] src,
    input [31:0] dst,
    input [15:0] len,
    input [31:0] ctrl
  );
    `uvm_info("DMA_DRV", $sformatf("Programming DMA: SRC=0x%08X, DST=0x%08X, LEN=%0d, CTRL=0x%08X",
              src, dst, len, ctrl), UVM_MEDIUM)

    // 1. Source Address (0x4000_4000)
    axil_write(32'h4000_4000, src, 4'hF);
    // 2. Destination Address (0x4000_4004)
    axil_write(32'h4000_4004, dst, 4'hF);
    // 3. Length (0x4000_4008)
    axil_write(32'h4000_4008, {16'h0, len}, 4'hF);
    // 4. Control (0x4000_400C): start (bit 0) | irq_en (bit 1)
    axil_write(32'h4000_400C, ctrl, 4'hF);
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

`endif // DMA_DRIVER_SV
