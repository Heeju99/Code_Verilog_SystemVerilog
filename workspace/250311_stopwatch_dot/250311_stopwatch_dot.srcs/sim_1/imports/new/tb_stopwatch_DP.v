`timescale 1ns / 1ps

module tb_stopwatch_DP();

    reg clk, reset, run, clear;
    wire [6:0] msec, sec, min;
    wire [4:0] hour;

    stopwatch_DP dut(
    .clk(clk),
    .reset(reset),
    .clear(clear)   ,
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
        wait(hour == 23);


        wait(hour == 1);
        #10; run = 0;
        repeat(4) @ (posedge clk) // 4번 반복, clk posedge 이벤트
        clear = 1;
        #100;
    end
endmodule
