@echo off
echo =====================================================================
echo   Simulating Full SoC Top-Level Module (soc_top.v ^& tb_soc_top.v)
echo =====================================================================

REM Check for Synopsys VCS
where vcs >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Compiling and running with Synopsys VCS...
    vcs -full64 -sverilog +v2k -timescale=1ns/1ps -debug_access+all -kdb -f tb_soc_top.f -l vcs_top_compile.log
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] VCS Compilation failed!
        pause
        exit /b 1
    )
    simv.exe -l vcs_top_sim.log
    goto finish
)

REM Check for Icarus Verilog
where iverilog >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Compiling with Icarus Verilog...
    iverilog -g2012 -I axi-lite_spi-ipcore-develop/src/include -I axi-lite_uart-ipcore-develop/src/include -o tb_soc_top.vvp tb_soc_top.v soc_top.v soc_interconnect/*.v soc_modules/*.v axi-lite_spi-ipcore-develop/src/rtl/*.v axi-lite_uart-ipcore-develop/src/rtl/*.v
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Compilation failed!
        pause
        exit /b 1
    )
    echo Running simulation...
    vvp tb_soc_top.vvp
    goto finish
)

REM Check for ModelSim / QuestaSim
where vlog >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Compiling and running with ModelSim / QuestaSim...
    if not exist work vlib work
    vlog +incdir+axi-lite_spi-ipcore-develop/src/include +incdir+axi-lite_uart-ipcore-develop/src/include axi-lite_spi-ipcore-develop/src/rtl/*.v axi-lite_uart-ipcore-develop/src/rtl/*.v soc_interconnect/*.v soc_modules/*.v soc_top.v tb_soc_top.v
    vsim -c -do "run -all; quit -f" tb_soc_top
    goto finish
)

REM Check for Xilinx Vivado xsim
where xvlog >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Compiling and running with Vivado xsim...
    xvlog -i axi-lite_spi-ipcore-develop/src/include -i axi-lite_uart-ipcore-develop/src/include axi-lite_spi-ipcore-develop/src/rtl/*.v axi-lite_uart-ipcore-develop/src/rtl/*.v soc_interconnect/*.v soc_modules/*.v soc_top.v tb_soc_top.v
    xelab -top tb_soc_top -snapshot tb_soc_top_snap
    xsim tb_soc_top_snap -runall
    goto finish
)

echo [ERROR] No supported simulator (vcs, iverilog, vlog, xvlog) found in PATH.
echo Please add your Verilog simulator to the Windows PATH.

:finish
pause
