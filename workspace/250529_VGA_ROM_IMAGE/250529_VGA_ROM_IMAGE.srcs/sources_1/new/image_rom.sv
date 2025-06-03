`timescale 1ns / 1ps

module Image_Rom (
    input  logic [9:0] x_pixel,
    input  logic [9:0] y_pixel,
    input  logic       DE,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port
);

    logic [16:0] image_addr;
    logic [15:0] image_data; // RGB565 => 16'b rrrrr gggggg bbbbb 상위 4bit 씩 사용


    assign image_addr = (320 * (y_pixel)) + (x_pixel);

    // 이미지 1/4만 남김    
    always_comb begin
        if((x_pixel >= 320) || (y_pixel >= 240)) begin
            {red_port, green_port, blue_port} = 12'h0;
        end else begin
            {red_port, green_port, blue_port} = 
            DE ? {image_data[15:12], image_data[10:7], image_data[4:1]} : 12'b0;
        end
    end

    rom U_rom(
        .addr(image_addr),
        .data(image_data)
    );    

endmodule

module grayscale_converter(
    input  logic [3:0] red_port,
    input  logic [3:0] green_port,
    input  logic [3:0] blue_port,
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

module mux_2x1(
    input  logic sw,
    //Grayscale
    input  logic [3:0] g_filter_red,
    input  logic [3:0] g_filter_green,
    input  logic [3:0] g_filter_blue,
    //Colour
    input  logic [3:0] r_filter_red,
    input  logic [3:0] r_filter_green,
    input  logic [3:0] r_filter_blue,
    //output
    output logic [3:0] filter_red,
    output logic [3:0] filter_green,
    output logic [3:0] filter_blue
);

    always_comb begin
        if(sw) begin  //0 = gray
            filter_red   = g_filter_red; //grascale
            filter_green = g_filter_green;
            filter_blue  = g_filter_blue;
        end else begin // 1 = colour
            filter_red   = r_filter_red; //rgb filter
            filter_green = r_filter_green;
            filter_blue  = r_filter_blue;
        end
    end
endmodule

module rgb_filter(
    input logic [2:0] sw_mode,
    input logic [3:0] red_port,
    input logic [3:0] green_port,
    input logic [3:0] blue_port,
    output logic [3:0] r_filter_red,
    output logic [3:0] r_filter_green,
    output logic [3:0] r_filter_blue
);
    always_comb begin
        if(sw_mode == 3'b001) begin   //RGB
            r_filter_red = 4'b0;
            r_filter_green = 4'b0;
            r_filter_blue = blue_port;
        end else if (sw_mode == 3'b010) begin //RGB
            r_filter_red = 4'b0;
            r_filter_green = green_port;
            r_filter_blue = 4'b0;
        end else if (sw_mode == 3'b011) begin //RGB
            r_filter_red = 4'b0;
            r_filter_green = green_port;
            r_filter_blue = blue_port;
        end else if (sw_mode == 3'b100) begin //RGB
            r_filter_red = red_port;
            r_filter_green = 4'b0;
            r_filter_blue = 4'b0;
        end else if (sw_mode == 3'b101) begin //RGB
            r_filter_red = red_port;
            r_filter_green = 4'b0;
            r_filter_blue = blue_port;
        end else if (sw_mode == 3'b110) begin //RGB
            r_filter_red = red_port;
            r_filter_green = green_port;
            r_filter_blue = 4'b0000;
        end else if (sw_mode == 3'b111)begin
            r_filter_red = red_port;
            r_filter_green = green_port;
            r_filter_blue = blue_port;
        end else begin
            r_filter_red = 4'b0;
            r_filter_green = 4'b0;
            r_filter_blue = 4'b0000;
        end
    end
endmodule 

module rom (
    input  logic [16:0] addr,
    output logic [15:0] data
);

    logic [15:0] rom[0:320*240-1];

    initial begin
        $readmemh("squid_girl.mem", rom); // h면 hex
    end

    assign data = rom[addr];
endmodule
