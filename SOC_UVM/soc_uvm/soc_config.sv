/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * Subsystem      : SoC-Level UVM Verification Environment
 * File           : soc_config.sv
 * Description    : SoC-level UVM configuration object encapsulating VIP virtual
 *                  interfaces, active/passive operating modes, and SoC memory map.
 * ============================================================================== */

`ifndef SOC_CONFIG_SV
`define SOC_CONFIG_SV

class soc_config extends uvm_object;
  `uvm_object_utils(soc_config)

  // --------------------------------------------------------------------------
  // Virtual Interface Handles for All Six Peripherals
  // --------------------------------------------------------------------------
  virtual uart_if                   uart_vif;
  virtual gpio_if                   gpio_vif;
  virtual spi_if                    spi_vif;
  virtual timer_if                  timer_vif;
  virtual arithmetic_accelerator_if accel_vif;
  virtual dma_if                    dma_vif;

  // --------------------------------------------------------------------------
  // Agent Operating Modes (Active: driver+sequencer+mon; Passive: mon only)
  // --------------------------------------------------------------------------
  uvm_active_passive_enum is_active_uart   = UVM_ACTIVE;
  uvm_active_passive_enum is_active_gpio   = UVM_ACTIVE;
  uvm_active_passive_enum is_active_spi    = UVM_ACTIVE;
  uvm_active_passive_enum is_active_timer  = UVM_ACTIVE;
  uvm_active_passive_enum is_active_accel  = UVM_ACTIVE;
  uvm_active_passive_enum is_active_dma    = UVM_ACTIVE;

  // --------------------------------------------------------------------------
  // SoC Memory Map Constants (Verified against RTL soc_axil_fabric & soc_top)
  // --------------------------------------------------------------------------
  parameter bit [31:0] IMEM_BASE_ADDR   = 32'h0000_0000; // m00: 64 KB IMEM
  parameter bit [31:0] DMEM_BASE_ADDR   = 32'h1000_0000; // m01: 64 KB DMEM
  parameter bit [31:0] UART_BASE_ADDR   = 32'h4000_0000; // m02: 4 KB UART
  parameter bit [31:0] TIMER_BASE_ADDR  = 32'h4000_1000; // m03: 4 KB Timer
  parameter bit [31:0] GPIO_BASE_ADDR   = 32'h4000_2000; // m04: 4 KB GPIO
  parameter bit [31:0] ACCEL_BASE_ADDR  = 32'h4000_3000; // m05: 4 KB Accelerator
  parameter bit [31:0] DMA_BASE_ADDR    = 32'h4000_4000; // m06: 4 KB DMA Registers
  parameter bit [31:0] SPI_BASE_ADDR    = 32'h4000_5000; // m07: 4 KB SPI

  // --------------------------------------------------------------------------
  // Constructor
  // --------------------------------------------------------------------------
  function new(string name = "soc_config");
    super.new(name);
  endfunction

endclass : soc_config

`endif // SOC_CONFIG_SV
