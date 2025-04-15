`timescale 1ns / 1ps

module TOP_STOPWATCH_WATCH(
    input clk,
    input reset,
    input run,
    input clear,
    input cu_sec,
    input cu_min,
    input cu_hour,
    input [1:0] sel_mode,
    input [2:0] sw_plus_minus,
    output [6:0] msec,
    
    output [15:0] sec_msec,
    output [15:0] hour_min,
    output [4:0] led
    );

    wire [6:0] st_msec;
    wire [5:0] st_sec, st_min;
    wire [4:0] st_hour;
    wire [6:0] clk_msec;
    wire [5:0] clk_sec, clk_min;
    wire [4:0] clk_hour;

    wire [5:0] sec, min;
    wire [4:0] hour;

    assign sec_msec[15:8] = sec;
    assign sec_msec[7:0] = msec;
    assign hour_min[15:8] = hour;
    assign hour_min[7:0] = min;

    stopwacth_dp U_stopwatch_dp1 (
        .clk  (clk),
        .reset(reset),
        .run  (run),
        .clear(clear),
        .msec (st_msec),
        .sec  (st_sec),
        .min  (st_min),
        .hour (st_hour)
    );

    wacth_dp U_watch_dp1 (
        .clk(clk),
        .reset(reset),
        .cu_sec_up(cu_sec),
        .cu_min_up(cu_min),
        .cu_hour_up(cu_hour),
        .msec(clk_msec),
        .sec(clk_sec),
        .min(clk_min),
        .hour(clk_hour),
        .sw_mode(sw_plus_minus) // plus, minus
    );

    mux_8x4 U_mux_8x4 (
        .sw_mode(sel_mode),
        .stw_msec(st_msec),
        .stw_sec(st_sec),
        .stw_min(st_min),
        .stw_hour(st_hour),
        .wat_msec(clk_msec),
        .wat_sec(clk_sec),
        .wat_min(clk_min),
        .wat_hour(clk_hour),
        .final_msec(msec),
        .final_sec(sec),
        .final_min(min),
        .final_hour(hour)
    );
    led_on_off U_led1 (
        .sw_mode(sw_mode),
        .led(led)
    );

endmodule

