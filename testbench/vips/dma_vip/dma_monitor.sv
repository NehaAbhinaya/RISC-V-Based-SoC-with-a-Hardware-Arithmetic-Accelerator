/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : DMA VIP
 * File           : dma_monitor.sv
 * Description    : Functional Monitor for DMA VIP. Observes DMA Master memory
 *                  accesses on m_axil_*, streaming handshakes, and irq_dma.
 * ============================================================================== */

`ifndef DMA_MONITOR_SV
`define DMA_MONITOR_SV

class dma_monitor extends uvm_monitor;
  virtual dma_if vif;
  uvm_analysis_port #(dma_item) ap;

  `uvm_component_utils(dma_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual dma_if)::get(this, "", "vif", vif) || vif == null) begin
      `uvm_fatal("NOVIF", {"Virtual interface vif must be set for ", get_full_name(), ".vif"});
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    bit prev_irq = 1'b0;
    dma_item item;

    if (vif != null && !vif.rst_n)
      @(posedge vif.rst_n);

    forever begin
      @(posedge vif.clk);

      // 1. Observe DMA Completion Interrupt
      if (vif.irq_dma !== prev_irq) begin
        item = dma_item::type_id::create("item");
        item.irq_dma   = vif.irq_dma;
        item.done_flag = vif.irq_dma;

        `uvm_info("DMA_MON", $sformatf("Monitored DMA IRQ transition: irq_dma = %b", vif.irq_dma), UVM_LOW)
        ap.write(item);
        prev_irq = vif.irq_dma;
      end

      // 2. Observe Master Memory Write Address/Data (DMA saving result to DMEM)
      if (vif.m_axil_awvalid && vif.m_axil_awready) begin
        item = dma_item::type_id::create("item");
        item.dst_addr      = vif.m_axil_awaddr;
        item.m_axil_wdata  = vif.m_axil_wdata;

        `uvm_info("DMA_MON", $sformatf("Monitored DMA Master Write to DMEM: Addr=0x%08X", vif.m_axil_awaddr), UVM_LOW)
        ap.write(item);
      end

      // 3. Observe Master Memory Read Address (DMA fetching operand from DMEM)
      if (vif.m_axil_arvalid && vif.m_axil_arready) begin
        item = dma_item::type_id::create("item");
        item.src_addr      = vif.m_axil_araddr;

        `uvm_info("DMA_MON", $sformatf("Monitored DMA Master Read from DMEM: Addr=0x%08X", vif.m_axil_araddr), UVM_LOW)
        ap.write(item);
      end
    end
  endtask

endclass

`endif // DMA_MONITOR_SV
