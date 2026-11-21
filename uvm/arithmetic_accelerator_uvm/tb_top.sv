`timescale 1ns / 1ps
module tb_top;
  import uvm_pkg::*;
  import arithmetic_accelerator_pkg::*;

  logic clk = 0;
  always #5 clk = ~clk;

  arithmetic_accelerator_if vif();
  assign vif.clk = clk;

  initial begin
    uvm_config_db#(virtual arithmetic_accelerator_if)::set(null, "*", "vif", vif);
    run_test("arithmetic_accelerator_test");
  end
endmodule
