// rtl/forwarding_unit.v
// 转发单元，生成 forwardA/forwardB
module forwarding_unit(
    input  wire [4:0] rs1_ID_EX,
    input  wire [4:0] rs2_ID_EX,
    input  wire [4:0] rd_EX_MEM,
    input  wire [4:0] rd_MEM_WB,
    input  wire       reg_write_EX_MEM,
    input  wire       reg_write_MEM_WB,
    output reg  [1:0] forwardA,
    output reg  [1:0] forwardB
);
    always @(*) begin
        // 默认不转发
        forwardA = 2'b00;
        forwardB = 2'b00;
        // EX/MEM -> EX 优先
        if (reg_write_EX_MEM && (rd_EX_MEM != 5'b0)) begin
            if (rd_EX_MEM == rs1_ID_EX) forwardA = 2'b01;
            if (rd_EX_MEM == rs2_ID_EX) forwardB = 2'b01;
        end
        // MEM/WB -> EX
        if (reg_write_MEM_WB && (rd_MEM_WB != 5'b0)) begin
            if ((forwardA == 2'b00) && (rd_MEM_WB == rs1_ID_EX)) forwardA = 2'b10;
            if ((forwardB == 2'b00) && (rd_MEM_WB == rs2_ID_EX)) forwardB = 2'b10;
        end
    end
endmodule
