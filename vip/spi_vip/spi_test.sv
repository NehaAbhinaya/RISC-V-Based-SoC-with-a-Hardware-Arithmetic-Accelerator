/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : SPI VIP
 * File           : spi_test.sv
 * Description    : UVM Test for SPI VIP standalone verification.
 * ============================================================================== */

`ifndef SPI_TEST_SV
`define SPI_TEST_SV

class spi_test extends uvm_test;
  spi_env env;

  `uvm_component_utils(spi_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = spi_env::type_id::create("env", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    spi_smoke_seq seq;
    phase.raise_objection(this);
    `uvm_info("SPI_TEST", "Executing SPI VIP Functional Verification Test...", UVM_LOW)

    env.sb.add_expected_mosi(8'h3C);
    env.sb.add_expected_miso(8'hA5);

    seq = spi_smoke_seq::type_id::create("seq");
    seq.start(env.agent.seqr);

    #2000;
    `uvm_info("SPI_TEST", "SPI VIP Test Finished.", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass

`endif // SPI_TEST_SV
