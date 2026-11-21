`timescale 1ns / 1ps

/* -------------------------------------------------------------------------------
 * Project        : RISC-V SoC with Hardware Arithmetic Accelerator
 * File           : soc_axil_fabric.v
 * Description    : Configured AXI4-Lite Interconnect Wrapper (3 Masters x 8 Slaves)
 *                  Matches the SoC Architecture & Memory Map in Section 3 & 5:
 *                  - Masters:
 *                      s00: IFU (Instruction Fetch Unit)
 *                      s01: LSU (Load / Store Unit)
 *                      s02: DMA Controller Master Port
 *                  - Slaves:
 *                      m00: Instruction Memory (0x0000_0000, 64 KB, IFU/LSU Read-Only)
 *                      m01: Data Memory        (0x1000_0000, 64 KB, LSU/DMA Read-Write)
 *                      m02: UART Controller    (0x4000_0000, 4 KB, LSU Read-Write)
 *                      m03: Timer Controller   (0x4000_1000, 4 KB, LSU Read-Write)
 *                      m04: GPIO Controller    (0x4000_2000, 4 KB, LSU Read-Write)
 *                      m05: Arithmetic Accel   (0x4000_3000, 4 KB, LSU Read-Write)
 *                      m06: DMA Registers      (0x4000_4000, 4 KB, LSU Read-Write)
 *                      m07: SPI Controller     (0x4000_5000, 4 KB, LSU Read-Write)
 * -------------------------------------------------------------------------------*/

`default_nettype none

module soc_axil_fabric (
  input wire clk,
  input wire rst, // Active-high synchronous reset

  // =========================================================================
  // Master Ports (sNN_axil_*)
  // =========================================================================

  // s00: IFU Bridge
  input  wire [31:0] s00_axil_awaddr,
  input  wire [2:0]  s00_axil_awprot,
  input  wire        s00_axil_awvalid,
  output wire        s00_axil_awready,
  input  wire [31:0] s00_axil_wdata,
  input  wire [3:0]  s00_axil_wstrb,
  input  wire        s00_axil_wvalid,
  output wire        s00_axil_wready,
  output wire [1:0]  s00_axil_bresp,
  output wire        s00_axil_bvalid,
  input  wire        s00_axil_bready,
  input  wire [31:0] s00_axil_araddr,
  input  wire [2:0]  s00_axil_arprot,
  input  wire        s00_axil_arvalid,
  output wire        s00_axil_arready,
  output wire [31:0] s00_axil_rdata,
  output wire [1:0]  s00_axil_rresp,
  output wire        s00_axil_rvalid,
  input  wire        s00_axil_rready,

  // s01: LSU Bridge
  input  wire [31:0] s01_axil_awaddr,
  input  wire [2:0]  s01_axil_awprot,
  input  wire        s01_axil_awvalid,
  output wire        s01_axil_awready,
  input  wire [31:0] s01_axil_wdata,
  input  wire [3:0]  s01_axil_wstrb,
  input  wire        s01_axil_wvalid,
  output wire        s01_axil_wready,
  output wire [1:0]  s01_axil_bresp,
  output wire        s01_axil_bvalid,
  input  wire        s01_axil_bready,
  input  wire [31:0] s01_axil_araddr,
  input  wire [2:0]  s01_axil_arprot,
  input  wire        s01_axil_arvalid,
  output wire        s01_axil_arready,
  output wire [31:0] s01_axil_rdata,
  output wire [1:0]  s01_axil_rresp,
  output wire        s01_axil_rvalid,
  input  wire        s01_axil_rready,

  // s02: DMA Controller
  input  wire [31:0] s02_axil_awaddr,
  input  wire [2:0]  s02_axil_awprot,
  input  wire        s02_axil_awvalid,
  output wire        s02_axil_awready,
  input  wire [31:0] s02_axil_wdata,
  input  wire [3:0]  s02_axil_wstrb,
  input  wire        s02_axil_wvalid,
  output wire        s02_axil_wready,
  output wire [1:0]  s02_axil_bresp,
  output wire        s02_axil_bvalid,
  input  wire        s02_axil_bready,
  input  wire [31:0] s02_axil_araddr,
  input  wire [2:0]  s02_axil_arprot,
  input  wire        s02_axil_arvalid,
  output wire        s02_axil_arready,
  output wire [31:0] s02_axil_rdata,
  output wire [1:0]  s02_axil_rresp,
  output wire        s02_axil_rvalid,
  input  wire        s02_axil_rready,

  // =========================================================================
  // Slave Ports (mNN_axil_*)
  // =========================================================================

  // m00: Instruction Memory
  output wire [31:0] m00_axil_awaddr,
  output wire [2:0]  m00_axil_awprot,
  output wire        m00_axil_awvalid,
  input  wire        m00_axil_awready,
  output wire [31:0] m00_axil_wdata,
  output wire [3:0]  m00_axil_wstrb,
  output wire        m00_axil_wvalid,
  input  wire        m00_axil_wready,
  input  wire [1:0]  m00_axil_bresp,
  input  wire        m00_axil_bvalid,
  output wire        m00_axil_bready,
  output wire [31:0] m00_axil_araddr,
  output wire [2:0]  m00_axil_arprot,
  output wire        m00_axil_arvalid,
  input  wire        m00_axil_arready,
  input  wire [31:0] m00_axil_rdata,
  input  wire [1:0]  m00_axil_rresp,
  input  wire        m00_axil_rvalid,
  output wire        m00_axil_rready,

  // m01: Data Memory
  output wire [31:0] m01_axil_awaddr,
  output wire [2:0]  m01_axil_awprot,
  output wire        m01_axil_awvalid,
  input  wire        m01_axil_awready,
  output wire [31:0] m01_axil_wdata,
  output wire [3:0]  m01_axil_wstrb,
  output wire        m01_axil_wvalid,
  input  wire        m01_axil_wready,
  input  wire [1:0]  m01_axil_bresp,
  input  wire        m01_axil_bvalid,
  output wire        m01_axil_bready,
  output wire [31:0] m01_axil_araddr,
  output wire [2:0]  m01_axil_arprot,
  output wire        m01_axil_arvalid,
  input  wire        m01_axil_arready,
  input  wire [31:0] m01_axil_rdata,
  input  wire [1:0]  m01_axil_rresp,
  input  wire        m01_axil_rvalid,
  output wire        m01_axil_rready,

  // m02: UART
  output wire [31:0] m02_axil_awaddr,
  output wire [2:0]  m02_axil_awprot,
  output wire        m02_axil_awvalid,
  input  wire        m02_axil_awready,
  output wire [31:0] m02_axil_wdata,
  output wire [3:0]  m02_axil_wstrb,
  output wire        m02_axil_wvalid,
  input  wire        m02_axil_wready,
  input  wire [1:0]  m02_axil_bresp,
  input  wire        m02_axil_bvalid,
  output wire        m02_axil_bready,
  output wire [31:0] m02_axil_araddr,
  output wire [2:0]  m02_axil_arprot,
  output wire        m02_axil_arvalid,
  input  wire        m02_axil_arready,
  input  wire [31:0] m02_axil_rdata,
  input  wire [1:0]  m02_axil_rresp,
  input  wire        m02_axil_rvalid,
  output wire        m02_axil_rready,

  // m03: Timer
  output wire [31:0] m03_axil_awaddr,
  output wire [2:0]  m03_axil_awprot,
  output wire        m03_axil_awvalid,
  input  wire        m03_axil_awready,
  output wire [31:0] m03_axil_wdata,
  output wire [3:0]  m03_axil_wstrb,
  output wire        m03_axil_wvalid,
  input  wire        m03_axil_wready,
  input  wire [1:0]  m03_axil_bresp,
  input  wire        m03_axil_bvalid,
  output wire        m03_axil_bready,
  output wire [31:0] m03_axil_araddr,
  output wire [2:0]  m03_axil_arprot,
  output wire        m03_axil_arvalid,
  input  wire        m03_axil_arready,
  input  wire [31:0] m03_axil_rdata,
  input  wire [1:0]  m03_axil_rresp,
  input  wire        m03_axil_rvalid,
  output wire        m03_axil_rready,

  // m04: GPIO
  output wire [31:0] m04_axil_awaddr,
  output wire [2:0]  m04_axil_awprot,
  output wire        m04_axil_awvalid,
  input  wire        m04_axil_awready,
  output wire [31:0] m04_axil_wdata,
  output wire [3:0]  m04_axil_wstrb,
  output wire        m04_axil_wvalid,
  input  wire        m04_axil_wready,
  input  wire [1:0]  m04_axil_bresp,
  input  wire        m04_axil_bvalid,
  output wire        m04_axil_bready,
  output wire [31:0] m04_axil_araddr,
  output wire [2:0]  m04_axil_arprot,
  output wire        m04_axil_arvalid,
  input  wire        m04_axil_arready,
  input  wire [31:0] m04_axil_rdata,
  input  wire [1:0]  m04_axil_rresp,
  input  wire        m04_axil_rvalid,
  output wire        m04_axil_rready,

  // m05: Arithmetic Accelerator
  output wire [31:0] m05_axil_awaddr,
  output wire [2:0]  m05_axil_awprot,
  output wire        m05_axil_awvalid,
  input  wire        m05_axil_awready,
  output wire [31:0] m05_axil_wdata,
  output wire [3:0]  m05_axil_wstrb,
  output wire        m05_axil_wvalid,
  input  wire        m05_axil_wready,
  input  wire [1:0]  m05_axil_bresp,
  input  wire        m05_axil_bvalid,
  output wire        m05_axil_bready,
  output wire [31:0] m05_axil_araddr,
  output wire [2:0]  m05_axil_arprot,
  output wire        m05_axil_arvalid,
  input  wire        m05_axil_arready,
  input  wire [31:0] m05_axil_rdata,
  input  wire [1:0]  m05_axil_rresp,
  input  wire        m05_axil_rvalid,
  output wire        m05_axil_rready,

  // m06: DMA Controller (Registers)
  output wire [31:0] m06_axil_awaddr,
  output wire [2:0]  m06_axil_awprot,
  output wire        m06_axil_awvalid,
  input  wire        m06_axil_awready,
  output wire [31:0] m06_axil_wdata,
  output wire [3:0]  m06_axil_wstrb,
  output wire        m06_axil_wvalid,
  input  wire        m06_axil_wready,
  input  wire [1:0]  m06_axil_bresp,
  input  wire        m06_axil_bvalid,
  output wire        m06_axil_bready,
  output wire [31:0] m06_axil_araddr,
  output wire [2:0]  m06_axil_arprot,
  output wire        m06_axil_arvalid,
  input  wire        m06_axil_arready,
  input  wire [31:0] m06_axil_rdata,
  input  wire [1:0]  m06_axil_rresp,
  input  wire        m06_axil_rvalid,
  output wire        m06_axil_rready,

  // m07: SPI Controller
  output wire [31:0] m07_axil_awaddr,
  output wire [2:0]  m07_axil_awprot,
  output wire        m07_axil_awvalid,
  input  wire        m07_axil_awready,
  output wire [31:0] m07_axil_wdata,
  output wire [3:0]  m07_axil_wstrb,
  output wire        m07_axil_wvalid,
  input  wire        m07_axil_wready,
  input  wire [1:0]  m07_axil_bresp,
  input  wire        m07_axil_bvalid,
  output wire        m07_axil_bready,
  output wire [31:0] m07_axil_araddr,
  output wire [2:0]  m07_axil_arprot,
  output wire        m07_axil_arvalid,
  input  wire        m07_axil_arready,
  input  wire [31:0] m07_axil_rdata,
  input  wire [1:0]  m07_axil_rresp,
  input  wire        m07_axil_rvalid,
  output wire        m07_axil_rready
);

  // Flattened bus packing
  wire [3*32-1:0] s_axil_awaddr = {s02_axil_awaddr, s01_axil_awaddr, s00_axil_awaddr};
  wire [3*3-1:0]  s_axil_awprot = {s02_axil_awprot, s01_axil_awprot, s00_axil_awprot};
  wire [3-1:0]    s_axil_awvalid = {s02_axil_awvalid, s01_axil_awvalid, s00_axil_awvalid};
  wire [3-1:0]    s_axil_awready;
  assign {s02_axil_awready, s01_axil_awready, s00_axil_awready} = s_axil_awready;

  wire [3*32-1:0] s_axil_wdata = {s02_axil_wdata, s01_axil_wdata, s00_axil_wdata};
  wire [3*4-1:0]  s_axil_wstrb = {s02_axil_wstrb, s01_axil_wstrb, s00_axil_wstrb};
  wire [3-1:0]    s_axil_wvalid = {s02_axil_wvalid, s01_axil_wvalid, s00_axil_wvalid};
  wire [3-1:0]    s_axil_wready;
  assign {s02_axil_wready, s01_axil_wready, s00_axil_wready} = s_axil_wready;

  wire [3*2-1:0]  s_axil_bresp;
  wire [3-1:0]    s_axil_bvalid;
  assign {s02_axil_bresp, s01_axil_bresp, s00_axil_bresp} = s_axil_bresp;
  assign {s02_axil_bvalid, s01_axil_bvalid, s00_axil_bvalid} = s_axil_bvalid;
  wire [3-1:0]    s_axil_bready = {s02_axil_bready, s01_axil_bready, s00_axil_bready};

  wire [3*32-1:0] s_axil_araddr = {s02_axil_araddr, s01_axil_araddr, s00_axil_araddr};
  wire [3*3-1:0]  s_axil_arprot = {s02_axil_arprot, s01_axil_arprot, s00_axil_arprot};
  wire [3-1:0]    s_axil_arvalid = {s02_axil_arvalid, s01_axil_arvalid, s00_axil_arvalid};
  wire [3-1:0]    s_axil_arready;
  assign {s02_axil_arready, s01_axil_arready, s00_axil_arready} = s_axil_arready;

  wire [3*32-1:0] s_axil_rdata;
  wire [3*2-1:0]  s_axil_rresp;
  wire [3-1:0]    s_axil_rvalid;
  assign {s02_axil_rdata, s01_axil_rdata, s00_axil_rdata} = s_axil_rdata;
  assign {s02_axil_rresp, s01_axil_rresp, s00_axil_rresp} = s_axil_rresp;
  assign {s02_axil_rvalid, s01_axil_rvalid, s00_axil_rvalid} = s_axil_rvalid;
  wire [3-1:0]    s_axil_rready = {s02_axil_rready, s01_axil_rready, s00_axil_rready};

  // Slaves packing
  wire [8*32-1:0] m_axil_awaddr;
  wire [8*3-1:0]  m_axil_awprot;
  wire [8-1:0]    m_axil_awvalid;
  assign {m07_axil_awaddr, m06_axil_awaddr, m05_axil_awaddr, m04_axil_awaddr, m03_axil_awaddr, m02_axil_awaddr, m01_axil_awaddr, m00_axil_awaddr} = m_axil_awaddr;
  assign {m07_axil_awprot, m06_axil_awprot, m05_axil_awprot, m04_axil_awprot, m03_axil_awprot, m02_axil_awprot, m01_axil_awprot, m00_axil_awprot} = m_axil_awprot;
  assign {m07_axil_awvalid, m06_axil_awvalid, m05_axil_awvalid, m04_axil_awvalid, m03_axil_awvalid, m02_axil_awvalid, m01_axil_awvalid, m00_axil_awvalid} = m_axil_awvalid;
  wire [8-1:0]    m_axil_awready = {m07_axil_awready, m06_axil_awready, m05_axil_awready, m04_axil_awready, m03_axil_awready, m02_axil_awready, m01_axil_awready, m00_axil_awready};

  wire [8*32-1:0] m_axil_wdata;
  wire [8*4-1:0]  m_axil_wstrb;
  wire [8-1:0]    m_axil_wvalid;
  assign {m07_axil_wdata, m06_axil_wdata, m05_axil_wdata, m04_axil_wdata, m03_axil_wdata, m02_axil_wdata, m01_axil_wdata, m00_axil_wdata} = m_axil_wdata;
  assign {m07_axil_wstrb, m06_axil_wstrb, m05_axil_wstrb, m04_axil_wstrb, m03_axil_wstrb, m02_axil_wstrb, m01_axil_wstrb, m00_axil_wstrb} = m_axil_wstrb;
  assign {m07_axil_wvalid, m06_axil_wvalid, m05_axil_wvalid, m04_axil_wvalid, m03_axil_wvalid, m02_axil_wvalid, m01_axil_wvalid, m00_axil_wvalid} = m_axil_wvalid;
  wire [8-1:0]    m_axil_wready = {m07_axil_wready, m06_axil_wready, m05_axil_wready, m04_axil_wready, m03_axil_wready, m02_axil_wready, m01_axil_wready, m00_axil_wready};

  wire [8*2-1:0]  m_axil_bresp = {m07_axil_bresp, m06_axil_bresp, m05_axil_bresp, m04_axil_bresp, m03_axil_bresp, m02_axil_bresp, m01_axil_bresp, m00_axil_bresp};
  wire [8-1:0]    m_axil_bvalid = {m07_axil_bvalid, m06_axil_bvalid, m05_axil_bvalid, m04_axil_bvalid, m03_axil_bvalid, m02_axil_bvalid, m01_axil_bvalid, m00_axil_bvalid};
  wire [8-1:0]    m_axil_bready;
  assign {m07_axil_bready, m06_axil_bready, m05_axil_bready, m04_axil_bready, m03_axil_bready, m02_axil_bready, m01_axil_bready, m00_axil_bready} = m_axil_bready;

  wire [8*32-1:0] m_axil_araddr;
  wire [8*3-1:0]  m_axil_arprot;
  wire [8-1:0]    m_axil_arvalid;
  assign {m07_axil_araddr, m06_axil_araddr, m05_axil_araddr, m04_axil_araddr, m03_axil_araddr, m02_axil_araddr, m01_axil_araddr, m00_axil_araddr} = m_axil_araddr;
  assign {m07_axil_arprot, m06_axil_arprot, m05_axil_arprot, m04_axil_arprot, m03_axil_arprot, m02_axil_arprot, m01_axil_arprot, m00_axil_arprot} = m_axil_arprot;
  assign {m07_axil_arvalid, m06_axil_arvalid, m05_axil_arvalid, m04_axil_arvalid, m03_axil_arvalid, m02_axil_arvalid, m01_axil_arvalid, m00_axil_arvalid} = m_axil_arvalid;
  wire [8-1:0]    m_axil_arready = {m07_axil_arready, m06_axil_arready, m05_axil_arready, m04_axil_arready, m03_axil_arready, m02_axil_arready, m01_axil_arready, m00_axil_arready};

  wire [8*32-1:0] m_axil_rdata = {m07_axil_rdata, m06_axil_rdata, m05_axil_rdata, m04_axil_rdata, m03_axil_rdata, m02_axil_rdata, m01_axil_rdata, m00_axil_rdata};
  wire [8*2-1:0]  m_axil_rresp = {m07_axil_rresp, m06_axil_rresp, m05_axil_rresp, m04_axil_rresp, m03_axil_rresp, m02_axil_rresp, m01_axil_rresp, m00_axil_rresp};
  wire [8-1:0]    m_axil_rvalid = {m07_axil_rvalid, m06_axil_rvalid, m05_axil_rvalid, m04_axil_rvalid, m03_axil_rvalid, m02_axil_rvalid, m01_axil_rvalid, m00_axil_rvalid};
  wire [8-1:0]    m_axil_rready;
  assign {m07_axil_rready, m06_axil_rready, m05_axil_rready, m04_axil_rready, m03_axil_rready, m02_axil_rready, m01_axil_rready, m00_axil_rready} = m_axil_rready;

  // Base Addresses:
  // m00: 0x0000_0000, 64KB (mask: 32'hFFFF_0000)
  // m01: 0x1000_0000, 64KB (mask: 32'hFFFF_0000)
  // m02: 0x4000_0000, 4KB  (mask: 32'hFFFF_F000)
  // m03: 0x4000_1000, 4KB  (mask: 32'hFFFF_F000)
  // m04: 0x4000_2000, 4KB  (mask: 32'hFFFF_F000)
  // m05: 0x4000_3000, 4KB  (mask: 32'hFFFF_F000)
  // m06: 0x4000_4000, 4KB  (mask: 32'hFFFF_F000)
  // m07: 0x4000_5000, 4KB  (mask: 32'hFFFF_F000)
  wire [8*32-1:0] m_base_addr = {
    32'h4000_5000, // m07 SPI
    32'h4000_4000, // m06 DMA
    32'h4000_3000, // m05 ACC
    32'h4000_2000, // m04 GPIO
    32'h4000_1000, // m03 Timer
    32'h4000_0000, // m02 UART
    32'h1000_0000, // m01 DMEM
    32'h0000_0000  // m00 IMEM
  };

  wire [8*32-1:0] m_addr_mask = {
    32'hFFFF_F000, // m07
    32'hFFFF_F000, // m06
    32'hFFFF_F000, // m05
    32'hFFFF_F000, // m04
    32'hFFFF_F000, // m03
    32'hFFFF_F000, // m02
    32'hFFFF_0000, // m01
    32'hFFFF_0000  // m00
  };

  // Permission Matrices (Section 3 & 5, Page 5)
  // bit 0 = s00 (IFU), bit 1 = s01 (LSU), bit 2 = s02 (DMA)
  // m00 IMEM: R: s00, s01 (3'b011); W: none (3'b000)
  // m01 DMEM: R: s01, s02 (3'b110); W: s01, s02 (3'b110)
  // m02 UART: R: s01 (3'b010); W: s01 (3'b010)
  // m03 Timer: R: s01 (3'b010); W: s01 (3'b010)
  // m04 GPIO: R: s01 (3'b010); W: s01 (3'b010)
  // m05 ACC:  R: s01 (3'b010); W: s01 (3'b010)
  // m06 DMA:  R: s01 (3'b010); W: s01 (3'b010)
  // m07 SPI:  R: s01 (3'b010); W: s01 (3'b010)
  wire [8*3-1:0] m_connect_read = {
    3'b010, // m07
    3'b010, // m06
    3'b010, // m05
    3'b010, // m04
    3'b010, // m03
    3'b010, // m02
    3'b110, // m01
    3'b011  // m00
  };

  wire [8*3-1:0] m_connect_write = {
    3'b010, // m07
    3'b010, // m06
    3'b010, // m05
    3'b010, // m04
    3'b010, // m03
    3'b010, // m02
    3'b110, // m01
    3'b000  // m00 (writes return DECERR)
  };

  axil_interconnect #(
    .S_COUNT    (3),
    .M_COUNT    (8),
    .DATA_WIDTH (32),
    .ADDR_WIDTH (32)
  ) u_axil_interconnect (
    .clk             (clk),
    .rst             (rst),
    .s_axil_awaddr   (s_axil_awaddr),
    .s_axil_awprot   (s_axil_awprot),
    .s_axil_awvalid  (s_axil_awvalid),
    .s_axil_awready  (s_axil_awready),
    .s_axil_wdata    (s_axil_wdata),
    .s_axil_wstrb    (s_axil_wstrb),
    .s_axil_wvalid   (s_axil_wvalid),
    .s_axil_wready   (s_axil_wready),
    .s_axil_bresp    (s_axil_bresp),
    .s_axil_bvalid   (s_axil_bvalid),
    .s_axil_bready   (s_axil_bready),
    .s_axil_araddr   (s_axil_araddr),
    .s_axil_arprot   (s_axil_arprot),
    .s_axil_arvalid  (s_axil_arvalid),
    .s_axil_arready  (s_axil_arready),
    .s_axil_rdata    (s_axil_rdata),
    .s_axil_rresp    (s_axil_rresp),
    .s_axil_rvalid   (s_axil_rvalid),
    .s_axil_rready   (s_axil_rready),
    .m_axil_awaddr   (m_axil_awaddr),
    .m_axil_awprot   (m_axil_awprot),
    .m_axil_awvalid  (m_axil_awvalid),
    .m_axil_awready  (m_axil_awready),
    .m_axil_wdata    (m_axil_wdata),
    .m_axil_wstrb    (m_axil_wstrb),
    .m_axil_wvalid   (m_axil_wvalid),
    .m_axil_wready   (m_axil_wready),
    .m_axil_bresp    (m_axil_bresp),
    .m_axil_bvalid   (m_axil_bvalid),
    .m_axil_bready   (m_axil_bready),
    .m_axil_araddr   (m_axil_araddr),
    .m_axil_arprot   (m_axil_arprot),
    .m_axil_arvalid  (m_axil_arvalid),
    .m_axil_arready  (m_axil_arready),
    .m_axil_rdata    (m_axil_rdata),
    .m_axil_rresp    (m_axil_rresp),
    .m_axil_rvalid   (m_axil_rvalid),
    .m_axil_rready   (m_axil_rready),
    .m_base_addr     (m_base_addr),
    .m_addr_mask     (m_addr_mask),
    .m_connect_read  (m_connect_read),
    .m_connect_write (m_connect_write)
  );

endmodule

`default_nettype wire
