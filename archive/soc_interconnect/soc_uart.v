`timescale 1ns / 1ps

/* -----------------------------------------------------------------------------
 * Project        : RISC-V SoC with Hardware Arithmetic Accelerator
 * File           : soc_uart.v
 * Description    : Thin SoC Wrapper for AXI4-Lite UART Slave Port (m02_axil_*)
 * ------------------------------------------------------------------------------*/

`default_nettype none

module soc_uart (
  input wire clk,
  input wire rst_n,

  // m02 AXI4-Lite Slave Port (from Fabric)
  input  wire [31:0] m02_axil_awaddr,
  input  wire [2:0]  m02_axil_awprot,
  input  wire        m02_axil_awvalid,
  output wire        m02_axil_awready,

  input  wire [31:0] m02_axil_wdata,
  input  wire [3:0]  m02_axil_wstrb,
  input  wire        m02_axil_wvalid,
  output wire        m02_axil_wready,

  output wire [1:0]  m02_axil_bresp,
  output wire        m02_axil_bvalid,
  input  wire        m02_axil_bready,

  input  wire [31:0] m02_axil_araddr,
  input  wire [2:0]  m02_axil_arprot,
  input  wire        m02_axil_arvalid,
  output wire        m02_axil_arready,

  output wire [31:0] m02_axil_rdata,
  output wire [1:0]  m02_axil_rresp,
  output wire        m02_axil_rvalid,
  input  wire        m02_axil_rready,

  // External UART Serial Pins
  output wire        uart_tx,
  input  wire        uart_rx,

  // Interrupt Output to PIC
  output wire        irq_uart
);

  axi_uart_top u_axi_uart_top (
    .clk      (clk),
    .rst_n    (rst_n),
    .awaddr   (m02_axil_awaddr),
    .awprot   (m02_axil_awprot),
    .awvalid  (m02_axil_awvalid),
    .awready  (m02_axil_awready),
    .wdata    (m02_axil_wdata),
    .wstrb    (m02_axil_wstrb),
    .wvalid   (m02_axil_wvalid),
    .wready   (m02_axil_wready),
    .bresp    (m02_axil_bresp),
    .bvalid   (m02_axil_bvalid),
    .bready   (m02_axil_bready),
    .araddr   (m02_axil_araddr),
    .arprot   (m02_axil_arprot),
    .arvalid  (m02_axil_arvalid),
    .arready  (m02_axil_arready),
    .rdata    (m02_axil_rdata),
    .rresp    (m02_axil_rresp),
    .rvalid   (m02_axil_rvalid),
    .rready   (m02_axil_rready),
    .uart_tx  (uart_tx),
    .uart_rx  (uart_rx),
    .irq_uart (irq_uart)
  );

endmodule

`default_nettype wire
