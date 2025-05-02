//Branch Unit
//Function: Calculate the next pc in the case of a control instruction (branch or jump).
//Inputs:
//instruction: Instruction currently processed. The least significant bits are used for the calcualting the target pc in the case of a jump instruction. 
//immediate_extended: Offset for a branch/jump instruction. 
//Outputs: 
//branch_pc: Target PC in the case of a branch instruction.
//jump_pc: Target PC in the case of a jump instruction.

module branch_unit#(
   parameter integer DATA_W     = 16
   )(
      input  wire signed [DATA_W-1:0]  current_pc,
      input  wire signed [DATA_W-1:0]  immediate_extended,
      output reg  signed [DATA_W-1:0]  branch_pc,
      output reg  signed [DATA_W-1:0]  jump_pc
   );

   always@(*) branch_pc           = current_pc + immediate_extended;
   always@(*) jump_pc             = current_pc + immediate_extended;
  
endmodule



