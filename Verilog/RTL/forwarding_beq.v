// rtl/forwarding_unit.v
module forwarding_beq(
        input  wire [4:0]   rs1_IF_ID,
        input  wire [4:0]   rs2_IF_ID,
        input  wire [4:0]   rd_EX_MEM,
        input  wire         reg_write_EX_MEM,
        input  wire         mem_read_EX_MEM,
        output reg          forwardA,
        output reg          forwardB
    );

    always @(*)
    begin
        forwardA = 1'b0;
        forwardB = 1'b0;

        // 只对非 Load 的 EX/MEM 做转发
        //  上上个命令有写入        上上个命令非ld        非零地址
        if (reg_write_EX_MEM && !mem_read_EX_MEM && (rd_EX_MEM != 5'b0))
        begin
            if (rd_EX_MEM == rs1_IF_ID)
                forwardA = 1'b1;
            if (rd_EX_MEM == rs2_IF_ID)
                forwardB = 1'b1;
        end

    end
endmodule
