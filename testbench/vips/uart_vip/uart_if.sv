/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * Subsystem      : SoC-Level UVM Verification Environment
 * File           : uart_if.sv
 * Description    : SystemVerilog interface for UART VIP integration with soc_top.
 *                  Includes external serial pins, internal AXI4-Lite slave channel,
 *                  and non-invasive DUT-side reception observation signals.
 * ============================================================================== */

`ifndef UART_IF_SV
`define UART_IF_SV

interface uart_if;
  logic clk;
  logic rst_n;

  // External UART serial pins
  logic uart_tx;
  logic uart_rx;

  // Interrupt line
  logic irq_uart;

  // AXI4-Lite Slave Interface (m02 @ 0x4000_0000)
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

  // --------------------------------------------------------------------------
  // Non-Invasive DUT-Side Internal Hardware Reception Observation Signals
  // --------------------------------------------------------------------------
  logic        rx_valid;     // DUT RX FIFO non-empty / valid data available
  logic [7:0]  rx_data;      // DUT RX FIFO head data (UART_RXDATA 0x4000_000C)
  logic        rx_fifo_push; // Strobe when receiver pushes byte into FIFO
  logic [7:0]  rx_fifo_din;  // Byte presented by deserializer to RX FIFO
  logic [15:0] baud_divisor; // Current active hardware baud divisor

endinterface : uart_if

typedef virtual uart_if uart_vif;

`endif // UART_IF_SV
