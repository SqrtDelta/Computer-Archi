// rtl/hazard_detection_unit.v
module hazard_detection_unit (
    input  wire        mem_read_ID_EX,  // ID/EX 阶段是否为 load
    input  wire [4:0]  rs1_IF_ID,       // IF/ID 阶段指令的 rs1
    input  wire [4:0]  rs2_IF_ID,       // IF/ID 阶段指令的 rs2
    input  wire [4:0]  rd_ID_EX,        // ID/EX 阶段指令的 rd
    output reg         pc_write,        // PC 寄存器写使能
    output reg         control_stall    // 在 ID/EX 注入气泡
);
    always @(*) begin
        if (mem_read_ID_EX && ((rd_ID_EX == rs1_IF_ID) || (rd_ID_EX == rs2_IF_ID))) begin
            pc_write      = 1'b0;   // 冻结 PC
            control_stall = 1'b1;   // 注入 EX 级气泡
        end else begin
            pc_write      = 1'b1;
            control_stall = 1'b0;
        end
    end
endmodule
