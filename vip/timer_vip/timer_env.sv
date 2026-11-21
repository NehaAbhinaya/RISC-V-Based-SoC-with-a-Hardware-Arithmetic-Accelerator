/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : Timer VIP
 * File           : timer_env.sv
 * Description    : Timer UVM Environment integrating Agent and Scoreboard.
 * ============================================================================== */

`ifndef TIMER_ENV_SV
`define TIMER_ENV_SV

class timer_env extends uvm_env;
  timer_agent      agent;
  timer_scoreboard sb;

  `uvm_component_utils(timer_env)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = timer_agent::type_id::create("agent", this);
    sb    = timer_scoreboard::type_id::create("sb", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.mon.ap.connect(sb.mon_export);
  endfunction

endclass

`endif // TIMER_ENV_SV
