#!/usr/bin/env bash
# ==============================================================================
# Script: run_soc_uvm.sh
# Subsystem: RISC-V VeeR EL2 SoC with Arithmetic Accelerator
# Location: Project/SOC_UVM/sim/run_soc_uvm.sh
# Description: Compiles and runs SoC-level UVM tests, generates Synopsys Verdi
#              FSDB waveform (soc_uart.fsdb), and launches Verdi GUI with
#              pre-configured signal list (DUT UART TX, VIP UART TX, INTERFACE UART TX).
#
# Usage:
#   ./run_soc_uvm.sh                     - Compile, simulate, and generate FSDB waveform
#   ./run_soc_uvm.sh <test_name>         - Run specific UVM test
#   ./run_soc_uvm.sh verdi               - Launch Verdi GUI with preloaded signals
#   ./run_soc_uvm.sh clean               - Remove simulation and build artifacts
# ==============================================================================

set -e

# Setup Synopsys environment
export VCS_HOME="${VCS_HOME:-/home/student/snps_tools_target/vcs/U-2023.03}"
export VERDI_HOME="${VERDI_HOME:-/home/student/snps_tools_target/verdi/U-2023.03-SP1}"
export SNPSLMD_LICENSE_FILE="${SNPSLMD_LICENSE_FILE:-27021@14.139.1.126}"
export PATH="$VERDI_HOME/bin:$VCS_HOME/bin:$PATH"

TARGET="${1:-uart_connectivity_test}"

if [ "$TARGET" == "clean" ]; then
    echo ">> Cleaning VCS & Verdi build artifacts..."
    rm -rf simv* csrc *.log *.key *.vpd *.fsdb *.vcd ucli.key vc_hdrs.h DVEfiles verdiLog nova* novas* vcd2fsdbLog
    echo ">> Clean complete."
    exit 0
fi

if [ "$TARGET" == "verdi" ]; then
    if [ ! -f "soc_uart.fsdb" ]; then
        if [ -f "soc_uart_waveform.vcd" ]; then
            echo ">> Converting soc_uart_waveform.vcd to soc_uart.fsdb..."
            vcd2fsdb soc_uart_waveform.vcd -o soc_uart.fsdb
        else
            echo "[ERROR] Waveform file not found. Run './run_soc_uvm.sh' first."
            exit 1
        fi
    fi
    echo "=================================================================="
    echo "  [VERDI] Launching Synopsys Verdi Waveform Viewer"
    echo "  Waveform File : soc_uart.fsdb"
    echo "  Signal Config : uart_verdi.rc"
    echo "  Preloaded Signals:"
    echo "    - DUT UART TX       (/tb_soc_uvm_top/soc_dut/uart_tx)"
    echo "    - UVM VIP UART TX   (/tb_soc_uvm_top/uart_tx)"
    echo "    - INTERFACE UART TX (/tb_soc_uvm_top/u_uart_if/uart_tx)"
    echo "    - UART RX Path      (Driver -> Interface -> DUT)"
    echo "    - DUT RX FIFO       (8'hA5, rx_valid, rx_fifo_push)"
    echo "=================================================================="
    verdi -ssf soc_uart.fsdb -sswr uart_verdi.rc -f filelist.f &
    exit 0
fi

TEST_NAME="$TARGET"
VCS_FLAGS="-full64 -sverilog +v2k -ntb_opts uvm -timescale=1ns/1ps -notice"

echo "=================================================================="
echo "  [VCS] Compiling SoC-Level UVM Environment (filelist.f)"
echo "=================================================================="
vcs ${VCS_FLAGS} -f filelist.f -l soc_uvm_compile.log -o simv_soc_uvm

echo "=================================================================="
echo "  [VCS] Simulating UVM Test: ${TEST_NAME}"
echo "=================================================================="
./simv_soc_uvm +UVM_TESTNAME=${TEST_NAME} -l soc_uart_run.log

echo "=================================================================="
echo "  [VERDI] Converting VCD to Synopsys FSDB Waveform"
echo "=================================================================="
if [ -f "soc_uart_waveform.vcd" ]; then
    vcd2fsdb soc_uart_waveform.vcd -o soc_uart.fsdb > /dev/null 2>&1
    echo "  [SUCCESS] soc_uart.fsdb generated successfully."
fi

echo "=================================================================="
echo "  [SUCCESS] All Steps Completed."
echo "  Log File : soc_uart_run.log"
echo "  Waveforms:"
echo "    - Synopsys Verdi FSDB : soc_uart.fsdb"
echo "    - Generic VCD         : soc_uart_waveform.vcd"
echo "  Signal Config           : uart_verdi.rc"
echo "  To launch Verdi GUI with pre-loaded signals:"
echo "    ./run_soc_uvm.sh verdi"
echo "=================================================================="
