// rtl/forwarding_unit.v
module forwarding_unit(
    input  wire [4:0] rs1_ID_EX,
    input  wire [4:0] rs2_ID_EX,
    input  wire [4:0] rd_EX_MEM,
    input  wire [4:0] rd_MEM_WB,
    input  wire       reg_write_EX_MEM,
    input  wire       mem_read_EX_MEM,   // 新增：Load 标志
    input  wire       reg_write_MEM_WB,
    output reg  [1:0] forwardA,
    output reg  [1:0] forwardB
);

    always @(*) begin
        forwardA = 2'b00;
        forwardB = 2'b00;
        // 只对非 Load 的 EX/MEM 做转发
        if (reg_write_EX_MEM && !mem_read_EX_MEM && (rd_EX_MEM != 5'b0)) begin
            if (rd_EX_MEM == rs1_ID_EX) forwardA = 2'b01;
            if (rd_EX_MEM == rs2_ID_EX) forwardB = 2'b01;
        end
        // MEM/WB 阶段一律可转发（包括 Load 结果）
        if (reg_write_MEM_WB && (rd_MEM_WB != 5'b0)) begin
            if ((forwardA == 2'b00) && (rd_MEM_WB == rs1_ID_EX)) forwardA = 2'b10;
            if ((forwardB == 2'b00) && (rd_MEM_WB == rs2_ID_EX)) forwardB = 2'b10;
        end
    end
endmodule
