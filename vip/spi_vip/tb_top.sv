/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : SPI VIP
 * File           : tb_top.sv
 * Description    : Standalone Testbench Top for SPI VIP verifying against soc_spi RTL.
 * ============================================================================== */

`timescale 1ns / 1ps

module tb_top;
  import uvm_pkg::*;
  import spi_pkg::*;

  logic clk = 0;
  always #5 clk = ~clk;

  logic rst_n = 0;
  initial begin
    #20 rst_n = 1;
  end

  spi_if vif();
  assign vif.clk   = clk;
  assign vif.rst_n = rst_n;

  // DUT: soc_spi
  soc_spi dut (
    .clk              (clk),
    .rst_n            (rst_n),
    .m07_axil_awaddr  (vif.s_axil_awaddr),
    .m07_axil_awprot  (vif.s_axil_awprot),
    .m07_axil_awvalid (vif.s_axil_awvalid),
    .m07_axil_awready (vif.s_axil_awready),
    .m07_axil_wdata   (vif.s_axil_wdata),
    .m07_axil_wstrb   (vif.s_axil_wstrb),
    .m07_axil_wvalid  (vif.s_axil_wvalid),
    .m07_axil_wready  (vif.s_axil_wready),
    .m07_axil_bresp   (vif.s_axil_bresp),
    .m07_axil_bvalid  (vif.s_axil_bvalid),
    .m07_axil_bready  (vif.s_axil_bready),
    .m07_axil_araddr  (vif.s_axil_araddr),
    .m07_axil_arprot  (vif.s_axil_arprot),
    .m07_axil_arvalid (vif.s_axil_arvalid),
    .m07_axil_arready (vif.s_axil_arready),
    .m07_axil_rdata   (vif.s_axil_rdata),
    .m07_axil_rresp   (vif.s_axil_rresp),
    .m07_axil_rvalid  (vif.s_axil_rvalid),
    .m07_axil_rready  (vif.s_axil_rready),
    .spi_sclk         (vif.spi_sclk),
    .spi_cs_n         (vif.spi_cs_n),
    .spi_mosi         (vif.spi_mosi),
    .spi_miso         (vif.spi_miso),
    .irq_spi          (vif.irq_spi)
  );

  initial begin
    uvm_config_db#(virtual spi_if)::set(null, "*", "vif", vif);
    run_test("spi_test");
  end

endmodule
