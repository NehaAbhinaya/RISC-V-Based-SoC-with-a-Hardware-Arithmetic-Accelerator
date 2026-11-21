/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : Timer VIP
 * File           : timer_seq.sv
 * Description    : UVM Sequences for Timer verification (Configuration,
 *                  counter progression, compare match, and interrupt check).
 * ============================================================================== */

`ifndef TIMER_SEQ_SV
`define TIMER_SEQ_SV

class timer_smoke_seq extends uvm_sequence #(timer_item);
  `uvm_object_utils(timer_smoke_seq)

  function new(string name="timer_smoke_seq");
    super.new(name);
  endfunction

  virtual task body();
    timer_item item;

    `uvm_info("TIMER_SEQ", "Starting Timer Verification Sequence...", UVM_LOW)

    // 1. Program Compare Threshold (0x4000_1008) = 15
    item = timer_item::type_id::create("item");
    start_item(item);
    item.is_write       = 1'b1;
    item.s_axil_awaddr  = 32'h4000_1008;
    item.s_axil_wdata   = 32'd15;
    item.s_axil_wstrb   = 4'hF;
    finish_item(item);

    // 2. Enable Timer & Interrupt in TIMER_CTRL (0x4000_1000): EN=1, IRQ_EN=1 -> 0x05
    item = timer_item::type_id::create("item");
    start_item(item);
    item.is_write       = 1'b1;
    item.s_axil_awaddr  = 32'h4000_1000;
    item.s_axil_wdata   = 32'h0000_0005;
    item.s_axil_wstrb   = 4'hF;
    finish_item(item);

    // 3. Read initial counter from TIMER_COUNT (0x4000_1004)
    item = timer_item::type_id::create("item");
    start_item(item);
    item.is_write       = 1'b0;
    item.s_axil_araddr  = 32'h4000_1004;
    finish_item(item);
    `uvm_info("TIMER_SEQ", $sformatf("Initial TIMER_COUNT = %0d", item.s_axil_rdata), UVM_LOW)

    // Wait for counter to increment past comparison threshold (30 cycles)
    #300;

    // 4. Read progression from TIMER_COUNT (0x4000_1004)
    item = timer_item::type_id::create("item");
    start_item(item);
    item.is_write       = 1'b0;
    item.s_axil_araddr  = 32'h4000_1004;
    finish_item(item);
    `uvm_info("TIMER_SEQ", $sformatf("Progressed TIMER_COUNT = %0d", item.s_axil_rdata), UVM_LOW)

    // 5. Clear Interrupt via W1C in TIMER_STATUS (0x4000_100C)
    item = timer_item::type_id::create("item");
    start_item(item);
    item.is_write       = 1'b1;
    item.s_axil_awaddr  = 32'h4000_100C;
    item.s_axil_wdata   = 32'h0000_0001;
    item.s_axil_wstrb   = 4'hF;
    finish_item(item);

    `uvm_info("TIMER_SEQ", "Timer Verification Sequence completed.", UVM_LOW)
  endtask
endclass

`endif // TIMER_SEQ_SV
