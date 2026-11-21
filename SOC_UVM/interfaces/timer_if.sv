/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * Subsystem      : SoC-Level UVM Verification Environment
 * File           : timer_if.sv
 * Description    : SystemVerilog interface for Timer VIP integration with soc_top.
 * ============================================================================== */

`ifndef TIMER_IF_SV
`define TIMER_IF_SV

interface timer_if;
  logic clk;
  logic rst_n;

  // Interrupt line
  logic irq_timer;

  // AXI4-Lite Slave Interface (m03 @ 0x4000_1000)
  logic [31:0] s_axil_awaddr;
  logic [2:0]  s_axil_awprot;
  logic        s_axil_awvalid;
  logic        s_axil_awready;
  logic [31:0] s_axil_wdata;
  logic [3:0]  s_axil_wstrb;
  logic        s_axil_wvalid;
  logic        s_axil_wready;
  logic [1:0]  s_axil_bresp;
  logic        s_axil_bvalid;
  logic        s_axil_bready;
  logic [31:0] s_axil_araddr;
  logic [2:0]  s_axil_arprot;
  logic        s_axil_arvalid;
  logic        s_axil_arready;
  logic [31:0] s_axil_rdata;
  logic [1:0]  s_axil_rresp;
  logic        s_axil_rvalid;
  logic        s_axil_rready;

endinterface : timer_if

typedef virtual timer_if timer_vif;

`endif // TIMER_IF_SV
