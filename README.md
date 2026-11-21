# Design Verification Laboratory Record — Supporting Files & Simulation Guide

**Student Name:** R. Neha Abhinaya  
**Roll Number:** 1602-23-735-160  
**Branch:** B.E. Electronics and Communication Engineering  
**College:** Vasavi College of Engineering (Autonomous), Hyderabad  
**Department:** Department of Electronics and Communication Engineering  
**Project Title:** Design and Verification of a RISC-V Based SoC with a Hardware Arithmetic Accelerator  

---

## 1. Executive Summary & Verification Matrix

This repository directory contains the complete supporting files, testbenches, simulation scripts, firmware, waveforms, and documentation for all ten experiments of the Design Verification Laboratory Record.

| Exp | Title | Primary RTL / Target | Testbench / BFM | Simulation Environment | Status | Waveform Status |
|:---:|:---|:---|:---|:---|:---:|:---:|
| **1** | Verification of I2C IP | *Absent in Repo* | Directed I2C Master BFM | Educational Reference | **BLOCKED** | Illustrative (Labeled) |
| **2** | Verification of AXI IP | `axil_interconnect.v` / `soc_axil_fabric.v` | `tb_soc_fabric.v` | Synopsys VCS U-2023.03 | **PASS** | Genuine VCS Simulation |
| **3** | Verification of AES IP | *Absent in Repo* | AXI4-Lite AES Testbench | Educational Reference | **BLOCKED** | Illustrative (Labeled) |
| **4** | Verification of UART IP | `axi_uart_top.v` / `soc_uart.v` | `tb_axi_uart.v` | Synopsys VCS U-2023.03 | **PASS** | Genuine VCS Simulation |
| **5** | Git Repository Setup | Git / GitHub Flow | Git CLI / Hooks | Linux / Windows | **PASS** | N/A (Doc Complete) |
| **6** | RISC-V Toolchain Setup | GNU GCC 13.2 / xPack | `verify_toolchain.sh` | Linux / Windows | **PASS** | N/A (Doc Complete) |
| **7** | RISC-V C Test Compilation | `startup.s`, `link.ld`, `main.c` | Bare-metal Linker Flow | GCC + bin2hex.py | **PASS** | Disassembly / Hex |
| **8** | SoC RTL Integration C Test | `soc_top.v` (All IPs + VeeR EL2) | `tb_soc_ctest.v` / `tb_soc_top.v` | Synopsys VCS U-2023.03 | **PASS** | Genuine VCS Simulation |
| **9** | UVM VIP Generation | 6 CSV Interface Specs | `uvm_full_tb_generator.py` | Python 3 + SystemVerilog | **PASS** | Syntax Verified |
| **10** | UVM VIP Test Development | `tb_soc_uvm_top.sv` (SoC DUT) | `uart_connectivity_test.sv` | Synopsys VCS + UVM-1.1d | **PASS** | Genuine VCS VCD / FSDB |

---

## 2. Directory Structure

```text
Lab_Record_Deliverables/
├── Neha_Abhinaya_Design_Verification_Lab_Record.pdf   # Complete 10-experiment lab record (PDF)
├── Neha_Abhinaya_Design_Verification_Lab_Record.docx  # Complete editable Word document (DOCX)
├── README.md                                          # This verification and reproduction guide
├── waveforms/                                         # Standalone PNG waveform figures (16 figures)
│   ├── fig1_1_i2c_write.png
│   ├── fig1_2_i2c_read.png
│   ├── fig2_1_axi_write_read.png
│   ├── fig2_2_axi_decerr.png
│   ├── fig2_3_axi_multimaster.png
│   ├── fig3_1_aes_encryption.png
│   ├── fig3_2_aes_decryption.png
│   ├── fig4_1_uart_csr_config.png
│   ├── fig4_2_uart_serial_loopback.png
│   ├── fig8_1_soc_boot_imem.png
│   ├── fig8_2_soc_accel_direct.png
│   ├── fig8_3_soc_dma_stream.png
│   ├── fig8_4_soc_uart_pass.png
│   ├── fig10_1_uvm_env_overview.png
│   ├── fig10_2_uvm_uart_serial.png
│   └── fig10_3_uvm_dut_hardware.png
├── exp01_i2c/                                         # Exp 1: I2C protocol specification & audit
├── exp02_axi/                                         # Exp 2: AXI4-Lite fabric RTL, TB & VCS logs
├── exp03_aes/                                         # Exp 3: AES-128 FIPS-197 specification & audit
├── exp04_uart/                                        # Exp 4: AXI4-Lite UART core RTL, TB & VCS logs
├── exp05_github/                                      # Exp 5: EDA .gitignore & Git setup scripts
├── exp06_toolchain/                                   # Exp 6: RISC-V toolchain verification scripts
├── exp07_c_compilation/                               # Exp 7: Firmware source, linker script & hex
├── exp08_soc_integration/                             # Exp 8: Full SoC RTL, C-test bench & VCS logs
├── exp09_uvm_vip_generation/                          # Exp 9: 6 CSV definitions & VIP interfaces
└── exp10_uvm_vip_test/                                # Exp 10: SoC UVM environment, test & VCD/FSDB
```

---

## 3. How to Reproduce Simulations

### Environment Prerequisites
- **Synopsys VCS:** Version U-2023.03 or newer (`vcs`, `simv`)
- **Synopsys Verdi:** Version U-2023.03-SP1 or newer (`verdi`)
- **RISC-V Cross-Compiler:** `riscv64-unknown-elf-gcc` (multilib with `rv32im/ilp32`)
- **Python:** Python 3.8+ (for `bin2hex.py` and `uvm_full_tb_generator.py`)

### Experiment 2: AXI4-Lite Interconnect Verification
```bash
cd exp02_axi
vcs -full64 -sverilog +v2k -timescale=1ns/1ps -notice -f tb_soc_fabric.f -l vcs_fabric_compile.log
./simv -l vcs_fabric_sim.log
```

### Experiment 4: UART IP Verification
```bash
cd exp04_uart
vcs -full64 -sverilog +v2k -timescale=1ns/1ps -notice +incdir+. -f tb_axi_uart.f -l vcs_uart_compile.log
./simv -l vcs_uart_sim.log
```

### Experiment 7: Bare-Metal C Compilation
```bash
cd exp07_c_compilation
make clean
make
# Generates soc_firmware.elf, soc_firmware.hex, and soc_firmware.dis
```

### Experiment 8: Full SoC Integration C-Test Execution
```bash
cd exp08_soc_integration
# Rebuild firmware if needed
make -C ../exp07_c_compilation
cp ../exp07_c_compilation/soc_firmware.hex .

# Run C-Test simulation with Synopsys VCS
./run_vcs.sh ctest_fsdb

# Inspect waveform in Synopsys Verdi
./run_vcs.sh ctest_verdi
```

### Experiment 9: UVM VIP Generation
```bash
cd exp09_uvm_vip_generation
python3 uvm_full_tb_generator.py arithmetic_accelerator arithmetic_accelerator.csv
python3 uvm_full_tb_generator.py dma dma.csv
python3 uvm_full_tb_generator.py gpio gpio.csv
python3 uvm_full_tb_generator.py spi spi.csv
python3 uvm_full_tb_generator.py timer timer.csv
python3 uvm_full_tb_generator.py uart uart.csv
```

### Experiment 10: SoC-Level UVM VIP Verification
```bash
cd exp10_uvm_vip_test
./run_soc_uvm.sh
# Dumps soc_uart.fsdb and soc_uart_waveform.vcd, verified against uart_verdi.rc
```
