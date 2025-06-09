`timescale 1ns / 1ps

module QVGA_MemController (
    //input logic sw_up,
    input logic [1:0] sw,
    // input logic     text_pixel,
    // VGA Controller side
    // input  logic        clk,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic        DE,
    input  logic        DE1,
    input  logic        DE2,
    input logic text_pixel_score1,
    input logic text_pixel_score2,
    input logic text_pixel_result1,
    input logic text_pixel_result2,
    // frame buffer side  -> camera
    // output logic        rclk,
    output logic        d_en,
    output logic [16:0] rAddr1,
    output logic [16:0] rAddr2,

    input  logic [11:0] rData,
 
    // export side
    output logic [ 3:0] red_port,
    output logic [ 3:0] green_port,
    output logic [ 3:0] blue_port
);

    logic [16:0] image_addr, image_addr1, image_addr2;
    logic [15:0] image_data, image_data1, image_data2; 


    logic display_en;
    logic [16:0] common_addr, cam_addr1, cam_addr2;
    //additional
    logic [16:0] center_black;
    
    // rom1 U_rom1(
    //     .addr(image_addr1),
    //     .data(image_data1)
    // );

    rom2 U_rom2(
        .addr(image_addr2),
        .data(image_data2)
    );

    // assign rclk = clk;

    assign display_en = ((x_pixel < 640) && (y_pixel < 480));
    assign d_en = display_en;

    assign cam_addr1 = display_en ? ((y_pixel)>>1) * 320 + (x_pixel>>1) : 17'd0;
    assign cam_addr2 = display_en ? ((y_pixel)>>3) * 80 + (x_pixel>>3) : 17'd0;
    
    assign common_addr = display_en ? ((y_pixel)>>1) * 320 + (x_pixel>>1) : 17'd0;
    assign image_addr1 = common_addr;
    assign image_addr2 = common_addr;
    assign rAddr1 = cam_addr1;
    assign rAddr2 = cam_addr2;
    assign rAddr3 = center_black;

    assign image_addr = image_addr2;//sw[1] ? image_addr2 : image_addr1; 
    assign image_data = image_data2;//sw[1] ? image_data2 : image_data1; 

    logic [3:0] red   = rData[11:8];
    logic [3:0] green = rData[7:4];
    logic [3:0] blue  = rData[3:0];

    always_comb begin
        if (DE && display_en) begin
            if(DE1) begin
                if(text_pixel_score1) begin
                    {red_port,green_port,blue_port} = 12'h000; //black
                end 
                else if(text_pixel_result1) begin
                    {red_port,green_port,blue_port} = 12'hF00; //red
                end 
                else if ((blue > red + 2) && (blue > green + 2)) begin
                    {red_port, green_port, blue_port} = {image_data[15:12], image_data[10:7], image_data[4:1]};
                end 
                else begin
                    {red_port, green_port, blue_port} = rData;
                end
            end
            else if(DE2) begin
                if(text_pixel_score2) begin
                    {red_port,green_port,blue_port} = 12'h000; //black
                end 
                else if(text_pixel_result2) begin
                    {red_port,green_port,blue_port} = 12'hF00; //red
                end 
                else if ((blue > red + 2) && (blue > green + 2)) begin
                    {red_port, green_port, blue_port} = {image_data[15:12], image_data[10:7], image_data[4:1]};
                end 
                else begin
                    {red_port, green_port, blue_port} = rData;
                end
            end
            else if ((blue > red + 2) && (blue > green + 2)) begin
                {red_port, green_port, blue_port} = {image_data[15:12], image_data[10:7], image_data[4:1]};
            end 
            else begin
                {red_port, green_port, blue_port} = rData;
            end
        end else begin
            {red_port, green_port, blue_port} = 12'd0;  // 검정색으로 출력
        end
    end
endmodule


// module rom1 (
//     input  logic [16:0] addr,
//     output logic [15:0] data
// );

//     logic [15:0] rom[0:160*120-1];
    
//     initial begin
//         $readmemh("playground.mem", rom); 
//     end

//     assign data = rom[addr];
// endmodule

module rom2 (
    input  logic [16:0] addr,
    output logic [15:0] data
);

    logic [15:0] rom[0:320*240-1];
    
    initial begin
        $readmemh("younghee.mem", rom); 
    end

    assign data = rom[addr];
endmodule