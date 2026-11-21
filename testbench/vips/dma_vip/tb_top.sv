/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : DMA VIP
 * File           : tb_top.sv
 * Description    : Standalone Testbench Top for DMA VIP verifying against dma_controller RTL.
 * ============================================================================== */

`timescale 1ns / 1ps

module tb_top;
  import uvm_pkg::*;
  import dma_pkg::*;

  logic clk = 0;
  always #5 clk = ~clk;

  logic rst_n = 0;
  initial begin
    #20 rst_n = 1;
  end

  dma_if vif();
  assign vif.clk   = clk;
  assign vif.rst_n = rst_n;

  // Emulated memory model responder for master port in standalone TB
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      vif.m_axil_awready <= 1'b0;
      vif.m_axil_wready  <= 1'b0;
      vif.m_axil_bvalid  <= 1'b0;
      vif.m_axil_bresp   <= 2'b00;
      vif.m_axil_arready <= 1'b0;
      vif.m_axil_rvalid  <= 1'b0;
      vif.m_axil_rresp   <= 2'b00;
      vif.m_axil_rdata   <= 32'd10;
      vif.dma_op_ready   <= 1'b1;
      vif.dma_res_valid  <= 1'b0;
      vif.dma_res_data   <= 32'd30;
    end else begin
      vif.m_axil_awready <= 1'b1;
      vif.m_axil_wready  <= 1'b1;
      vif.m_axil_arready <= 1'b1;
      vif.dma_op_ready   <= 1'b1;

      if (vif.m_axil_wvalid && vif.m_axil_wready)
        vif.m_axil_bvalid <= 1'b1;
      else if (vif.m_axil_bready)
        vif.m_axil_bvalid <= 1'b0;

      if (vif.m_axil_arvalid && vif.m_axil_arready)
        vif.m_axil_rvalid <= 1'b1;
      else if (vif.m_axil_rready)
        vif.m_axil_rvalid <= 1'b0;

      if (vif.dma_op_valid && vif.dma_op_ready)
        vif.dma_res_valid <= 1'b1;
      else if (vif.dma_res_ready)
        vif.dma_res_valid <= 1'b0;
    end
  end

  // DUT: dma_controller
  dma_controller dut (
    .clk            (clk),
    .rst_n          (rst_n),
    .awaddr         (vif.s_axil_awaddr),
    .awprot         (vif.s_axil_awprot),
    .awvalid        (vif.s_axil_awvalid),
    .awready        (vif.s_axil_awready),
    .wdata          (vif.s_axil_wdata),
    .wstrb          (vif.s_axil_wstrb),
    .wvalid         (vif.s_axil_wvalid),
    .wready         (vif.s_axil_wready),
    .bresp          (vif.s_axil_bresp),
    .bvalid         (vif.s_axil_bvalid),
    .bready         (vif.s_axil_bready),
    .araddr         (vif.s_axil_araddr),
    .arprot         (vif.s_axil_arprot),
    .arvalid        (vif.s_axil_arvalid),
    .arready        (vif.s_axil_arready),
    .rdata          (vif.s_axil_rdata),
    .rresp          (vif.s_axil_rresp),
    .rvalid         (vif.s_axil_rvalid),
    .rready         (vif.s_axil_rready),
    .m_awaddr       (vif.m_axil_awaddr),
    .m_awprot       (vif.m_axil_awprot),
    .m_awvalid      (vif.m_axil_awvalid),
    .m_awready      (vif.m_axil_awready),
    .m_wdata        (vif.m_axil_wdata),
    .m_wstrb        (vif.m_axil_wstrb),
    .m_wvalid       (vif.m_axil_wvalid),
    .m_wready       (vif.m_axil_wready),
    .m_bresp        (vif.m_axil_bresp),
    .m_bvalid       (vif.m_axil_bvalid),
    .m_bready       (vif.m_axil_bready),
    .m_araddr       (vif.m_axil_araddr),
    .m_arprot       (vif.m_axil_arprot),
    .m_arvalid      (vif.m_axil_arvalid),
    .m_arready      (vif.m_axil_arready),
    .m_rdata        (vif.m_axil_rdata),
    .m_rresp        (vif.m_axil_rresp),
    .m_rvalid       (vif.m_axil_rvalid),
    .m_rready       (vif.m_axil_rready),
    .dma_op_valid   (vif.dma_op_valid),
    .dma_op_data_a  (vif.dma_op_data_a),
    .dma_op_data_b  (vif.dma_op_data_b),
    .dma_op_ready   (vif.dma_op_ready),
    .dma_res_valid  (vif.dma_res_valid),
    .dma_res_data   (vif.dma_res_data),
    .dma_res_ready  (vif.dma_res_ready),
    .dma_last       (vif.dma_last),
    .irq_dma        (vif.irq_dma)
  );

  initial begin
    uvm_config_db#(virtual dma_if)::set(null, "*", "vif", vif);
    run_test("dma_test");
  end

endmodule
