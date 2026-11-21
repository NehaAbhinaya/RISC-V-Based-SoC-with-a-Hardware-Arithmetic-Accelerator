/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * Subsystem      : SoC-Level UVM Verification Environment
 * File           : soc_virtual_sequence.sv
 * Description    : SoC-level Virtual Sequence base class. Provides coordination
 *                  foundation across VIP sequencers without issuing functional
 *                  peripheral transactions in this phase.
 * ============================================================================== */

`ifndef SOC_VIRTUAL_SEQUENCE_SV
`define SOC_VIRTUAL_SEQUENCE_SV

class soc_virtual_sequence extends uvm_sequence;
  `uvm_object_utils(soc_virtual_sequence)
  `uvm_declare_p_sequencer(soc_virtual_sequencer)

  function new(string name = "soc_virtual_sequence");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing SoC virtual sequence foundation (transactions quiescent in Step 1-5)", UVM_LOW)
    // Functional multi-peripheral stimulus generation is reserved for subsequent verification phases.
  endtask

endclass : soc_virtual_sequence

`endif // SOC_VIRTUAL_SEQUENCE_SV
