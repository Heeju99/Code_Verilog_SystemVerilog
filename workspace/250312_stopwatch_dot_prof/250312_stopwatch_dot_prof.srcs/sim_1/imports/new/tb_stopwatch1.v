`timescale 1ns/1ps

module stopwatch_tb;

    reg clk, reset, run, clear, switch_mode;
    wire [6:0] msec;
    wire [5:0] sec;
    wire [5:0] min;
    wire [4:0] hour;
    wire [3:0] fnd_comm;
    wire [7:0] fnd_font;

    stopwatch_DP dut(
    .clk(clk),
    .reset(reset),
    .clear(clear),
    .run(run),
    .msec(msec),
    .sec(sec),
    .min(min),
    .hour(hour)
    );

    fnd_controller dut1(
    .clk(clk), 
    .reset(reset),
    .switch_mode(switch_mode),
    .msec(msec),
    .sec(sec),
    .min(min),
    .hour(hour),
    .fnd_font(fnd_font),
    .fnd_comm(fnd_comm)
);

    // Clock generation
    always #5 clk = ~clk;

    // Test procedure
    initial begin
    clear = 1;
    clk = 0;
    reset = 0;
    run = 0;
    switch_mode = 0;

        reset = 1;
        #10 reset = 0; 
        #10 clear = 0; 

        run = 1;
        #5_000_000;  

        switch_mode = 1;
        #100;  

        run = 0;
        #500;

        reset = 1;
        #10 reset = 0;
    end

endmodule
