`timescale 1ns / 1ps
module tb_top;
  import uvm_pkg::*;
  import interconnect_pkg::*;

  logic clk = 0;
  always #5 clk = ~clk;

  interconnect_if vif();
  assign vif.clk = clk;

  initial begin
    uvm_config_db#(virtual interconnect_if)::set(null, "*", "vif", vif);
    run_test("interconnect_test");
  end
endmodule
