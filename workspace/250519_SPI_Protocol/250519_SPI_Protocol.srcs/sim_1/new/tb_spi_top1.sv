`timescale 1ns / 1ps

module tb_spi_top1();

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
    logic       SS;

    SPI_MASTER dut(.*);

    SPI_SLAVE dut1(.*);

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        #10 reset = 0;
        
        repeat (3) @(posedge clk); //clk 3번 후에 동작

        SS = 1;
        @(posedge clk); //write, tx_data[7] == 1, address == 0,
        tx_data = 8'b10000000; start = 1; cpol = 0; cpha = 0; 
        SS = 0;
        @(posedge clk);
        start = 0;
        wait(done == 1); 
        @(posedge clk);


        @(posedge clk); //write data 8'h10  address == 0
        tx_data = 8'h10; start = 1; cpol = 0; cpha = 0; 
        @(posedge clk);
        start = 0;
        wait(done == 1); 
        @(posedge clk);

        @(posedge clk); //write data 8'h20  address == 1
        tx_data = 8'h20; start = 1; cpol = 0; cpha = 0; 
        @(posedge clk);
        start = 0;
        wait(done == 1); 
        @(posedge clk);

        @(posedge clk); //write data 8'h30  address == 2
        tx_data = 8'h30; start = 1; cpol = 0; cpha = 0; 
        @(posedge clk);
        start = 0;
        wait(done == 1); 
        @(posedge clk);

        @(posedge clk); //write data 8'h40  address == 3
        tx_data = 8'h40; start = 1; cpol = 0; cpha = 0; 
        @(posedge clk);
        start = 0;
        wait(done == 1); 
        @(posedge clk);

        SS = 1;


        //read saction
        repeat(5) @(posedge clk);
        SS = 0;
        @(posedge clk); // read, address == 0
        tx_data = 8'b00000000; start = 1; cpol = 0; cpha = 0;
        @(posedge clk);
        start = 0;
        wait(done == 1);
        @(posedge clk);

        for(int i = 0; i < 4; i = i + 1) begin
            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;
            wait(done == 1);
            @(posedge clk);
        end

        SS = 1;

        #2000 $finish;
    end

endmodule
