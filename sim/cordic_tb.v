`timescale 1ns / 1ps
module cordic_tb;

reg clk;
reg rst_n;
reg start;
reg sel;
reg signed [31:0] x_in;
reg signed [31:0] y_in;
reg signed [31:0] z_in;
wire signed [31:0] x_out;
wire signed [31:0] y_out;
wire signed [31:0] z_out;
wire done;

wire [1:0] vec_theta_adj;
wire [31:0] u1_to_u2_x;
wire [31:0] u1_to_u2_y;
wire [31:0] u1_to_u2_z;
wire u1_to_u2_done;
cordic_angle_correct u1(
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .sel(sel),
    .x_in(x_in),
    .y_in(y_in),
    .z_in(z_in),
    .x_out(u1_to_u2_x),
    .y_out(u1_to_u2_y),
    .z_out(u1_to_u2_z),
    .vec_theta_adj(vec_theta_adj),
    .done(u1_to_u2_done)
);

cordic u2(
    .clk(clk),
    .rst_n(rst_n),
    .sel(sel),
    .start(u1_to_u2_done),
    .x_in(u1_to_u2_x),
    .y_in(u1_to_u2_y),
    .z_in(u1_to_u2_z),
    .vec_theta_adj(vec_theta_adj),
    .done(done),
    .x_out(x_out),
    .y_out(y_out),
    .z_out(z_out)
);

initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

initial begin
    rst_n = 1'b0;
    start = 1'b0;
    x_in = 32'd0;
    y_in = 32'd0;
    z_in = 32'd0;
    #20;
    $stop;
    rst_n = 1'b1;
    #10;
    sel = 1'b0;// 选择模式
    #10;
    // 第一组测试向量
    start = 1'b1;
    x_in = 32'h0001_0000; // 输入x=1
    y_in = 32'h0000_0000; // 输入y=0
    z_in = 32'h0000_860B; // 输入z=pi/6
    #10;
    start = 1'b0;
    wait(done);
    #10;
    // 第二组测试向量
    start = 1'b1;
    x_in = 32'h0100_0000; // 输入x=256
    y_in = 32'h0000_0000; // 输入y=0
    z_in = 32'h0006_CE89; // 输入z=7pi/6
    #10;
    start = 1'b0;
    wait(done);
    #10;
    // 第三组测试向量
    start = 1'b1;
    x_in = 32'h0001_0000; // 输入x=1
    y_in = 32'h0000_0000; // 输入y=0
    z_in = 32'h0008_60A9; // 输入z=5pi/3
    #10;
    start = 1'b0;
    wait(done);
    #10;
    // 第四组测试向量
    start = 1'b1;
    x_in = 32'h0001_0000; // 输入x=1
    y_in = 32'h0000_0000; // 输入y=0
    z_in = 32'h0009_F2C9; // 输入z=13pi/6
    #10;
    start = 1'b0;
    wait(done);
    #10;
    sel = 1'b1; // 向量模式
    #10;
    // 第五组测试向量
    start = 1'b1;
    x_in = 32'h0001_0000; // 输入x=1
    y_in = 32'h0001_0000; // 输入y=1
    z_in = 32'h0000_0000; // 输入z=0
    #10;
    start = 1'b0;
    wait(done);
    #10;
    // 第六组测试向量
    start = 1'b1;
    x_in = 32'hf500_0000; // 输入x=-2816
    y_in = 32'hf500_0000; // 输入y=-2816
    z_in = 32'h0000_0000; // 输入z=0
    #10;
    start = 1'b0;
    wait(done);
    #200;
    $finish;
end
endmodule
