`timescale 1ns / 1ps
module tb_top;
  import uvm_pkg::*;
  import timer_pkg::*;

  logic clk = 0;
  always #5 clk = ~clk;

  timer_if vif();
  assign vif.clk = clk;

  initial begin
    uvm_config_db#(virtual timer_if)::set(null, "*", "vif", vif);
    run_test("timer_test");
  end
endmodule
