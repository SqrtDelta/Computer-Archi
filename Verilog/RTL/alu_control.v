module alu_control(
      input wire [6:0] funct7,
      input wire [2:0] func3,
      input wire [1:0] alu_op,
      // input wire       mult,
      output reg [3:0] alu_control
   );

   // ALUOp 对应编码
   parameter [1:0] ADD_OPCODE    = 2'b00;
   parameter [1:0] SUB_OPCODE    = 2'b01;
   parameter [1:0] R_TYPE_OPCODE = 2'b10;

   // ALU 控制码定义（参考书中描述）
   parameter [3:0] AND_OP        = 4'd0;
   parameter [3:0] OR_OP         = 4'd1;
   parameter [3:0] ADD_OP        = 4'd2;
   parameter [3:0] SLL_OP        = 4'd3;
   parameter [3:0] SRL_OP        = 4'd4;
   parameter [3:0] SUB_OP        = 4'd6;
   parameter [3:0] SLT_OP        = 4'd7;
   // parameter [3:0] MUL_OP        = 4'd8;  // 新的乘法操作

   reg [3:0] rtype_op;
   
   always @(*) begin
      // if(mult)
      //    rtype_op = MUL_OP;
      // else begin
         case({funct7[5], func3})
            4'b0000: rtype_op = ADD_OP;  // add
            4'b1000: rtype_op = SUB_OP;  // sub
            4'b0111: rtype_op = AND_OP;  // and
            4'b0110: rtype_op = OR_OP;   // or
            4'b0010: rtype_op = SLT_OP;  // slt
            4'b0001: rtype_op = SLL_OP;  // sll
            4'b0101: rtype_op = SRL_OP;  // srl
            default: rtype_op = 4'd0;
         endcase
      // end
   end

   always @(*) begin
      case(alu_op)
         ADD_OPCODE    : alu_control = ADD_OP;   // 对于 ALU_I、LOAD、STORE
         SUB_OPCODE    : alu_control = SUB_OP;   // 对于 BRANCH_EQ
         R_TYPE_OPCODE : alu_control = rtype_op;
         default       : alu_control = 4'b0;
      endcase
   end

endmodule

