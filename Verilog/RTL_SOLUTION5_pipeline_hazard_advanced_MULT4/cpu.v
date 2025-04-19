// rtl/cpu.v
// 完整五级流水：全转发 + Load-Use 停顿 + ID 级分支/跳转提前判断
module cpu(
    input  wire        clk,
    input  wire        arst_n,
    input  wire        enable,
    // IF 级外部 imem 接口
    input  wire [63:0] addr_ext,
    input  wire        wen_ext,
    input  wire        ren_ext,
    input  wire [31:0] wdata_ext,
    // MEM 级外部 dmem 接口
    input  wire [63:0] addr_ext_2,
    input  wire        wen_ext_2,
    input  wire        ren_ext_2,
    input  wire [63:0] wdata_ext_2,
    output wire [31:0] rdata_ext,
    output wire [63:0] rdata_ext_2
);

  // -----------------------------
  // 管道寄存器总线
  // -----------------------------
  wire [95:0]   if_id_dout;
  wire [297:0]  id_ex_dout;
  wire [229:0]  ex_mem_dout;
  wire [225:0]  mem_wb_dout;

  // -----------------------------
  // IF 阶段信号
  // -----------------------------
  wire [63:0] current_pc, updated_pc;
  wire [31:0] instruction;

  // IF/ID 阶段信号
  wire [63:0] pc_IF_ID;
  wire [31:0] instruction_IF_ID;

  // -----------------------------
  // ID 阶段信号
  // -----------------------------
  wire [1:0]           alu_op;
  wire                 reg_dst, branch, mem_read, mem_2_reg;
  wire                 mem_write, alu_src, reg_write, jump, mult;
  wire signed [63:0]   immediate_extended;
  wire [63:0]          regfile_rdata_1, regfile_rdata_2;
  wire                 equal, branch_taken;

  // ID/EX 阶段信号
  wire [63:0]  pc_ID_EX;
  wire [63:0]  regfile_rdata_1_ID_EX;
  wire [63:0]  regfile_rdata_2_ID_EX;
  wire [63:0]  immediate_extended_ID_EX;
  wire [31:0]  instruction_ID_EX;
  wire [1:0]   alu_op_ID_EX;
  wire         alu_src_ID_EX, reg_write_ID_EX, mem_read_ID_EX;
  wire         mem_write_ID_EX, mem_2_reg_ID_EX;
  wire         branch_ID_EX, jump_ID_EX, mult_ID_EX;

  // -----------------------------
  // EX 阶段信号
  // -----------------------------
  wire [4:0]   rs1_ID_EX = instruction_ID_EX[19:15];
  wire [4:0]   rs2_ID_EX = instruction_ID_EX[24:20];
  wire [4:0]   rd_EX_MEM, rd_MEM_WB;
  wire [1:0]   forwardA, forwardB;
  wire [63:0]  alu_in_0_fwd, regfile_rdata_2_fwd;
  wire [63:0]  alu_operand_2;
  wire [3:0]   alu_control;
  wire [63:0]  alu_out;
  wire         zero_flag;

  // EX/MEM 阶段信号
  wire [63:0]  pc_EX_MEM;
  wire [63:0]  alu_out_EX_MEM;
  wire [63:0]  regfile_rdata_2_EX_MEM;
  wire [31:0]  instruction_EX_MEM;
  wire         reg_write_EX_MEM, mem_read_EX_MEM;
  wire         mem_write_EX_MEM, mem_2_reg_EX_MEM;
  wire         branch_EX_MEM, jump_EX_MEM;

  // -----------------------------
  // MEM 级信号
  // -----------------------------
  wire [63:0]  mem_data;

  // -----------------------------
  // MEM/WB 阶段信号
  // -----------------------------
  wire [63:0]  pc_MEM_WB;
  wire [63:0]  alu_out_MEM_WB;
  wire [63:0]  mem_data_MEM_WB;
  wire [31:0]  instruction_MEM_WB;
  wire         reg_write_MEM_WB, mem_2_reg_MEM_WB;

  // -----------------------------
  // WB 级信号
  // -----------------------------
  wire [63:0]  regfile_wdata;


  // -----------------------------
  // Load-Use 冒险检测
  // -----------------------------
  wire        pc_write, control_stall;
  hazard_detection_unit hdu (
      .mem_read_ID_EX  (mem_read_ID_EX),
      .rs1_IF_ID       (instruction_IF_ID[19:15]),
      .rs2_IF_ID       (instruction_IF_ID[24:20]),
      .rd_ID_EX        (instruction_ID_EX[11:7]),
      .pc_write        (pc_write),
      .control_stall   (control_stall)
  );

  // -----------------------------
  // IF 级：分支/跳转提前决策
  // -----------------------------
  // 由 branch_unit 统一计算目标 PC
  wire [63:0] branch_pc, jump_pc;
  branch_unit #(.DATA_W(64)) branch_unit_inst (
      .current_pc          (pc_IF_ID),
      .immediate_extended  (immediate_extended),
      .branch_pc            (branch_pc),
      .jump_pc              (jump_pc)
  );
  assign branch_taken = branch & equal;

  pc #(.DATA_W(64)) program_counter (
      .clk        (clk),
      .arst_n     (arst_n),
      .branch_pc  (branch_pc),
      .jump_pc    (jump_pc),
      .zero_flag  (equal),
      .branch     (branch),
      .jump       (jump),
      .current_pc (current_pc),
      .enable     (enable & pc_write),
      .updated_pc (updated_pc)
  );

  sram_BW32 #(.ADDR_W(9)) instruction_memory (
      .clk       (clk),
      .addr      (current_pc),
      .wen       (1'b0),
      .ren       (1'b1),
      .wdata     (32'b0),
      .rdata     (instruction),
      .addr_ext  (addr_ext),
      .wen_ext   (wen_ext),
      .ren_ext   (ren_ext),
      .wdata_ext (wdata_ext),
      .rdata_ext (rdata_ext)
  );

  // IF/ID 管道寄存器：遇到数据停顿或控制冒险需冲刷
  reg_arstn_en #(.DATA_W(96)) IF_ID_pipe (
      .clk   (clk),
      .arst_n(arst_n),
      .en    (enable & pc_write),
      .din   ((control_stall || branch_taken || jump)
               ? 96'b0
               : {current_pc, instruction}),
      .dout  (if_id_dout)
  );
  assign pc_IF_ID          = if_id_dout[95:32];
  assign instruction_IF_ID = if_id_dout[31:0];

  // -----------------------------
  // ID 级
  // -----------------------------
  control_unit control_unit_inst (
      .opcode    (instruction_IF_ID[6:0]),
      .funct7    (instruction_IF_ID[31:25]),
      .func3     (instruction_IF_ID[14:12]),
      .alu_op    (alu_op),
      .reg_dst   (reg_dst),
      .branch    (branch),
      .mem_read  (mem_read),
      .mem_2_reg (mem_2_reg),
      .mem_write (mem_write),
      .alu_src   (alu_src),
      .reg_write (reg_write),
      .jump      (jump),
      .mult      (mult)
  );

  immediate_extend_unit imm_extend (
      .instruction        (instruction_IF_ID),
      .immediate_extended (immediate_extended)
  );

  assign equal = (regfile_rdata_1 == regfile_rdata_2);

  // ID/EX 管道寄存器：在 Load‑Use 停顿或控制冒险（branch）时注入气泡
  reg_arstn_en #(.DATA_W(298)) ID_EX_pipe (
      .clk   (clk),
      .arst_n(arst_n),
      .en    (enable),
      .din   ((control_stall || branch_taken)
               ? 298'b0
               : {
                 pc_IF_ID,
                 regfile_rdata_1, regfile_rdata_2,
                 immediate_extended,
                 instruction_IF_ID,
                 alu_op, alu_src, reg_write,
                 mem_read, mem_write,
                 mem_2_reg, branch,
                 jump, mult
               }),
      .dout  (id_ex_dout)
  );

  assign pc_ID_EX                 = id_ex_dout[297-:64];
  assign regfile_rdata_1_ID_EX    = id_ex_dout[233-:64];
  assign regfile_rdata_2_ID_EX    = id_ex_dout[169-:64];
  assign immediate_extended_ID_EX = id_ex_dout[105-:64];
  assign instruction_ID_EX        = id_ex_dout[41-:32];
  assign alu_op_ID_EX             = id_ex_dout[9-:2];
  assign alu_src_ID_EX            = id_ex_dout[7];
  assign reg_write_ID_EX          = id_ex_dout[6];
  assign mem_read_ID_EX           = id_ex_dout[5];
  assign mem_write_ID_EX          = id_ex_dout[4];
  assign mem_2_reg_ID_EX          = id_ex_dout[3];
  assign branch_ID_EX             = id_ex_dout[2];
  assign jump_ID_EX               = id_ex_dout[1];
  assign mult_ID_EX               = id_ex_dout[0];

  // 寄存器堆（含写回）
  register_file #(.DATA_W(64)) register_file (
      .clk       (clk),
      .arst_n    (arst_n),
      .reg_write (reg_write_MEM_WB),
      .raddr_1   (instruction_IF_ID[19:15]),
      .raddr_2   (instruction_IF_ID[24:20]),
      .waddr     (instruction_MEM_WB[11:7]),
      .wdata     (regfile_wdata),
      .rdata_1   (regfile_rdata_1),
      .rdata_2   (regfile_rdata_2)
  );


  // -----------------------------
  // EX 级（转发）
  // -----------------------------
  forwarding_unit fw_unit (
      .rs1_ID_EX        (rs1_ID_EX),
      .rs2_ID_EX        (rs2_ID_EX),
      .rd_EX_MEM        (instruction_EX_MEM[11:7]),
      .rd_MEM_WB        (instruction_MEM_WB[11:7]),
      .reg_write_EX_MEM (reg_write_EX_MEM),
    //   .reg_write_MEM_WB (reg_write_MEM_WB),
      .mem_read_EX_MEM  (mem_read_EX_MEM),    // 新增
      .reg_write_MEM_WB (reg_write_MEM_WB),
      .forwardA         (forwardA),
      .forwardB         (forwardB)
  );

  mux_3 #(.DATA_W(64)) muxA (
      .input0 (regfile_rdata_1_ID_EX),
      .input1 (alu_out_EX_MEM),
      .input2 (regfile_wdata),
      .select (forwardA),
      .mux_out(alu_in_0_fwd)
  );
  mux_3 #(.DATA_W(64)) muxB (
      .input0 (regfile_rdata_2_ID_EX),
      .input1 (alu_out_EX_MEM),
      .input2 (regfile_wdata),
      .select (forwardB),
      .mux_out(regfile_rdata_2_fwd)
  );

  mux_2 #(.DATA_W(64)) alu_src_mux (
      .input_a(immediate_extended_ID_EX),
      .input_b(regfile_rdata_2_fwd),
      .select_a(alu_src_ID_EX),
      .mux_out(alu_operand_2)
  );

  alu_control alu_ctl (
      .funct7     (instruction_ID_EX[31:25]),
      .func3      (instruction_ID_EX[14:12]),
      .alu_op     (alu_op_ID_EX),
      .mult       (mult_ID_EX),
      .alu_control(alu_control)
  );
  alu #(.DATA_W(64)) alu_inst (
      .alu_in_0  (alu_in_0_fwd),
      .alu_in_1  (alu_operand_2),
      .alu_ctrl  (alu_control),
      .alu_out   (alu_out),
      .zero_flag (zero_flag),
      .overflow  ()
  );

  // -----------------------------
  // EX/MEM 管道寄存器
  // -----------------------------
  reg_arstn_en #(.DATA_W(230)) EX_MEM_pipe (
      .clk   (clk),
      .arst_n(arst_n),
      .en    (enable),
      .din   ({
        pc_ID_EX, alu_out, regfile_rdata_2_fwd,
        instruction_ID_EX,
        reg_write_ID_EX, mem_read_ID_EX, mem_write_ID_EX,
        mem_2_reg_ID_EX, branch_ID_EX, jump_ID_EX
      }),
      .dout  (ex_mem_dout)
  );
  assign pc_EX_MEM              = ex_mem_dout[229-:64];
  assign alu_out_EX_MEM         = ex_mem_dout[165-:64];
  assign regfile_rdata_2_EX_MEM = ex_mem_dout[101-:64];
  assign instruction_EX_MEM     = ex_mem_dout[37-:32];
  assign reg_write_EX_MEM       = ex_mem_dout[5];
  assign mem_read_EX_MEM        = ex_mem_dout[4];
  assign mem_write_EX_MEM       = ex_mem_dout[3];
  assign mem_2_reg_EX_MEM       = ex_mem_dout[2];
  assign branch_EX_MEM          = ex_mem_dout[1];
  assign jump_EX_MEM            = ex_mem_dout[0];

  // -----------------------------
  // MEM 级
  // -----------------------------
  sram_BW64 #(.ADDR_W(10)) data_memory (
      .clk       (clk),
      .addr      (alu_out_EX_MEM),
      .wen       (mem_write_EX_MEM),
      .ren       (mem_read_EX_MEM),
      .wdata     (regfile_rdata_2_EX_MEM),
      .rdata     (mem_data),
      .addr_ext  (addr_ext_2),
      .wen_ext   (wen_ext_2),
      .ren_ext   (ren_ext_2),
      .wdata_ext (wdata_ext_2),
      .rdata_ext (rdata_ext_2)
  );

  // -----------------------------
  // MEM/WB 管道寄存器
  // -----------------------------
  reg_arstn_en #(.DATA_W(226)) MEM_WB_pipe (
      .clk   (clk),
      .arst_n(arst_n),
      .en    (enable),
      .din   ({
        pc_EX_MEM, alu_out_EX_MEM, mem_data,
        instruction_EX_MEM,
        reg_write_EX_MEM, mem_2_reg_EX_MEM
      }),
      .dout  (mem_wb_dout)
  );
  assign pc_MEM_WB          = mem_wb_dout[225-:64];
  assign alu_out_MEM_WB     = mem_wb_dout[161-:64];
  assign mem_data_MEM_WB    = mem_wb_dout[97 -:64];
  assign instruction_MEM_WB = mem_wb_dout[33 -:32];
  assign reg_write_MEM_WB   = mem_wb_dout[1];
  assign mem_2_reg_MEM_WB   = mem_wb_dout[0];

  // -----------------------------
  // WB 级
  // -----------------------------
  mux_2 #(.DATA_W(64)) regfile_data_mux (
      .input_a (mem_data_MEM_WB),
      .input_b (alu_out_MEM_WB),
      .select_a(mem_2_reg_MEM_WB),
      .mux_out (regfile_wdata)
  );

endmodule
