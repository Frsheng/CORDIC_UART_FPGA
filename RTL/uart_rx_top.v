module uart_rx_top #(
    parameter CLK_FREQ = 50_000_000,
    parameter BPS = 9_600,
    parameter BYTES_NUM = 12
)(
    input clk,
    input rst_n,
    input rx_in,
    (*keep = "true"*)
    (*mark_debug = "true"*)
    output reg [BYTES_NUM*8-1:0] data_out,
    output reg done
);

wire [7:0] rx_data;
wire rx_done;
reg [3:0] rx_cnt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        data_out <= 'b0;
        rx_cnt <= 'b0;
        done <= 1'b0;
    end else if(rx_done) begin
        if (rx_cnt < BYTES_NUM - 1) begin
            data_out <= {data_out[BYTES_NUM*8-9:0], rx_data};
            rx_cnt <= rx_cnt + 1;
        end else if(rx_cnt == BYTES_NUM - 1) begin
            data_out <= {data_out[BYTES_NUM*8-9:0], rx_data};
            done <= 1'b1;
            rx_cnt <= 'b0; // 重置计数器以准备下一轮接收
        end
    end else begin
        done <= 1'b0; // 在没有接收完成时保持done信号为0
    end
end

uart_rx #(
    .CLK_FREQ(CLK_FREQ),
    .BPS(BPS)
)RX(
    .rx_in(rx_in),
    .rst_n(rst_n),
    .clk(clk),
    .data(rx_data),
    .done(rx_done)
);
endmodule
