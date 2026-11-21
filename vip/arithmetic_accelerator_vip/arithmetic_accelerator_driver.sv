/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : Arithmetic Accelerator VIP
 * File           : arithmetic_accelerator_driver.sv
 * Description    : Functional Driver for Arithmetic Accelerator supporting
 *                  Direct Mode register access and Streaming Mode handshakes.
 * ============================================================================== */

`ifndef ARITHMETIC_ACCELERATOR_DRIVER_SV
`define ARITHMETIC_ACCELERATOR_DRIVER_SV

class arithmetic_accelerator_driver extends uvm_driver #(arithmetic_accelerator_item);
  virtual arithmetic_accelerator_if vif;

  `uvm_component_utils(arithmetic_accelerator_driver)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual arithmetic_accelerator_if)::get(this, "", "vif", vif) || vif == null) begin
      `uvm_fatal("NOVIF", {"Virtual interface vif must be set for ", get_full_name(), ".vif"});
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    if (vif != null) begin
      vif.dma_op_valid   <= 1'b0;
      vif.dma_op_data_a  <= 32'h0;
      vif.dma_op_data_b  <= 32'h0;
      vif.dma_res_ready  <= 1'b1;
      vif.dma_last       <= 1'b0;
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

    if (vif != null && !vif.rst_n)
      @(posedge vif.rst_n);

    forever begin
      seq_item_port.get_next_item(req);

      if (req.is_direct) begin
        execute_direct_op(req.op, req.op_a, req.op_b, req.res_val, req.error_flag);
      end else if (req.is_streaming) begin
        drive_stream_pair(req.op_a, req.op_b, req.dma_last, req.res_val);
      end else if (req.is_write) begin
        axil_write(req.s_axil_awaddr, req.s_axil_wdata, req.s_axil_wstrb);
      end else begin
        axil_read(req.s_axil_araddr, req.s_axil_rdata);
      end

      seq_item_port.item_done();
    end
  endtask

  // Direct Mode ALU Operation
  task execute_direct_op(
    input  [2:0]  opcode,
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] result,
    output        err
  );
    reg [31:0] status_val;
    `uvm_info("ACCEL_DRV", $sformatf("Direct Mode ALU Trigger: Opcode=%0d, A=%0d, B=%0d", opcode, a, b), UVM_MEDIUM)

    // Write Operand A (0x4000_300C)
    axil_write(32'h4000_300C, a, 4'hF);
    // Write Operand B (0x4000_3010)
    axil_write(32'h4000_3010, b, 4'hF);
    // Write ACC_CTRL (0x4000_3000): opcode | start (bit 3)
    axil_write(32'h4000_3000, {28'h0, 1'b1, opcode}, 4'hF);

    @(posedge vif.clk);

    // Read Result: from ACC_RESULT (0x4000_3014) or ACC_MAC_ACC (0x4000_3018) for MAC
    if (opcode == 3'b100)
      axil_read(32'h4000_3018, result);
    else
      axil_read(32'h4000_3014, result);

    // Check ACC_STATUS (0x4000_3004) for error flag (bit 2)
    axil_read(32'h4000_3004, status_val);
    err = status_val[2];
  endtask

  // Streaming Mode Driver
  task drive_stream_pair(
    input  [31:0] a,
    input  [31:0] b,
    input         last,
    output [31:0] res
  );
    int timeout;
    @(posedge vif.clk);
    vif.dma_op_valid  <= 1'b1;
    vif.dma_op_data_a <= a;
    vif.dma_op_data_b <= b;
    vif.dma_last      <= last;
    vif.dma_res_ready <= 1'b1;

    timeout = 0;
    while (!vif.dma_op_ready && timeout < 100) begin
      @(posedge vif.clk);
      timeout++;
    end
    @(posedge vif.clk);
    vif.dma_op_valid <= 1'b0;

    timeout = 0;
    while (!vif.dma_res_valid && timeout < 100) begin
      @(posedge vif.clk);
      timeout++;
    end
    res = vif.dma_res_data;
    @(posedge vif.clk);
  endtask

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

`endif // ARITHMETIC_ACCELERATOR_DRIVER_SV
