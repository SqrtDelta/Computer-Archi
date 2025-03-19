// OpenRAM SRAM model
// Words: 128
// Word size: 32

module sky130_sram_2rw_32x128_32(
`ifdef USE_POWER_PINS
    vccd1,
    vssd1,
`endif
// Port 0: RW
    clk0,csb0,web0,addr0,din0,dout0,
// Port 1: RW
    clk1,csb1,web1,addr1,din1,dout1
  );

  parameter DATA_WIDTH = 32 ;
  parameter ADDR_WIDTH = 7 ;
  parameter RAM_DEPTH = 1 << ADDR_WIDTH;
  // FIXME: This delay is arbitrary.
  parameter DELAY = 0 ;
  parameter VERBOSE = 1 ; //Set to 0 to only display warnings
  parameter T_HOLD = 1 ; //Delay to hold dout value after posedge. Value is arbitrary

`ifdef USE_POWER_PINS
    inout vccd1;
    inout vssd1;
`endif
  input  clk0; // clock
  input   csb0; // active low chip select
  input  web0; // active low write control
  input [ADDR_WIDTH-1:0]  addr0;
  input [DATA_WIDTH-1:0]  din0;
  output [DATA_WIDTH-1:0] dout0;
  input  clk1; // clock
  input   csb1; // active low chip select
  input  web1; // active low write control
  input [ADDR_WIDTH-1:0]  addr1;
  input [DATA_WIDTH-1:0]  din1;
  output [DATA_WIDTH-1:0] dout1;

  reg [DATA_WIDTH-1:0]  dout0;
  reg [DATA_WIDTH-1:0]  dout1;

  reg [DATA_WIDTH-1:0]    mem [0:RAM_DEPTH-1];

  // Memory Write Block Port 0
  // Write Operation : When web0 = 0, csb0 = 0
  always @ (posedge clk0)
  begin : MEM_WRITE0
    if ( !csb0 && !web0 ) begin
        mem[addr0][31:0] <= din0[31:0];
    end
  end

  // Memory Read Block Port 0
  // Read Operation : When web0 = 1, csb0 = 0
  always @ (csb0 or web0 or mem[addr0])
  begin : MEM_READ0
    if (!csb0 && web0)
       dout0 = mem[addr0];
    else
       dout0 = 'bx;
  end

  // Memory Write Block Port 1
  // Write Operation : When web1 = 0, csb1 = 0
  always @ (posedge clk1)
  begin : MEM_WRITE1
    if ( !csb1 && !web1 ) begin
        mem[addr1][31:0] <= din1[31:0];
    end
  end

  // Memory Read Block Port 1
  // Read Operation : When web1 = 1, csb1 = 0
  always @ (csb1 or web1 or mem[addr1])
  begin : MEM_READ1
    if (!csb1 && web1)
       dout1 = mem[addr1];
    else
       dout1 = 'bx;
  end

endmodule


// OpenRAM SRAM model
// Words: 128
// Word size: 64

module sky130_sram_2rw_64x128_64(
`ifdef USE_POWER_PINS
    vccd1,
    vssd1,
`endif
// Port 0: RW
    clk0,csb0,web0,addr0,din0,dout0,
// Port 1: RW
    clk1,csb1,web1,addr1,din1,dout1
  );

  parameter DATA_WIDTH = 64 ;
  parameter ADDR_WIDTH = 7 ;
  parameter RAM_DEPTH = 1 << ADDR_WIDTH;
  // FIXME: This delay is arbitrary.
  parameter DELAY = 0 ;
  parameter VERBOSE = 1 ; //Set to 0 to only display warnings
  parameter T_HOLD = 1 ; //Delay to hold dout value after posedge. Value is arbitrary

`ifdef USE_POWER_PINS
    inout vccd1;
    inout vssd1;
`endif
  input  clk0; // clock
  input   csb0; // active low chip select
  input  web0; // active low write control
  input [ADDR_WIDTH-1:0]  addr0;
  input [DATA_WIDTH-1:0]  din0;
  output [DATA_WIDTH-1:0] dout0;
  input  clk1; // clock
  input   csb1; // active low chip select
  input  web1; // active low write control
  input [ADDR_WIDTH-1:0]  addr1;
  input [DATA_WIDTH-1:0]  din1;
  output [DATA_WIDTH-1:0] dout1;

  reg [DATA_WIDTH-1:0]  dout0;
  reg [DATA_WIDTH-1:0]  dout1;
  reg [DATA_WIDTH-1:0]    mem [0:RAM_DEPTH-1];

  // Memory Write Block Port 0
  // Write Operation : When web0 = 0, csb0 = 0
  always @ (posedge clk0)
  begin : MEM_WRITE0
    if ( !csb0 && !web0 ) begin
        mem[addr0][63:0] = din0[63:0];
    end
  end

  // Memory Read Block Port 0
  // Read Operation : When web0 = 1, csb0 = 0
  always @ (csb0 or web0 or mem[addr0])
  begin : MEM_READ0
    if (!csb0 && web0)
       dout0 = mem[addr0];
    else
       dout0 = 'bx;
  end

  // Memory Write Block Port 1
  // Write Operation : When web1 = 0, csb1 = 0
  always @ (posedge clk1)
  begin : MEM_WRITE1
    if ( !csb1 && !web1 ) begin
        mem[addr1][63:0] = din1[63:0];
    end
  end

  // Memory Read Block Port 1
  // Read Operation : When web1 = 1, csb1 = 0
  always @ (csb1 or web1 or mem[addr1])
  begin : MEM_READ1
    if (!csb1 && web1)
       dout1 = mem[addr1];
    else
       dout1 = 'bx;
  end

endmodule
