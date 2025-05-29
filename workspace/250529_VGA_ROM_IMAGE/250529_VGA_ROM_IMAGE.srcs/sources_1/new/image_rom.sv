`timescale 1ns / 1ps

module Image_rom(
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    input logic DE,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port
);

    logic [18:0] image_addr;
    logic [15:0] image_data; //RGB565 -> 16'b rrrrr_gggggg_bbbbb
    // RGB565를 상위 4bit씩 가져와 총 12bit의 값을 가져오게됨

    assign image_addr = 640 * y_pixel + x_pixel; 

    //16bit의 RGB565의 각 최상위 4bit씩 가져와서 12bit의 Data로 변환
    assign {red_port, green_port, blue_port} = 
           {image_data[15:12], image_data[10:7], image_data[4:1]};

    image_rom U_image_ROM(
        .addr(image_addr),
        .data({red_port, green_port, blue_port})
);

endmodule

//비동기 rom
module image_rom(
    input logic [18:0] addr,
    output logic [15:0] data
);

    logic [15:0] rom[0:640*480 -1]; //1frame의 메모리 공간

    assign data = rom[addr];
endmodule
