`timescale 1ns / 1ps

module sensor_dp_tb;
    // Input signals
    reg clk;
    reg reset;
    reg echo;
    reg btn_start;
    wire trigger;
    wire [8:0] dist;
    
    sensor_dp uut (
        .clk(clk),
        .reset(reset),
        .echo(echo),
        .btn_start(btn_start),
        .trigger(trigger),
        .dist(dist)
    );
    
    always begin
        #5 clk = ~clk; 
    end
    
    initial begin
        clk = 0;
        reset = 1;
        echo = 0;
        btn_start = 0;
        
        #10;
        reset = 0;
        #10000
        btn_start = 1;
        #10;
        btn_start = 0;

        #11000;
        echo = 1;
      #580000; //580u
        echo = 0;

        #20000
        btn_start = 1;
        #10;
        btn_start = 0;

        #11000;
        echo = 1;
        #290000; //290u
        echo = 0;  
        #50;

        #20000
        btn_start = 1;
        #10;
        btn_start = 0;
        #11000;
        echo = 1;
        #2320000; //2320u
        echo = 0;  
        #50;
    end

endmodule