`timescale 1ns / 1ps

module Image_VGA(
    input   logic   clk,
    input   logic   [2:0] sw_mode,
    input   logic   sw,
    input   logic   reset,
    output  logic   h_sync,
    output  logic   v_sync,
    output  logic   [3:0] filter_red,//red_port,
    output  logic   [3:0] filter_green,//green_port,
    output  logic   [3:0] filter_blue//blue_port
    );
 
    logic DE;
    logic [9:0] x_pixel, y_pixel;
    logic [3:0] r_red_port, r_blue_port, r_green_port;
    logic [3:0] red_port, blue_port, green_port;
    logic [3:0] r_filter_red, r_filter_blue,r_filter_green;
    logic [3:0] g_filter_red, g_filter_green, g_filter_blue;

    VGA_Controller U_VGA_Controller(.*);

    Image_Rom U_Image_Rom(.*);

    rgb_filter U_rgb_filter(.*);

    grayscale_converter U_grayscale_converter(.*);

    mux_2x1 U_Mux_2x1(.*);

endmodule
