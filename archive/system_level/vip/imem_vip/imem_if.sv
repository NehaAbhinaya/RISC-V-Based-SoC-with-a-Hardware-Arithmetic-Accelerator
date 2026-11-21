interface imem_if;
  logic clk;
  logic rst_n;
  logic [31:0] araddr;
  logic [2:0] arprot;
  logic arvalid;
  logic arready;
  logic [31:0] rdata;
  logic [1:0] rresp;
  logic rvalid;
  logic rready;
endinterface
