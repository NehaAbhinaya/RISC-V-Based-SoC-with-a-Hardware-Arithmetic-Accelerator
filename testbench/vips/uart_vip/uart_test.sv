/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : UART VIP
 * File           : uart_test.sv
 * Description    : UVM Test for UART VIP standalone verification.
 * ============================================================================== */

`ifndef UART_TEST_SV
`define UART_TEST_SV

class uart_test extends uvm_test;
  uart_env env;

  `uvm_component_utils(uart_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = uart_env::type_id::create("env", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    uart_smoke_seq seq;
    phase.raise_objection(this);
    `uvm_info("UART_TEST", "Executing UART VIP Functional Verification Test...", UVM_LOW)

    env.sb.add_expected(8'hA5);

    seq = uart_smoke_seq::type_id::create("seq");
    seq.start(env.agent.seqr);

    #2000;
    `uvm_info("UART_TEST", "UART VIP Test Finished.", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass

`endif // UART_TEST_SV
