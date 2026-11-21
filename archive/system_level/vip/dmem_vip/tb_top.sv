`timescale 1ns / 1ps
module tb_top;
  import uvm_pkg::*;
  import dmem_pkg::*;

  logic clk = 0;
  always #5 clk = ~clk;

  dmem_if vif();
  assign vif.clk = clk;

  initial begin
    uvm_config_db#(virtual dmem_if)::set(null, "*", "vif", vif);
    run_test("dmem_test");
  end
endmodule
