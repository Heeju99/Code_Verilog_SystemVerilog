`timescale 1ns / 1ps

module tb_sensor();

    logic        PCLK;
    logic        PRESET;
    logic [ 3:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PENABLE;
    logic        PSEL;
    logic [31:0] PRDATA;
    logic        PREADY;
    logic        trigger;
    logic        echo;

    ultrasonic_periph DUT(
        .*
);

/*
module sensor_dp_tb;
    // Input signals
    reg clk;
    reg PRESET;
    reg echo;
    reg btn_start;
    wire trigger;
    wire [8:0] dist;
    
    sensor_dp uut (
        .clk(clk),
        .PRESET(PRESET),
        .echo(echo),
        .btn_start(btn_start),
        .trigger(trigger),
        .dist(dist)
    );
*/  
    always begin
        #5 PCLK = ~PCLK; 
    end
    
    initial begin
        PCLK = 0;
        PRESET = 1;
        echo = 0;
        PWDATA = 0;
        
        #10;
        PRESET = 0;
        
        #10000
        PADDR = 0;
        PWRITE = 1;
        PWDATA = 1;
        PSEL       = 1;
        PENABLE    = 1;

        #11000;
        echo = 1;
        #580000; //580u
        echo = 0;

        #10;
        PADDR = 4;
        PWRITE = 0;  
        PSEL       = 1;
        PENABLE    = 1;
        @(posedge PREADY);
        PSEL = 0;
        PENABLE = 0; 
/*
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
*/
    end

endmodule