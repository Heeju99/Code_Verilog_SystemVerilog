`timescale 1ns / 1ps

module TOP_HCSR04(
    input clk,
    input reset,
    input btn_left,
    input echo,
    input [1:0] sw_mode, 
    input [11:0] distance_digit,
    output trigger,
    output wr_tx,
    output [8:0] distance,
    output [7:0] wdata_tx
    );

    wire w_echo_done;

    HCSR04_cu U_HCSR04_cu(
        .clk(clk),
        .reset(reset),
        .btn_trig(btn_left),
        .sw_mode(sw_mode),
        .echo(echo),
        .trigger(trigger),
        .distance(distance),
        .echo_done(w_echo_done)
    );

    HCSR04_dp U_HCSR04_dp(
        .clk(clk),
        .reset(reset),
        .echo_done(w_echo_done),
        .distance_digit(distance_digit),
        .wr_tx(wr_tx),
        .data_sensor_tx(wdata_tx)
    );

endmodule
