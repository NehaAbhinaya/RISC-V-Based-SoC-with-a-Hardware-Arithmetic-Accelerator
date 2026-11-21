/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : Arithmetic Accelerator VIP
 * File           : arithmetic_accelerator_test.sv
 * Description    : UVM Test for Arithmetic Accelerator VIP standalone verification.
 * ============================================================================== */

`ifndef ARITHMETIC_ACCELERATOR_TEST_SV
`define ARITHMETIC_ACCELERATOR_TEST_SV

class arithmetic_accelerator_test extends uvm_test;
  arithmetic_accelerator_env env;

  `uvm_component_utils(arithmetic_accelerator_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = arithmetic_accelerator_env::type_id::create("env", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    arithmetic_accelerator_smoke_seq seq;
    phase.raise_objection(this);
    `uvm_info("ACCEL_TEST", "Executing Arithmetic Accelerator VIP Functional Verification Test...", UVM_LOW)

    seq = arithmetic_accelerator_smoke_seq::type_id::create("seq");
    seq.start(env.agent.seqr);

    #1000;
    `uvm_info("ACCEL_TEST", "Arithmetic Accelerator VIP Test Finished.", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass

`endif // ARITHMETIC_ACCELERATOR_TEST_SV
