// ==============================================================================
// Synopsys VCS Filelist: Full Integrated Top Module (soc_top.v & tb_soc_top.v)
// Segregated IP-Based Project Structure
// ==============================================================================

// Include search paths
+incdir+../ip/spi
+incdir+../ip/uart
+incdir+../ip/riscv_core/snapshots/default_ahb
+incdir+../ip/riscv_core/design/include

// VeeR EL2 simulation defines: suppress physical-only $error checks
+define+RV_PHYSICAL

// ============================================================
// 1. RISC-V VeeR EL2 Core Complex
// ============================================================
../ip/riscv_core/design/include/el2_def.sv
../ip/riscv_core/design/lib/el2_assert.sv
../ip/riscv_core/design/el2_mubi_pkg.sv
../ip/riscv_core/design/el2_lockstep_pkg.sv
../ip/riscv_core/design/lib/el2_mem_if.sv
../ip/riscv_core/design/lib/el2_regfile_if.sv

../ip/riscv_core/design/lib/beh_lib.sv
../ip/riscv_core/design/lib/mem_lib.sv
../ip/riscv_core/design/lib/el2_lib.sv
../ip/riscv_core/design/lib/el2_prim_buf.sv
../ip/riscv_core/design/lib/el2_prim_generic_buf.sv
../ip/riscv_core/design/lib/ahb_to_axi4.sv
../ip/riscv_core/design/lib/axi4_to_ahb.sv

../ip/riscv_core/design/el2_pmp.sv

../ip/riscv_core/design/dec/el2_dec_decode_ctl.sv
../ip/riscv_core/design/dec/el2_dec_gpr_ctl.sv
../ip/riscv_core/design/dec/el2_dec_ib_ctl.sv
../ip/riscv_core/design/dec/el2_dec_pmp_ctl.sv
../ip/riscv_core/design/dec/el2_dec_tlu_ctl.sv
../ip/riscv_core/design/dec/el2_dec_trigger.sv
../ip/riscv_core/design/dec/el2_dec.sv

../ip/riscv_core/design/exu/el2_exu_alu_ctl.sv
../ip/riscv_core/design/exu/el2_exu_mul_ctl.sv
../ip/riscv_core/design/exu/el2_exu_div_ctl.sv
../ip/riscv_core/design/exu/el2_exu.sv

../ip/riscv_core/design/ifu/el2_ifu_ifc_ctl.sv
../ip/riscv_core/design/ifu/el2_ifu_bp_ctl.sv
../ip/riscv_core/design/ifu/el2_ifu_aln_ctl.sv
../ip/riscv_core/design/ifu/el2_ifu_compress_ctl.sv
../ip/riscv_core/design/ifu/el2_ifu_mem_ctl.sv
../ip/riscv_core/design/ifu/el2_ifu_iccm_mem.sv
../ip/riscv_core/design/ifu/el2_ifu_ic_mem.sv
// ../ip/riscv_core/design/ifu/el2_ifu_tb_memread.sv (standalone testbench, excluded)
../ip/riscv_core/design/ifu/el2_ifu.sv

../ip/riscv_core/design/lsu/el2_lsu_addrcheck.sv
../ip/riscv_core/design/lsu/el2_lsu_clkdomain.sv
../ip/riscv_core/design/lsu/el2_lsu_ecc.sv
../ip/riscv_core/design/lsu/el2_lsu_lsc_ctl.sv
../ip/riscv_core/design/lsu/el2_lsu_stbuf.sv
../ip/riscv_core/design/lsu/el2_lsu_dccm_ctl.sv
../ip/riscv_core/design/lsu/el2_lsu_dccm_mem.sv
../ip/riscv_core/design/lsu/el2_lsu_bus_buffer.sv
../ip/riscv_core/design/lsu/el2_lsu_bus_intf.sv
../ip/riscv_core/design/lsu/el2_lsu_trigger.sv
../ip/riscv_core/design/lsu/el2_lsu.sv

../ip/riscv_core/design/dbg/el2_dbg.sv
../ip/riscv_core/design/dmi/dmi_jtag_to_core_sync.v
../ip/riscv_core/design/dmi/dmi_mux.v
../ip/riscv_core/design/dmi/rvjtag_tap.v
../ip/riscv_core/design/dmi/dmi_wrapper.v

../ip/riscv_core/design/el2_pic_ctrl.sv
../ip/riscv_core/design/el2_dma_ctrl.sv
../ip/riscv_core/design/el2_mem.sv
../ip/riscv_core/design/el2_veer.sv
../ip/riscv_core/design/el2_veer_lockstep.sv
../ip/riscv_core/design/el2_veer_wrapper.sv

../ip/riscv_core/ahblite_to_axilite_bridge.v
../ip/riscv_core/riscv_core_top.sv

// ============================================================
// 2. SPI IP Core
// ============================================================
../ip/spi/axi_spi_ctrl.v
../ip/spi/ratio_clk.v
../ip/spi/spi_clk_gen.v
../ip/spi/spi_ctrl.v
../ip/spi/spi_exch_byte.v
../ip/spi/spi_fifo.v
../ip/spi/spi_valid_logic.v
../ip/spi/axi_spi_top.v
../ip/spi/soc_spi.v

// ============================================================
// 3. UART IP Core
// ============================================================
../ip/uart/axi_internal_fifo.v
../ip/uart/uart_parity_bit_compute.v
../ip/uart/uart_transmitter.v
../ip/uart/uart_receiver.v
../ip/uart/uart_controller.v
../ip/uart/axi_uart_top.v
../ip/uart/soc_uart.v

// ============================================================
// 4. SoC Interconnect Fabric
// ============================================================
../ip/interconnect/axil_interconnect.v
../ip/interconnect/soc_axil_fabric.v

// ============================================================
// 5. Arithmetic Accelerator, DMA, Timer, GPIO, Memories
// ============================================================
../ip/arithmetic_accelerator/arithmetic_accelerator.v
../ip/dma_controller/dma_controller.v
../ip/timer/soc_timer.v
../ip/gpio/soc_gpio.v
../ip/memories/imem_axil.v
../ip/memories/dmem_axil.v

// ============================================================
// 6. Top-Level SoC & Testbench
// ============================================================
soc_top.v
tb_soc_top.v
