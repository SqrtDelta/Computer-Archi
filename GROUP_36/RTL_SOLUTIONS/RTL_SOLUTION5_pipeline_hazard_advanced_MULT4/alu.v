module alu #(
   parameter integer DATA_W = 16
   )(
      input   wire signed [DATA_W-1:0] alu_in_0,
      input   wire signed [DATA_W-1:0] alu_in_1,
      input   wire        [3:0] alu_ctrl,
      output  reg  signed [DATA_W-1:0] alu_out,
      output  reg         zero_flag,
      output  reg         overflow
   );

   // ALU 控制码定义
   parameter [3:0] AND_OP = 4'd0;
   parameter [3:0] OR_OP  = 4'd1;
   parameter [3:0] ADD_OP = 4'd2;
   parameter [3:0] SLL_OP = 4'd3;
   parameter [3:0] SRL_OP = 4'd4;
   parameter [3:0] SUB_OP = 4'd6;
   parameter [3:0] SLT_OP = 4'd7;
   parameter [3:0] MUL_OP = 4'd8;  // 新增乘法操作

   reg signed [DATA_W-1:0] sub_out, add_out, and_out, or_out, sll_out, srl_out, slt_out;
   reg overflow_add, overflow_sub, msb_equal_flag;
   
   // zero_flag 逻辑
   always @(*) begin
      if(alu_out == 0)
         zero_flag = 1'b1;
      else
         zero_flag = 1'b0;
   end

   // 算术与逻辑运算
   always @(*) begin
      add_out = alu_in_0 + alu_in_1;
      sll_out = alu_in_0 << alu_in_1;
      srl_out = alu_in_0 >> alu_in_1;
      sub_out = alu_in_0 - alu_in_1;
      and_out = alu_in_0 & alu_in_1;
      or_out  = alu_in_0 | alu_in_1;
      slt_out = (alu_in_0 < alu_in_1) ? 1 : 0;
   end

   // 根据 alu_ctrl 选择输出
   always @(*) begin
      case (alu_ctrl)
         AND_OP:  alu_out = and_out;
         OR_OP:   alu_out = or_out;
         ADD_OP:  alu_out = add_out;
         SUB_OP:  alu_out = sub_out;
         SLT_OP:  alu_out = slt_out;
         SLL_OP:  alu_out = sll_out;
         SRL_OP:  alu_out = srl_out;
         MUL_OP:  alu_out = alu_in_0 * alu_in_1;  // 一周期乘法实现
         default: alu_out = 0;
      endcase
   end

   // 检测 MSB 是否相等，用于溢出检测
   always @(*) begin
      if(alu_in_0[DATA_W-1] == alu_in_1[DATA_W-1])
         msb_equal_flag = 1'b1;
      else
         msb_equal_flag = 1'b0;
   end
   
   always @(*) begin
      if((msb_equal_flag == 1'b1) && (add_out[DATA_W-1] != alu_in_0[DATA_W-1]))
         overflow_add = 1'b1;
      else
         overflow_add = 1'b0;
   end

   always @(*) begin
      if((msb_equal_flag == 1'b1) && (sub_out[DATA_W-1] != alu_in_0[DATA_W-1]))
         overflow_sub = 1'b1;
      else
         overflow_sub = 1'b0;
   end

   always @(*) begin
      if(alu_ctrl == ADD_OP)
         overflow = overflow_add;
      else if(alu_ctrl == SUB_OP)
         overflow = overflow_sub;
      else
         overflow = 1'b0;  // 其他操作认为无溢出
   end

endmodule

