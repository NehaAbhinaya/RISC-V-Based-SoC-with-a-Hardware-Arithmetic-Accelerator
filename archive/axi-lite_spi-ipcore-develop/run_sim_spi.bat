@echo off
echo ===================================================
echo   Compiling and Running AXI4-Lite SPI Testbench
echo ===================================================

REM Check for Icarus Verilog
where iverilog >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Using Icarus Verilog...
    iverilog -g2012 -I src/include -o tb_axi_spi.vvp tb/tb_axi_spi.v src/rtl/axi_spi_top.v src/rtl/axi_spi_ctrl.v src/rtl/spi_ctrl.v src/rtl/spi_clk_gen.v src/rtl/ratio_clk.v src/rtl/spi_exch_byte.v src/rtl/spi_fifo.v src/rtl/spi_valid_logic.v
    vvp tb_axi_spi.vvp
    goto end
)

REM Check for ModelSim / QuestaSim
where vlog >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Using ModelSim / QuestaSim...
    vlib work
    vlog +incdir+src/include src/rtl/*.v tb/tb_axi_spi.v
    vsim -c -do "run -all; quit -f" tb_axi_spi
    goto end
)

REM Check for Vivado xsim
where xvlog >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Using Vivado Simulator (xsim)...
    xvlog -i src/include src/rtl/*.v tb/tb_axi_spi.v
    xelab -top tb_axi_spi -snapshot tb_axi_spi_snap
    xsim tb_axi_spi_snap -R
    goto end
)

echo [ERROR] No supported simulator (iverilog, vlog, xvlog) found in PATH.
echo Please add your Verilog simulator (Vivado, ModelSim, or Icarus Verilog) to your PATH.

:end
pause
