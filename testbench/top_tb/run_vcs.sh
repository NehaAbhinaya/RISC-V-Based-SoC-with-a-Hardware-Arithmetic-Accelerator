#!/usr/bin/env bash
# ==============================================================================
# Synopsys VCS & Verdi Simulation Script for SoC Top & C-Test
# Location: Project/top/
# Usage:
#   ./run_vcs.sh ctest        - Compile & run pure bare-metal C-Test (boots from hex)
#   ./run_vcs.sh ctest_fsdb   - Run C-Test with Verdi FSDB waveform dump
#   ./run_vcs.sh ctest_verdi  - Open Verdi GUI with C-Test FSDB & preloaded UART signals
#   ./run_vcs.sh              - Compile and run tb_soc_top full regression
#   ./run_vcs.sh fsdb         - Dump Verdi FSDB waveform for tb_soc_top
#   ./run_vcs.sh verdi        - Open Verdi GUI for tb_soc_top with preloaded UART signals
#   ./run_vcs.sh build_fw     - Rebuild firmware hex from Project/firmware
#   ./run_vcs.sh clean        - Remove build artifacts
# ==============================================================================

set -e

# Auto-setup Synopsys environment if not already set
export VCS_HOME="${VCS_HOME:-/home/student/snps_tools_target/vcs/U-2023.03}"
export VERDI_HOME="${VERDI_HOME:-/home/student/snps_tools_target/verdi/U-2023.03-SP1}"
export SNPSLMD_LICENSE_FILE="${SNPSLMD_LICENSE_FILE:-27021@14.139.1.126}"
export PATH="$VERDI_HOME/bin:$VCS_HOME/bin:$PATH"

TARGET="${1:-none}"
VCS_FLAGS="-full64 -sverilog +v2k -timescale=1ns/1ps -debug_access+all -kdb -notice"

# Handle Clean
if [ "$TARGET" == "clean" ]; then
    echo "Cleaning VCS & Verdi build artifacts..."
    rm -rf simv simv.daidir csrc *.log *.key *.vpd *.fsdb *.vcd ucli.key vc_hdrs.h DVEfiles verdiLog nova* novas*
    echo "Clean complete."
    exit 0
fi

# Handle Firmware Rebuild
if [ "$TARGET" == "build_fw" ]; then
    echo ">> Rebuilding bare-metal C firmware and hex file..."
    make -C ../../firmware clean
    make -C ../../firmware
    echo ">> Firmware rebuild complete: soc_firmware.hex generated and placed."
    exit 0
fi

# Handle Verdi GUI launches
if [ "$TARGET" == "ctest_verdi" ]; then
    if [ ! -f "tb_soc_ctest.fsdb" ]; then
        echo "[ERROR] tb_soc_ctest.fsdb not found. Run './run_vcs.sh ctest_fsdb' first."
        exit 1
    fi
    echo ">> Launching Synopsys Verdi with C-Test waveform (tb_soc_ctest.fsdb) and signal list (uart_ctest.rc)..."
    verdi -ssf tb_soc_ctest.fsdb -sswr uart_ctest.rc -f tb_soc_ctest.f &
    exit 0
elif [ "$TARGET" == "verdi" ]; then
    if [ ! -f "tb_soc_top.fsdb" ]; then
        echo "[ERROR] tb_soc_top.fsdb not found. Run './run_vcs.sh fsdb' first."
        exit 1
    fi
    echo ">> Launching Synopsys Verdi with Top waveform (tb_soc_top.fsdb) and signal list (tb_soc_top_uart.rc)..."
    verdi -ssf tb_soc_top.fsdb -sswr tb_soc_top_uart.rc -f tb_soc_top.f &
    exit 0
fi

# Check for VCS executable
if ! command -v vcs &> /dev/null; then
    echo "[ERROR] Synopsys VCS ('vcs') executable not found in PATH."
    exit 1
fi

# Determine simulation configuration: C-Test or Full Regression
FILELIST="tb_soc_top.f"
TOP_MOD="tb_soc_top"
DUMP_DEF=""
SIM_LOG="vcs_top_sim.log"
COMPILE_LOG="vcs_top_compile.log"

if [ "$TARGET" == "ctest" ]; then
    FILELIST="tb_soc_ctest.f"
    TOP_MOD="tb_soc_ctest"
    SIM_LOG="vcs_ctest_sim.log"
    COMPILE_LOG="vcs_ctest_compile.log"
    echo ">> Mode: Pure Bare-Metal SoC C-Test (Processor boots hex at 0x0000_0000)"
elif [ "$TARGET" == "ctest_fsdb" ]; then
    FILELIST="tb_soc_ctest.f"
    TOP_MOD="tb_soc_ctest"
    DUMP_DEF="+define+DUMP_FSDB"
    SIM_LOG="vcs_ctest_sim.log"
    COMPILE_LOG="vcs_ctest_compile.log"
    echo ">> Mode: Pure Bare-Metal SoC C-Test with Verdi FSDB Waveform Dumping"
elif [ "$TARGET" == "fsdb" ]; then
    DUMP_DEF="+define+DUMP_FSDB"
    echo ">> Mode: Full Top Regression with Verdi FSDB Waveform Dumping"
elif [ "$TARGET" == "vcd" ]; then
    DUMP_DEF="+define+DUMP_VCD"
    echo ">> Mode: Full Top Regression with VCD Waveform Dumping"
fi

# Ensure latest firmware hex exists
if [ ! -f "soc_firmware.hex" ]; then
    echo ">> soc_firmware.hex not found, compiling from Project/firmware..."
    make -C ../../firmware
fi

echo "=================================================================="
echo "  [VCS] Compiling: ${TOP_MOD} (${FILELIST})"
echo "=================================================================="
vcs ${VCS_FLAGS} ${DUMP_DEF} -f ${FILELIST} -l ${COMPILE_LOG}

echo "=================================================================="
echo "  [VCS] Simulating: ${TOP_MOD}"
echo "=================================================================="
./simv -l ${SIM_LOG}

echo "[SUCCESS] Simulation finished successfully. Log: ${SIM_LOG}"
