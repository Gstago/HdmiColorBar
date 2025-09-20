`timescale 1ns/1ps

// 可选地在这里指定分辨率或在 Vivado 仿真编译选项中定义
// `define VIDEO_640_480
// `define FRAME_CNT_MAX 2

module tb_colorbar();
defparam dut.H_ACTIVE = 8;
defparam dut.H_FP = 2;
defparam dut.H_SYNC = 2;
defparam dut.H_BP = 2;
defparam dut.V_ACTIVE = 2;
defparam dut.V_FP = 2;
defparam dut.V_SYNC = 2;
defparam dut.V_BP = 2;

  // 时钟：例如用 25MHz (period 40ns)，仿真可调
  reg clk = 0;
  always #2 clk = ~clk; // 25 MHz

  // 复位
  reg rst = 1;
  initial begin
    #200; rst = 0;   // 200ns 后释放复位
  end

  // DUT 信号
  wire hs, vs, de;
  wire [7:0] rgb_r, rgb_g, rgb_b;

  // 实例化被测模块
  ColorBarPixelGenerator dut (
    .clk(clk),
    .rst(rst),
    .hs(hs),
    .vs(vs),
    .de(de),
    .rgb_r(rgb_r),
    .rgb_g(rgb_g),
    .rgb_b(rgb_b)
  );

  // 在仿真控制里设置仿真时长（GUI 用 Run → Simulation Run Options）
  initial begin
    // 在仿真结束前输出若干信息，或只等待
    #20000000; // 2ms = 2,000,000 ns (按需调整)
    $display("SIM DONE");
    $finish;
  end
  
always @(posedge clk) 
  begin
    $display("%0t phase=%0d rot_cnt = %0d", 
             $time, dut.phase, dut.rot_cnt);
end

  // 周期性打印，快速确认状态
//  integer pcnt = 0;
//  always @(posedge clk) begin
//    pcnt = pcnt + 1;
//    if (pcnt == 1000) begin
//      pcnt = 0;
//      $display("%0t : hs=%b vs=%b de=%b a=%b active_x=%0d",
//               $time, hs, vs, de, a, dut.active_x);
//    end
//  end

endmodule
