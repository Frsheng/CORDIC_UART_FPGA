module TOP(
input clk,
input rst_n,
input rx_in,
input key,
output tx_out,
output sel_led//sel_led=0显示旋转模式，sel_led=1显示向量模式
);

// 内部信号定义
wire sel;
wire rx_done;
wire tx_start;
wire cor_start;
wire [1:0] vec_theta_adj;
wire [31:0] x_in,y_in,z_in;
wire [31:0] x_cor, y_cor,z_cor;
wire [31:0] x_out, y_out,z_out;
wire [95:0] rx_data_out, tx_data_buffer; // 12字节数据
reg SS;
reg reg_sel;

// 实例化模块
uart_rx_top #(.CLK_FREQ(50_000_000),
.BPS(9_600),
.BYTES_NUM(12)
) RX_T (
    .clk(clk),
    .rst_n(rst_n),
    .rx_in(rx_in),
    .data_out(rx_data_out),
    .done(rx_done)
);

uart_tx_top #(.CLK_FREQ(50_000_000),
.BPS(9_600),
.BYTES_NUM(12)
) TX_T (
    .clk(clk),
    .start(tx_start), 
    .rst_n(rst_n),
    .data_buffer(tx_data_buffer), // 需要定义tx_data_buffer并连接到CORIDIC的输出
    .tx_out(tx_out)
    );

cordic_angle_correct angle(
    .clk(clk),
    .rst_n(rst_n),
    .start(rx_done),
    .sel(sel),
    .x_in(x_in),
    .y_in(y_in),
    .z_in(z_in),
    .x_out(x_cor),
    .y_out(y_cor),
    .z_out(z_cor),
    .vec_theta_adj(vec_theta_adj),
    .done(cor_start)
);


cordic cor(
    .clk(clk),
    .rst_n(rst_n),
    .sel(sel),
    .start(cor_start),
    .vec_theta_adj(vec_theta_adj),
    .x_in(x_cor),
    .y_in(y_cor),
    .z_in(z_cor),
    .done(tx_start),
    .x_out(x_out),
    .y_out(y_out),
    .z_out(z_out)
);

// SS控制和寄存器选择
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        SS <= 1'b1;
        reg_sel <= 1'b0;
    end else begin
        case(SS)
            1'b0:begin
                if(!key)begin
                    SS <= 1'b1;
                    reg_sel <= ~reg_sel;
                end
            end
            1'b1:begin
                if(key)begin
                    SS <= 1'b0;
                end
            end
        endcase
    end
end
assign sel = reg_sel;
assign sel_led = reg_sel;

assign x_in = rx_data_out[95:64];
assign y_in = rx_data_out[63:32];
assign z_in = rx_data_out[31:0];

assign tx_data_buffer = {x_out,y_out,z_out};

endmodule
