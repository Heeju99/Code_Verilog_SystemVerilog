`timescale 1ns / 1ps

module tb_sensor_uart();

    reg clk, reset,echo, btn_start, rx;
    wire [7:0] seg;
    wire [3:0] seg_comm;
    wire trigger, tx, led;

    sensor dut(
    .clk(clk),
    .reset(reset),
    .echo(echo),
    .btn_start(btn_start),
    .trigger(trigger),
    .rx(rx),
    .tx(tx),
    .seg(seg),
    .seg_comm(seg_comm),
    .led(led)
);
    integer j = 0;
    always begin
        #5 clk = ~clk; 
    end
    
    initial begin
        clk = 0;
        reset = 1;
        echo = 0;
        btn_start = 0;
        j = 0; 
        #10;
        reset = 0;
        #10000
        /*
        btn_start = 1;
        #10;
        btn_start = 0;
        */

        for(j = 0; j < 6; j = j +1) begin
        rx = 0; #104160; send_bit("o"); rx = 1; #104160;

        #11000;
        echo = 1;
      #725000; //640u  12.5cm
        echo = 0;
        #110000;
        end
    end
    task send_bit(input [7:0] data);
        integer i;
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
            #104160;
            end
    endtask

endmodule