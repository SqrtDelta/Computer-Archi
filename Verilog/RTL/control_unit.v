module control_unit(
      input  wire [6:0] opcode,
      input  wire [6:0] funct7,
      input  wire [2:0] func3,
      output reg  [1:0] alu_op,
      output reg        reg_dst,
      output reg        branch,
      output reg        mem_read,
      output reg        mem_2_reg,
      output reg        mem_write,
      output reg        alu_src,
      output reg        reg_write,
      output reg        jump,
      output reg        mult
   );

   // RISC-V opcode[6:0]
   parameter integer ALU_R      = 7'b0110011;
   parameter integer ALU_I      = 7'b0010011;
   parameter integer BRANCH_EQ  = 7'b1100011;
   parameter integer JUMP       = 7'b1101111;
   parameter integer LOAD       = 7'b0000011;
   parameter integer STORE      = 7'b0100011;

   // RISC-V ALUOp[1:0]
   parameter [1:0] ADD_OPCODE     = 2'b00;
   parameter [1:0] SUB_OPCODE     = 2'b01;
   parameter [1:0] R_TYPE_OPCODE  = 2'b10;

   always @(*) begin
      // 默认值
      alu_src   = 1'b0;
      mem_2_reg = 1'b0;
      reg_write = 1'b0;
      mem_read  = 1'b0;
      mem_write = 1'b0;
      branch    = 1'b0;
      alu_op    = R_TYPE_OPCODE;
      jump      = 1'b0;
      mult      = 1'b0;
      
      case(opcode)
         ALU_R: begin
            alu_src   = 1'b0;
            mem_2_reg = 1'b0;
            reg_write = 1'b1;
            mem_read  = 1'b0;
            mem_write = 1'b0;
            branch    = 1'b0;
            alu_op    = R_TYPE_OPCODE;
            jump      = 1'b0;
            // 检测是否为 MULT 指令：funct7 == 0000001 且 func3 == 000
            if (funct7 == 7'b0000001 && func3 == 3'b000)
                mult = 1'b1;
            else
                mult = 1'b0;
         end
         ALU_I: begin
            alu_src   = 1'b1;
            mem_2_reg = 1'b0;
            reg_write = 1'b1;
            mem_read  = 1'b0;
            mem_write = 1'b0;
            branch    = 1'b0;
            alu_op    = ADD_OPCODE; // 用于立即数加法
            jump      = 1'b0;
            mult      = 1'b0;
         end
         LOAD: begin
            alu_src   = 1'b1;
            mem_2_reg = 1'b1;
            reg_write = 1'b1;
            mem_read  = 1'b1;
            mem_write = 1'b0;
            branch    = 1'b0;
            alu_op    = ADD_OPCODE; // 地址计算
            jump      = 1'b0;
            mult      = 1'b0;
         end
         STORE: begin
            alu_src   = 1'b1;
            mem_2_reg = 1'b0; // 无关紧要
            reg_write = 1'b0;
            mem_read  = 1'b0;
            mem_write = 1'b1;
            branch    = 1'b0;
            alu_op    = ADD_OPCODE; // 地址计算
            jump      = 1'b0;
            mult      = 1'b0;
         end
         BRANCH_EQ: begin
            alu_src   = 1'b0;
            mem_2_reg = 1'b0; // 无关紧要
            reg_write = 1'b0;
            mem_read  = 1'b0;
            mem_write = 1'b0;
            branch    = 1'b1;
            alu_op    = SUB_OPCODE; // 用于比较
            jump      = 1'b0;
            mult      = 1'b0;
         end
         JUMP: begin
            alu_src   = 1'b0; // 无关紧要
            mem_2_reg = 1'b0; // 无关紧要
            reg_write = 1'b1; // 写回返回地址（可选）
            mem_read  = 1'b0;
            mem_write = 1'b0;
            branch    = 1'b0;
            alu_op    = ADD_OPCODE; // 用于跳转地址计算
            jump      = 1'b1;
            mult      = 1'b0;
         end
         default: begin
            alu_src   = 1'b0;
            mem_2_reg = 1'b0;
            reg_write = 1'b0;
            mem_read  = 1'b0;
            mem_write = 1'b0;
            branch    = 1'b0;
            alu_op    = R_TYPE_OPCODE;
            jump      = 1'b0;
            mult      = 1'b0;
         end
      endcase
   end

endmodule

