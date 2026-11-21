@echo off
REM ==============================================================================
REM Synopsys VCS Simulation Runner for Windows / WSL
REM ==============================================================================

echo =====================================================================
echo   Synopsys VCS Simulation Runner (Windows / WSL Wrapper)
echo =====================================================================

REM 1. Check for native Windows vcs.exe
where vcs >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo [INFO] Found native Synopsys VCS in PATH.
    echo Compiling and running full SoC Top Module...
    vcs -full64 -sverilog +v2k -timescale=1ns/1ps -debug_access+all -kdb -f tb_soc_top.f -l vcs_top_compile.log
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] VCS Compilation failed! Check vcs_top_compile.log
        pause
        exit /b 1
    )
    simv.exe -l vcs_top_sim.log
    goto finish
)

REM 2. Check for Windows Subsystem for Linux (WSL) with VCS installed
where wsl >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo [INFO] WSL detected. Attempting to run via WSL Synopsys VCS...
    wsl which vcs >nul 2>&1
    if %ERRORLEVEL% == 0 (
        echo Running ./run_vcs.sh inside WSL...
        wsl bash -c "chmod +x run_vcs.sh && ./run_vcs.sh top"
        goto finish
    )
)

echo [ERROR] 'vcs' executable not found in Windows PATH or WSL.
echo.
echo If running on a Linux server or remote EDA cluster:
echo   1. Copy or push this project folder to your Linux server.
echo   2. Source your Synopsys license/environment:
echo        source /path/to/synopsys/env.sh
echo   3. Run using either Make or the script:
echo        make top
echo      OR:
echo        chmod +x run_vcs.sh
echo        ./run_vcs.sh top
echo.
echo To run all 4 testbenches:
echo        make all
echo.

:finish
pause
