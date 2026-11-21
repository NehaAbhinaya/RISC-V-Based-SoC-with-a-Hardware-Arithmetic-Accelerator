`timescale 1ns / 1ps
module tb_top;
  import uvm_pkg::*;
  import uart_pkg::*;

  logic clk = 0;
  always #5 clk = ~clk;

  uart_if vif();
  assign vif.clk = clk;

  initial begin
    uvm_config_db#(virtual uart_if)::set(null, "*", "vif", vif);
    run_test("uart_test");
  end
endmodule
