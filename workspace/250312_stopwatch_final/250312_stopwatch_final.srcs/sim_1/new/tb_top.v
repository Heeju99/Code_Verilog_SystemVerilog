`timescale 1ns / 1ps

module tb_top();

    reg clk, reset, btn_left, btn_up, btn_down;
    reg [1:0] switch_mode;
    wire [3:0] fnd_comm;
    wire [7:0] fnd_font;
    wire [3:0] led;

    top_stopwatch dut(
    .clk(clk),
    .reset(reset),
    .switch_mode(switch_mode),
    .btn_left(btn_left),
    .btn_up(btn_up),
    .btn_down(btn_down),
    .fnd_comm(fnd_comm),
    .fnd_font(fnd_font),
    .led(led)
    );

    always #5 clk = ~clk;
    initial begin
        clk = 0;
        reset = 1;
        btn_left = 1'b0;
        btn_down = 1'b0;
        btn_up = 1'b0;

        #10;
        reset = 0;
        
      #10;
        switch_mode = 2'b11;

    #10000000;
        btn_down = 1'b1;
    #10000000;
        btn_down = 1'b0;
    #10000000;
        btn_down = 1'b1;
    #10000000;
        btn_down = 1'b0;
    end 
endmodule
