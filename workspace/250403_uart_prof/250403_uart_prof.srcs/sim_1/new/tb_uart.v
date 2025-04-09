`timescale 1ns / 1ps

module tb_uart();

    reg clk, reset, rx, tx_start;
    reg [7:0] tx_data;
    wire tx_done, tx_busy, tx, rx_data, rx_done;

    uart1 dut(
    .clk(clk),
    .reset(reset),
    .tx_data(tx_data),
    .tx_start(tx_start),
    .rx(tx), //loop 위해 tx로 연결
    .tx_done(tx_done),
    .tx_busy(tx_busy),
    .tx(tx),
    .rx_data(rx_data),
    .rx_done(rx_done)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        
        #10 reset = 0;
        @(posedge clk);
        #1 tx_data = 8'b11001010;
        tx_start = 1;
        @(posedge clk);
        #1 tx_start = 0;
        @(posedge rx_done);
        #20;
        $finish;
    end
endmodule
