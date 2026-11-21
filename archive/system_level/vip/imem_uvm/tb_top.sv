`timescale 1ns / 1ps
module tb_top;
  import uvm_pkg::*;
  import imem_pkg::*;

  logic clk = 0;
  always #5 clk = ~clk;

  imem_if vif();
  assign vif.clk = clk;

  initial begin
    uvm_config_db#(virtual imem_if)::set(null, "*", "vif", vif);
    run_test("imem_test");
  end
endmodule
