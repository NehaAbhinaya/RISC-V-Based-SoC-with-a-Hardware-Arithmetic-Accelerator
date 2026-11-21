`timescale 1ns / 1ps
module tb_top;
  import uvm_pkg::*;
  import gpio_pkg::*;

  logic clk = 0;
  always #5 clk = ~clk;

  gpio_if vif();
  assign vif.clk = clk;

  initial begin
    uvm_config_db#(virtual gpio_if)::set(null, "*", "vif", vif);
    run_test("gpio_test");
  end
endmodule
