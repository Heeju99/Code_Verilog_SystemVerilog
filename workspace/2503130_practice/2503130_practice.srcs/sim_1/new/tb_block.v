`timescale 1ns / 1ps

module tb_block();
    reg clk, a, b;

    initial begin
        a = 0;
        b = 1;
        clk = 0;
    end

    always
        clk = #5 ~clk;
    always @(posedge clk)begin
        a <= b;
        b <= a;
    end
endmodule
