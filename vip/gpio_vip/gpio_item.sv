/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : GPIO VIP
 * File           : gpio_item.sv
 * Description    : Transaction item for GPIO VIP supporting pin-level stimulus
 *                  and memory-mapped AXI4-Lite register access.
 * ============================================================================== */

`ifndef GPIO_ITEM_SV
`define GPIO_ITEM_SV

class gpio_item extends uvm_sequence_item;

  // Pin-level signals
  rand bit [7:0]  gpio_in;
  bit [7:0]       gpio_out;
  bit             irq_gpio;

  // AXI4-Lite slave channel signals
  rand bit [31:0] s_axil_awaddr;
  rand bit [2:0]  s_axil_awprot;
  rand bit        s_axil_awvalid;
  bit             s_axil_awready;
  rand bit [31:0] s_axil_wdata;
  rand bit [3:0]  s_axil_wstrb;
  rand bit        s_axil_wvalid;
  bit             s_axil_wready;
  bit [1:0]       s_axil_bresp;
  bit             s_axil_bvalid;
  rand bit        s_axil_bready;
  rand bit [31:0] s_axil_araddr;
  rand bit [2:0]  s_axil_arprot;
  rand bit        s_axil_arvalid;
  bit             s_axil_arready;
  bit [31:0]      s_axil_rdata;
  bit [1:0]       s_axil_rresp;
  bit             s_axil_rvalid;
  rand bit        s_axil_rready;

  // Functional protocol fields
  rand bit        is_pin_drive; // 1: drive gpio_in pins
  rand bit        is_axil;      // 1: AXI4-Lite register transaction
  rand bit        is_write;     // 1: write, 0: read

  `uvm_object_utils_begin(gpio_item)
    `uvm_field_int(gpio_in,        UVM_ALL_ON)
    `uvm_field_int(gpio_out,       UVM_ALL_ON)
    `uvm_field_int(irq_gpio,       UVM_ALL_ON)
    `uvm_field_int(s_axil_awaddr,  UVM_ALL_ON)
    `uvm_field_int(s_axil_wdata,   UVM_ALL_ON)
    `uvm_field_int(s_axil_araddr,  UVM_ALL_ON)
    `uvm_field_int(s_axil_rdata,   UVM_ALL_ON)
    `uvm_field_int(is_pin_drive,   UVM_ALL_ON)
    `uvm_field_int(is_axil,        UVM_ALL_ON)
    `uvm_field_int(is_write,       UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="gpio_item");
    super.new(name);
    gpio_in       = 8'h00;
    s_axil_wstrb  = 4'hF;
    s_axil_bready = 1'b1;
    s_axil_rready = 1'b1;
    is_pin_drive  = 1'b0;
    is_axil       = 1'b0;
    is_write      = 1'b0;
  endfunction

endclass

`endif // GPIO_ITEM_SV
