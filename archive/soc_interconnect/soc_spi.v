`timescale 1ns / 1ps

/* -----------------------------------------------------------------------------
 * Project        : RISC-V SoC with Hardware Arithmetic Accelerator
 * File           : soc_spi.v
 * Description    : Thin SoC Wrapper for AXI4-Lite SPI Slave Port (m07_axil_*)
 * ------------------------------------------------------------------------------*/

`default_nettype none

module soc_spi (
  input wire clk,
  input wire rst_n,

  // m07 AXI4-Lite Slave Port (from Fabric)
  input  wire [31:0] m07_axil_awaddr,
  input  wire [2:0]  m07_axil_awprot,
  input  wire        m07_axil_awvalid,
  output wire        m07_axil_awready,

  input  wire [31:0] m07_axil_wdata,
  input  wire [3:0]  m07_axil_wstrb,
  input  wire        m07_axil_wvalid,
  output wire        m07_axil_wready,

  output wire [1:0]  m07_axil_bresp,
  output wire        m07_axil_bvalid,
  input  wire        m07_axil_bready,

  input  wire [31:0] m07_axil_araddr,
  input  wire [2:0]  m07_axil_arprot,
  input  wire        m07_axil_arvalid,
  output wire        m07_axil_arready,

  output wire [31:0] m07_axil_rdata,
  output wire [1:0]  m07_axil_rresp,
  output wire        m07_axil_rvalid,
  input  wire        m07_axil_rready,

  // External SPI Interface Pins
  output wire        spi_sclk,
  output wire        spi_cs_n,
  output wire        spi_mosi,
  input  wire        spi_miso,

  // Interrupt Output to PIC
  output wire        irq_spi
);

  axi_spi_top u_axi_spi_top (
    .clk      (clk),
    .rst_n    (rst_n),
    .awaddr   (m07_axil_awaddr),
    .awprot   (m07_axil_awprot),
    .awvalid  (m07_axil_awvalid),
    .awready  (m07_axil_awready),
    .wdata    (m07_axil_wdata),
    .wstrb    (m07_axil_wstrb),
    .wvalid   (m07_axil_wvalid),
    .wready   (m07_axil_wready),
    .bresp    (m07_axil_bresp),
    .bvalid   (m07_axil_bvalid),
    .bready   (m07_axil_bready),
    .araddr   (m07_axil_araddr),
    .arprot   (m07_axil_arprot),
    .arvalid  (m07_axil_arvalid),
    .arready  (m07_axil_arready),
    .rdata    (m07_axil_rdata),
    .rresp    (m07_axil_rresp),
    .rvalid   (m07_axil_rvalid),
    .rready   (m07_axil_rready),
    .spi_sclk (spi_sclk),
    .spi_cs_n (spi_cs_n),
    .spi_mosi (spi_mosi),
    .spi_miso (spi_miso),
    .irq_spi  (irq_spi)
  );

endmodule

`default_nettype wire
