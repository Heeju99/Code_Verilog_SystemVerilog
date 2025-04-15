`timescale 1ns / 1ps

module mux_8x4 (
    input [1:0] sw_mode,
    input [6:0] stw_msec,
    input [5:0] stw_sec,
    input [5:0] stw_min,
    input [4:0] stw_hour,
    input [6:0] wat_msec,
    input [5:0] wat_sec,
    input [5:0] wat_min,
    input [4:0] wat_hour,
    output reg [6:0] final_msec,
    output reg [5:0] final_sec,
    output reg [5:0] final_min,
    output reg [4:0] final_hour
);
    always @(sw_mode) begin
        if (sw_mode == 2'b00) begin
            final_msec = stw_msec;
            final_sec  = stw_sec;
            final_min  = stw_min;
            final_hour = stw_hour;
        end else if (sw_mode == 2'b01) begin
            final_msec = wat_msec;
            final_sec  = wat_sec;
            final_min  = wat_min;
            final_hour = wat_hour;
        end
    end
endmodule