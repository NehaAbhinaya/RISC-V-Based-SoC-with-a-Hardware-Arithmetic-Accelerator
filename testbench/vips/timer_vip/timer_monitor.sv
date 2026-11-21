/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : Timer VIP
 * File           : timer_monitor.sv
 * Description    : Functional Timer Monitor. Passively observes irq_timer,
 *                  counter reads, and compare/control register operations.
 * ============================================================================== */

`ifndef TIMER_MONITOR_SV
`define TIMER_MONITOR_SV

class timer_monitor extends uvm_monitor;
  virtual timer_if vif;
  uvm_analysis_port #(timer_item) ap;

  `uvm_component_utils(timer_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual timer_if)::get(this, "", "vif", vif) || vif == null) begin
      `uvm_fatal("NOVIF", {"Virtual interface vif must be set for ", get_full_name(), ".vif"});
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    bit prev_irq = 1'b0;
    timer_item item;

    if (vif != null && !vif.rst_n)
      @(posedge vif.rst_n);

    forever begin
      @(posedge vif.clk);

      // Check for interrupt state transition
      if (vif.irq_timer !== prev_irq) begin
        item = timer_item::type_id::create("item");
        item.irq_timer     = vif.irq_timer;
        item.compare_match = vif.irq_timer;

        `uvm_info("TIMER_MON", $sformatf("Monitored Timer IRQ transition: irq_timer = %b", vif.irq_timer), UVM_LOW)
        ap.write(item);
        prev_irq = vif.irq_timer;
      end

      // Check for read of counter
      if (vif.s_axil_rvalid && vif.s_axil_rready) begin
        item = timer_item::type_id::create("item");
        item.s_axil_rdata = vif.s_axil_rdata;
        item.count_val    = vif.s_axil_rdata;
        item.irq_timer    = vif.irq_timer;

        `uvm_info("TIMER_MON", $sformatf("Monitored Timer read: 0x%08X (count/status)", vif.s_axil_rdata), UVM_LOW)
        ap.write(item);
      end
    end
  endtask

endclass

`endif // TIMER_MONITOR_SV
