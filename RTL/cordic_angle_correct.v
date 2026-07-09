module cordic_angle_correct(
    input clk,
    input rst_n,
    input start,
    input sel,
    input signed [31:0]x_in,y_in,z_in,
    output reg signed [31:0]x_out,y_out,z_out,
    output reg [1:0] vec_theta_adj,// 00: 无修正 01：追加pi/2 10：追加pi
    output reg done
);

localparam IDLE     = 2'b00;
localparam INIT_CP  = 2'b01;
localparam RUN      = 2'b10;

localparam signed pi_0_5 = 102944;
localparam signed pi = 205887;
localparam signed pi_2 = 411775 ;
localparam signed pi_10 = 2058874;

reg next;
reg [1:0]state;
reg signed [31:0]x_reg,y_reg,z_reg;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= IDLE;
    end else begin
        case(state)
            IDLE:     state <= start ? INIT_CP : IDLE;
            INIT_CP:  state <= next ? RUN : INIT_CP;
            RUN:      state <= done ? IDLE : RUN;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        x_reg <= 32'b0;
        y_reg <= 32'b0;
        z_reg <= 32'b0;
        next <= 1'b0;
    end else if (next) begin
        next <= 1'b0;
    end else if (state == INIT_CP) begin
        x_reg <= x_in;
        y_reg <= y_in;
        z_reg <= z_in;
        next <= 1'b1;
    end else if (state == RUN) begin
        if (sel == 1'b0) begin
            if (z_reg < -pi_10) begin
                z_reg <= z_reg + pi_10;
            end else if (z_reg > pi_10) begin
                z_reg <= z_reg - pi_10;
            end else if (z_reg < -pi) begin
                z_reg <= z_reg + pi_2;
            end else if (z_reg > pi) begin
                z_reg <= z_reg - pi_2;
            end else if (z_reg < -pi_0_5) begin
                z_reg <= z_reg + pi;
                x_reg <= -x_reg;
                y_reg <= -y_reg;
            end else if (z_reg > pi_0_5) begin
                z_reg <= z_reg - pi;
                x_reg <= -x_reg;
                y_reg <= -y_reg;
            end
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        x_out <= 32'b0;
        y_out <= 32'b0;
        z_out <= 32'b0;
        vec_theta_adj <= 2'b00;
        done <= 1'b0;
    end else if (state == RUN) begin
        if (sel == 1'b0) begin
            if (z_reg <= pi_0_5 && z_reg >= -pi_0_5) begin
                x_out <= x_reg;
                y_out <= y_reg;
                z_out <= z_reg;
                done <= 1'b1;
            end else begin
                done <= 1'b0;
            end
        end else if (sel == 1'b1) begin
            if (x_reg >= 0 && y_reg >= 0) begin
                x_out <= x_reg;
                y_out <= y_reg;
                z_out <= z_reg;
                vec_theta_adj <= 2'b00;
                done <= 1'b1;
            end else if (x_reg < 0 && y_reg >= 0) begin
                x_out <= y_reg;
                y_out <= -x_reg;
                z_out <= z_reg;
                vec_theta_adj <= 2'b01;
                done <= 1'b1;
            end else if (x_reg < 0 && y_reg < 0) begin
                x_out <= -x_reg;
                y_out <= -y_reg;
                z_out <= z_reg;
                vec_theta_adj <= 2'b10;
                done <= 1'b1;
            end else if (x_reg >= 0 && y_reg < 0) begin
                x_out <= -y_reg;
                y_out <= x_reg;
                z_out <= z_reg;
                vec_theta_adj <= 2'b00;
                done <= 1'b1;
            end else begin
                done <= 1'b0;
            end
        end
    end else begin
        done <= 1'b0;
    end
end

endmodule
