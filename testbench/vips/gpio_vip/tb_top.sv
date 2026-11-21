/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : GPIO VIP
 * File           : tb_top.sv
 * Description    : Standalone Testbench Top for GPIO VIP verifying against soc_gpio RTL.
 * ============================================================================== */

`timescale 1ns / 1ps

module tb_top;
  import uvm_pkg::*;
  import gpio_pkg::*;

  logic clk = 0;
  always #5 clk = ~clk;

  logic rst_n = 0;
  initial begin
    #20 rst_n = 1;
  end

  gpio_if vif();
  assign vif.clk   = clk;
  assign vif.rst_n = rst_n;

  // DUT: soc_gpio (8-bit width)
  soc_gpio #(
    .N (8)
  ) dut (
    .clk      (clk),
    .rst_n    (rst_n),
    .awaddr   (vif.s_axil_awaddr),
    .awprot   (vif.s_axil_awprot),
    .awvalid  (vif.s_axil_awvalid),
    .awready  (vif.s_axil_awready),
    .wdata    (vif.s_axil_wdata),
    .wstrb    (vif.s_axil_wstrb),
    .wvalid   (vif.s_axil_wvalid),
    .wready   (vif.s_axil_wready),
    .bresp    (vif.s_axil_bresp),
    .bvalid   (vif.s_axil_bvalid),
    .bready   (vif.s_axil_bready),
    .araddr   (vif.s_axil_araddr),
    .arprot   (vif.s_axil_arprot),
    .arvalid  (vif.s_axil_arvalid),
    .arready  (vif.s_axil_arready),
    .rdata    (vif.s_axil_rdata),
    .rresp    (vif.s_axil_rresp),
    .rvalid   (vif.s_axil_rvalid),
    .rready   (vif.s_axil_rready),
    .gpio_in  (vif.gpio_in),
    .gpio_out (vif.gpio_out),
    .irq_gpio (vif.irq_gpio)
  );

  initial begin
    uvm_config_db#(virtual gpio_if)::set(null, "*", "vif", vif);
    run_test("gpio_test");
  end

endmodule
