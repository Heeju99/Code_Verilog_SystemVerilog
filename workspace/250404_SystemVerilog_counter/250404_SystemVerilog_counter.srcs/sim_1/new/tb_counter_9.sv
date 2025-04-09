`timescale 1ns / 1ps

module tb_counter_9();

    logic clk, reset;
    logic [7:0] OutPort;

    counter_9 dut( 
    .clk(clk),
    .reset(reset),
    .OutPort(OutPort)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        OutPort = 0;
        
        #10
        reset = 0;

    end
endmodule
