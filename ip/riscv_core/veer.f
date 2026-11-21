// ==============================================================================
// VCS Filelist: VeeR EL2 RISC-V Core (Reconstructed)
// ==============================================================================

// VeeR EL2 parameter snapshot include path
+incdir+riscv_core/snapshots/default_ahb
+incdir+riscv_core/design/include

// Design include file (el2_def.sv must come first)
riscv_core/design/include/el2_def.sv

// Library / utility packages (order matters for SV package dependencies)
riscv_core/design/el2_mubi_pkg.sv
riscv_core/design/el2_lockstep_pkg.sv
riscv_core/design/lib/el2_mem_if.sv
riscv_core/design/lib/el2_regfile_if.sv

// Primitive / behavioral library
riscv_core/design/lib/beh_lib.sv
riscv_core/design/lib/mem_lib.sv
riscv_core/design/lib/el2_lib.sv
riscv_core/design/lib/el2_prim_buf.sv
riscv_core/design/lib/el2_prim_generic_buf.sv

// AHB <-> AXI4 bridge library (internal to VeeR)
riscv_core/design/lib/ahb_to_axi4.sv
riscv_core/design/lib/axi4_to_ahb.sv

// Assertions (include before RTL)
riscv_core/design/lib/el2_assert.sv

// PMP
riscv_core/design/el2_pmp.sv

// Decode stage sub-modules
riscv_core/design/dec/el2_dec_decode_ctl.sv
riscv_core/design/dec/el2_dec_gpr_ctl.sv
riscv_core/design/dec/el2_dec_ib_ctl.sv
riscv_core/design/dec/el2_dec_pmp_ctl.sv
riscv_core/design/dec/el2_dec_tlu_ctl.sv
riscv_core/design/dec/el2_dec_trigger.sv
riscv_core/design/dec/el2_dec.sv

// Execute stage sub-modules
riscv_core/design/exu/el2_exu_alu_ctl.sv
riscv_core/design/exu/el2_exu_mul_ctl.sv
riscv_core/design/exu/el2_exu_div_ctl.sv
riscv_core/design/exu/el2_exu.sv

// Instruction Fetch Unit sub-modules
riscv_core/design/ifu/el2_ifu_ifc_ctl.sv
riscv_core/design/ifu/el2_ifu_bp_ctl.sv
riscv_core/design/ifu/el2_ifu_aln_ctl.sv
riscv_core/design/ifu/el2_ifu_compress_ctl.sv
riscv_core/design/ifu/el2_ifu_mem_ctl.sv
riscv_core/design/ifu/el2_ifu_iccm_mem.sv
riscv_core/design/ifu/el2_ifu_ic_mem.sv
// riscv_core/design/ifu/el2_ifu_tb_memread.sv (standalone testbench, excluded)
riscv_core/design/ifu/el2_ifu.sv

// Load/Store Unit sub-modules
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

// Debug module
riscv_core/design/dbg/el2_dbg.sv

// DMI (Debug Module Interface)
riscv_core/design/dmi/dmi_jtag_to_core_sync.v
riscv_core/design/dmi/dmi_mux.v
riscv_core/design/dmi/rvjtag_tap.v
riscv_core/design/dmi/dmi_wrapper.v

// Top-level VeeR modules
riscv_core/design/el2_pic_ctrl.sv
riscv_core/design/el2_dma_ctrl.sv
riscv_core/design/el2_mem.sv
riscv_core/design/el2_veer.sv
riscv_core/design/el2_veer_lockstep.sv
riscv_core/design/el2_veer_wrapper.sv
