`timescale 1ns / 1ps

module tb_stopwatch_DP();

    reg clk, reset, run, clear;
    wire [6:0] msec, sec, min;
    wire [3:0] hour;

    stopwatch_DP dut(
    .clk(clk),
    .reset(reset),
    .clear(clear),
    .run(run),
    .msec(msec),
    .sec(sec),
    .min(min),
    .hour(hour)
    );


    always #5 clk = ~clk;
    initial begin
        clk = 0;
        reset = 1;
        run = 0;
        clear = 0;

        #10; reset = 0;
        run = 1;
        wait(sec == 2);
        #10; run = 0;

        
    end
endmodule
