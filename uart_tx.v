module uart_tx #(
    parameter CLK_FREQ = 50_000_000,
    parameter BPS      = 9_600
)(
    input        clk,
    input        rst_n,
    input        start,
    input  [7:0] data,
    output reg   tx_out,
    output reg   done
);

localparam IDLE     = 1'b0;
localparam TRANSMIT = 1'b1;

reg       state;
reg [7:0] r_data;
reg [12:0] baud_cnt;
reg       bit_flag;
reg [3:0] bit_cnt;

localparam BPS_CNT_MAX = CLK_FREQ / BPS - 1;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        r_data <= 8'd0;
    else if(start)
        r_data <= data;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        state <= IDLE;
    else begin
        case(state)
            IDLE:     state <= start ? TRANSMIT : IDLE;
            TRANSMIT: state <= (bit_flag && bit_cnt == 4'd10) ? IDLE : TRANSMIT;
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
    else if(state == TRANSMIT && baud_cnt >= BPS_CNT_MAX)
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
        if(bit_cnt == 4'd10)
            bit_cnt <= 4'd0;
        else
            bit_cnt <= bit_cnt + 4'd1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        tx_out <= 1'b1;
    else if(state == TRANSMIT) begin
        if(bit_flag) begin
            case(bit_cnt)
                4'd0:  tx_out <= 1'b0;
                4'd1:  tx_out <= r_data[0];
                4'd2:  tx_out <= r_data[1];
                4'd3:  tx_out <= r_data[2];
                4'd4:  tx_out <= r_data[3];
                4'd5:  tx_out <= r_data[4];
                4'd6:  tx_out <= r_data[5];
                4'd7:  tx_out <= r_data[6];
                4'd8:  tx_out <= r_data[7];
                4'd9:  tx_out <= 1'b1;
                4'd10: tx_out <= 1'b1;
                default: tx_out <= 1'b1;
            endcase
        end
    end
    else
        tx_out <= 1'b1;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        done <= 1'b0;
    else
        done <= (state == TRANSMIT) && (bit_flag) && (bit_cnt == 4'd10);
end

endmodule