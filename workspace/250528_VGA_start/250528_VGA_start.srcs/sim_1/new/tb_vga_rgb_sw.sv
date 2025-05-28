`timescale 1ns / 1ps

module tb_vga_rgb_sw();

    logic clk;
    logic reset;
    logic [3:0] sw_red;
    logic [3:0] sw_green;
    logic [3:0] sw_blue;
    logic  h_sync;
    logic  v_sync;
    logic [3:0] red_port;
    logic [3:0] green_port;
    logic [3:0] blue_port;

    VGA_Controller DUT(.*);

    always #5 clk = ~clk;

    initial begin
        clk = 0; reset = 1;
        #10 reset = 0;
        #10 sw_red = 0; sw_green = 0; sw_blue = 0;
        $finish;
    end
endmodule
