`timescale 1ns / 1ps

module tb_TopCounter();

    logic clk,reset;
    logic [7:0] outPort;

    TopCounter dut(
        .clk(clk),
        .reset(reset),
        .Outport(outPort)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;

        #10
        reset = 0;
        wait(outPort == 8'd55);
    end

endmodule
