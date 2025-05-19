`timescale 1ns / 1ps
module tb_spi_master();

    logic       clk;
    logic       reset;
    logic       start;
    logic       cpol;
    logic       cpha;
    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic       done;
    logic       ready;
    logic       SCLK;
    logic       MOSI;
    logic       MISO;

    SPI_MASTER dut(.*);

    assign MISO = MOSI;

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        #10 reset = 0;
        
        repeat (3) @(posedge clk); //clk 3번 후에 동작

        @(posedge clk);
        tx_data = 8'haa; start = 1; cpol = 1; cpha = 1; 
        @(posedge clk);
        start = 0;
        wait(done == 1); 
        @(posedge clk);

        @(posedge clk);
        tx_data = 8'h55; start = 1; cpol = 0; cpha = 0;
        @(posedge clk);
        start = 0;
        wait(done == 1); 
        @(posedge clk);

    end

endmodule
