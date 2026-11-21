/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : Arithmetic Accelerator VIP
 * File           : arithmetic_accelerator_monitor.sv
 * Description    : Functional Monitor for Arithmetic Accelerator observing
 *                  direct-mode computation and streaming DMA compute cycles.
 * ============================================================================== */

`ifndef ARITHMETIC_ACCELERATOR_MONITOR_SV
`define ARITHMETIC_ACCELERATOR_MONITOR_SV

class arithmetic_accelerator_monitor extends uvm_monitor;
  virtual arithmetic_accelerator_if vif;
  uvm_analysis_port #(arithmetic_accelerator_item) ap;

  `uvm_component_utils(arithmetic_accelerator_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual arithmetic_accelerator_if)::get(this, "", "vif", vif) || vif == null) begin
      `uvm_fatal("NOVIF", {"Virtual interface vif must be set for ", get_full_name(), ".vif"});
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    arithmetic_accelerator_item item;

    if (vif != null && !vif.rst_n)
      @(posedge vif.rst_n);

    forever begin
      @(posedge vif.clk);

      // 1. Observe streaming DMA result handshake
      if (vif.dma_res_valid && vif.dma_res_ready) begin
        item = arithmetic_accelerator_item::type_id::create("item");
        item.is_streaming  = 1'b1;
        item.res_val       = vif.dma_res_data;
        item.dma_last      = vif.dma_last;
        item.irq_acc       = vif.irq_acc;

        `uvm_info("ACCEL_MON", $sformatf("Monitored streaming result = 0x%08X (%0d), last=%b",
                  vif.dma_res_data, vif.dma_res_data, vif.dma_last), UVM_LOW)
        ap.write(item);
      end

      // 2. Observe direct mode result read on AXI4-Lite slave channel
      if (vif.s_axil_rvalid && vif.s_axil_rready) begin
        item = arithmetic_accelerator_item::type_id::create("item");
        item.is_direct  = 1'b1;
        item.res_val    = vif.s_axil_rdata;
        item.irq_acc    = vif.irq_acc;

        `uvm_info("ACCEL_MON", $sformatf("Monitored direct mode register read = 0x%08X (%0d)",
                  vif.s_axil_rdata, vif.s_axil_rdata), UVM_LOW)
        ap.write(item);
      end
    end
  endtask

endclass

`endif // ARITHMETIC_ACCELERATOR_MONITOR_SV
