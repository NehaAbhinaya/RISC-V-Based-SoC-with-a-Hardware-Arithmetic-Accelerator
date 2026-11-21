// ==============================================================================
// Synopsys VCS Filelist: Full Integrated Top Module (soc_top.v & tb_soc_top.v)
// Segregated IP-Based Architecture
// ==============================================================================

// Include search paths
+incdir+spi
+incdir+uart
+incdir+riscv_core/snapshots/default_ahb
+incdir+riscv_core/design/include

// VeeR EL2 simulation defines: suppress physical-only $error checks
+define+RV_PHYSICAL

// ============================================================
// 1. VeeR EL2 RISC-V Core
// ============================================================
riscv_core/design/include/el2_def.sv
riscv_core/design/lib/el2_assert.sv
riscv_core/design/el2_mubi_pkg.sv
riscv_core/design/el2_lockstep_pkg.sv
riscv_core/design/lib/el2_mem_if.sv
riscv_core/design/lib/el2_regfile_if.sv

riscv_core/design/lib/beh_lib.sv
riscv_core/design/lib/mem_lib.sv
riscv_core/design/lib/el2_lib.sv
riscv_core/design/lib/el2_prim_buf.sv
riscv_core/design/lib/el2_prim_generic_buf.sv
riscv_core/design/lib/ahb_to_axi4.sv
riscv_core/design/lib/axi4_to_ahb.sv

riscv_core/design/el2_pmp.sv

riscv_core/design/dec/el2_dec_decode_ctl.sv
riscv_core/design/dec/el2_dec_gpr_ctl.sv
riscv_core/design/dec/el2_dec_ib_ctl.sv
riscv_core/design/dec/el2_dec_pmp_ctl.sv
riscv_core/design/dec/el2_dec_tlu_ctl.sv
riscv_core/design/dec/el2_dec_trigger.sv
riscv_core/design/dec/el2_dec.sv

riscv_core/design/exu/el2_exu_alu_ctl.sv
riscv_core/design/exu/el2_exu_mul_ctl.sv
riscv_core/design/exu/el2_exu_div_ctl.sv
riscv_core/design/exu/el2_exu.sv

riscv_core/design/ifu/el2_ifu_ifc_ctl.sv
riscv_core/design/ifu/el2_ifu_bp_ctl.sv
riscv_core/design/ifu/el2_ifu_aln_ctl.sv
riscv_core/design/ifu/el2_ifu_compress_ctl.sv
riscv_core/design/ifu/el2_ifu_mem_ctl.sv
riscv_core/design/ifu/el2_ifu_iccm_mem.sv
riscv_core/design/ifu/el2_ifu_ic_mem.sv
// riscv_core/design/ifu/el2_ifu_tb_memread.sv (standalone testbench, excluded)
riscv_core/design/ifu/el2_ifu.sv

riscv_core/design/lsu/el2_lsu_addrcheck.sv
riscv_core/design/lsu/el2_lsu_clkdomain.sv
riscv_core/design/lsu/el2_lsu_ecc.sv
riscv_core/design/lsu/el2_lsu_lsc_ctl.sv
riscv_core/design/lsu/el2_lsu_stbuf.sv
riscv_core/design/lsu/el2_lsu_dccm_ctl.sv
riscv_core/design/lsu/el2_lsu_dccm_mem.sv
riscv_core/design/lsu/el2_lsu_bus_buffer.sv
riscv_core/design/lsu/el2_lsu_bus_intf.sv
riscv_core/design/lsu/el2_lsu_trigger.sv
riscv_core/design/lsu/el2_lsu.sv

riscv_core/design/dbg/el2_dbg.sv
riscv_core/design/dmi/dmi_jtag_to_core_sync.v
riscv_core/design/dmi/dmi_mux.v
riscv_core/design/dmi/rvjtag_tap.v
riscv_core/design/dmi/dmi_wrapper.v

riscv_core/design/el2_pic_ctrl.sv
riscv_core/design/el2_dma_ctrl.sv
riscv_core/design/el2_mem.sv
riscv_core/design/el2_veer.sv
riscv_core/design/el2_veer_lockstep.sv
riscv_core/design/el2_veer_wrapper.sv

riscv_core/ahblite_to_axilite_bridge.v
riscv_core/riscv_core_top.sv

// ============================================================
// 2. SPI IP Core
// ============================================================
spi/axi_spi_ctrl.v
spi/ratio_clk.v
spi/spi_clk_gen.v
spi/spi_ctrl.v
spi/spi_exch_byte.v
spi/spi_fifo.v
spi/spi_valid_logic.v
spi/axi_spi_top.v
spi/soc_spi.v

// ============================================================
// 3. UART IP Core
// ============================================================
uart/axi_internal_fifo.v
uart/uart_parity_bit_compute.v
uart/uart_transmitter.v
uart/uart_receiver.v
uart/uart_controller.v
uart/axi_uart_top.v
uart/soc_uart.v

// ============================================================
// 4. SoC Interconnect Fabric
// ============================================================
interconnect/axil_interconnect.v
interconnect/soc_axil_fabric.v

// ============================================================
// 5. SoC Peripherals, Memories & Accelerator
// ============================================================
arithmetic_accelerator/arithmetic_accelerator.v
dma_controller/dma_controller.v
timer/soc_timer.v
gpio/soc_gpio.v
memories/imem_axil.v
memories/dmem_axil.v

// ============================================================
// 6. Top-Level Module and Testbench
// ============================================================
top/soc_top.v
top/tb_soc_top.v
