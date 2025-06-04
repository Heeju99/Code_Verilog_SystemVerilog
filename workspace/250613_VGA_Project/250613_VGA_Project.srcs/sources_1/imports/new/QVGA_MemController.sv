`timescale 1ns / 1ps

module QVGA_MemController (
    //input logic sw_up,
    input logic sw_chroma,
    input logic c_chroma,
    // VGA Controller side
    input  logic        clk,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic        DE,
    // frame buffer side  -> camera
    output logic        rclk,
    output logic        d_en,
    output logic [16:0] rAddr,
    input  logic [15:0] rData,
 
    // export side
    output logic [ 3:0] red_port,
    output logic [ 3:0] green_port,
    output logic [ 3:0] blue_port
);

    logic [16:0] image_addr, image1_addr;
    logic [15:0] image_data, image1_data;  //-> background

    rom U_rom(
        .addr(image_addr),
        .data(image_data)
    );

    rom1 U_rom1(
        .addr(image1_addr),
        .data(image1_data)
    );

    logic display_en;
    logic [16:0] common_addr;

    assign rclk = clk;

    assign display_en = (x_pixel < 320) && (120 < y_pixel) && (y_pixel < 360);
    assign d_en = display_en;

    assign forimage_addr = display_en ? (((y_pixel-120)/2) * 160 + (x_pixel/2)) : 17'd0;
    assign common_addr = display_en ? ((y_pixel/2) * 160 + (x_pixel/2)) : 17'd0;
    assign image_addr = forimage_addr;
    assign image1_addr = forimage_addr;
    assign rAddr = common_addr;

    logic [3:0] red   = rData[15:12];
    logic [3:0] green = rData[10:7];
    logic [3:0] blue  = rData[4:1];

    always_comb begin
        if (DE && display_en) begin
            if (sw_chroma) begin
                if(c_chroma == 0) begin    //younghee
                    if ((green > red + 2) && (green > blue + 2)) begin
                        {red_port, green_port, blue_port} = {image_data[15:12], image_data[10:7], image_data[4:1]};
                    end else begin
                        {red_port, green_port, blue_port} = {rData[15:12], rData[10:7], rData[4:1]};
                    end
                end else begin             //playground
                    if ((green > red + 2) && (green > blue + 2)) begin
                        {red_port, green_port, blue_port} = {image1_data[15:12], image1_data[10:7], image1_data[4:1]};
                    end else begin
                        {red_port, green_port, blue_port} = {rData[15:12], rData[10:7], rData[4:1]};
                    end
                end
            end else begin
                {red_port, green_port, blue_port} = {rData[15:12], rData[10:7], rData[4:1]};
            end
        end else begin
            {red_port, green_port, blue_port} = 12'd0;  // 검정색으로 출력
        end
    end
endmodule


module rom (
    input  logic [16:0] addr,
    output logic [15:0] data
);

    logic [15:0] rom[0:160*120-1];
    
    initial begin
        $readmemh("younghee.mem", rom); 
    end

    assign data = rom[addr];
endmodule

module rom1 (
    input  logic [16:0] addr,
    output logic [15:0] data
);

    logic [15:0] rom[0:160*120-1];
    
    initial begin
        $readmemh("playground.mem", rom); 
    end

    assign data = rom[addr];
endmodule