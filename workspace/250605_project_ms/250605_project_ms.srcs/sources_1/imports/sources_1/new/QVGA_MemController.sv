`timescale 1ns / 1ps

module QVGA_MemController (
    //input logic sw_up,
    input logic [1:0] sw,
    // VGA Controller side
    // input  logic        clk,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic        DE,
    // frame buffer side  -> camera
    // output logic        rclk,
    output logic        d_en,
    output logic [16:0] rAddr,
    input  logic [11:0] rData,
 
    // export side
    output logic [ 3:0] red_port,
    output logic [ 3:0] green_port,
    output logic [ 3:0] blue_port
);

    logic [16:0] image_addr, image_addr1, image_addr2;
    logic [15:0] image_data, image_data1, image_data2; 


    logic display_en;
    logic [16:0] common_addr, cam_addr;
    
    rom1 U_rom1(
        .addr(image_addr1),
        .data(image_data1)
    );

    rom2 U_rom2(
        .addr(image_addr2),
        .data(image_data2)
    );

    // assign rclk = clk;

    assign display_en = ((x_pixel > 0) && (x_pixel < 320) && (y_pixel > 120) && (y_pixel < 360));
    assign d_en = display_en;

    assign cam_addr = display_en ? ((y_pixel)/2) * 160 + (x_pixel/2) : 17'd0;
    assign common_addr = display_en ? ((y_pixel-120)/2) * 160 + (x_pixel/2) : 17'd0;
    assign image_addr1 = common_addr;
    assign image_addr2 = common_addr;
    assign rAddr = cam_addr;

    assign image_addr = sw[1] ? image_addr2 : image_addr1; 
    assign image_data = sw[1] ? image_data2 : image_data1; 

    logic [3:0] red   = rData[11:8];
    logic [3:0] green = rData[7:4];
    logic [3:0] blue  = rData[3:0];

    always_comb begin
        if (DE && display_en) begin
            if (sw[0]) begin
                if ((blue > red + 2) && (blue > green + 2)) begin
                    {red_port, green_port, blue_port} = {image_data[15:12], image_data[10:7], image_data[4:1]};
                end else begin
                    {red_port, green_port, blue_port} = rData;
                end
            end else begin
                {red_port, green_port, blue_port} = rData;
            end
        end else begin
            {red_port, green_port, blue_port} = 12'd0;  // 검정색으로 출력
        end
    end
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

module rom2 (
    input  logic [16:0] addr,
    output logic [15:0] data
);

    logic [15:0] rom[0:160*120-1];
    
    initial begin
        $readmemh("younghee.mem", rom); 
    end

    assign data = rom[addr];
endmodule