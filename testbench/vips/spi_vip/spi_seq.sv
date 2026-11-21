/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : SPI VIP
 * File           : spi_seq.sv
 * Description    : UVM Sequences for SPI verification (Basic transmit and receive transaction).
 * ============================================================================== */

`ifndef SPI_SEQ_SV
`define SPI_SEQ_SV

class spi_slave_resp_seq extends uvm_sequence #(spi_item);
  `uvm_object_utils(spi_slave_resp_seq)

  function new(string name="spi_slave_resp_seq");
    super.new(name);
  endfunction

  virtual task body();
    spi_item item = spi_item::type_id::create("item");
    start_item(item);
    item.is_slave_resp = 1'b1;
    item.tx_data       = 8'hA5;
    finish_item(item);
    `uvm_info("SPI_SEQ", "Configured SPI slave model with response byte 0xA5", UVM_LOW)
  endtask
endclass

class spi_master_trans_seq extends uvm_sequence #(spi_item);
  `uvm_object_utils(spi_master_trans_seq)

  function new(string name="spi_master_trans_seq");
    super.new(name);
  endfunction

  virtual task body();
    spi_item item;

    // 1. Configure Prescaler (0x4000_5030) = 0
    item = spi_item::type_id::create("item");
    start_item(item);
    item.is_axil        = 1'b1;
    item.is_write       = 1'b1;
    item.s_axil_awaddr  = 32'h4000_5030;
    item.s_axil_wdata   = 32'd0;
    item.s_axil_wstrb   = 4'hF;
    finish_item(item);

    // 2. Configure SPI_CR (0x4000_5060): Master mode=1, Enable=1 -> 0x06
    item = spi_item::type_id::create("item");
    start_item(item);
    item.is_axil        = 1'b1;
    item.is_write       = 1'b1;
    item.s_axil_awaddr  = 32'h4000_5060;
    item.s_axil_wdata   = 32'h0000_0006;
    item.s_axil_wstrb   = 4'hF;
    finish_item(item);

    // 3. Select Slave 0 via SPI_SSR (0x4000_5070) = 0xFFFFFFFE
    item = spi_item::type_id::create("item");
    start_item(item);
    item.is_axil        = 1'b1;
    item.is_write       = 1'b1;
    item.s_axil_awaddr  = 32'h4000_5070;
    item.s_axil_wdata   = 32'hFFFFFFFE;
    item.s_axil_wstrb   = 4'hF;
    finish_item(item);

    // 4. Transmit byte 0x3C via SPI_DTR (0x4000_5068)
    item = spi_item::type_id::create("item");
    start_item(item);
    item.is_axil        = 1'b1;
    item.is_write       = 1'b1;
    item.s_axil_awaddr  = 32'h4000_5068;
    item.s_axil_wdata   = 32'h0000_003C;
    item.s_axil_wstrb   = 4'hF;
    finish_item(item);

    #1500; // Await 8-bit SPI transmission

    // 5. Read back from SPI_DRR (0x4000_506C)
    item = spi_item::type_id::create("item");
    start_item(item);
    item.is_axil        = 1'b1;
    item.is_write       = 1'b0;
    item.s_axil_araddr  = 32'h4000_506C;
    finish_item(item);
    `uvm_info("SPI_SEQ", $sformatf("Read SPI_DRR returned received byte: 0x%02X", item.s_axil_rdata[7:0]), UVM_LOW)

    // 6. Deselect slave via SPI_SSR = 0xFFFFFFFF
    item = spi_item::type_id::create("item");
    start_item(item);
    item.is_axil        = 1'b1;
    item.is_write       = 1'b1;
    item.s_axil_awaddr  = 32'h4000_5070;
    item.s_axil_wdata   = 32'hFFFFFFFF;
    item.s_axil_wstrb   = 4'hF;
    finish_item(item);
  endtask
endclass

class spi_smoke_seq extends uvm_sequence #(spi_item);
  `uvm_object_utils(spi_smoke_seq)

  function new(string name="spi_smoke_seq");
    super.new(name);
  endfunction

  virtual task body();
    spi_slave_resp_seq  slave_seq;
    spi_master_trans_seq master_seq;

    `uvm_info("SPI_SEQ", "Starting SPI Smoke Sequence...", UVM_LOW)
    `uvm_do(slave_seq)
    `uvm_do(master_seq)
    `uvm_info("SPI_SEQ", "SPI Smoke Sequence completed successfully.", UVM_LOW)
  endtask
endclass

`endif // SPI_SEQ_SV
