module cordic(
input clk,
input rst_n,
input sel,
input start,
input signed [31:0] x_in,y_in,
input signed [16:0] z_in,
output reg done,
output reg signed [31:0] x_out,y_out,
output reg signed [16:0] z_out
);

localparam IDLE     = 1'b0;
localparam TRANSMIT = 1'b1;
localparam ITER_NUM = 16;
localparam signed K = 17'd39797; 

reg signed[16:0] atan_table [0:ITER_NUM-1];
initial begin
    atan_table[0] = 16'd51472;
    atan_table[1] = 16'd30386;
    atan_table[2] = 16'd16055;
    atan_table[3] = 16'd8150;
    atan_table[4] = 16'd4091;
    atan_table[5] = 16'd2047;
    atan_table[6] = 16'd1024;
    atan_table[7] = 16'd512;
    atan_table[8] = 16'd256;
    atan_table[9] = 16'd128;
    atan_table[10] = 16'd64;
    atan_table[11] = 16'd32;
    atan_table[12] = 16'd16;
    atan_table[13] = 16'd8;
    atan_table[14] = 16'd4;
    atan_table[15] = 16'd2;
end

reg state;
reg [4:0]iter_cnt;
reg signed [31:0]x_reg,y_reg;
reg signed [16:0] z_reg;
reg signed [47:0] mult_tmp_x;
reg signed [47:0] mult_tmp_y;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        state <= IDLE;
    else begin
        case(state)
            IDLE:     state <= start ? TRANSMIT : IDLE;
            TRANSMIT: state <= done ? IDLE : TRANSMIT;
        endcase
    end
end

always @(posedge clk or negedge rst_n)begin
    if (!rst_n)begin
        done <= 1'b0;
        iter_cnt <= 5'b0;
        x_reg <= 32'b0;
        y_reg <= 32'b0;
        z_reg <= 17'b0;
        x_out <= 32'b0;
        y_out <= 32'b0;
        z_out <= 17'b0;
    end else begin
        if (!done && state)begin
            case (sel)
                2'b0: begin
                    if (iter_cnt == 1'b0) begin
                        if (z_in[16] == 1'b0) begin
                            x_reg <= x_in - (y_in >>> iter_cnt);
                            y_reg <= y_in + (x_in >>> iter_cnt);
                            z_reg <= z_in - atan_table[iter_cnt];
                        end else begin
                            x_reg <= x_in + (y_in >>> iter_cnt);
                            y_reg <= y_in - (x_in >>> iter_cnt);
                            z_reg <= z_in + atan_table[iter_cnt];
                        end
                        iter_cnt <= iter_cnt + 1'b1;
                    end else if (iter_cnt < ITER_NUM) begin
                        if (z_reg[16] == 1'b0) begin
                            x_reg <= x_reg - (y_reg >>> iter_cnt);
                            y_reg <= y_reg + (x_reg >>> iter_cnt);
                            z_reg <= z_reg - atan_table[iter_cnt];
                        end else begin
                            x_reg <= x_reg + (y_reg >>> iter_cnt);
                            y_reg <= y_reg - (x_reg >>> iter_cnt);
                            z_reg <= z_reg + atan_table[iter_cnt];
                        end
                        iter_cnt <= iter_cnt + 1'b1;
                    end else if(iter_cnt == ITER_NUM)begin
                        mult_tmp_x <= x_reg * K;
                        mult_tmp_y <= y_reg * K;
                        iter_cnt <= iter_cnt + 1'b1;
                    end else begin
                        done <= 1'b1;
                        x_out <= mult_tmp_x[47:16];
                        y_out <= mult_tmp_y[47:16];
                        z_out <= 1'b0;
                    end
                end
                2'b1: begin
                    if (iter_cnt == 1'b0) begin
                        if (y_in[31] == 1'b0) begin
                            x_reg <= x_in + (y_in >>> iter_cnt);
                            y_reg <= y_in - (x_in >>> iter_cnt);
                            z_reg <= atan_table[iter_cnt];
                        end else begin
                            x_reg <= x_in - (y_in >>> iter_cnt);
                            y_reg <= y_in + (x_in >>> iter_cnt);
                            z_reg <= - atan_table[iter_cnt];
                        end
                        iter_cnt <= iter_cnt + 1'b1;
                    end else if (iter_cnt < ITER_NUM) begin
                        if (y_reg[31] == 1'b0) begin
                            x_reg <= x_reg + (y_reg >>> iter_cnt);
                            y_reg <= y_reg - (x_reg >>> iter_cnt);
                            z_reg <= z_reg + atan_table[iter_cnt];
                        end else begin
                            x_reg <= x_reg - (y_reg >>> iter_cnt);
                            y_reg <= y_reg + (x_reg >>> iter_cnt);
                            z_reg <= z_reg - atan_table[iter_cnt];
                        end
                        iter_cnt <= iter_cnt + 1'b1;
                    end else if(iter_cnt == ITER_NUM)begin
                        mult_tmp_x <= x_reg * K;
                        mult_tmp_y <= y_reg * K;
                        iter_cnt <= iter_cnt + 1'b1;
                    end else begin
                        done <= 1'b1;
                        x_out <= mult_tmp_x[47:16];
                        y_out <= mult_tmp_y[47:16];
                        z_out <= z_reg;
                    end
                end
                default: done <= 1'b0;
            endcase
        end else if (done)begin
            done <= 1'b0;
            iter_cnt <= 5'b0;
        end
    end
end

endmodule
