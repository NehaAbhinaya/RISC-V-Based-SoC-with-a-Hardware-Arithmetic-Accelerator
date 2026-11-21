/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : GPIO VIP
 * File           : gpio_seq.sv
 * Description    : UVM Sequences for GPIO verification (Input pattern testing,
 *                  output pattern testing, and edge-triggered interrupt testing).
 * ============================================================================== */

`ifndef GPIO_SEQ_SV
`define GPIO_SEQ_SV

class gpio_input_pattern_seq extends uvm_sequence #(gpio_item);
  `uvm_object_utils(gpio_input_pattern_seq)

  function new(string name="gpio_input_pattern_seq");
    super.new(name);
  endfunction

  virtual task body();
    gpio_item item;

    // 1. Drive input pattern 0x5A onto gpio_in pins
    item = gpio_item::type_id::create("item");
    start_item(item);
    item.is_pin_drive = 1'b1;
    item.gpio_in      = 8'h5A;
    finish_item(item);

    // 2. Read back from GPIO_IN_REG (0x4000_2008)
    item = gpio_item::type_id::create("item");
    start_item(item);
    item.is_axil        = 1'b1;
    item.is_write       = 1'b0;
    item.s_axil_araddr  = 32'h4000_2008;
    finish_item(item);

    `uvm_info("GPIO_SEQ", $sformatf("Read GPIO_IN_REG returned: 0x%02X", item.s_axil_rdata[7:0]), UVM_LOW)
  endtask
endclass

class gpio_output_pattern_seq extends uvm_sequence #(gpio_item);
  `uvm_object_utils(gpio_output_pattern_seq)

  function new(string name="gpio_output_pattern_seq");
    super.new(name);
  endfunction

  virtual task body();
    gpio_item item;

    // 1. Configure Direction: upper 4 output (0xF0), lower 4 input
    item = gpio_item::type_id::create("item");
    start_item(item);
    item.is_axil        = 1'b1;
    item.is_write       = 1'b1;
    item.s_axil_awaddr  = 32'h4000_2000;
    item.s_axil_wdata   = 32'h0000_00F0;
    item.s_axil_wstrb   = 4'hF;
    finish_item(item);

    // 2. Drive Output Register with 0xA0
    item = gpio_item::type_id::create("item");
    start_item(item);
    item.is_axil        = 1'b1;
    item.is_write       = 1'b1;
    item.s_axil_awaddr  = 32'h4000_2004;
    item.s_axil_wdata   = 32'h0000_00A0;
    item.s_axil_wstrb   = 4'hF;
    finish_item(item);

    `uvm_info("GPIO_SEQ", "Configured GPIO outputs to drive pattern 0xA0", UVM_LOW)
  endtask
endclass

class gpio_interrupt_seq extends uvm_sequence #(gpio_item);
  `uvm_object_utils(gpio_interrupt_seq)

  function new(string name="gpio_interrupt_seq");
    super.new(name);
  endfunction

  virtual task body();
    gpio_item item;

    // 1. Enable bit 0 interrupt via GPIO_INT_EN_REG (0x4000_200C)
    item = gpio_item::type_id::create("item");
    start_item(item);
    item.is_axil        = 1'b1;
    item.is_write       = 1'b1;
    item.s_axil_awaddr  = 32'h4000_200C;
    item.s_axil_wdata   = 32'h0000_0001;
    item.s_axil_wstrb   = 4'hF;
    finish_item(item);

    // 2. Generate rising edge on gpio_in[0]
    item = gpio_item::type_id::create("item");
    start_item(item);
    item.is_pin_drive = 1'b1;
    item.gpio_in      = 8'h00;
    finish_item(item);

    item = gpio_item::type_id::create("item");
    start_item(item);
    item.is_pin_drive = 1'b1;
    item.gpio_in      = 8'h01; // Rising edge on bit 0
    finish_item(item);

    // 3. Clear interrupt status via W1C in GPIO_INT_STATUS_REG (0x4000_2010)
    item = gpio_item::type_id::create("item");
    start_item(item);
    item.is_axil        = 1'b1;
    item.is_write       = 1'b1;
    item.s_axil_awaddr  = 32'h4000_2010;
    item.s_axil_wdata   = 32'h0000_0001;
    item.s_axil_wstrb   = 4'hF;
    finish_item(item);

    `uvm_info("GPIO_SEQ", "Completed GPIO edge interrupt trigger and W1C clear sequence", UVM_LOW)
  endtask
endclass

class gpio_smoke_seq extends uvm_sequence #(gpio_item);
  `uvm_object_utils(gpio_smoke_seq)

  function new(string name="gpio_smoke_seq");
    super.new(name);
  endfunction

  virtual task body();
    gpio_input_pattern_seq  in_seq;
    gpio_output_pattern_seq out_seq;
    gpio_interrupt_seq      int_seq;

    `uvm_info("GPIO_SEQ", "Starting GPIO Smoke Sequence...", UVM_LOW)
    `uvm_do(in_seq)
    `uvm_do(out_seq)
    `uvm_do(int_seq)
    `uvm_info("GPIO_SEQ", "GPIO Smoke Sequence completed successfully.", UVM_LOW)
  endtask
endclass

`endif // GPIO_SEQ_SV
