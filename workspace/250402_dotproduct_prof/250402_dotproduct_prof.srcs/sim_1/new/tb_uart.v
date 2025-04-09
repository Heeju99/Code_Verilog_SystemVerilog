`timescale 1ns / 1ps

module tb_uart();

    reg clk, reset, rx;
    //wire [7:0] rx_data;
    //wire rx_done;

    /*uart DUT(
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .rx_data(rx_data),
        .rx_done(rx_done)*/

    top_counter_up_down dut(
    .clk(clk),
    .reset(reset),
    .rx(rx)//,
    //.fndCom(),
    //.fndFont
);


    always #5 clk = ~clk;

    integer i;

    initial begin
        clk = 0;
        reset = 1;
        rx = 0;

        #1000;
        reset = 0;
        #1000;

        for(i=0;i<5;i=i+1) begin
            rx = 0; #104160; send_bit("r"); rx = 1; #104160;

            rx = 0; #104160; send_bit("s"); rx = 1; #104160;

            rx = 0; #104160; send_bit("c"); rx = 1; #104160;

            rx = 0; #104160; send_bit("m"); rx = 1; #104160;
        end
        

        #10000000;

        #1000;
         $stop;
    end

    task send_bit(input [7:0] data);
        integer i;
        for (i = 0; i < 8; i = i + 1) begin
            rx = data[i];
            #104160;
        end
    endtask

endmodule