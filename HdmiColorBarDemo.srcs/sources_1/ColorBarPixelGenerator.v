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

// ---------------- AXI4-Stream interface to CORDIC IP (example instance) ----------------
// NOTE: Replace 'cordic_ip' with your generated IP wrapper name if different.
// The IP in your screenshot expects S_AXIS_CARTESIAN.TDATA with {IMAG(31:16), REAL(15:0)}
wire [31:0] s_axis_cartesian_tdata = { y_frac16, x_frac16 }; // IMAG = y, REAL = x (match IP)
reg s_axis_cartesian_tvalid;
wire s_axis_cartesian_tready; // driven by IP

// Drive tvalid simply when pixel is active. If your IP's tready can be 0 occasionally,
// consider adding a FIFO or hold logic so you don't lose samples.
always @(posedge clk or posedge rst) begin
    if (rst) s_axis_cartesian_tvalid <= 1'b0;
    else s_axis_cartesian_tvalid <= video_active; // simple approach: assert when pixel valid
end

// ---------------- instantiate cordic IP wrapper (AXIS) ----------------
// Replace "cordic_ip" with the actual name of the generated IP (eg. cordic_0)
// The ports below are the common AXIS ports; adjust names to your wrapper exactly.

wire [15:0] m_axis_dout_tdata;
wire        m_axis_dout_tvalid;
reg         m_axis_dout_tready;


cordic_ip cordic_inst (
    .aclk                     (clk),
    .aresetn                  (~rst),
    .s_axis_cartesian_tdata   (s_axis_cartesian_tdata),
    .s_axis_cartesian_tvalid  (s_axis_cartesian_tvalid),
    .s_axis_cartesian_tready  (s_axis_cartesian_tready),
    .m_axis_dout_tdata        (m_axis_dout_tdata),
    .m_axis_dout_tvalid       (m_axis_dout_tvalid),
    .m_axis_dout_tready       (m_axis_dout_tready)
);


// For safety, keep m_axis_dout_tready high to always accept IP output
always @(posedge clk or posedge rst) begin
    if (rst) m_axis_dout_tready <= 1'b1;
    else m_axis_dout_tready <= 1'b1;
end

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

// ---------------- convert IP output phase -> angle12 (0..4095 mapping 0..2pi) ----------------
// We assume IP outputs phase in signed fixed-point radians format (fix16_13):
// m_axis_dout_tdata is signed 16-bit representing theta * 2^13 (radians).
// Convert signed radians in [-pi,pi] to unsigned [0..4095]:
// angle12 = ((theta + pi) / (2*pi)) * 4096
// Implement integer math: angle12 = ((phase_q + PI_Q) * SCALE) >> SHIFT
// where PI_Q = round(pi * 2^13), SCALE/SHIFT approximate 4096/(2*pi*2^13) = 1/(4*pi)
// We'll use SCALE = round(1/(4*pi) * 2^24) = 1336934, SHIFT = 24

localparam integer PI_Q = 25736; // round(pi * 2^13) = 3.141592653589793*8192
localparam integer SCALE = 1336934; // round(1/(4*pi) * 2^24)
localparam integer SHIFT = 24;

wire signed [15:0] phase_fixed = m_axis_dout_tdata; // signed fix16_13
wire signed [31:0] phase_ext = $signed({{16{phase_fixed[15]}}, phase_fixed}); // extend to 32-bit
wire signed [31:0] phase_shifted = phase_ext + PI_Q; // now ~ [0..2*pi]*2^13

// multiply: use wider reg
wire signed [63:0] mult_phase = phase_shifted * $signed(SCALE);
wire [11:0] angle12 = mult_phase[SHIFT +: 12]; // take shifted 12 bits (equivalent to >> SHIFT)

// NOTE: depending on synthesis tool, you might prefer: angle12 = (mult_phase >> SHIFT) & 12'hFFF;
// Above slice uses bit-select for clarity

// If your IP outputs angle in a different format (e.g. unsigned 0..2pi mapped to full 16-bit),
// replace the conversion accordingly.

// ---------------- phase_reg (frame aligned rotation offset) ----------------
reg [11:0] phase_reg;
parameter PHASE_STEP = 12'd32;
always @(posedge clk or posedge rst) begin
    if (rst) phase_reg <= 12'd0;
    else if (h_cnt == H_TOTAL - 1 && v_cnt == V_TOTAL - 1)
        phase_reg <= phase_reg + PHASE_STEP;
end

wire [11:0] angle_shift = (angle12 + phase_reg) & 12'hFFF;
wire [2:0] sector = angle_shift[11:9]; // top 3 bits for 8 sectors

// ---------------- color output (aligned with cordic_valid & video_active_aligned) ----------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        rgb_r_reg <= 8'h00; rgb_g_reg <= 8'h00; rgb_b_reg <= 8'h00;
    end else if (m_axis_dout_tvalid && video_active_aligned) begin
        case (sector)
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
