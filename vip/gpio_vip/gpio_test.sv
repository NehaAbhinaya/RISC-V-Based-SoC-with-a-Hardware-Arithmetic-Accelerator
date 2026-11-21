/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : GPIO VIP
 * File           : gpio_test.sv
 * Description    : UVM Test for GPIO VIP standalone verification.
 * ============================================================================== */

`ifndef GPIO_TEST_SV
`define GPIO_TEST_SV

class gpio_test extends uvm_test;
  gpio_env env;

  `uvm_component_utils(gpio_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = gpio_env::type_id::create("env", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    gpio_smoke_seq seq;
    phase.raise_objection(this);
    `uvm_info("GPIO_TEST", "Executing GPIO VIP Functional Verification Test...", UVM_LOW)

    env.sb.add_expected_out(8'hA0);

    seq = gpio_smoke_seq::type_id::create("seq");
    seq.start(env.agent.seqr);

    #2000;
    `uvm_info("GPIO_TEST", "GPIO VIP Test Finished.", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass

`endif // GPIO_TEST_SV
