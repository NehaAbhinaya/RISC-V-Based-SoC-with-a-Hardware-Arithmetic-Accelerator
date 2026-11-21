/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : UART VIP
 * File           : uart_driver.sv
 * Description    : Functional UART Driver supporting serial line driving (RX)
 *                  with accurate start, data (8-bit LSB-first), and stop bit timing,
 *                  plus memory-mapped AXI4-Lite slave channel driving.
 *                  Calls item_done() only AFTER the entire serial frame is completed.
 * ============================================================================== */

`ifndef UART_DRIVER_SV
`define UART_DRIVER_SV

class uart_driver extends uvm_driver #(uart_item);
  virtual uart_if vif;

  `uvm_component_utils(uart_driver)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif) || vif == null) begin
      `uvm_fatal("NOVIF", {"Virtual interface vif must be set for ", get_full_name(), ".vif"});
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    // Initialize default pin states
    if (vif != null) begin
      vif.uart_rx        <= 1'b1; // Idle high
      vif.s_axil_awaddr  <= 32'h0;
      vif.s_axil_awprot  <= 3'b000;
      vif.s_axil_awvalid <= 1'b0;
      vif.s_axil_wdata   <= 32'h0;
      vif.s_axil_wstrb   <= 4'h0;
      vif.s_axil_wvalid  <= 1'b0;
      vif.s_axil_bready  <= 1'b0;
      vif.s_axil_araddr  <= 32'h0;
      vif.s_axil_arprot  <= 3'b000;
      vif.s_axil_arvalid <= 1'b0;
      vif.s_axil_rready  <= 1'b0;
    end

    // Wait for reset release
    if (vif != null && !vif.rst_n)
      @(posedge vif.rst_n);

    // Wait an additional 10 clock cycles for DUT stabilization
    repeat (10) @(posedge vif.clk);

    forever begin
      seq_item_port.get_next_item(req);

      if (req.is_rx) begin
        drive_serial_byte(req.data, req.baud_div);
      end else if (req.is_axil) begin
        if (req.is_write)
          axil_write(req.s_axil_awaddr, req.s_axil_wdata, req.s_axil_wstrb);
        else
          axil_read(req.s_axil_araddr, req.s_axil_rdata);
      end else begin
        @(posedge vif.clk);
      end

      seq_item_port.item_done();
    end
  endtask

  // Drive serial byte onto uart_rx pin (8-N-1 format, LSB first)
  task drive_serial_byte(input [7:0] byte_val, input int baud_div);
    int div;
    div = (baud_div > 0) ? baud_div : 16; // Default: 16 clock cycles/bit
    `uvm_info("UART_DRV", $sformatf("=== [UART_DRV] Starting Serial RX Frame: 0x%02X (Divisor=%0d cycles/bit) ===", byte_val, div), UVM_LOW)

    // Ensure line is idle high before transmission
    vif.uart_rx <= 1'b1;
    repeat (div) @(posedge vif.clk);

    // 1. Start Bit: Drive LOW for exactly 1 bit duration
    @(posedge vif.clk);
    vif.uart_rx <= 1'b0;
    `uvm_info("UART_DRV", "  [START BIT] Driving LOW", UVM_HIGH)
    repeat (div) @(posedge vif.clk);

    // 2. 8 Data Bits: Transmit LSB-first
    for (int i = 0; i < 8; i++) begin
      vif.uart_rx <= byte_val[i];
      `uvm_info("UART_DRV", $sformatf("  [DATA BIT %0d] Driving bit value: %b", i, byte_val[i]), UVM_HIGH)
      repeat (div) @(posedge vif.clk);
    end

    // 3. Stop Bit: Drive HIGH for 1 bit duration
    vif.uart_rx <= 1'b1;
    `uvm_info("UART_DRV", "  [STOP BIT] Driving HIGH", UVM_HIGH)
    repeat (div) @(posedge vif.clk);

    // 4. Return to Idle State
    repeat (div) @(posedge vif.clk);
    `uvm_info("UART_DRV", $sformatf("=== [UART_DRV] Serial RX Frame Complete: 0x%02X ===", byte_val), UVM_LOW)
  endtask

  // AXI4-Lite Write Cycle
  task axil_write(input [31:0] addr, input [31:0] data, input [3:0] strb);
    int timeout;
    @(posedge vif.clk);
    vif.s_axil_awaddr  <= addr;
    vif.s_axil_awprot  <= 3'b000;
    vif.s_axil_awvalid <= 1'b1;
    vif.s_axil_wdata   <= data;
    vif.s_axil_wstrb   <= (strb != 4'h0) ? strb : 4'hF;
    vif.s_axil_wvalid  <= 1'b1;
    vif.s_axil_bready  <= 1'b1;

    timeout = 0;
    while ((!vif.s_axil_awready || !vif.s_axil_wready) && timeout < 200) begin
      @(posedge vif.clk);
      if (vif.s_axil_awready) vif.s_axil_awvalid <= 1'b0;
      if (vif.s_axil_wready)  vif.s_axil_wvalid  <= 1'b0;
      timeout++;
    end
    @(posedge vif.clk);
    vif.s_axil_awvalid <= 1'b0;
    vif.s_axil_wvalid  <= 1'b0;

    timeout = 0;
    while (!vif.s_axil_bvalid && timeout < 200) begin
      @(posedge vif.clk);
      timeout++;
    end
    @(posedge vif.clk);
    vif.s_axil_bready <= 1'b0;
    @(posedge vif.clk);
  endtask

  // AXI4-Lite Read Cycle
  task axil_read(input [31:0] addr, output [31:0] data);
    int timeout;
    @(posedge vif.clk);
    vif.s_axil_araddr  <= addr;
    vif.s_axil_arprot  <= 3'b000;
    vif.s_axil_arvalid <= 1'b1;
    vif.s_axil_rready  <= 1'b1;

    timeout = 0;
    while (!vif.s_axil_arready && timeout < 200) begin
      @(posedge vif.clk);
      timeout++;
    end
    @(posedge vif.clk);
    vif.s_axil_arvalid <= 1'b0;

    timeout = 0;
    while (!vif.s_axil_rvalid && timeout < 200) begin
      @(posedge vif.clk);
      timeout++;
    end
    data = vif.s_axil_rdata;
    @(posedge vif.clk);
    vif.s_axil_rready <= 1'b0;
    @(posedge vif.clk);
  endtask

endclass

`endif // UART_DRIVER_SV
