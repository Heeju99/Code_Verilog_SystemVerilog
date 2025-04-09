`timescale 1ns/1ps

module stopwatch_tb;

    reg clk;
    reg reset;
    reg btn_clear;
    reg btn_run;
    reg switch_mode;
    wire [3:0] fnd_comm;
    wire [7:0] fnd_font;

    top_stopwatch dut(
    .clk(clk),
    .reset(reset),
    .switch_mode(switch_mode),
    .btn_run(btn_run),
    .btn_clear(btn_clear),
    .fnd_comm(fnd_comm),
    .fnd_font(fnd_font)
    );

    // Clock generation
    always #1 clk = ~clk;

    // Test procedure
    initial begin
    clk = 0;
    btn_clear = 0;
    btn_run = 0;
    switch_mode = 0;

        reset = 1;
        #10 reset = 0;  

        btn_run = 1;
        #5_000_000;  

        switch_mode = 1;
        #100;  

        btn_clear = 1;
        #10 btn_clear = 0;

        btn_run = 0;
        #500;

        reset = 1;
        #10 reset = 0;
    end

endmodule
