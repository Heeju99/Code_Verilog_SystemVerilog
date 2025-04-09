`timescale 1ns / 1ps


module tb_counter_adder_55();

    logic clk,reset;
    logic [7:0] OutPort;

    Counter_adder_55 dut(
        .clk(clk),
        .reset(reset),
        .OutPort(OutPort)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;

        #10 reset = 0;
    end
endmodule
