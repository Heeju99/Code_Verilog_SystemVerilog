`timescale 1ns / 1ps

module ISP_module(

    );
endmodule


module grayscale_converter(
    //from QVGA MemController
    input  logic [3:0] red_port,
    input  logic [3:0] green_port,
    input  logic [3:0] blue_port,
    //to Sobel
    output logic [3:0] g_filter_red,
    output logic [3:0] g_filter_green,
    output logic [3:0] g_filter_blue
);
    logic [11: 0] gray;
    assign gray = (77 * red_port) + (150 * green_port) + (29 * blue_port);
    assign g_filter_red = gray[11:8];
    assign g_filter_green = gray[11:8];
    assign g_filter_blue = gray[11:8];
endmodule

module sobel(
    input clk,
    input reset,
    //gray-scale
    input logic [3:0] g_filter_red,
    input logic [3:0] g_filter_green,
    input logic [3:0] g_filter_blue,

    //internal
    input logic       DE,
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,

    //output
    output logic [3:0] s_filter_red,
    output logic [3:0] s_filter_green,
    output logic [3:0] s_filter_blue
);

    // gray = (R + G + B) / 3
    logic [5:0] gray;
    assign gray = (g_filter_red + g_filter_green + g_filter_blue) / 3;

    // 3x3 Window Buffer
    logic [5:0] window[0:2][0:2];  // 3x3 gray-scale values

    // Shift registers (line buffers should be added externally in practice)
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            foreach (window[y, x])
                window[y][x] <= 0;
        end else if (DE) begin
            // Shift columns
            window[0][0] <= window[0][1];
            window[0][1] <= window[0][2];
            window[0][2] <= window[1][0];
            
            window[1][0] <= window[1][1];
            window[1][1] <= window[1][2];
            window[1][2] <= window[2][0];
            
            window[2][0] <= window[2][1];
            window[2][1] <= window[2][2];
            window[2][2] <= gray;  // Newest pixel into bottom-right
        end
    end

    // Sobel gradient calculation
    logic signed [9:0] Gx, Gy;
    logic [9:0] abs_Gx, abs_Gy;
    logic [9:0] gradient;

    always_comb begin
        Gx = -window[0][0] + window[0][2]
           - 2*window[1][0] + 2*window[1][2]
           - window[2][0] + window[2][2];

        Gy = -window[0][0] - 2*window[0][1] - window[0][2]
             + window[2][0] + 2*window[2][1] + window[2][2];

        abs_Gx = (Gx < 0) ? -Gx : Gx;
        abs_Gy = (Gy < 0) ? -Gy : Gy;

        gradient = abs_Gx + abs_Gy;
    end

    // Clamp and output as grayscale RGB
    logic [3:0] grad_out;
    assign grad_out = (gradient > 15) ? 4'd15 : gradient[3:0];

    assign s_filter_red   = grad_out;
    assign s_filter_green = grad_out;
    assign s_filter_blue  = grad_out;

endmodule

module QVGA_UpScaler (
    // VGA Controller side
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic        DE,
    // frame buffer side
    output logic        d_en,
    output logic [16:0] rAddr,
    input  logic [15:0] rData,
    // export side
    output logic [ 3:0] red_port,
    output logic [ 3:0] green_port,
    output logic [ 3:0] blue_port
);
    logic display_en;

    assign  d_en = display_en;
    assign  display_en = (x_pixel < 320 && y_pixel < 240);
    assign  rAddr = display_en ? (160 * (y_pixel/2) + (x_pixel/2)) : 0;

    assign {red_port, green_port, blue_port} = display_en ? {rData[15:12], rData[10:7], rData[4:1]} : 12'b0; // RGB565 -> RGB444


endmodule