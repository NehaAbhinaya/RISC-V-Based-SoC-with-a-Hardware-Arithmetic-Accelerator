`timescale 1ns / 1ps

/* -------------------------------------------------------------------------------
 * Project        : RISC-V SoC with Hardware Arithmetic Accelerator
 * File           : riscv_core_top.sv
 * Description    : RISC-V VeeR EL2 Subsystem with Integrated AHB-Lite to AXI4-Lite
 *                  Bridges (Sections 1 & 2, Pages 7-9)
 *                  - VeeR EL2 RISC-V Processor Core (RV32IMC)
 *                  - AHB-Lite to AXI4-Lite Instruction Fetch Bridge (Master s00)
 *                  - AHB-Lite to AXI4-Lite Load/Store Unit Bridge (Master s01)
 *                  - 6 Peripheral Interrupts routed to VeeR PIC (Section 12)
 *                  - Optional External Host/Debug Bus Multiplexer for LSU
 * -------------------------------------------------------------------------------*/

`default_nettype none

import el2_pkg::*;

module riscv_core_top #(
`include "el2_param.vh"
)(
  input  wire        clk,
  input  wire        rst_n,

  // External Interrupt Sources from SoC Peripherals (PIC lines 1-6)
  input  wire        irq_acc,   // Source 1: Accelerator
  input  wire        irq_dma,   // Source 2: DMA Controller
  input  wire        irq_spi,   // Source 3: SPI Controller
  input  wire        irq_uart,  // Source 4: UART Controller
  input  wire        irq_timer, // Source 5: Timer Controller
  input  wire        irq_gpio,  // Source 6: GPIO Controller

  // =========================================================================
  // Master Port s00: CPU Instruction Fetch Unit (IFU - Read-Only)
  // =========================================================================
  output wire [31:0] ifu_axil_araddr,
  output wire [2:0]  ifu_axil_arprot,
  output wire        ifu_axil_arvalid,
  input  wire        ifu_axil_arready,
  input  wire [31:0] ifu_axil_rdata,
  input  wire [1:0]  ifu_axil_rresp,
  input  wire        ifu_axil_rvalid,
  output wire        ifu_axil_rready,

  // =========================================================================
  // Master Port s01: CPU Load/Store Unit (LSU - Read/Write)
  // =========================================================================
  output wire [31:0] lsu_axil_awaddr,
  output wire [2:0]  lsu_axil_awprot,
  output wire        lsu_axil_awvalid,
  input  wire        lsu_axil_awready,
  output wire [31:0] lsu_axil_wdata,
  output wire [3:0]  lsu_axil_wstrb,
  output wire        lsu_axil_wvalid,
  input  wire        lsu_axil_wready,
  input  wire [1:0]  lsu_axil_bresp,
  input  wire        lsu_axil_bvalid,
  output wire        lsu_axil_bready,

  output wire [31:0] lsu_axil_araddr,
  output wire [2:0]  lsu_axil_arprot,
  output wire        lsu_axil_arvalid,
  input  wire        lsu_axil_arready,
  input  wire [31:0] lsu_axil_rdata,
  input  wire [1:0]  lsu_axil_rresp,
  input  wire        lsu_axil_rvalid,
  output wire        lsu_axil_rready,

  // =========================================================================
  // Optional Testbench Host / Direct Bus Injection Interface
  // =========================================================================
  input  wire        ext_host_en,

  input  wire [31:0] ext_lsu_awaddr,
  input  wire [2:0]  ext_lsu_awprot,
  input  wire        ext_lsu_awvalid,
  output wire        ext_lsu_awready,
  input  wire [31:0] ext_lsu_wdata,
  input  wire [3:0]  ext_lsu_wstrb,
  input  wire        ext_lsu_wvalid,
  output wire        ext_lsu_wready,
  output wire [1:0]  ext_lsu_bresp,
  output wire        ext_lsu_bvalid,
  input  wire        ext_lsu_bready,

  input  wire [31:0] ext_lsu_araddr,
  input  wire [2:0]  ext_lsu_arprot,
  input  wire        ext_lsu_arvalid,
  output wire        ext_lsu_arready,
  output wire [31:0] ext_lsu_rdata,
  output wire [1:0]  ext_lsu_rresp,
  output wire        ext_lsu_rvalid,
  input  wire        ext_lsu_rready,

  // Core instruction trace outputs
  output wire [31:0] rv_trace_insn,
  output wire [31:0] rv_trace_address,
  output wire        rv_trace_valid
);

  // SystemVerilog Interfaces for VeeR EL2 Memory Export
  el2_mem_if el2_icache_export ();
  el2_mem_if el2_mem_export ();

  // PIC External Interrupt Vector
  wire [pt.PIC_TOTAL_INT:1] extintsrc_req;
  assign extintsrc_req[1] = irq_acc;
  assign extintsrc_req[2] = irq_dma;
  assign extintsrc_req[3] = irq_spi;
  assign extintsrc_req[4] = irq_uart;
  assign extintsrc_req[5] = irq_timer;
  assign extintsrc_req[6] = irq_gpio;
  generate
    if (pt.PIC_TOTAL_INT > 6) begin : gen_pic_tieoff
      assign extintsrc_req[pt.PIC_TOTAL_INT:7] = '0;
    end
  endgenerate

  // AHB-Lite Core Bus Signals
  wire [31:0] ifu_haddr;
  wire [2:0]  ifu_hburst;
  wire        ifu_hmastlock;
  wire [3:0]  ifu_hprot;
  wire [2:0]  ifu_hsize;
  wire [1:0]  ifu_htrans;
  wire        ifu_hwrite;
  wire [63:0] ifu_hrdata;
  wire        ifu_hready;
  wire        ifu_hresp;

  wire [31:0] lsu_haddr;
  wire [2:0]  lsu_hburst;
  wire        lsu_hmastlock;
  wire [3:0]  lsu_hprot;
  wire [2:0]  lsu_hsize;
  wire [1:0]  lsu_htrans;
  wire        lsu_hwrite;
  wire [63:0] lsu_hwdata;
  wire [63:0] lsu_hrdata;
  wire        lsu_hready;
  wire        lsu_hresp;

  // Debug system bus signals (tied off)
  wire [31:0] sb_haddr;
  wire [2:0]  sb_hburst;
  wire        sb_hmastlock;
  wire [3:0]  sb_hprot;
  wire [2:0]  sb_hsize;
  wire [1:0]  sb_htrans;
  wire        sb_hwrite;
  wire [63:0] sb_hwdata;
  wire [63:0] sb_hrdata = 64'h0;
  wire        sb_hready = 1'b1;
  wire        sb_hresp  = 1'b0;

  // Unused IFU write AXI ports
  wire [31:0] core_ifu_axil_awaddr;
  wire [2:0]  core_ifu_axil_awprot;
  wire        core_ifu_axil_awvalid;
  wire        core_ifu_axil_awready = 1'b0;
  wire [31:0] core_ifu_axil_wdata;
  wire [3:0]  core_ifu_axil_wstrb;
  wire        core_ifu_axil_wvalid;
  wire        core_ifu_axil_wready = 1'b0;
  wire [1:0]  core_ifu_axil_bresp = 2'b00;
  wire        core_ifu_axil_bvalid = 1'b0;
  wire        core_ifu_axil_bready;

  // Core LSU AXI signals (from bridge)
  wire [31:0] core_lsu_axil_awaddr;
  wire [2:0]  core_lsu_axil_awprot;
  wire        core_lsu_axil_awvalid;
  wire        core_lsu_axil_awready;
  wire [31:0] core_lsu_axil_wdata;
  wire [3:0]  core_lsu_axil_wstrb;
  wire        core_lsu_axil_wvalid;
  wire        core_lsu_axil_wready;
  wire [1:0]  core_lsu_axil_bresp;
  wire        core_lsu_axil_bvalid;
  wire        core_lsu_axil_bready;

  wire [31:0] core_lsu_axil_araddr;
  wire [2:0]  core_lsu_axil_arprot;
  wire        core_lsu_axil_arvalid;
  wire        core_lsu_axil_arready;
  wire [31:0] core_lsu_axil_rdata;
  wire [1:0]  core_lsu_axil_rresp;
  wire        core_lsu_axil_rvalid;
  wire        core_lsu_axil_rready;

  // Multiplex between internal Core LSU and External Host
  assign lsu_axil_awaddr  = ext_host_en ? ext_lsu_awaddr  : core_lsu_axil_awaddr;
  assign lsu_axil_awprot  = ext_host_en ? ext_lsu_awprot  : core_lsu_axil_awprot;
  assign lsu_axil_awvalid = ext_host_en ? ext_lsu_awvalid : core_lsu_axil_awvalid;
  assign core_lsu_axil_awready = ext_host_en ? 1'b0 : lsu_axil_awready;
  assign ext_lsu_awready       = ext_host_en ? lsu_axil_awready : 1'b0;

  assign lsu_axil_wdata   = ext_host_en ? ext_lsu_wdata   : core_lsu_axil_wdata;
  assign lsu_axil_wstrb   = ext_host_en ? ext_lsu_wstrb   : core_lsu_axil_wstrb;
  assign lsu_axil_wvalid  = ext_host_en ? ext_lsu_wvalid  : core_lsu_axil_wvalid;
  assign core_lsu_axil_wready  = ext_host_en ? 1'b0 : lsu_axil_wready;
  assign ext_lsu_wready        = ext_host_en ? lsu_axil_wready : 1'b0;

  assign ext_lsu_bresp         = ext_host_en ? lsu_axil_bresp  : 2'b00;
  assign ext_lsu_bvalid        = ext_host_en ? lsu_axil_bvalid : 1'b0;
  assign core_lsu_axil_bresp   = ext_host_en ? 2'b00 : lsu_axil_bresp;
  assign core_lsu_axil_bvalid  = ext_host_en ? 1'b0  : lsu_axil_bvalid;
  assign lsu_axil_bready  = ext_host_en ? ext_lsu_bready  : core_lsu_axil_bready;

  assign lsu_axil_araddr  = ext_host_en ? ext_lsu_araddr  : core_lsu_axil_araddr;
  assign lsu_axil_arprot  = ext_host_en ? ext_lsu_arprot  : core_lsu_axil_arprot;
  assign lsu_axil_arvalid = ext_host_en ? ext_lsu_arvalid : core_lsu_axil_arvalid;
  assign core_lsu_axil_arready = ext_host_en ? 1'b0 : lsu_axil_arready;
  assign ext_lsu_arready       = ext_host_en ? lsu_axil_arready : 1'b0;

  assign ext_lsu_rdata         = ext_host_en ? lsu_axil_rdata  : 32'h0;
  assign ext_lsu_rresp         = ext_host_en ? lsu_axil_rresp  : 2'b00;
  assign ext_lsu_rvalid        = ext_host_en ? lsu_axil_rvalid : 1'b0;
  assign core_lsu_axil_rdata   = ext_host_en ? 32'h0 : lsu_axil_rdata;
  assign core_lsu_axil_rresp   = ext_host_en ? 2'b00 : lsu_axil_rresp;
  assign core_lsu_axil_rvalid  = ext_host_en ? 1'b0  : lsu_axil_rvalid;
  assign lsu_axil_rready  = ext_host_en ? ext_lsu_rready  : core_lsu_axil_rready;

  // =========================================================================
  // VeeR EL2 AXI4 buses (only present when RV_BUILD_AXI4 is defined)
  // This project uses AHB mode — AXI4 ports do NOT exist here.
  // =========================================================================

  // DMA AHB Slave (not used - tie off)
  wire [31:0] dma_haddr_t   = 32'h0; wire [2:0] dma_hburst_t  = 3'b0;
  wire        dma_hmastlock_t = 1'b0; wire [3:0] dma_hprot_t   = 4'h3;
  wire [2:0]  dma_hsize_t   = 3'b0;  wire [1:0] dma_htrans_t  = 2'b0;
  wire        dma_hwrite_t  = 1'b0;  wire [63:0] dma_hwdata_t  = 64'h0;
  wire        dma_hsel_t    = 1'b0;  wire        dma_hreadyin_t = 1'b1;
  wire [63:0] dma_hrdata_nc; wire dma_hreadyout_nc; wire dma_hresp_nc;

  // ECC / lockstep / DMI / perf counter tieoffs
  wire        iccm_ecc_single_error_nc, iccm_ecc_double_error_nc;
  wire        dccm_ecc_single_error_nc, dccm_ecc_double_error_nc;
  wire        dccm_write_readback_error_nc;
  wire        dec_tlu_perfcnt0_nc, dec_tlu_perfcnt1_nc;
  wire        dec_tlu_perfcnt2_nc, dec_tlu_perfcnt3_nc;
  // Shadow core (lockstep) outputs
  wire [31:0] shadow_insn_nc, shadow_addr_nc;
  wire        shadow_valid_nc, shadow_exc_nc, shadow_int_nc;
  wire [4:0]  shadow_ecause_nc;
  wire [31:0] shadow_tval_nc;
  // Lockstep control
  el2_mubi_pkg::el2_mubi_t disable_corruption_t = el2_mubi_pkg::El2MuBiFalse;
  el2_mubi_pkg::el2_mubi_t lockstep_err_inject_t = el2_mubi_pkg::El2MuBiFalse;
  el2_mubi_pkg::el2_mubi_t corruption_detected_nc;
  // DMI
  wire        dmi_core_enable_t   = 1'b0;
  wire        dmi_uncore_enable_t = 1'b0;
  wire        dmi_uncore_en_nc, dmi_uncore_wr_en_nc, dmi_active_nc;
  wire [6:0]  dmi_uncore_addr_nc;
  wire [31:0] dmi_uncore_wdata_nc;
  wire [31:0] dmi_uncore_rdata_t = 32'h0;

  // Instantiate VeeR EL2 Core
  el2_veer_wrapper rvtop (
    .clk                           (clk),
    .rst_l                         (rst_n),
    .dbg_rst_l                     (rst_n),
    .rst_vec                       (31'h0000_0000), // Boot address 0x0000_0000 (IMEM)
    .nmi_int                       (1'b0),
    .nmi_vec                       (31'h0000_0000),
    .jtag_id                       (31'h0),

    .trace_rv_i_insn_ip            (rv_trace_insn),
    .trace_rv_i_address_ip         (rv_trace_address),
    .trace_rv_i_valid_ip           (rv_trace_valid),
    .trace_rv_i_exception_ip       (),
    .trace_rv_i_ecause_ip          (),
    .trace_rv_i_interrupt_ip       (),
    .trace_rv_i_tval_ip            (),

    // AHB-Lite Instruction Fetch Master
    .haddr                         (ifu_haddr),
    .hburst                        (ifu_hburst),
    .hmastlock                     (ifu_hmastlock),
    .hprot                         (ifu_hprot),
    .hsize                         (ifu_hsize),
    .htrans                        (ifu_htrans),
    .hwrite                        (ifu_hwrite),
    .hrdata                        (ifu_hrdata),
    .hready                        (ifu_hready),
    .hresp                         (ifu_hresp),

    // AHB-Lite LSU Master
    .lsu_haddr                     (lsu_haddr),
    .lsu_hburst                    (lsu_hburst),
    .lsu_hmastlock                 (lsu_hmastlock),
    .lsu_hprot                     (lsu_hprot),
    .lsu_hsize                     (lsu_hsize),
    .lsu_htrans                    (lsu_htrans),
    .lsu_hwrite                    (lsu_hwrite),
    .lsu_hwdata                    (lsu_hwdata),
    .lsu_hrdata                    (lsu_hrdata),
    .lsu_hready                    (lsu_hready),
    .lsu_hresp                     (lsu_hresp),

    // AHB-Lite Debug Master (tied off)
    .sb_haddr                      (sb_haddr),
    .sb_hburst                     (sb_hburst),
    .sb_hmastlock                  (sb_hmastlock),
    .sb_hprot                      (sb_hprot),
    .sb_hsize                      (sb_hsize),
    .sb_htrans                     (sb_htrans),
    .sb_hwrite                     (sb_hwrite),
    .sb_hwdata                     (sb_hwdata),
    .sb_hrdata                     (sb_hrdata),
    .sb_hready                     (sb_hready),
    .sb_hresp                      (sb_hresp),

    // DMA AHB Slave (tied off - not used)
    .dma_hsel                      (dma_hsel_t),
    .dma_haddr                     (dma_haddr_t),
    .dma_hburst                    (dma_hburst_t),
    .dma_hmastlock                 (dma_hmastlock_t),
    .dma_hprot                     (dma_hprot_t),
    .dma_hsize                     (dma_hsize_t),
    .dma_htrans                    (dma_htrans_t),
    .dma_hwrite                    (dma_hwrite_t),
    .dma_hwdata                    (dma_hwdata_t),
    .dma_hreadyin                  (dma_hreadyin_t),
    .dma_hrdata                    (dma_hrdata_nc),
    .dma_hreadyout                 (dma_hreadyout_nc),
    .dma_hresp                     (dma_hresp_nc),

    .lsu_bus_clk_en                (1'b1),
    .ifu_bus_clk_en                (1'b1),
    .dbg_bus_clk_en                (1'b1),
    .dma_bus_clk_en                (1'b1),

    // ECC outputs (not exposed to top)
    .iccm_ecc_single_error         (iccm_ecc_single_error_nc),
    .iccm_ecc_double_error         (iccm_ecc_double_error_nc),
    .dccm_ecc_single_error         (dccm_ecc_single_error_nc),
    .dccm_ecc_double_error         (dccm_ecc_double_error_nc),
    .dccm_write_readback_error     (dccm_write_readback_error_nc),

    .timer_int                     (1'b0),
    .soft_int                      (1'b0),
    .extintsrc_req                 (extintsrc_req),

    // Performance counters
    .dec_tlu_perfcnt0              (dec_tlu_perfcnt0_nc),
    .dec_tlu_perfcnt1              (dec_tlu_perfcnt1_nc),
    .dec_tlu_perfcnt2              (dec_tlu_perfcnt2_nc),
    .dec_tlu_perfcnt3              (dec_tlu_perfcnt3_nc),

    .el2_icache_export             (el2_icache_export),
    .el2_mem_export                (el2_mem_export),

    .jtag_tck                      (1'b0),
    .jtag_tms                      (1'b0),
    .jtag_tdi                      (1'b0),
    .jtag_trst_n                   (1'b1),
    .jtag_tdo                      (),
    .jtag_tdoEn                    (),

    .core_id                       (28'h0),

    // Shadow / lockstep ports: only present when RV_LOCKSTEP_ENABLE is defined
    // Not enabled in the default_ahb snapshot - these ports are absent

    // DMI ports (tied off)
    .dmi_core_enable               (dmi_core_enable_t),
    .dmi_uncore_enable             (dmi_uncore_enable_t),
    .dmi_uncore_en                 (dmi_uncore_en_nc),
    .dmi_uncore_wr_en              (dmi_uncore_wr_en_nc),
    .dmi_uncore_addr               (dmi_uncore_addr_nc),
    .dmi_uncore_wdata              (dmi_uncore_wdata_nc),
    .dmi_uncore_rdata              (dmi_uncore_rdata_t),
    .dmi_active                    (dmi_active_nc),

    .mpc_debug_halt_req            (1'b0),
    .mpc_debug_run_req             (1'b1),
    .mpc_reset_run_req             (1'b1),
    .mpc_debug_halt_ack            (),
    .mpc_debug_run_ack             (),
    .debug_brkpt_status            (),
    .i_cpu_halt_req                (1'b0),
    .i_cpu_run_req                 (1'b1),
    .o_cpu_halt_ack                (),
    .o_cpu_halt_status             (),
    .o_cpu_run_ack                 (),
    .o_debug_mode_status           (),
    .scan_mode                     (1'b0),
    .mbist_mode                    (1'b0)
  );

  // Instruction Fetch AHB-to-AXI Bridge (Read-Only)
  ahblite_to_axilite_bridge #(
    .IS_FETCH (1)
  ) u_ifu_bridge (
    .clk          (clk),
    .rst_n        (rst_n),
    .haddr        (ifu_haddr),
    .htrans       (ifu_htrans),
    .hsize        (ifu_hsize),
    .hprot        (ifu_hprot),
    .hwrite       (ifu_hwrite),
    .hwdata       (64'h0),
    .hrdata       (ifu_hrdata),
    .hready       (ifu_hready),
    .hresp        (ifu_hresp),
    .axil_awaddr  (core_ifu_axil_awaddr),
    .axil_awprot  (core_ifu_axil_awprot),
    .axil_awvalid (core_ifu_axil_awvalid),
    .axil_awready (core_ifu_axil_awready),
    .axil_wdata   (core_ifu_axil_wdata),
    .axil_wstrb   (core_ifu_axil_wstrb),
    .axil_wvalid  (core_ifu_axil_wvalid),
    .axil_wready  (core_ifu_axil_wready),
    .axil_bresp   (core_ifu_axil_bresp),
    .axil_bvalid  (core_ifu_axil_bvalid),
    .axil_bready  (core_ifu_axil_bready),
    .axil_araddr  (ifu_axil_araddr),
    .axil_arprot  (ifu_axil_arprot),
    .axil_arvalid (ifu_axil_arvalid),
    .axil_arready (ifu_axil_arready),
    .axil_rdata   (ifu_axil_rdata),
    .axil_rresp   (ifu_axil_rresp),
    .axil_rvalid  (ifu_axil_rvalid),
    .axil_rready  (ifu_axil_rready)
  );

  // Load/Store AHB-to-AXI Bridge (Read/Write)
  ahblite_to_axilite_bridge #(
    .IS_FETCH (0)
  ) u_lsu_bridge (
    .clk          (clk),
    .rst_n        (rst_n),
    .haddr        (lsu_haddr),
    .htrans       (lsu_htrans),
    .hsize        (lsu_hsize),
    .hprot        (lsu_hprot),
    .hwrite       (lsu_hwrite),
    .hwdata       (lsu_hwdata),
    .hrdata       (lsu_hrdata),
    .hready       (lsu_hready),
    .hresp        (lsu_hresp),
    .axil_awaddr  (core_lsu_axil_awaddr),
    .axil_awprot  (core_lsu_axil_awprot),
    .axil_awvalid (core_lsu_axil_awvalid),
    .axil_awready (core_lsu_axil_awready),
    .axil_wdata   (core_lsu_axil_wdata),
    .axil_wstrb   (core_lsu_axil_wstrb),
    .axil_wvalid  (core_lsu_axil_wvalid),
    .axil_wready  (core_lsu_axil_wready),
    .axil_bresp   (core_lsu_axil_bresp),
    .axil_bvalid  (core_lsu_axil_bvalid),
    .axil_bready  (core_lsu_axil_bready),
    .axil_araddr  (core_lsu_axil_araddr),
    .axil_arprot  (core_lsu_axil_arprot),
    .axil_arvalid (core_lsu_axil_arvalid),
    .axil_arready (core_lsu_axil_arready),
    .axil_rdata   (core_lsu_axil_rdata),
    .axil_rresp   (core_lsu_axil_rresp),
    .axil_rvalid  (core_lsu_axil_rvalid),
    .axil_rready  (core_lsu_axil_rready)
  );

endmodule

`default_nettype wire
