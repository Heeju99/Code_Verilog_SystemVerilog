`timescale 1ns / 1ps

module OV7670_VGA_Display(
    input  logic        clk,
    input  logic        reset,
    //camera
    output logic        ov7670_xclk,
    input  logic        ov7670_pclk,
    input  logic        ov7670_href,
    input  logic        ov7670_v_sync,
    input  logic [7:0]  ov7670_data,
    //export
    output logic        h_sync,
    output logic        v_sync,
    output logic [3:0]  red_port,
    output logic [3:0]  green_port,
    output logic [3:0]  blue_port
);

    logic d_en;
    logic w_rclk;
    logic DE;
    logic [9:0] x_pixel, y_pixel;
    logic [16:0] wAddr, rAddr;
    logic [15:0] wData, rData;

    pixel_clk_gen U_Pixel_clk_gen(
        .clk(clk),
        .reset(reset),
        .pclk(ov7670_xclk)
);

    VGA_Controller U_VGA_Controller(
        .clk(clk),
        .reset(reset),
        .rclk(w_rclk),
        .h_sync(h_sync), //output
        .v_sync(v_sync),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .DE(DE)
);

    ov7670_Mem_Controller U_ov7670_Mem_Controller(
        .pclk(ov7670_pclk),
        .reset(reset),
        .href(ov7670_href),  //input
        .v_sync(ov7670_v_sync),
        .ov7670_data(ov7670_data),
        .we(we),
        .wAddr(wAddr),
        .wData(wData)
);

    Frame_Buffer U_Frame_Buffer(
        //write Side
        .wclk(ov7670_pclk),
        .wAddr(wAddr),
        .wData(wData),
        .we(we),
        //read Side
        .rclk(rclk),
        .oe(d_en),
        .rAddr(rAddr),
        .rData(rData)
);

    QVGA_Mem_Controller U_QVGA_Mem_Controller(
        //VGA Controller
        .clk(w_rclk),
        .DE(DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        //frame Buffer Side
        .rclk(rclk),
        .d_en(d_en),
        .rAddr(rAddr),
        .rData(rData),
        //export Side
        .red_port(red_port),
        .green_port(green_port),
        .blue_port(blue_port)
);
endmodule
