/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : UART VIP
 * File           : uart_monitor.sv
 * Description    : Functional UART Monitor. Passively observes serial TX frames
 *                  from the DUT, reconstructs 8-bit characters with start/stop
 *                  bit verification, and broadcasts them via analysis port.
 * ============================================================================== */

`ifndef UART_MONITOR_SV
`define UART_MONITOR_SV

class uart_monitor extends uvm_monitor;
  virtual uart_if vif;
  uvm_analysis_port #(uart_item) ap;

  int baud_div = 8; // Default clock cycles per bit

  `uvm_component_utils(uart_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif) || vif == null) begin
      `uvm_fatal("NOVIF", {"Virtual interface vif must be set for ", get_full_name(), ".vif"});
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    bit [7:0] captured_byte;
    uart_item item;

    // Wait for reset release
    if (vif != null && !vif.rst_n)
      @(posedge vif.rst_n);

    forever begin
      // 1. Detect start bit (falling edge of uart_tx while idle high)
      @(negedge vif.uart_tx);

      // 2. Wait 1.5 bit periods to align to the middle of bit 0
      repeat (baud_div + (baud_div / 2)) @(posedge vif.clk);

      // 3. Sample 8 data bits (LSB first)
      for (int i = 0; i < 8; i++) begin
        captured_byte[i] = vif.uart_tx;
        repeat (baud_div) @(posedge vif.clk);
      end

      // 4. Check stop bit (must be 1)
      if (vif.uart_tx !== 1'b1) begin
        `uvm_warning("UART_MON", $sformatf("Framing error: stop bit is %b (expected 1)", vif.uart_tx));
      end

      // 5. Package and publish transaction
      item = uart_item::type_id::create("item");
      item.data    = captured_byte;
      item.uart_tx = 1'b1;
      item.is_tx   = 1'b1;

      `uvm_info("UART_MON", $sformatf("Monitored UART TX frame: 0x%02X ('%c')",
                captured_byte, (captured_byte >= 32 && captured_byte <= 126) ? captured_byte : "."), UVM_LOW)

      ap.write(item);
    end
  endtask

endclass

`endif // UART_MONITOR_SV
