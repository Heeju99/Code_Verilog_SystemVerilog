`timescale 1ns / 1ps

module tb_machine();
    reg clk, reset, i_bit;
    wire o_bit;

    machine dut(
        clk,      
        reset,
        i_bit,
        o_bit
    );

    always #5 clk = ~clk;
    initial begin
        clk = 0;
        #10
        reset = 1;
        #10
        reset = 0;
        #10
        i_bit = 0;
        #10
        i_bit = 0;
        #10
        i_bit = 0;
        #10
        i_bit = 1;
        #10
        i_bit = 1;
        #10
        i_bit = 1;
        $stop;
    end
endmodule
