/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : DMA VIP
 * File           : dma_env.sv
 * Description    : DMA UVM Environment integrating Agent and Scoreboard.
 * ============================================================================== */

`ifndef DMA_ENV_SV
`define DMA_ENV_SV

class dma_env extends uvm_env;
  dma_agent      agent;
  dma_scoreboard sb;

  `uvm_component_utils(dma_env)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = dma_agent::type_id::create("agent", this);
    sb    = dma_scoreboard::type_id::create("sb", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.mon.ap.connect(sb.mon_export);
  endfunction

endclass

`endif // DMA_ENV_SV
