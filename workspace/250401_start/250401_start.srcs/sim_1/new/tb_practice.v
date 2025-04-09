`timescale 1ns / 1ps

module tb_practice();

    reg clk, reset, mode;


    top_counter dut(
    .clk(clk),
    .reset(reset),
    .mode(mode)
);

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset =1;
        mode = 1;

        #10
        reset = 0;


        #4000000
        mode = 0;
    end
endmodule
