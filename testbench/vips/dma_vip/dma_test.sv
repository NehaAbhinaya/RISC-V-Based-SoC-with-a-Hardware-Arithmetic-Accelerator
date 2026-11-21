/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : DMA VIP
 * File           : dma_test.sv
 * Description    : UVM Test for DMA VIP standalone verification.
 * ============================================================================== */

`ifndef DMA_TEST_SV
`define DMA_TEST_SV

class dma_test extends uvm_test;
  dma_env env;

  `uvm_component_utils(dma_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = dma_env::type_id::create("env", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma_smoke_seq seq;
    phase.raise_objection(this);
    `uvm_info("DMA_TEST", "Executing DMA VIP Functional Verification Test...", UVM_LOW)

    seq = dma_smoke_seq::type_id::create("seq");
    seq.start(env.agent.seqr);

    #1000;
    `uvm_info("DMA_TEST", "DMA VIP Test Finished.", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass

`endif // DMA_TEST_SV
