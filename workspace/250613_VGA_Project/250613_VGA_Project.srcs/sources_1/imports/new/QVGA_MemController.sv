`timescale 1ns / 1ps

module QVGA_MemController (
    //input logic sw_up,
    input logic sw_chroma,
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

    logic [16:0] image_addr;
    logic [15:0] image_data;  //-> background

    rom U_rom(
    .addr(image_addr),
    .data(image_data)
);

    logic display_en;

    assign rclk = clk;

    assign display_en = (x_pixel < 320 && y_pixel < 240);
    assign d_en = display_en;

    assign common_addr = display_en ? ((y_pixel) * 320 + x_pixel) : 0;
    assign real_addr = common_addr;
    assign image_addr = common_addr;


    always_comb begin
        if(sw_chroma) begin
            if(rData[10:7] > 4'b1100 && rData[15:12] < 4'b0110 && rData[4:1] < 4'b0110) begin
                {red_port, green_port, blue_port} = {image_data[15:12], image_data[10:7], image_data[4:1]};
            end else begin
                {red_port, green_port, blue_port} = {rData[15:12], rData[10:7], rData[4:1]};
            end
            end else begin
            {red_port, green_port, blue_port} = {rData[15:12], rData[10:7], rData[4:1]};
        end
    end 


endmodule


module rom (
    input  logic [16:0] addr,
    output logic [15:0] data
);

    logic [15:0] rom[0:320*240-1];
    
    initial begin
    $readmemh("squid_girl.mem", rom);
end
    //initial begin
    //    $readmemh("squid_girl.mem", rom); 
    //end

    assign data = rom[addr];
endmodule