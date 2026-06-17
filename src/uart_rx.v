module uart_rx #(
    parameter CLK_FREQ = 50_000_000,  
    parameter BPS      = 9_600        
)(
    input rx_in,
    input rst_n,
    input clk,
    output reg [7:0] data,
    output reg done
);

localparam IDLE     = 1'b0;
localparam TRANSMIT = 1'b1;
//
wire nedge;
reg rx_1, rx_2, rx_3;
reg [3:0] bit_cnt;
reg [12:0] baud_cnt;
reg state;
reg bit_flag;

localparam BPS_CNT_MAX = CLK_FREQ / BPS - 1;

localparam SAMPLE_POINT = BPS_CNT_MAX / 2;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        rx_1 <= 1'b1;
        rx_2 <= 1'b1;
        rx_3 <= 1'b1;
    end else begin
        rx_1 <= rx_in;
        rx_2 <= rx_1;
        rx_3 <= rx_2;
    end
end

assign nedge = !rx_2 && rx_3;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        state <= IDLE;
    end else begin
        case(state)
            IDLE:     state <= nedge ? TRANSMIT : IDLE;
            TRANSMIT: state <= (bit_flag && bit_cnt == 4'd9) ? IDLE : TRANSMIT;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        baud_cnt <= 13'd0;
    else if(state == TRANSMIT) begin
        if(baud_cnt >= BPS_CNT_MAX)
            baud_cnt <= 13'd0;
        else
            baud_cnt <= baud_cnt + 13'd1;
    end
    else
        baud_cnt <= 13'd0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        bit_flag <= 1'b0;
    else if(state == TRANSMIT && baud_cnt == SAMPLE_POINT)
        bit_flag <= 1'b1;
    else
        bit_flag <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        bit_cnt <= 4'd0;
    else if(state == IDLE)
        bit_cnt <= 4'd0;
    else if(bit_flag) begin
        if(bit_cnt == 4'd9)
            bit_cnt <= 4'd0;
        else
            bit_cnt <= bit_cnt + 4'd1;
    end
end
//
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        data <= 8'd0;
    else if(state == TRANSMIT) begin
        if(bit_flag) begin
            case(bit_cnt)
                4'd1:  data[0] <= rx_3;
                4'd2:  data[1] <= rx_3;
                4'd3:  data[2] <= rx_3;
                4'd4:  data[3] <= rx_3;
                4'd5:  data[4] <= rx_3;
                4'd6:  data[5] <= rx_3;
                4'd7:  data[6] <= rx_3;
                4'd8:  data[7] <= rx_3;
            endcase
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        done <= 1'b0;
    else
        done <= (state == TRANSMIT) && (bit_flag) && (bit_cnt == 4'd9);
end

endmodule
