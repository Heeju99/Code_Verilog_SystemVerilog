`timescale 1ns / 1ps

module tb_uart_tx();
    reg clk, reset;
    //reg [7:0] data;
    reg rx;
    wire w_baud_tick, w_rx_done;
    wire [7:0] rx_data;

    /*send_tx_btn dut(
    .clk(clk),
    .reset(reset),
    .btn_start(btn_start),
    .tx(tx)
    );*/
    Uart_RX dut(
    .clk(clk),
    .reset(reset),
    .tick(w_baud_tick),
    .rx(rx),
    .rx_done(w_rx_done),
    .rx_data(rx_data)
);

    Baud_Tick_Gen dut1(
    .clk(clk),
    .reset(reset),
    .baud_tick(w_baud_tick)
);

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        rx = 1;
        #10;
        reset = 0;

        #100;
        rx = 0; //start
    #104160;
        rx = 1; //data0
    #104160;
        rx = 0; //data1
    #104160;
        rx = 0; //data2
    #104160;
        rx = 0; //data3
    #104160;
        rx = 1; //data4
    #104160;
        rx = 1; //data5
    #104160;
        rx = 0; //data6
    #104160;
        rx = 0; //data7
    #104160;
        rx = 1; //stop
    #10000;
    $stop;
        /*btn_start = 1'b0;

        #10;
        reset = 0;
	   #100000; 
	    btn_start = 1'b1;
	   #100000; 
	    btn_start = 1'b0;*/

    end
endmodule