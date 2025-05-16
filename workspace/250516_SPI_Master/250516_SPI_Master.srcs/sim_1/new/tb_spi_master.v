`timescale 1ns / 1ps

module tb_spi_master();

    reg     clk;
    reg     reset;
    //Master Left Signal
    reg   start;
    reg   [7:0] tx_data;
    wire  [7:0] rx_data;
    wire done;
    wire ready;
    //to Slave Signal
    wire   sclk;
    wire   mosi;
    reg    miso;
    wire   cs; 

    SPI_MASTER dut(
    //Global Signal
    .clk(clk),
    .reset(reset),
    //Master Left Signal
    .start(start),
    .tx_data(tx_data),
    .rx_data(rx_data),
    .done(done),
    .ready(ready),
    //to Slave Signal
    .sclk(sclk),
    .mosi(mosi),
    .miso(miso),
    .cs(cs) 
);

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        #10 reset = 0;
        #100000 start = 1; tx_data = 8'b10101010;
        #10 start = 0;
        @(posedge done);
    end

endmodule
