/* ==============================================================================
 * Project        : RISC-V VeeR EL2 SoC with Hardware Arithmetic Accelerator
 * VIP            : SPI VIP
 * File           : spi_env.sv
 * Description    : SPI UVM Environment integrating Agent and Scoreboard.
 * ============================================================================== */

`ifndef SPI_ENV_SV
`define SPI_ENV_SV

class spi_env extends uvm_env;
  spi_agent      agent;
  spi_scoreboard sb;

  `uvm_component_utils(spi_env)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = spi_agent::type_id::create("agent", this);
    sb    = spi_scoreboard::type_id::create("sb", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.mon.ap.connect(sb.mon_export);
  endfunction

endclass

`endif // SPI_ENV_SV
