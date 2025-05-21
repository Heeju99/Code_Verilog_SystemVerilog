`timescale 1ns / 1ps

module tb_i2c_master();

    //Global Input
    reg clk;
    reg reset;
    //external
    reg [7:0] tx_data;
    reg start;
    reg i2c_en;
    reg stop;
    //interanal signal
    wire SCL;
    wire SDA;
    wire tx_done;
    reg  ACK;


    I2C_Master dut(
        .*
);

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        #10 reset = 0;

        @(posedge clk);
        start = 1; tx_data = 8'h01; ACK = 1;//0000_0001(Write) A
        @(posedge clk);
        wait(tx_done == 1);

        @(posedge clk);
        tx_data = 8'haa;
        @(posedge clk);
        wait(tx_done == 1); 
/*        
        @(posedge clk);
        tx_data = 8'h55;
        @(posedge clk);
        start = 0;
        //wait(tx_done == 1); 
        
        @(posedge clk);
        stop = 1;
        @(posedge clk);

        #2000;
        $finish;
*/
    end
endmodule
