`timescale 1ns / 1ps

/* -------------------------------------------------------------------------------
 * Project        : RISC-V SoC with Hardware Arithmetic Accelerator
 * File           : imem_axil.v
 * Description    : AXI4-Lite Instruction Memory (Section 4, Page 10)
 *                  - 64 KB capacity (16K x 32-bit words)
 *                  - Read-only via fabric (awready, wready tied low)
 *                  - Simulation firmware loading via $readmemh
 *                  - Read address decoded using araddr[15:2]
 * -------------------------------------------------------------------------------*/

`default_nettype none

module imem_axil #(
  parameter MEM_SIZE_BYTES = 64 * 1024,
  parameter WORDS          = MEM_SIZE_BYTES / 4,
  parameter INIT_FILE      = "soc_firmware.hex"
)(
  input wire clk,
  input wire rst_n,

  // AXI4-Lite Write Interface (Tied off as read-only)
  input  wire [31:0] awaddr,
  input  wire [2:0]  awprot,
  input  wire        awvalid,
  output wire        awready,

  input  wire [31:0] wdata,
  input  wire [3:0]  wstrb,
  input  wire        wvalid,
  output wire        wready,

  output wire [1:0]  bresp,
  output wire        bvalid,
  input  wire        bready,

  // AXI4-Lite Read Interface
  input  wire [31:0] araddr,
  input  wire [2:0]  arprot,
  input  wire        arvalid,
  output reg         arready,

  output reg  [31:0] rdata,
  output reg  [1:0]  rresp,
  output reg         rvalid,
  input  wire        rready
);

  // Write channel is disabled/tied off per specification
  assign awready = 1'b0;
  assign wready  = 1'b0;
  assign bresp   = 2'b11; // DECERR if reached
  assign bvalid  = 1'b0;

  // 16K x 32-bit Memory Array
  reg [31:0] mem [0:WORDS-1];

  integer fd;
  reg [1023:0] init_file_str;
  initial begin
    if ($value$plusargs("IMEM_INIT=%s", init_file_str)) begin
      $display("[IMEM] Loading simulation firmware from plusarg: %0s", init_file_str);
      $readmemh(init_file_str, mem);
    end else if (INIT_FILE != "") begin
      fd = $fopen(INIT_FILE, "r");
      if (fd != 0) begin
        $fclose(fd);
        $display("[IMEM] Loading simulation firmware from: %0s", INIT_FILE);
        $readmemh(INIT_FILE, mem);
      end else begin
        fd = $fopen({"../firmware/", INIT_FILE}, "r");
        if (fd != 0) begin
          $fclose(fd);
          $display("[IMEM] Loading simulation firmware from: ../firmware/%0s", INIT_FILE);
          $readmemh({"../firmware/", INIT_FILE}, mem);
        end else begin
          fd = $fopen({"firmware/", INIT_FILE}, "r");
          if (fd != 0) begin
            $fclose(fd);
            $display("[IMEM] Loading simulation firmware from: firmware/%0s", INIT_FILE);
            $readmemh({"firmware/", INIT_FILE}, mem);
          end else begin
            $display("[IMEM] Warning: Firmware file '%0s' not found.", INIT_FILE);
          end
        end
      end
    end
  end

  // Read Channel
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      arready <= 1'b1;
      rvalid  <= 1'b0;
      rdata   <= 32'h0;
      rresp   <= 2'b00;
    end else begin
      if (arvalid && arready) begin
        arready <= 1'b0;
        rvalid  <= 1'b1;
        rresp   <= 2'b00; // OKAY
        rdata   <= mem[araddr[15:2]];
      end else if (rvalid && rready) begin
        rvalid  <= 1'b0;
        arready <= 1'b1;
      end
    end
  end

endmodule

`default_nettype wire
