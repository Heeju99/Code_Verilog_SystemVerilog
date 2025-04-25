`timescale 1ns / 1ps

module tb_FIFO();

    logic       clk;
    logic       reset;
    
    logic       wr_en;
    logic [7:0] wdata;
    logic       full;
    
    logic       empty;
    logic       rd_en;
    logic [7:0] rdata;


    FIFO DUT(
        .*
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        #10 reset = 0;
        @(posedge clk) #1; wdata = 1; wr_en = 1; rd_en = 0;
        @(posedge clk) #1; wdata = 2; wr_en = 1; rd_en = 0;
        @(posedge clk) #1; wdata = 3; wr_en = 1; rd_en = 0;
        @(posedge clk) #1; wdata = 4; wr_en = 1; rd_en = 0;
        @(posedge clk);
        @(posedge clk) #1; rd_en = 1; wr_en = 0; 
        @(posedge clk) #1; rd_en = 1; wr_en = 0;
        @(posedge clk) #1; rd_en = 1; wr_en = 0;
        @(posedge clk) #1; rd_en = 1; wr_en = 0;
        #20; $finish;
    end
endmodule