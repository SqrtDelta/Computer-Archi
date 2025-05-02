// rtl/register_file.v
// 修改后：增加写回数据的“就地”转发，避免同周期写——读不一致
module register_file#(
   parameter integer DATA_W     = 16
)(
      input  wire              clk,
      input  wire              arst_n,
      input  wire              reg_write,
      input  wire [       4:0] raddr_1,
      input  wire [       4:0] raddr_2,
      input  wire [       4:0] waddr,
      input  wire [DATA_W-1:0] wdata,
      output reg  [DATA_W-1:0] rdata_1,
      output reg  [DATA_W-1:0] rdata_2
   );

   parameter integer N_REG      = 32;
   reg [DATA_W-1:0] reg_array     [0:N_REG-1];
   reg [DATA_W-1:0] reg_array_nxt [0:N_REG-1];
   integer idx;

   // 异步读端口 + 写回前向转发
   always @(*) begin
      // 如果当前周期要写回，并且写回地址 == 读地址，就直接读新数据
      if (reg_write && (waddr != 5'd0) && (waddr == raddr_1))
         rdata_1 = wdata;
      else
         rdata_1 = reg_array[raddr_1];

      if (reg_write && (waddr != 5'd0) && (waddr == raddr_2))
         rdata_2 = wdata;
      else
         rdata_2 = reg_array[raddr_2];
   end

   // 写回下一状态计算（保持与原来一致）
   always @(*) begin
      for(idx = 0; idx < N_REG; idx = idx + 1) begin
         if ((reg_write == 1'b1) && (waddr == idx))
            reg_array_nxt[idx] = wdata;
         else
            reg_array_nxt[idx] = reg_array[idx];
      end
   end

   // 同步更新并异步复位（x0 保持为 0）
   always @(posedge clk, negedge arst_n) begin
      if (arst_n == 1'b0) begin
         for (idx = 0; idx < N_REG; idx = idx + 1)
            reg_array[idx] <= 'b0;
      end else begin
         // 从 1 开始，保持 x0=0
         for (idx = 1; idx < N_REG; idx = idx + 1)
            reg_array[idx] <= reg_array_nxt[idx];
      end
   end

endmodule
