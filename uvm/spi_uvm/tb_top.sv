`timescale 1ns / 1ps
module tb_top;
  import uvm_pkg::*;
  import spi_pkg::*;

  logic clk = 0;
  always #5 clk = ~clk;

  spi_if vif();
  assign vif.clk = clk;

  initial begin
    uvm_config_db#(virtual spi_if)::set(null, "*", "vif", vif);
    run_test("spi_test");
  end
endmodule
