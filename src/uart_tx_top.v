module uart_tx_top #(
    parameter CLK_FREQ = 50_000_000,
    parameter BPS = 9_600,
    parameter BYTES_NUM = 12
)(
    input clk,
    input start,
    input rst_n,
    input [BYTES_NUM*8-1:0] data_buffer,
    output tx_out
    );

localparam IDLE      = 2'd0;  // 空闲状态
localparam START_BIT = 2'd1;  // 起始位状态
localparam SENDING   = 2'd2;  // 发送状态

reg SS;
reg [1:0]state;
reg [3:0]byte_index;
reg [7:0]current_data;
reg start_transmit;
reg send_start;
wire tx_done;
wire tx_start;
wire [7:0]tx_data;

// 按键控制数据发送
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        SS <= 1'b0;
        start_transmit <= 1'b0;
    end else begin
        case(SS)
            1'b0:begin
                if(!start)begin
                    SS <= 1'b1;
                    start_transmit <= 1'b1;
                end else begin
                    start_transmit <= 1'b0;
                end
            end
            1'b1:begin
                if(start)begin
                    SS <= 1'b0;
                    start_transmit <= 1'b0;
                end else begin
                    start_transmit <= 1'b0;
                end
            end
        endcase
    end
end

// 状态机控制数据发送
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        state <= IDLE;
        send_start <= 'b0;
        byte_index <= 'b0;
    end else begin
        case(state)
            IDLE:begin
                if(start_transmit)begin
                    send_start <= 'b1;
                    byte_index <= 'b1;
                    state <= START_BIT;
                    current_data <= data_buffer[(BYTES_NUM*8 - 1) -: 8];
                end
            end
            START_BIT:begin
                send_start <= 1'b0;
                state <= SENDING;
            end
            SENDING:begin
                if(tx_done)begin
                    if(byte_index == BYTES_NUM)begin
                        state <= IDLE;
                    end else begin
                        send_start <= 1'b1;
                        byte_index <= byte_index + 1;
                        current_data <= data_buffer[(BYTES_NUM*8 - byte_index*8 - 1) -: 8];
                        state <= START_BIT;
                    end
                end
            end
        endcase
    end
end

assign tx_start = send_start;
assign tx_data = current_data;

uart_tx #(.CLK_FREQ(CLK_FREQ),
.BPS(BPS)
) TX (
    .clk(clk),
    .rst_n(rst_n),
    .start(tx_start),
    .data(tx_data),
    .tx_out(tx_out),
    .done(tx_done)
);
endmodule