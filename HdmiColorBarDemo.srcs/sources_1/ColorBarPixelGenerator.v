`timescale 1ns/1ps
`include "VideoTimingParameterDefine.v"

module ColorBarPixelGenerator(
    input                 clk,
    input                 rst,
    output                hs,
    output                vs,
    output                de,
    output[7:0]           rgb_r,
    output[7:0]           rgb_g,
    output[7:0]           rgb_b
);

// ---------------- video timing parameters (same as original) ----------------
`ifdef  VIDEO_1280_720
parameter H_ACTIVE = 16'd1280; parameter H_FP = 16'd110; parameter H_SYNC = 16'd40; parameter H_BP = 16'd220;
parameter V_ACTIVE = 16'd720;  parameter V_FP  = 16'd5;   parameter V_SYNC  = 16'd5;  parameter V_BP  = 16'd20;
parameter HS_POL = 1'b1; parameter VS_POL = 1'b1;
`endif
`ifdef  VIDEO_480_272
parameter H_ACTIVE = 16'd480; parameter H_FP = 16'd2; parameter H_SYNC = 16'd41; parameter H_BP = 16'd2;
parameter V_ACTIVE = 16'd272; parameter V_FP  = 16'd2; parameter V_SYNC  = 16'd10; parameter V_BP  = 16'd2;
parameter HS_POL = 1'b0; parameter VS_POL = 1'b0;
`endif
`ifdef  VIDEO_640_480
parameter H_ACTIVE = 16'd640; parameter H_FP = 16'd16; parameter H_SYNC = 16'd96; parameter H_BP = 16'd48;
parameter V_ACTIVE = 16'd480; parameter V_FP  = 16'd10; parameter V_SYNC  = 16'd2;  parameter V_BP  = 16'd33;
parameter HS_POL = 1'b0; parameter VS_POL = 1'b0;
`endif
`ifdef  VIDEO_800_480
parameter H_ACTIVE = 16'd800; parameter H_FP = 16'd40; parameter H_SYNC = 16'd128; parameter H_BP = 16'd88;
parameter V_ACTIVE = 16'd480; parameter V_FP  = 16'd1;  parameter V_SYNC  = 16'd3;   parameter V_BP  = 16'd21;
parameter HS_POL = 1'b0; parameter VS_POL = 1'b0;
`endif
`ifdef  VIDEO_800_600
parameter H_ACTIVE = 16'd800; parameter H_FP = 16'd40; parameter H_SYNC = 16'd128; parameter H_BP = 16'd88;
parameter V_ACTIVE = 16'd600; parameter V_FP  = 16'd1;  parameter V_SYNC  = 16'd4;   parameter V_BP  = 16'd23;
parameter HS_POL = 1'b1; parameter VS_POL = 1'b1;
`endif
`ifdef  VIDEO_1024_768
parameter H_ACTIVE = 16'd1024; parameter H_FP = 16'd24; parameter H_SYNC = 16'd136; parameter H_BP = 16'd160;
parameter V_ACTIVE = 16'd768;  parameter V_FP  = 16'd3;  parameter V_SYNC  = 16'd6;   parameter V_BP  = 16'd29;
parameter HS_POL = 1'b0; parameter VS_POL = 1'b0;
`endif
`ifdef  VIDEO_1920_1080
parameter H_ACTIVE = 16'd1920; parameter H_FP = 16'd88; parameter H_SYNC = 16'd44; parameter H_BP = 16'd148;
parameter V_ACTIVE = 16'd1080; parameter V_FP  = 16'd4;  parameter V_SYNC  = 16'd5;   parameter V_BP  = 16'd36;
parameter HS_POL = 1'b1; parameter VS_POL = 1'b1;
`endif

parameter H_TOTAL = H_ACTIVE + H_FP + H_SYNC + H_BP;
parameter V_TOTAL = V_ACTIVE + V_FP + V_SYNC + V_BP;

// ---------------- colors (same as original) ----------------
parameter WHITE_R       = 8'hff; parameter WHITE_G       = 8'hff; parameter WHITE_B       = 8'hff;
parameter YELLOW_R      = 8'hff; parameter YELLOW_G      = 8'hff; parameter YELLOW_B      = 8'h00;
parameter CYAN_R        = 8'h00; parameter CYAN_G        = 8'hff; parameter CYAN_B        = 8'hff;
parameter GREEN_R       = 8'h00; parameter GREEN_G       = 8'hff; parameter GREEN_B       = 8'h00;
parameter MAGENTA_R     = 8'hff; parameter MAGENTA_G     = 8'h00; parameter MAGENTA_B     = 8'hff;
parameter RED_R         = 8'hff; parameter RED_G         = 8'h00; parameter RED_B         = 8'h00;
parameter BLUE_R        = 8'h00; parameter BLUE_G        = 8'h00; parameter BLUE_B        = 8'hff;
parameter BLACK_R       = 8'h00; parameter BLACK_G       = 8'h00; parameter BLACK_B       = 8'h00;

// ---------------- registers & timing ----------------
reg hs_reg, vs_reg;
reg hs_reg_d0, vs_reg_d0;
reg [11:0] h_cnt;
reg [11:0] v_cnt;
reg [11:0] active_x;
reg [11:0] active_y;
reg [7:0] rgb_r_reg, rgb_g_reg, rgb_b_reg;
reg h_active, v_active;
wire video_active;
reg video_active_d0;
assign hs = hs_reg_d0;
assign vs = vs_reg_d0;
assign video_active = h_active & v_active;
assign de = video_active_d0;
assign rgb_r = rgb_r_reg;
assign rgb_g = rgb_g_reg;
assign rgb_b = rgb_b_reg;

// pipeline registers (carry-over)
always@(posedge clk or posedge rst) begin
    if(rst) begin
        hs_reg_d0 <= 1'b0; vs_reg_d0 <= 1'b0; video_active_d0 <= 1'b0;
    end else begin
        hs_reg_d0 <= hs_reg; vs_reg_d0 <= vs_reg; video_active_d0 <= video_active;
    end
end

// h_cnt
always@(posedge clk or posedge rst) begin
    if (rst) h_cnt <= 12'd0;
    else if (h_cnt == H_TOTAL - 1) h_cnt <= 12'd0;
    else h_cnt <= h_cnt + 12'd1;
end

// active_x
always@(posedge clk or posedge rst) begin
    if (rst) active_x <= 12'd0;
    else if (h_cnt >= H_FP + H_SYNC + H_BP - 1)
        active_x <= h_cnt - (H_FP[11:0] + H_SYNC[11:0] + H_BP[11:0] - 12'd1);
    else active_x <= active_x;
end

// v_cnt
always@(posedge clk or posedge rst) begin
    if (rst) v_cnt <= 12'd0;
    else if (h_cnt == H_FP - 1) begin
        if (v_cnt == V_TOTAL - 1) v_cnt <= 12'd0;
        else v_cnt <= v_cnt + 12'd1;
    end else v_cnt <= v_cnt;
end

// active_y
always@(posedge clk or posedge rst) begin
    if (rst) active_y <= 12'd0;
    else if (v_cnt >= V_FP + V_SYNC + V_BP - 1)
        active_y <= v_cnt - (V_FP[11:0] + V_SYNC[11:0] + V_BP[11:0] - 12'd1);
    else active_y <= active_y;
end

// hs_reg
always@(posedge clk or posedge rst) begin
    if (rst) hs_reg <= 1'b0;
    else if (h_cnt == H_FP - 1) hs_reg <= HS_POL;
    else if (h_cnt == H_FP + H_SYNC - 1) hs_reg <= ~hs_reg;
    else hs_reg <= hs_reg;
end

// h_active
always@(posedge clk or posedge rst) begin
    if (rst) h_active <= 1'b0;
    else if (h_cnt == H_FP + H_SYNC + H_BP - 1) h_active <= 1'b1;
    else if (h_cnt == H_TOTAL - 1) h_active <= 1'b0;
    else h_active <= h_active;
end

// vs_reg
always@(posedge clk or posedge rst) begin
    if (rst) vs_reg <= 1'b0;
    else if ((v_cnt == V_FP - 1) && (h_cnt == H_FP - 1)) vs_reg <= VS_POL;
    else if ((v_cnt == V_FP + V_SYNC - 1) && (h_cnt == H_FP - 1)) vs_reg <= ~vs_reg;
    else vs_reg <= vs_reg;
end

// v_active
always@(posedge clk or posedge rst) begin
    if (rst) v_active <= 1'b0;
    else if ((v_cnt == V_FP + V_SYNC + V_BP - 1) && (h_cnt == H_FP - 1)) v_active <= 1'b1;
    else if ((v_cnt == V_TOTAL - 1) && (h_cnt == H_FP - 1)) v_active <= 1'b0;
    else v_active <= v_active;
end

// ---------------- prepare dx/dy (signed) ----------------
localparam integer CX_INT = H_ACTIVE / 2;
localparam integer CY_INT = V_ACTIVE / 2;
wire signed [13:0] dx = $signed({1'b0, active_x}) - $signed({1'b0, CX_INT[11:0]});
wire signed [13:0] dy = $signed({1'b0, active_y}) - $signed({1'b0, CY_INT[11:0]});

// ---------------- scale to IP fixed-point format ----------------
// IP screenshot used fix16_14 (SignedFraction with 14 fractional bits).
localparam integer FBITS = 14;
localparam integer INPUT_WIDTH = 16; // IP Input Width
// Choose RADIUS as half of larger dimension (compile-time constant), ensures |dx|/RADIUS <= 1
localparam integer RADIUS = ( (H_ACTIVE > V_ACTIVE) ? H_ACTIVE : V_ACTIVE ) / 2;

// temp wide regs for scaling
reg signed [31:0] tmp_x;
reg signed [31:0] tmp_y;
wire signed [15:0] x_frac16;
wire signed [15:0] y_frac16;

always @(*) begin
    // sign-extend dx/dy to 32 bits, multiply by (1<<FBITS)
    tmp_x = $signed({{18{dx[13]}}, dx}) * (1 <<< FBITS); // dx * 2^FBITS
    tmp_y = $signed({{18{dy[13]}}, dy}) * (1 <<< FBITS);
end

// divide by constant RADIUS (synthesis will optimize division by constant)
assign x_frac16 = $signed(tmp_x / RADIUS); // Q1.FBITS in 16-bit signed
assign y_frac16 = $signed(tmp_y / RADIUS);

// ---------------- align video_active by IP latency ----------------
// Use the latency printed by IP (your screenshot shows Latency = 20).
// If your IP is configured differently, change CORDIC_LATENCY accordingly.
localparam integer CORDIC_LATENCY = 20;
reg [CORDIC_LATENCY-1:0] video_pipe;
always @(posedge clk or posedge rst) begin
    if (rst) video_pipe <= {CORDIC_LATENCY{1'b0}};
    else video_pipe <= {video_pipe[CORDIC_LATENCY-2:0], video_active};
end
wire video_active_aligned = video_pipe[CORDIC_LATENCY-1];

localparam integer PI_Q = 25736; // round(pi * 2^13) = 3.141592653589793*8192


// ---------------- phase_reg (frame aligned rotation offset) ----------------
reg [11:0] phase_reg;
parameter PHASE_STEP = 12'd32;//128帧一圈
always @(posedge clk or posedge rst) begin
    if (rst) phase_reg <= 12'd0;
    else if (h_cnt == H_TOTAL - 1 && v_cnt == V_TOTAL - 1)
        phase_reg <= phase_reg + PHASE_STEP;
end

// ... (dx/dy, x_frac16, y_frac16 逻辑保持不变) ...

// *** (A.1) 新增：计算 -y_frac16 ***
wire signed [15:0] neg_y_frac16 = -y_frac16;

// *** (A.2) 新增：转换 phase_reg (0..4095 -> 0..2pi) 为 IP 的 phase_in 格式 (-pi..+pi) ***
// 假设 IP 需要与你旧 IP 输出 (fix16_13) 相同的格式: signed 16-bit, 13 fractional bits
// PI_Q = 25736 (来自你的代码)
// 映射 [0, 4095] to [-PI_Q, +PI_Q]
// 1. 将 [0, 4095] 映射到 [-2048, 2047]
wire signed [12:0] phase_signed_12bit = $signed({phase_reg[11], phase_reg[10:0]}) - 12'd2048;
// 2. 缩放: (val / 2048) * PI_Q
wire signed [31:0] phase_mult = $signed(phase_signed_12bit) * PI_Q; // PI_Q = 25736
// 3. 右移 11 (除以 2048)
wire signed [15:0] phase_input = $signed(phase_mult >>> 11);


// *** (A.3) 修改 CORDIC 输入数据 ***
// 假设你的新 IP 只有一个 s_axis_cartesian 输入，并且它需要 {Y_in, X_in}
// 并且有另一个 s_axis_phase 输入
// !!! 这里的 s_axis_cartesian_tdata 格式取决于你新 IP 的配置 !!!
// 示例: {IMAG(31:16), REAL(15:0)} -> {Y_in(31:16), X_in(15:0)}
wire [31:0] s_axis_cartesian_tdata = { neg_y_frac16, x_frac16 }; // Y_in = -y, X_in = x
wire [15:0] m_axis_dout_tdata;
wire        m_axis_dout_tvalid;
reg s_axis_cartesian_tvalid;



always @(posedge clk or posedge rst) begin
    if (rst) s_axis_cartesian_tvalid <= 1'b0;
    else s_axis_cartesian_tvalid <= video_active; // simple approach: assert when pixel valid
end

cordic_1 cordic_inst (
    .aclk(clk),

    // X, Y 输入流
    .s_axis_cartesian_tdata  (s_axis_cartesian_tdata),    // {Y_in, X_in}
    .s_axis_cartesian_tvalid (s_axis_cartesian_tvalid),
    // .s_axis_cartesian_tready ( ... ), // 如果需要

    // Phase (角度) 输入流
    .s_axis_phase_tdata      (phase_input),               // 角度 phi
    .s_axis_phase_tvalid     (s_axis_cartesian_tvalid),   // 随 (X,Y) 数据一起发送
    // .s_axis_phase_tready ( ... ), // 如果需要

    // X', Y' 输出流
    .m_axis_dout_tdata       (m_axis_dout_tdata),         // {Y_out, X_out}
    .m_axis_dout_tvalid      (m_axis_dout_tvalid)
);


wire signed [15:0] x_out_frac16 = m_axis_dout_tdata[15:0];

// *** (C.2) 反向缩放，得到 x_src (中心化像素坐标) ***
// x_src_centered = (x_out_frac16 * RADIUS) >> FBITS
// (FBITS = 14, RADIUS 保持不变)
wire signed [31:0] tmp_x_src_mult = $signed(x_out_frac16) * RADIUS;
wire signed [13:0] x_src_centered = $signed(tmp_x_src_mult >>> FBITS); // (>> 14)

// *** (C.3) 转换为绝对屏幕坐标 active_x_src ***
wire signed [13:0] active_x_src = x_src_centered + $signed({1'b0, CX_INT[11:0]});

// *** (C.4) 根据 active_x_src 确定彩条索引 ***
// 将 H_ACTIVE 分成 8 个条
parameter BAR_WIDTH = H_ACTIVE / 8;
reg [2:0] bar_index;

always @(*) begin
    // 这实现了 bar_index = active_x_src / BAR_WIDTH，但更适合硬件
    // 同时处理了屏幕外区域
    if (active_x_src < 0)
        bar_index = 3'd0; // 屏幕左侧，设为第一个颜色
    else if (active_x_src < BAR_WIDTH * 1)
        bar_index = 3'd0; // White
    else if (active_x_src < BAR_WIDTH * 2)
        bar_index = 3'd1; // Yellow
    else if (active_x_src < BAR_WIDTH * 3)
        bar_index = 3'd2; // Cyan
    else if (active_x_src < BAR_WIDTH * 4)
        bar_index = 3'd3; // Green
    else if (active_x_src < BAR_WIDTH * 5)
        bar_index = 3'd4; // Magenta
    else if (active_x_src < BAR_WIDTH * 6)
        bar_index = 3'd5; // Red
    else if (active_x_src < BAR_WIDTH * 7)
        bar_index = 3'd6; // Blue
    else
        bar_index = 3'd7; // Black (包括 H_ACTIVE * 7/8 到 H_ACTIVE 以及屏幕右侧)
end

// ---------------- color output (aligned with cordic_valid & video_active_aligned) ----------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        rgb_r_reg <= 8'h00; rgb_g_reg <= 8'h00; rgb_b_reg <= 8'h00;
    end 
    else if ( video_active_aligned) begin
        case (bar_index) 
            3'd0: begin rgb_r_reg <= WHITE_R;   rgb_g_reg <= WHITE_G;   rgb_b_reg <= WHITE_B; end
            3'd1: begin rgb_r_reg <= YELLOW_R;  rgb_g_reg <= YELLOW_G;  rgb_b_reg <= YELLOW_B; end
            3'd2: begin rgb_r_reg <= CYAN_R;    rgb_g_reg <= CYAN_G;    rgb_b_reg <= CYAN_B; end
            3'd3: begin rgb_r_reg <= GREEN_R;   rgb_g_reg <= GREEN_G;   rgb_b_reg <= GREEN_B; end
            3'd4: begin rgb_r_reg <= MAGENTA_R; rgb_g_reg <= MAGENTA_G; rgb_b_reg <= MAGENTA_B; end
            3'd5: begin rgb_r_reg <= RED_R;     rgb_g_reg <= RED_G;     rgb_b_reg <= RED_B; end
            3'd6: begin rgb_r_reg <= BLUE_R;    rgb_g_reg <= BLUE_G;    rgb_b_reg <= BLUE_B; end
            3'd7: begin rgb_r_reg <= BLACK_R;   rgb_g_reg <= BLACK_G;   rgb_b_reg <= BLACK_B; end
            default: begin rgb_r_reg <= 8'h00; rgb_g_reg <= 8'h00; rgb_b_reg <= 8'h00; end
        endcase
    end else begin
        rgb_r_reg <= 8'h00; rgb_g_reg <= 8'h00; rgb_b_reg <= 8'h00;
    end
end

endmodule




