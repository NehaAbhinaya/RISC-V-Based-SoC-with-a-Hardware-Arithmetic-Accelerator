/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : SPI VIP
 * File           : spi_item.sv
 * Description    : Transaction item for SPI VIP supporting pin-level SPI frames
 *                  (SCLK, CS_N, MOSI, MISO) and AXI4-Lite register access.
 * ============================================================================== */

`ifndef SPI_ITEM_SV
`define SPI_ITEM_SV

class spi_item extends uvm_sequence_item;

  // Pin-level signals
  bit             spi_sclk;
  bit             spi_cs_n;
  bit             spi_mosi;
  rand bit        spi_miso;
  bit             irq_spi;

  // AXI4-Lite slave channel signals
  rand bit [31:0] s_axil_awaddr;
  rand bit [2:0]  s_axil_awprot;
  rand bit        s_axil_awvalid;
  bit             s_axil_awready;
  rand bit [31:0] s_axil_wdata;
  rand bit [3:0]  s_axil_wstrb;
  rand bit        s_axil_wvalid;
  bit             s_axil_wready;
  bit [1:0]       s_axil_bresp;
  bit             s_axil_bvalid;
  rand bit        s_axil_bready;
  rand bit [31:0] s_axil_araddr;
  rand bit [2:0]  s_axil_arprot;
  rand bit        s_axil_arvalid;
  bit             s_axil_arready;
  bit [31:0]      s_axil_rdata;
  bit [1:0]       s_axil_rresp;
  bit             s_axil_rvalid;
  rand bit        s_axil_rready;

  // Functional protocol fields
  rand bit [7:0]  tx_data;        // Data byte to send on MISO (slave mode)
  bit [7:0]       rx_data;        // Data byte sampled from MOSI
  rand bit        is_slave_resp;  // 1: act as SPI slave responding with tx_data
  rand bit        is_axil;        // 1: AXI4-Lite register transaction
  rand bit        is_write;       // 1: write, 0: read

  `uvm_object_utils_begin(spi_item)
    `uvm_field_int(spi_sclk,       UVM_ALL_ON)
    `uvm_field_int(spi_cs_n,       UVM_ALL_ON)
    `uvm_field_int(spi_mosi,       UVM_ALL_ON)
    `uvm_field_int(spi_miso,       UVM_ALL_ON)
    `uvm_field_int(irq_spi,        UVM_ALL_ON)
    `uvm_field_int(s_axil_awaddr,  UVM_ALL_ON)
    `uvm_field_int(s_axil_wdata,   UVM_ALL_ON)
    `uvm_field_int(s_axil_araddr,  UVM_ALL_ON)
    `uvm_field_int(s_axil_rdata,   UVM_ALL_ON)
    `uvm_field_int(tx_data,        UVM_ALL_ON)
    `uvm_field_int(rx_data,        UVM_ALL_ON)
    `uvm_field_int(is_slave_resp,  UVM_ALL_ON)
    `uvm_field_int(is_axil,        UVM_ALL_ON)
    `uvm_field_int(is_write,       UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="spi_item");
    super.new(name);
    tx_data       = 8'hA5;
    s_axil_wstrb  = 4'hF;
    s_axil_bready = 1'b1;
    s_axil_rready = 1'b1;
    is_slave_resp = 1'b0;
    is_axil       = 1'b0;
    is_write      = 1'b0;
  endfunction

endclass

`endif // SPI_ITEM_SV
