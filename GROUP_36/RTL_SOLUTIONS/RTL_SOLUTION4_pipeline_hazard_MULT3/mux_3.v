// rtl/mux_3.v
// 3:1 复用器，用于转发逻辑
module mux_3 #(
    parameter integer DATA_W = 16
)(
    input  wire [DATA_W-1:0] input0,   // 寄存器堆读出
    input  wire [DATA_W-1:0] input1,   // EX/MEM 的 ALU 结果
    input  wire [DATA_W-1:0] input2,   // MEM/WB 的写回数据
    input  wire [1:0]        select,   // 00=input0, 01=input1, 10=input2
    output reg  [DATA_W-1:0] mux_out
);
    always @(*) begin
        case (select)
            2'b00: mux_out = input0;
            2'b01: mux_out = input1;
            2'b10: mux_out = input2;
            default: mux_out = input0;
        endcase
    end
endmodule
