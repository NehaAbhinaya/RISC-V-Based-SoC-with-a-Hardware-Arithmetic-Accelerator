/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : Arithmetic Accelerator VIP
 * File           : arithmetic_accelerator_seq.sv
 * Description    : UVM Sequences for Arithmetic Accelerator verification
 *                  (ADD, SUB, MUL, DIV, MAC, and Div-by-zero exception).
 * ============================================================================== */

`ifndef ARITHMETIC_ACCELERATOR_SEQ_SV
`define ARITHMETIC_ACCELERATOR_SEQ_SV

class arithmetic_accelerator_smoke_seq extends uvm_sequence #(arithmetic_accelerator_item);
  `uvm_object_utils(arithmetic_accelerator_smoke_seq)

  function new(string name="arithmetic_accelerator_smoke_seq");
    super.new(name);
  endfunction

  virtual task body();
    arithmetic_accelerator_item item;

    `uvm_info("ACCEL_SEQ", "Starting Arithmetic Accelerator ALU Sequences...", UVM_LOW)

    // 1. ADD: 7 + 5 = 12
    item = arithmetic_accelerator_item::type_id::create("item");
    start_item(item);
    item.is_direct = 1'b1;
    item.op        = 3'b000; // ADD
    item.op_a      = 32'd7;
    item.op_b      = 32'd5;
    finish_item(item);
    `uvm_info("ACCEL_SEQ", $sformatf("Executed ADD: 7 + 5 = %0d", item.res_val), UVM_LOW)

    // 2. SUB: 15 - 6 = 9
    item = arithmetic_accelerator_item::type_id::create("item");
    start_item(item);
    item.is_direct = 1'b1;
    item.op        = 3'b001; // SUB
    item.op_a      = 32'd15;
    item.op_b      = 32'd6;
    finish_item(item);
    `uvm_info("ACCEL_SEQ", $sformatf("Executed SUB: 15 - 6 = %0d", item.res_val), UVM_LOW)

    // 3. MUL: 6 * 7 = 42
    item = arithmetic_accelerator_item::type_id::create("item");
    start_item(item);
    item.is_direct = 1'b1;
    item.op        = 3'b010; // MUL
    item.op_a      = 32'd6;
    item.op_b      = 32'd7;
    finish_item(item);
    `uvm_info("ACCEL_SEQ", $sformatf("Executed MUL: 6 * 7 = %0d", item.res_val), UVM_LOW)

    // 4. DIV: 20 / 4 = 5
    item = arithmetic_accelerator_item::type_id::create("item");
    start_item(item);
    item.is_direct = 1'b1;
    item.op        = 3'b011; // DIV
    item.op_a      = 32'd20;
    item.op_b      = 32'd4;
    finish_item(item);
    `uvm_info("ACCEL_SEQ", $sformatf("Executed DIV: 20 / 4 = %0d", item.res_val), UVM_LOW)

    // 5. MAC: Clear accumulator, then (10*20) + (30*40) = 1400
    // Step 5a: Clear MAC accumulator (0x4000_3018 = 0)
    item = arithmetic_accelerator_item::type_id::create("item");
    start_item(item);
    item.is_write       = 1'b1;
    item.s_axil_awaddr  = 32'h4000_3018;
    item.s_axil_wdata   = 32'd0;
    item.s_axil_wstrb   = 4'hF;
    finish_item(item);

    // Step 5b: First MAC product: 10 * 20 -> 200
    item = arithmetic_accelerator_item::type_id::create("item");
    start_item(item);
    item.is_direct = 1'b1;
    item.op        = 3'b100; // MAC
    item.op_a      = 32'd10;
    item.op_b      = 32'd20;
    finish_item(item);

    // Step 5c: Second MAC product: 30 * 40 -> 200 + 1200 = 1400
    item = arithmetic_accelerator_item::type_id::create("item");
    start_item(item);
    item.is_direct = 1'b1;
    item.op        = 3'b100; // MAC
    item.op_a      = 32'd30;
    item.op_b      = 32'd40;
    finish_item(item);
    `uvm_info("ACCEL_SEQ", $sformatf("Executed MAC: (10*20) + (30*40) = %0d", item.res_val), UVM_LOW)

    // 6. Divide-by-Zero Exception: 100 / 0
    item = arithmetic_accelerator_item::type_id::create("item");
    start_item(item);
    item.is_direct = 1'b1;
    item.op        = 3'b011; // DIV
    item.op_a      = 32'd100;
    item.op_b      = 32'd0;
    finish_item(item);
    `uvm_info("ACCEL_SEQ", $sformatf("Executed Divide-by-zero: err flag = %b", item.error_flag), UVM_LOW)

    `uvm_info("ACCEL_SEQ", "Arithmetic Accelerator ALU Sequences finished.", UVM_LOW)
  endtask
endclass

`endif // ARITHMETIC_ACCELERATOR_SEQ_SV
