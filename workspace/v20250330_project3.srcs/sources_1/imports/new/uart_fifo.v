`timescale 1ns / 1ps

module uart_fifo(
    input clk,
    input reset,
    input rx,
    input wr_tx,
    input [7:0] wdata_tx,
    output empty_rx_b,
    output [7:0] rdata_rx,
    output tx
    );

    wire w_rx_done, w_tx_done;
    wire full_rx, empty_rx, full_tx, empty_tx;
    wire [7:0] data_rx_tx, rdata_tx, wdata_rx;

    assign empty_rx_b = ~empty_rx;

    uart U_uart(
        .clk(clk),
        .rst(reset),
        .btn_start(~empty_tx), // input
        .tx_data_in(rdata_tx),
        .tx(tx),
        .tx_done(w_tx_done),
        .rx(rx),
        .rx_done(w_rx_done),
        .rx_data(wdata_rx)
    );

    fifo U_FIFO_RX(
        .clk(clk),
        .reset(reset),
        .wdata(wdata_rx),
        .wr(w_rx_done),
        .rd(~full_tx),
        .full(full_rx),
        .empty(empty_rx),
        .rdata(rdata_rx)
    );

    fifo U_FIFO_TX(
        .clk(clk),
        .reset(reset),
        .wdata(wdata_tx),
        .wr(wr_tx),
        .rd(~w_tx_done), 
        .full(full_tx),
        .empty(empty_tx),
        .rdata(rdata_tx)
    );

endmodule
