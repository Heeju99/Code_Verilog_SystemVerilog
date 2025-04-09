`timescale 1ns / 1ps

module top_stopwatch(
    input clk,
    input reset,
    input switch_mode,
    input btn_run,
    input btn_clear,
    output [3:0] fnd_comm,
    output [7:0] fnd_font
    );

    wire w_run , w_clear, run, clear;
    // wire run, clear;  -> 1bit 짜리는 선언 안해도 1bit로 자동 선언
    wire [6:0] msec; 
    wire [5:0] sec, min;
    wire [4:0] hour;

    stopwatch_DP u_stopwatch_dp(
        .clk(clk),
        .reset(reset),
        .clear(clear),
        .run(run), 
        .msec(msec),
        .sec(sec),
        .min(min),
        .hour(hour)
    );
    button_debounce u_button_debounce_run(
        .clk(clk),
        .reset(reset),
        .i_btn(btn_run),
        .o_btn(w_run)
    );
    button_debounce u_button_debounce_clear(
        .clk(clk),
        .reset(reset),
        .i_btn(btn_clear),
        .o_btn(w_clear)
    );
    stopwatch_CU u_stopwatch_CU(
        .clk(clk),
        .reset(reset),
        .i_btn_run(w_run),
        .i_btn_clear(w_clear),
        .o_run(run),
        .o_clear(clear)
    );

    fnd_controller u_fnd_controller(
        .clk(clk), 
        .reset(reset),
        .switch_mode(switch_mode),
        .msec(msec),
        .sec(sec),
        .min(min),
        .hour(hour),
        .fnd_font(fnd_font),
        .fnd_comm(fnd_comm)
    );

endmodule
