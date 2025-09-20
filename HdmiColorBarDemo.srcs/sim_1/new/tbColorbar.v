`timescale 1ns/1ps
module tb_colorbar;

// 时钟周期：假设 40ns (25MHz)，你可以改
reg clk;
reg rst;

// DUT 输出
wire hs;
wire vs;
wire de;
wire [7:0] rgb_r, rgb_g, rgb_b;

// 生成时钟
initial clk = 0;
always #20 clk = ~clk;  // 25MHz, 周期40ns

// 产生复位
initial begin
    rst = 1;
    #100;       // 100ns 复位
    rst = 0;
end

// 例化 DUT
ColorBarPixelGenerator uut(
    .clk(clk),
    .rst(rst),
    .hs(hs),
    .vs(vs),
    .de(de),
    .rgb_r(rgb_r),
    .rgb_g(rgb_g),
    .rgb_b(rgb_b)
);

endmodule
