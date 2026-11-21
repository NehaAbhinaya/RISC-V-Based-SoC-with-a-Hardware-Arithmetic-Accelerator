`timescale 1ns / 1ps
module tb_top;
  import uvm_pkg::*;
  import soc_top_pkg::*;

  logic clk = 0;
  always #5 clk = ~clk;

  soc_top_if vif();
  assign vif.clk = clk;

  initial begin
    uvm_config_db#(virtual soc_top_if)::set(null, "*", "vif", vif);
    run_test("soc_top_test");
  end
endmodule
