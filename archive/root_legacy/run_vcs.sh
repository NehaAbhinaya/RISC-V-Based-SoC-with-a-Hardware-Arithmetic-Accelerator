#!/usr/bin/env bash
# ==============================================================================
# Synopsys VCS Simulation Script for RISC-V Accelerator SoC
# Usage:
#   ./run_vcs.sh top [fsdb|vcd]   - Run full SoC top module (soc_top.v & tb_soc_top.v)
#   ./run_vcs.sh verdi            - Open Verdi GUI to view tb_soc_top.fsdb
#   ./run_vcs.sh fabric           - Run interconnect fabric regression (tb_soc_fabric.v)
#   ./run_vcs.sh spi              - Run standalone SPI unit testbench (tb_axi_spi.v)
#   ./run_vcs.sh uart             - Run standalone UART unit testbench (tb_axi_uart.v)
#   ./run_vcs.sh all              - Run all 4 verification suites
#   ./run_vcs.sh clean            - Remove compilation and simulation artifacts
# ==============================================================================

set -e

# Default Target
TARGET="${1:-top}"
WAVE="${2:-none}"

VCS_FLAGS="-full64 -sverilog +v2k -timescale=1ns/1ps -debug_access+all -kdb -notice"

# Check for waveform option
DUMP_DEF=""
if [ "$WAVE" == "fsdb" ]; then
    DUMP_DEF="+define+DUMP_FSDB"
    echo ">> Waveform dumping enabled: FSDB (Verdi)"
elif [ "$WAVE" == "vcd" ]; then
    DUMP_DEF="+define+DUMP_VCD"
    echo ">> Waveform dumping enabled: VCD"
fi

# Ensure VCS is in PATH
if ! command -v vcs &> /dev/null; then
    echo "[ERROR] Synopsys VCS ('vcs') executable not found in PATH."
    echo "Please ensure Synopsys VCS environment is sourced (e.g., source /tools/synopsys/env.sh)."
    exit 1
fi

run_suite() {
    local name=$1
    local flist=$2
    local compile_log="vcs_${name}_compile.log"
    local sim_log="vcs_${name}_sim.log"

    echo "=================================================================="
    echo "  [VCS] Compiling: ${name} (${flist})"
    echo "=================================================================="
    vcs ${VCS_FLAGS} ${DUMP_DEF} -f ${flist} -l ${compile_log}

    echo "=================================================================="
    echo "  [VCS] Simulating: ${name}"
    echo "=================================================================="
    ./simv -l ${sim_log}
    echo "[SUCCESS] Simulation finished for ${name}. Log: ${sim_log}"
}

case "$TARGET" in
    top)
        run_suite "top" "tb_soc_top.f"
        ;;
    fabric)
        run_suite "fabric" "tb_soc_fabric.f"
        ;;
    spi)
        run_suite "spi" "tb_axi_spi.f"
        ;;
    uart)
        run_suite "uart" "tb_axi_uart.f"
        ;;
    all)
        echo ">>> Running All 4 Verification Suites under Synopsys VCS <<<"
        run_suite "spi" "tb_axi_spi.f"
        run_suite "uart" "tb_axi_uart.f"
        run_suite "fabric" "tb_soc_fabric.f"
        run_suite "top" "tb_soc_top.f"
        echo "=================================================================="
        echo "  ALL 4 VCS SIMULATION SUITES PASSED SUCCESSFULLY!"
        echo "=================================================================="
        ;;
    verdi)
        echo ">> Launching Synopsys Verdi with tb_soc_top.fsdb..."
        verdi -ssf tb_soc_top.fsdb -f tb_soc_top.f &
        ;;
    clean)
        echo "Cleaning VCS artifacts..."
        rm -rf simv simv.daidir csrc *.log *.key *.vpd *.fsdb *.vcd ucli.key vc_hdrs.h DVEfiles verdiLog nova* novas*
        echo "Clean completed."
        ;;
    *)
        echo "Unknown target: $TARGET"
        echo "Valid targets: top | fabric | spi | uart | all | clean"
        exit 1
        ;;
esac
