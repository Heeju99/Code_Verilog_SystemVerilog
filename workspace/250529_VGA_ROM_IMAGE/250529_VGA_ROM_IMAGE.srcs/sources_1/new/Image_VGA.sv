`timescale 1ns / 1ps

module Image_VGA(
    input   logic   clk,
    input   logic   reset,
    output  logic   h_sync,
    output  logic   v_sync,
    output  logic   [3:0] red_port,
    output  logic   [3:0] green_port,
    output  logic   [3:0] blue_port
    );

    logic DE;
    logic [9:0] x_pixel, y_pixel;

    VGA_Controller U_VGA_Controller(.*);

    Image_rom U_Image_rom(.*);

endmodule
