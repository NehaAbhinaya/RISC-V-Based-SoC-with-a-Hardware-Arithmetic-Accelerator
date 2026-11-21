# ==============================================================================
# Synopsys VCS & Verdi Automation Makefile
# RISC-V Arithmetic Accelerator SoC
# ==============================================================================

# VCS executable and simulator commands
VCS            = vcs
SIMV           = ./simv

# Standard Synopsys VCS Compilation Flags:
# -full64             : 64-bit binary mode
# -sverilog           : SystemVerilog support
# +v2k                : Verilog-2001 compatibility
# -timescale=1ns/1ps  : Global default timescale
# -debug_access+all   : Full debug and waveform dumping capability
# -kdb                : Generate Knowledge Database (KDB) for Synopsys Verdi
VCS_FLAGS      = -full64 -sverilog +v2k -timescale=1ns/1ps -debug_access+all -kdb -notice

# Optional Waveform Selection:
# Usage: make top WAVE=fsdb (for Verdi) or make top WAVE=vcd (for GTKWave/DVE)
ifeq ($(WAVE), fsdb)
	DUMP_DEF = +define+DUMP_FSDB
else ifeq ($(WAVE), vcd)
	DUMP_DEF = +define+DUMP_VCD
else
	DUMP_DEF =
endif

.PHONY: all top fabric spi uart clean verdi_top help

help:
	@echo "=================================================================="
	@echo "  Synopsys VCS Simulation Targets:"
	@echo "    make top         : Compile & run Full SoC Top Module (tb_soc_top)"
	@echo "    make fabric      : Compile & run Interconnect Fabric (tb_soc_fabric)"
	@echo "    make spi         : Compile & run Standalone SPI Core (tb_axi_spi)"
	@echo "    make uart        : Compile & run Standalone UART Core (tb_axi_uart)"
	@echo "    make all         : Compile & run all 4 verification suites"
	@echo "    make verdi_top   : Open Synopsys Verdi GUI for SoC Top"
	@echo "    make clean       : Clean all simulation and log artifacts"
	@echo ""
	@echo "  Waveform Dumping Options:"
	@echo "    make top WAVE=fsdb   (Generate FSDB waveform for Verdi)"
	@echo "    make top WAVE=vcd    (Generate standard VCD waveform)"
	@echo "=================================================================="

all: spi uart fabric top

top:
	@echo ">>> [VCS] Compiling and Running Full SoC Top Module..."
	$(VCS) $(VCS_FLAGS) $(DUMP_DEF) -f tb_soc_top.f -l vcs_top_compile.log
	$(SIMV) -l vcs_top_sim.log

fabric:
	@echo ">>> [VCS] Compiling and Running SoC Fabric & Interconnect..."
	$(VCS) $(VCS_FLAGS) $(DUMP_DEF) -f tb_soc_fabric.f -l vcs_fabric_compile.log
	$(SIMV) -l vcs_fabric_sim.log

spi:
	@echo ">>> [VCS] Compiling and Running Standalone SPI Core..."
	$(VCS) $(VCS_FLAGS) $(DUMP_DEF) -f tb_axi_spi.f -l vcs_spi_compile.log
	$(SIMV) -l vcs_spi_sim.log

uart:
	@echo ">>> [VCS] Compiling and Running Standalone UART Core..."
	$(VCS) $(VCS_FLAGS) $(DUMP_DEF) -f tb_axi_uart.f -l vcs_uart_compile.log
	$(SIMV) -l vcs_uart_sim.log

verdi_top:
	verdi -ssf tb_soc_top.fsdb &

clean:
	rm -rf simv simv.daidir csrc *.log *.key *.vpd *.fsdb *.vcd ucli.key vc_hdrs.h DVEfiles verdiLog nova* novas*
