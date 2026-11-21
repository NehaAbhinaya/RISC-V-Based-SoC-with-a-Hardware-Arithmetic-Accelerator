@echo off
echo =====================================================================
echo   Running All AXI4-Lite IP Core and SoC Fabric Verification Suites
echo =====================================================================

REM Check for Synopsys VCS
where vcs >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Running with Synopsys VCS...
    echo [1/4] Simulating AXI4-Lite SPI Core...
    vcs -full64 -sverilog +v2k -timescale=1ns/1ps -debug_access+all -kdb -f tb_axi_spi.f -l vcs_spi_compile.log
    simv.exe -l vcs_spi_sim.log

    echo [2/4] Simulating AXI4-Lite UART Core...
    vcs -full64 -sverilog +v2k -timescale=1ns/1ps -debug_access+all -kdb -f tb_axi_uart.f -l vcs_uart_compile.log
    simv.exe -l vcs_uart_sim.log

    echo [3/4] Simulating SoC Fabric and Interconnect Routing...
    vcs -full64 -sverilog +v2k -timescale=1ns/1ps -debug_access+all -kdb -f tb_soc_fabric.f -l vcs_fabric_compile.log
    simv.exe -l vcs_fabric_sim.log

    echo [4/4] Simulating Complete Integrated SoC Top (soc_top.v ^& tb_soc_top.v)...
    vcs -full64 -sverilog +v2k -timescale=1ns/1ps -debug_access+all -kdb -f tb_soc_top.f -l vcs_top_compile.log
    simv.exe -l vcs_top_sim.log
    goto finish
)

REM Check for Icarus Verilog
where iverilog >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo [1/4] Simulating AXI4-Lite SPI Core...
    iverilog -g2012 -I axi-lite_spi-ipcore-develop/src/include -o tb_spi.vvp axi-lite_spi-ipcore-develop/tb/tb_axi_spi.v axi-lite_spi-ipcore-develop/src/rtl/*.v
    vvp tb_spi.vvp

    echo [2/4] Simulating AXI4-Lite UART Core...
    iverilog -g2012 -I axi-lite_uart-ipcore-develop/src/include -o tb_uart.vvp axi-lite_uart-ipcore-develop/tb/tb_axi_uart.v axi-lite_uart-ipcore-develop/src/rtl/*.v
    vvp tb_uart.vvp

    echo [3/4] Simulating SoC Fabric and Interconnect Routing...
    iverilog -g2012 -I axi-lite_spi-ipcore-develop/src/include -I axi-lite_uart-ipcore-develop/src/include -o tb_soc.vvp soc_modules/tb_soc_fabric.v soc_interconnect/*.v soc_modules/*.v axi-lite_spi-ipcore-develop/src/rtl/*.v axi-lite_uart-ipcore-develop/src/rtl/*.v
    vvp tb_soc.vvp

    echo [4/4] Simulating Complete Integrated SoC Top (soc_top.v ^& tb_soc_top.v)...
    iverilog -g2012 -I axi-lite_spi-ipcore-develop/src/include -I axi-lite_uart-ipcore-develop/src/include -o tb_soc_top.vvp tb_soc_top.v soc_top.v soc_interconnect/*.v soc_modules/*.v axi-lite_spi-ipcore-develop/src/rtl/*.v axi-lite_uart-ipcore-develop/src/rtl/*.v
    vvp tb_soc_top.vvp
    goto finish
)

REM Check for ModelSim / QuestaSim
where vlog >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Running with ModelSim / QuestaSim...
    if not exist work vlib work
    vlog +incdir+axi-lite_spi-ipcore-develop/src/include +incdir+axi-lite_uart-ipcore-develop/src/include axi-lite_spi-ipcore-develop/src/rtl/*.v axi-lite_spi-ipcore-develop/tb/tb_axi_spi.v axi-lite_uart-ipcore-develop/src/rtl/*.v axi-lite_uart-ipcore-develop/tb/tb_axi_uart.v soc_interconnect/*.v soc_modules/*.v soc_top.v tb_soc_top.v
    vsim -c -do "run -all; quit -f" tb_axi_spi
    vsim -c -do "run -all; quit -f" tb_axi_uart
    vsim -c -do "run -all; quit -f" tb_soc_fabric
    vsim -c -do "run -all; quit -f" tb_soc_top
    goto finish
)

echo [ERROR] No supported simulator (vcs, iverilog, vlog) found in PATH.
echo Please install or add your EDA simulator to PATH to run simulation.

:finish
pause
