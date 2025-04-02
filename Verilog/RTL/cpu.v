// 流水线化处理器 cpu.v —— Session2 Obj-1：流水线处理器（MULT2 测试）
module cpu(
    input  wire              clk,
    input  wire              arst_n,
    input  wire              enable,
    input  wire   [63:0]     addr_ext,
    input  wire              wen_ext,
    input  wire              ren_ext,
    input  wire   [31:0]     wdata_ext,
    input  wire   [63:0]     addr_ext_2,
    input  wire              wen_ext_2,
    input  wire              ren_ext_2,
    input  wire   [63:0]     wdata_ext_2,
    output wire   [31:0]     rdata_ext,
    output wire   [63:0]     rdata_ext_2
);

// ==============================
// IF 阶段信号
// ==============================
wire [63:0] current_pc;
wire [31:0] instruction;
wire [63:0] updated_pc;

// pc 模块：产生当前 PC 与更新后的 PC
pc #(
    .DATA_W(64)
) program_counter (
    .clk       (clk),
    .arst_n    (arst_n),
    // 此处分支和跳转的信号在流水线中稍后处理
    .branch_pc (32'd0),
    .jump_pc   (32'd0),
    .zero_flag (1'b0),
    .branch    (1'b0),
    .jump      (1'b0),
    .current_pc(current_pc),
    .enable    (enable),
    .updated_pc(updated_pc)
);

// 指令存储器（IF 阶段）
sram_BW32 #(
    .ADDR_W(9)
) instruction_memory (
    .clk      (clk),
    .addr     (current_pc),
    .wen      (1'b0),
    .ren      (1'b1),
    .wdata    (32'b0),
    .rdata    (instruction),
    .addr_ext (addr_ext),
    .wen_ext  (wen_ext),
    .ren_ext  (ren_ext),
    .wdata_ext(wdata_ext),
    .rdata_ext(rdata_ext)
);

// ------------------------------
// IF/ID 流水线寄存器
// 将 IF 阶段的 PC 与指令传递到 ID 阶段
// 使用 reg_arstn_en 模块，宽度为 64+32 = 96 位
// ------------------------------
wire [95:0] if_id_dout;
reg_arstn_en #(
    .DATA_W(96)
) IF_ID_pipe (
    .clk    (clk),
    .arst_n (arst_n),
    .en     (enable),
    .din    ({current_pc, instruction}),  // 高 64 位为 PC，低 32 位为指令
    .dout   (if_id_dout)
);
wire [63:0] pc_IF_ID       = if_id_dout[95:32];
wire [31:0] instruction_IF_ID = if_id_dout[31:0];

// ==============================
// ID 阶段：译码、寄存器读出、立即数扩展、控制信号生成
// ==============================

// 控制单元
wire [1:0] alu_op;
wire       reg_dst, branch, mem_read, mem_2_reg, mem_write, alu_src, reg_write, jump;
wire       mult;
control_unit control_unit_inst (
    .opcode   (instruction_IF_ID[6:0]),
    .funct7   (instruction_IF_ID[31:25]),
    .func3    (instruction_IF_ID[14:12]),
    .alu_op   (alu_op),
    .reg_dst  (reg_dst),
    .branch   (branch),
    .mem_read (mem_read),
    .mem_2_reg(mem_2_reg),
    .mem_write(mem_write),
    .alu_src  (alu_src),
    .reg_write(reg_write),
    .jump     (jump),
    .mult     (mult)
);

// 立即数扩展单元
wire signed [63:0] immediate_extended;
immediate_extend_unit immediate_extend_u (
    .instruction         (instruction_IF_ID),
    .immediate_extended  (immediate_extended)
);

// 寄存器堆（ID 阶段读出）
wire [63:0] regfile_rdata_1, regfile_rdata_2;
register_file #(
    .DATA_W(64)
) register_file_inst (
    .clk      (clk),
    .arst_n   (arst_n),
    .reg_write(reg_write),  // 写回信号将由 WB 阶段产生（后续连接）
    .raddr_1  (instruction_IF_ID[19:15]),
    .raddr_2  (instruction_IF_ID[24:20]),
    .waddr    (instruction_MEM_WB[11:7]),  // 从 MEM/WB 流水线寄存器取写地址
    .wdata    (regfile_wdata),             // 写回数据
    .rdata_1  (regfile_rdata_1),
    .rdata_2  (regfile_rdata_2)
);

// ------------------------------
// ID/EX 流水线寄存器
// 将 ID 阶段产生的信号传递给 EX 阶段
// 这里打包传递：PC、寄存器数据1、寄存器数据2、扩展立即数、指令、以及控制信号
// 控制信号：alu_op (2b)、alu_src、reg_write、mem_read、mem_write、mem_2_reg、branch、jump、mult（各 1b）
// 总计宽度 = 64 + 64 + 64 + 64 + 32 + 2 + 1*7 = 64*4 +32 +2+7 = 256+32+9 = 297 位
// 为便于说明，此处将各信号依次打包
// ------------------------------
wire [296:0] id_ex_dout;
reg_arstn_en #(
    .DATA_W(297)
) ID_EX_pipe (
    .clk    (clk),
    .arst_n (arst_n),
    .en     (enable),
    .din    ({
              pc_IF_ID,                // [296:233] 64b
              regfile_rdata_1,         // [232:169] 64b
              regfile_rdata_2,         // [168:105] 64b
              immediate_extended,      // [104:41] 64b
              instruction_IF_ID,       // [40:9]   32b
              alu_op,                  // [8:7]    2b
              alu_src,                 // [6]      1b
              reg_write,               // [5]      1b
              mem_read,                // [4]      1b
              mem_write,               // [3]      1b
              mem_2_reg,               // [2]      1b
              branch,                  // [1]      1b
              jump,                    // [0]      1b
              mult                     // 另外再1b，实际总宽度 298b
             }),
    .dout   (id_ex_dout)
);
// 注意：上面打包时各信号的位宽和顺序可根据实际需求调整，本例中假设打包顺序为
// {pc, rdata1, rdata2, immediate, instr, alu_op, alu_src, reg_write, mem_read, mem_write, mem_2_reg, branch, jump, mult}
// 这里我们取 id_ex_dout[297]为 mult 信号，依次向低位排列
wire [63:0] pc_ID_EX         = id_ex_dout[297-:64];
wire [63:0] regfile_rdata_1_ID_EX = id_ex_dout[233-:64];
wire [63:0] regfile_rdata_2_ID_EX = id_ex_dout[169-:64];
wire [63:0] immediate_extended_ID_EX = id_ex_dout[105-:64];
wire [31:0] instruction_ID_EX = id_ex_dout[41-:32];
wire [1:0]  alu_op_ID_EX      = id_ex_dout[9-:2];
wire        alu_src_ID_EX     = id_ex_dout[7];
wire        reg_write_ID_EX   = id_ex_dout[6];
wire        mem_read_ID_EX    = id_ex_dout[5];
wire        mem_write_ID_EX   = id_ex_dout[4];
wire        mem_2_reg_ID_EX   = id_ex_dout[3];
wire        branch_ID_EX      = id_ex_dout[2];
wire        jump_ID_EX        = id_ex_dout[1];
wire        mult_ID_EX        = id_ex_dout[0];

// ==============================
// EX 阶段：运算单元
// ==============================

// ALU 操作数选择：若 alu_src_ID_EX 为 1，则使用扩展立即数；否则使用寄存器 2 的数据
wire [63:0] alu_operand_2;
mux_2 #(
    .DATA_W(64)
) alu_operand_mux (
    .input_a (immediate_extended_ID_EX),
    .input_b (regfile_rdata_2_ID_EX),
    .select_a(alu_src_ID_EX),
    .mux_out (alu_operand_2)
);

// ALU 控制单元
wire [3:0] alu_control;
alu_control alu_ctrl (
    .func7       (instruction_ID_EX[31:25]),
    .func3       (instruction_ID_EX[14:12]),
    .alu_op      (alu_op_ID_EX),
    .mult        (mult_ID_EX),
    .alu_control (alu_control)
);

// ALU 运算
wire [63:0] alu_out;
wire        zero_flag;
alu #(
    .DATA_W(64)
) alu_inst (
    .alu_in_0 (regfile_rdata_1_ID_EX),
    .alu_in_1 (alu_operand_2),
    .alu_ctrl (alu_control),
    .alu_out  (alu_out),
    .zero_flag(zero_flag),
    .overflow ( )
);

// ------------------------------
// EX/MEM 流水线寄存器
// 将 EX 阶段产生的 PC、ALU 结果、寄存器堆第二操作数、指令以及部分控制信号传递到 MEM 阶段
// 控制信号：reg_write、mem_read、mem_write、mem_2_reg、branch、jump
// 总宽度 = 64 (pc) + 64 (alu_out) + 64 (rdata2) + 32 (instr) + 6 (control) = 250 位
// ------------------------------
wire [249:0] ex_mem_dout;
reg_arstn_en #(
    .DATA_W(250)
) EX_MEM_pipe (
    .clk    (clk),
    .arst_n (arst_n),
    .en     (enable),
    .din    ({pc_ID_EX, alu_out, regfile_rdata_2_ID_EX, instruction_ID_EX,
              reg_write_ID_EX, mem_read_ID_EX, mem_write_ID_EX, mem_2_reg_ID_EX, branch_ID_EX, jump_ID_EX}),
    .dout   (ex_mem_dout)
);
wire [63:0] pc_EX_MEM         = ex_mem_dout[249-:64];
wire [63:0] alu_out_EX_MEM      = ex_mem_dout[185-:64];
wire [63:0] regfile_rdata_2_EX_MEM = ex_mem_dout[121-:64];
wire [31:0] instruction_EX_MEM  = ex_mem_dout[57-:32];
wire        reg_write_EX_MEM    = ex_mem_dout[25];
wire        mem_read_EX_MEM     = ex_mem_dout[24];
wire        mem_write_EX_MEM    = ex_mem_dout[23];
wire        mem_2_reg_EX_MEM    = ex_mem_dout[22];
wire        branch_EX_MEM       = ex_mem_dout[21];
wire        jump_EX_MEM         = ex_mem_dout[20];

// ==============================
// MEM 阶段：数据存储器访问
// ==============================
wire [63:0] mem_data;
sram_BW64 #(
    .ADDR_W(10)
) data_memory (
    .clk      (clk),
    .addr     (alu_out_EX_MEM),
    .wen      (mem_write_EX_MEM),
    .ren      (mem_read_EX_MEM),
    .wdata    (regfile_rdata_2_EX_MEM),
    .rdata    (mem_data),
    .addr_ext (addr_ext_2),
    .wen_ext  (wen_ext_2),
    .ren_ext  (ren_ext_2),
    .wdata_ext(wdata_ext_2),
    .rdata_ext(rdata_ext_2)
);

// ------------------------------
// MEM/WB 流水线寄存器
// 将 MEM 阶段的 PC、ALU 结果、存储器数据、指令及控制信号（reg_write、mem_2_reg）传递到 WB 阶段
// 总宽度 = 64 + 64 + 64 + 32 + 2 = 226 位
// ------------------------------
wire [225:0] mem_wb_dout;
reg_arstn_en #(
    .DATA_W(226)
) MEM_WB_pipe (
    .clk    (clk),
    .arst_n (arst_n),
    .en     (enable),
    .din    ({pc_EX_MEM, alu_out_EX_MEM, mem_data, instruction_EX_MEM,
              reg_write_EX_MEM, mem_2_reg_EX_MEM}),
    .dout   (mem_wb_dout)
);
wire [63:0] pc_MEM_WB        = mem_wb_dout[225-:64];
wire [63:0] alu_out_MEM_WB     = mem_wb_dout[161-:64];
wire [63:0] mem_data_MEM_WB    = mem_wb_dout[97-:64];
wire [31:0] instruction_MEM_WB = mem_wb_dout[65-:32];
wire        reg_write_MEM_WB   = mem_wb_dout[33];
wire        mem_2_reg_MEM_WB   = mem_wb_dout[32];

// ==============================
// WB 阶段：写回寄存器堆
// 根据 mem_2_reg_MEM_WB 信号选择写回数据来源（存储器数据或 ALU 运算结果）
wire [63:0] regfile_wdata;
mux_2 #(
    .DATA_W(64)
) regfile_data_mux (
    .input_a  (mem_data_MEM_WB),
    .input_b  (alu_out_MEM_WB),
    .select_a (mem_2_reg_MEM_WB),
    .mux_out  (regfile_wdata)
);

endmodule
