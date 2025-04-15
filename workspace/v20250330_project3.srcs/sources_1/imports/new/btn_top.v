`timescale 1ns / 1ps

module btn_top(
    input clk,
    input reset,
    input btn_left,
    input btn_right,
    input btn_down,
    output o_left,
    output o_right,
    output o_down
    );

    btn_debounce bd_left (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_left),
        .o_btn(o_left)
    );
    btn_debounce bd_right (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_right),
        .o_btn(o_right)
    );
    btn_debounce bd_down (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_down),
        .o_btn(o_down)
    );

endmodule
