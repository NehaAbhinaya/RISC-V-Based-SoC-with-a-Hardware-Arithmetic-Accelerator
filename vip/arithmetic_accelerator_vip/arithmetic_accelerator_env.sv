/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : Arithmetic Accelerator VIP
 * File           : arithmetic_accelerator_env.sv
 * Description    : Arithmetic Accelerator UVM Environment integrating Agent and Scoreboard.
 * ============================================================================== */

`ifndef ARITHMETIC_ACCELERATOR_ENV_SV
`define ARITHMETIC_ACCELERATOR_ENV_SV

class arithmetic_accelerator_env extends uvm_env;
  arithmetic_accelerator_agent      agent;
  arithmetic_accelerator_scoreboard sb;

  `uvm_component_utils(arithmetic_accelerator_env)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = arithmetic_accelerator_agent::type_id::create("agent", this);
    sb    = arithmetic_accelerator_scoreboard::type_id::create("sb", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.mon.ap.connect(sb.mon_export);
  endfunction

endclass

`endif // ARITHMETIC_ACCELERATOR_ENV_SV
