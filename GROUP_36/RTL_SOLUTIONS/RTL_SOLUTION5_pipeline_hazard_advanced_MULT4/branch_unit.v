// rtl/branch_unit.v
module branch_unit#(
   parameter integer DATA_W     = 16
)(
      input  wire signed [DATA_W-1:0]  current_pc,
      input  wire signed [DATA_W-1:0]  immediate_extended,
      output reg  signed [DATA_W-1:0]  branch_pc,
      output reg  signed [DATA_W-1:0]  jump_pc
   );

   always @(*) branch_pc = current_pc + immediate_extended;
   always @(*) jump_pc   = current_pc + immediate_extended;
endmodule
