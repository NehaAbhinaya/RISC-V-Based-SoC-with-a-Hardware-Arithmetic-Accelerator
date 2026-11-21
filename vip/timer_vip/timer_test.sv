/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : Timer VIP
 * File           : timer_test.sv
 * Description    : UVM Test for Timer VIP standalone verification.
 * ============================================================================== */

`ifndef TIMER_TEST_SV
`define TIMER_TEST_SV

class timer_test extends uvm_test;
  timer_env env;

  `uvm_component_utils(timer_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = timer_env::type_id::create("env", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    timer_smoke_seq seq;
    phase.raise_objection(this);
    `uvm_info("TIMER_TEST", "Executing Timer VIP Functional Verification Test...", UVM_LOW)

    seq = timer_smoke_seq::type_id::create("seq");
    seq.start(env.agent.seqr);

    #1000;
    `uvm_info("TIMER_TEST", "Timer VIP Test Finished.", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass

`endif // TIMER_TEST_SV
