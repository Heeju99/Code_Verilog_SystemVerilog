`timescale 1ns / 1ps

module CTRL_UNIT(   
    input clk, // FPGA
    input reset, // FPGA
    input [4:0] sw_mode, // FPGA
    input [7:0] rdata_rx, // uart
    input empty_rx_b, // uart
    input btn_left, // FPGA
    input btn_right, // FPGA
    input btn_down,  //FPGA

    // HC-SR04 input
    input echo, // sensor
    input wr_tx_HCSR04, // CU(uart)
    input [7:0] data_HCSR04_tx, // CU(uart)

    // DHT11 input
    input wr_tx_DHT11, // DP to CU(uart)
    input [7:0] data_DHT11_tx, // DP to CU(uart)

    // UART output
    output reg [7:0] wdata_tx,
    output reg wr_tx,

    // STOPWATCH, WATCH output
    output run, // DP
    output clear, // DP
    output cu_sec, // DP
    output cu_min, // DP
    output cu_hour, // DP

    // HC-SR04 output 
    output trigger, // sensor
    output echo_done, // DP
    output [8:0] distance,  // mux

    // DHT11  output
    output [39:0] data_DHT11_out, // DP
    output dht_done, // DP

    inout dht_io // sensor
    );

    wire w_left, w_right, w_down;

    uart_btn_cu U_btn_cu(
        .clk(clk),
        .reset(reset),
        .data_in(rdata_rx),
        .empty_rx_b(empty_rx_b),
        .btn_left(btn_left),
        .btn_right(btn_right),
        .btn_down(btn_down),
        .sw_mode(sw_mode[4:3]),
        .left(w_left),
        .right(w_right),
        .down(w_down)
    );
    
     stopwatch_cu U_stopwatch_cu (
        .clk(clk),
        .reset(reset),
        .btn_left(w_left),  
        .btn_right(w_right),
        .sw_mode(sw_mode[4:3]),
        .o_run(run),
        .o_clear(clear)
    );

     watch_cu U_watch_cu (
        .clk(clk),
        .reset(reset),
        .btn_left(w_left),
        .btn_down(w_down),
        .btn_right(w_right),
        .sw_mode(sw_mode[4:3]),
        .o_sec_up(cu_sec),
        .o_min_up(cu_min),
        .o_hour_up(cu_hour)
    );

    HCSR04_cu U_HCSR04_cu(
        .clk(clk),
        .reset(reset),
        .btn_trig(w_left),
        .sw_mode(sw_mode[4:3]),
        .echo(echo),
        .trigger(trigger),
        .distance(distance),
        .echo_done(echo_done)
    );

    DHT11_CU U_DHT11_CU(
        .clk(clk),
        .reset(reset),
        .btn_start(w_left),
        .sw_mode(sw_mode[4:3]),
        .data_out(data_DHT11_out), // 40bit
        .led(led),
        .dht_done(dht_done),
        .dht_io(dht_io)
    );

    always @(*) begin
        if(sw_mode[4:3] == 2'b00 || sw_mode[4:3] == 2'b01) begin
            wdata_tx = rdata_rx;
            wr_tx = empty_rx_b;
        end
        else if(sw_mode[4:3] == 2'b10) begin
            wdata_tx = data_HCSR04_tx;
            wr_tx = wr_tx_HCSR04;
        end
        else if(sw_mode[4:3] == 2'b11) begin
            wdata_tx = data_DHT11_tx;
            wr_tx = wr_tx_DHT11;
        end
    end
endmodule
