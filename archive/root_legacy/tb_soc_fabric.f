// ==============================================================================
// Synopsys VCS Filelist: SoC AXI4-Lite Interconnect Fabric (tb_soc_fabric.v)
// Segregated IP-Based Architecture
// ==============================================================================

// Include search paths
+incdir+spi
+incdir+uart

// SPI IP Core RTL Files
spi/axi_spi_ctrl.v
spi/ratio_clk.v
spi/spi_clk_gen.v
spi/spi_ctrl.v
spi/spi_exch_byte.v
spi/spi_fifo.v
spi/spi_valid_logic.v
spi/axi_spi_top.v
spi/soc_spi.v

// UART IP Core RTL Files
uart/axi_internal_fifo.v
uart/uart_parity_bit_compute.v
uart/uart_transmitter.v
uart/uart_receiver.v
uart/uart_controller.v
uart/axi_uart_top.v
uart/soc_uart.v

// SoC Interconnect & Bridges
interconnect/axil_interconnect.v
interconnect/soc_axil_fabric.v
riscv_core/ahblite_to_axilite_bridge.v

// Peripherals, Memories & Accelerator
arithmetic_accelerator/arithmetic_accelerator.v
dma_controller/dma_controller.v
timer/soc_timer.v
gpio/soc_gpio.v
memories/imem_axil.v
memories/dmem_axil.v

// Testbench
interconnect/tb_soc_fabric.v
