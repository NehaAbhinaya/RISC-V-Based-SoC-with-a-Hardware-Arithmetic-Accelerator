/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : GPIO VIP
 * File           : gpio_monitor.sv
 * Description    : Functional GPIO Monitor. Passively monitors external gpio_in,
 *                  gpio_out, and irq_gpio pins and publishes observed transactions.
 * ============================================================================== */

`ifndef GPIO_MONITOR_SV
`define GPIO_MONITOR_SV

class gpio_monitor extends uvm_monitor;
  virtual gpio_if vif;
  uvm_analysis_port #(gpio_item) ap;

  `uvm_component_utils(gpio_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual gpio_if)::get(this, "", "vif", vif) || vif == null) begin
      `uvm_fatal("NOVIF", {"Virtual interface vif must be set for ", get_full_name(), ".vif"});
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    bit [7:0] prev_in  = 8'h00;
    bit [7:0] prev_out = 8'h00;
    bit       prev_irq = 1'b0;
    gpio_item item;

    if (vif != null && !vif.rst_n)
      @(posedge vif.rst_n);

    forever begin
      @(posedge vif.clk);

      if ((vif.gpio_in !== prev_in) || (vif.gpio_out !== prev_out) || (vif.irq_gpio !== prev_irq)) begin
        item = gpio_item::type_id::create("item");
        item.gpio_in   = vif.gpio_in;
        item.gpio_out  = vif.gpio_out;
        item.irq_gpio  = vif.irq_gpio;

        `uvm_info("GPIO_MON", $sformatf("Monitored GPIO state change: in=0x%02X, out=0x%02X, irq_gpio=%b",
                  vif.gpio_in, vif.gpio_out, vif.irq_gpio), UVM_LOW)

        ap.write(item);

        prev_in  = vif.gpio_in;
        prev_out = vif.gpio_out;
        prev_irq = vif.irq_gpio;
      end
    end
  endtask

endclass

`endif // GPIO_MONITOR_SV
