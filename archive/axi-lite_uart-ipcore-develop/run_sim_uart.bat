@echo off
echo ===================================================
echo   Compiling and Running AXI4-Lite UART Testbench
echo ===================================================

REM Check for Icarus Verilog
where iverilog >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Using Icarus Verilog...
    iverilog -g2012 -I src/include -o tb_axi_uart.vvp tb/tb_axi_uart.v src/rtl/axi_uart_top.v src/rtl/uart_controller.v src/rtl/uart_transmitter.v src/rtl/uart_receiver.v src/rtl/axi_internal_fifo.v src/rtl/uart_parity_bit_compute.v
    vvp tb_axi_uart.vvp
    goto end
)

REM Check for ModelSim / QuestaSim
where vlog >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Using ModelSim / QuestaSim...
    vlib work
    vlog +incdir+src/include src/rtl/*.v tb/tb_axi_uart.v
    vsim -c -do "run -all; quit -f" tb_axi_uart
    goto end
)

REM Check for Vivado xsim
where xvlog >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Using Vivado Simulator (xsim)...
    xvlog -i src/include src/rtl/*.v tb/tb_axi_uart.v
    xelab -top tb_axi_uart -snapshot tb_axi_uart_snap
    xsim tb_axi_uart_snap -R
    goto end
)

echo [ERROR] No supported simulator (iverilog, vlog, xvlog) found in PATH.
echo Please add your Verilog simulator (Vivado, ModelSim, or Icarus Verilog) to your PATH.

:end
pause
