/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * Subsystem      : SoC-Level UVM Verification Environment
 * File           : soc_env.sv
 * Description    : SoC-level UVM Environment instantiating all six VIP agents
 *                  and connecting them to the SoC virtual sequencer.
 * ============================================================================== */

`ifndef SOC_ENV_SV
`define SOC_ENV_SV

class soc_env extends uvm_env;
  `uvm_component_utils(soc_env)

  // --------------------------------------------------------------------------
  // Configuration Object
  // --------------------------------------------------------------------------
  soc_config cfg;

  // --------------------------------------------------------------------------
  // Six Peripheral VIP Agents & Scoreboard
  // --------------------------------------------------------------------------
  uart_pkg::uart_agent                                     uart_agnt;
  uart_pkg::uart_scoreboard                                uart_sb;
  gpio_pkg::gpio_agent                                     gpio_agnt;
  spi_pkg::spi_agent                                       spi_agnt;
  timer_pkg::timer_agent                                   timer_agnt;
  arithmetic_accelerator_pkg::arithmetic_accelerator_agent accel_agnt;
  dma_pkg::dma_agent                                       dma_agnt;

  // --------------------------------------------------------------------------
  // SoC Virtual Sequencer
  // --------------------------------------------------------------------------
  soc_virtual_sequencer v_seqr;

  // --------------------------------------------------------------------------
  // Constructor
  // --------------------------------------------------------------------------
  function new(string name = "soc_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // --------------------------------------------------------------------------
  // Build Phase: Fetch config, distribute VIFs, instantiate agents and seqr
  // --------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    `uvm_info(get_type_name(), "=== [BUILD PHASE] Starting SoC UVM Environment Construction ===", UVM_LOW)

    // Retrieve or create SoC configuration object
    if (!uvm_config_db#(soc_config)::get(this, "", "cfg", cfg) || cfg == null) begin
      `uvm_info(get_type_name(), "No soc_config found in config_db; creating default instance", UVM_LOW)
      cfg = soc_config::type_id::create("cfg", this);
    end

    // Distribute virtual interface handles to VIP agent namespaces
    if (cfg.uart_vif != null) begin
      uvm_config_db#(virtual uart_if)::set(this, "uart_agnt.*", "vif", cfg.uart_vif);
      uvm_config_db#(virtual uart_if)::set(this, "uart_sb", "vif", cfg.uart_vif);
    end
    if (cfg.gpio_vif != null)
      uvm_config_db#(virtual gpio_if)::set(this, "gpio_agnt.*", "vif", cfg.gpio_vif);
    if (cfg.spi_vif != null)
      uvm_config_db#(virtual spi_if)::set(this, "spi_agnt.*", "vif", cfg.spi_vif);
    if (cfg.timer_vif != null)
      uvm_config_db#(virtual timer_if)::set(this, "timer_agnt.*", "vif", cfg.timer_vif);
    if (cfg.accel_vif != null)
      uvm_config_db#(virtual arithmetic_accelerator_if)::set(this, "accel_agnt.*", "vif", cfg.accel_vif);
    if (cfg.dma_vif != null)
      uvm_config_db#(virtual dma_if)::set(this, "dma_agnt.*", "vif", cfg.dma_vif);

    // Instantiate VIP agents and scoreboard
    uart_agnt  = uart_pkg::uart_agent::type_id::create("uart_agnt", this);
    uart_sb    = uart_pkg::uart_scoreboard::type_id::create("uart_sb", this);
    gpio_agnt  = gpio_pkg::gpio_agent::type_id::create("gpio_agnt", this);
    spi_agnt   = spi_pkg::spi_agent::type_id::create("spi_agnt", this);
    timer_agnt = timer_pkg::timer_agent::type_id::create("timer_agnt", this);
    accel_agnt = arithmetic_accelerator_pkg::arithmetic_accelerator_agent::type_id::create("accel_agnt", this);
    dma_agnt   = dma_pkg::dma_agent::type_id::create("dma_agnt", this);

    // Instantiate Virtual Sequencer
    v_seqr = soc_virtual_sequencer::type_id::create("v_seqr", this);

    `uvm_info(get_type_name(), "=== [BUILD PHASE] All 6 VIP Agents and Virtual Sequencer successfully instantiated ===", UVM_LOW)
  endfunction

  // --------------------------------------------------------------------------
  // Connect Phase: Connect VIP sequencers to Virtual Sequencer
  // --------------------------------------------------------------------------
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    `uvm_info(get_type_name(), "=== [CONNECT PHASE] Connecting VIP Sequencers to Virtual Sequencer ===", UVM_LOW)

    // Connect UART monitor analysis port to scoreboard
    uart_agnt.ap.connect(uart_sb.mon_export);

    v_seqr.uart_seqr  = uart_agnt.seqr;
    v_seqr.gpio_seqr  = gpio_agnt.seqr;
    v_seqr.spi_seqr   = spi_agnt.seqr;
    v_seqr.timer_seqr = timer_agnt.seqr;
    v_seqr.accel_seqr = accel_agnt.seqr;
    v_seqr.dma_seqr   = dma_agnt.seqr;

    `uvm_info(get_type_name(), "=== [CONNECT PHASE] Virtual Sequencer connected to all 6 VIP sequencers ===", UVM_LOW)
  endfunction

  // --------------------------------------------------------------------------
  // End of Elaboration: Report structural summary
  // --------------------------------------------------------------------------
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info(get_type_name(), "=== [END OF ELABORATION] SoC UVM Environment structural hierarchy complete ===", UVM_LOW)
  endfunction

endclass : soc_env

`endif // SOC_ENV_SV
