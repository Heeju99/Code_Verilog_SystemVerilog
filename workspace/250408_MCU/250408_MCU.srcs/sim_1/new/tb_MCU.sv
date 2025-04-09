`timescale 1ns / 1ps

module tb_MCU ();

    logic clk;
    logic reset;

    MCU dut (
        .clk  (clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        reset = 1;
        #10 reset = 0;
    end
    
endmodule