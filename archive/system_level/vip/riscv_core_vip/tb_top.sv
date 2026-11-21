`timescale 1ns / 1ps
module tb_top;
  import uvm_pkg::*;
  import riscv_core_pkg::*;

  logic clk = 0;
  always #5 clk = ~clk;

  riscv_core_if vif();
  assign vif.clk = clk;

  initial begin
    uvm_config_db#(virtual riscv_core_if)::set(null, "*", "vif", vif);
    run_test("riscv_core_test");
  end
endmodule
