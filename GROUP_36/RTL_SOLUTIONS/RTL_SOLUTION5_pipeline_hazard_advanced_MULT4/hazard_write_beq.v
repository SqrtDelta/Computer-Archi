module hazard_write_beq (
        input            branch,    // ID指令为beq
        input   [4:0] rs1_IF_ID, // IF/ID 阶段指令的 rs1
        input   [4:0] rs2_IF_ID,  // IF/ID 阶段指令的 rs2

        input   reg_write_ID_EX,  // EX 阶段是否有 write 指令
        input   [4:0] rd_ID_EX,  // EX 阶段指令的 rd

        input   mem_read_EX_MEM,    // MEM 阶段是否有 ld 信号】
        input   [4:0] rd_EX_MEM,    // MEM 阶段指令的 rd

        output reg write_beq_stall  // 暂停 ID/EX 并 flush 后面
    );

    always @(*)
    begin
        if (branch)
        begin
            // EX stage
            //  write                write_addr  beq_addr_1     write_addr  beq_addr_2
            if (reg_write_ID_EX && ((rd_ID_EX == rs1_IF_ID) || (rd_ID_EX == rs2_IF_ID)))
            begin
                write_beq_stall = 1'b1;  // 注入 EX 级气泡
            end
            else
            begin
                // MEM stage 是否有ld指令
                // ld指令                 write_addr   beq_addr_1     write_addr   beq_addr_2
                if (mem_read_EX_MEM && ((rd_EX_MEM == rs1_IF_ID) || (rd_EX_MEM == rs2_IF_ID)))
                begin
                    write_beq_stall = 1'b1;  // 注入 EX 级气泡
                end
                else
                begin
                    write_beq_stall = 1'b0;
                end
            end
        end
        else
        begin
            write_beq_stall = 1'b0;
        end
    end

endmodule
