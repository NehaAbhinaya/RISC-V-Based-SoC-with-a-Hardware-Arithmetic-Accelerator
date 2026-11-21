/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : UART VIP
 * File           : tb_top.sv
 * Description    : Standalone Testbench Top for UART VIP verifying against soc_uart RTL.
 * ============================================================================== */

`timescale 1ns / 1ps

module tb_top;
  import uvm_pkg::*;
  import uart_pkg::*;

  logic clk = 0;
  always #5 clk = ~clk;

  logic rst_n = 0;
  initial begin
    #20 rst_n = 1;
  end

  uart_if vif();
  assign vif.clk   = clk;
  assign vif.rst_n = rst_n;

  // DUT: soc_uart
  soc_uart dut (
    .clk              (clk),
    .rst_n            (rst_n),
    .m02_axil_awaddr  (vif.s_axil_awaddr),
    .m02_axil_awprot  (vif.s_axil_awprot),
    .m02_axil_awvalid (vif.s_axil_awvalid),
    .m02_axil_awready (vif.s_axil_awready),
    .m02_axil_wdata   (vif.s_axil_wdata),
    .m02_axil_wstrb   (vif.s_axil_wstrb),
    .m02_axil_wvalid  (vif.s_axil_wvalid),
    .m02_axil_wready  (vif.s_axil_wready),
    .m02_axil_bresp   (vif.s_axil_bresp),
    .m02_axil_bvalid  (vif.s_axil_bvalid),
    .m02_axil_bready  (vif.s_axil_bready),
    .m02_axil_araddr  (vif.s_axil_araddr),
    .m02_axil_arprot  (vif.s_axil_arprot),
    .m02_axil_arvalid (vif.s_axil_arvalid),
    .m02_axil_arready (vif.s_axil_arready),
    .m02_axil_rdata   (vif.s_axil_rdata),
    .m02_axil_rresp   (vif.s_axil_rresp),
    .m02_axil_rvalid  (vif.s_axil_rvalid),
    .m02_axil_rready  (vif.s_axil_rready),
    .uart_tx          (vif.uart_tx),
    .uart_rx          (vif.uart_rx),
    .irq_uart         (vif.irq_uart)
  );

  initial begin
    uvm_config_db#(virtual uart_if)::set(null, "*", "vif", vif);
    run_test("uart_test");
  end

endmodule
