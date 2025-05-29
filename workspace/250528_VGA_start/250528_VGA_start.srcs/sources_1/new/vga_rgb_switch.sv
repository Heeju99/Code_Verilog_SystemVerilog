`timescale 1ns / 1ps

module vga_rgb_switch(
    // switch
    input logic [3:0] sw_red,
    input logic [3:0] sw_green,
    input logic [3:0] sw_blue,
    // Enable
    input logic DE,
    //input logic [9:0] x_pixel,  //아직 필요 x
    //input logic [9:0] y_pixel,  //아직 필요 x
    
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port
 );
    assign red_port   = DE ? sw_red : 4'b0;
    assign green_port = DE ? sw_blue : 4'b0;
    assign blue_port  = DE ? sw_green : 4'b0;
endmodule


//jeong
module vga_rgb_display(
    input  logic       DE,
    input  logic [9:0] x_pixel,
    input  logic [9:0] y_pixel,
    output logic [3:0] red_port, 
    output logic [3:0] green_port, 
    output logic [3:0] blue_port 
    );

    logic [11:0] color;
    logic [ 3:0] red, green, blue;

    assign {red, green, blue} = color;
    assign red_port   = DE ? red : 4'b0;
    assign green_port = DE ? green : 4'b0;
    assign blue_port  = DE ? blue : 4'b0;

    always_comb begin
       if (y_pixel <320) begin
            if (x_pixel < 91) begin //w
                color = 12'hfff;
            end
            else if (x_pixel < 183) begin //y
                color = 12'hff0;
            end
            else if (x_pixel < 274) begin //m
                color = 12'h0ff;
            end
            else if (x_pixel < 365) begin //g
                color = 12'h0f0;
            end
            else if (x_pixel < 457) begin //p
                color = 12'hf0f;
            end
            else if (x_pixel < 549) begin //r
                color = 12'hf00;
            end
            else begin //b
                color = 12'h00f; 
            end
        end
        else if (y_pixel < 360) begin
            if (x_pixel < 91) begin //b
                color = 12'h00f;
            end
            else if (x_pixel < 183) begin //bl
                color = 12'h000;
            end
            else if (x_pixel < 274) begin //p
                color = 12'hf0f;
            end
            else if (x_pixel < 365) begin //bl
                color = 12'h000;
            end
            else if (x_pixel < 457) begin //m
                color = 12'h0ff;
            end
            else if (x_pixel < 549) begin //bl
                color = 12'h0;
            end
            else begin //w
                color = 12'hfff;
            end
        end
        else begin
            if (x_pixel < 107) begin //navy
                color = 12'h003;
            end
            else if (x_pixel < 213) begin //w
                color = 12'hfff;
            end
            else if (x_pixel < 320) begin //purple
                color = 12'hc0f;
            end
            else if (x_pixel < 427) begin //bl2
                color = 12'h111;
            end
            else if (x_pixel < 463) begin //bl
                color = 12'h000;
            end
            else if (x_pixel < 498) begin //bl2
                color = 12'h111;
            end
            else if (x_pixel < 533) begin //bl3
                color = 12'h222;
            end
            else begin //bl
                color = 12'h0;
            end
        end
    end
endmodule


module vga_jojung(
    input logic DE,
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,

    output logic [3:0] red_port2,
    output logic [3:0] green_port2,
    output logic [3:0] blue_port2
);

    logic [3:0] red_port;
    logic [3:0] green_port;
    logic [3:0] blue_port;

    assign red_port2   = DE ? red_port : 4'b0;
    assign blue_port2  = DE ? blue_port : 4'b0;
    assign green_port2 = DE ? green_port : 4'b0;

    always_comb begin
            if(y_pixel < 320) begin
                if(x_pixel < 91) begin  //white
                    red_port = 4'b1111;
                    green_port = 4'b1111;
                    blue_port = 4'b1111;
                end else if (x_pixel < 182) begin //Yellow
                    red_port = 4'b1111;
                    green_port = 4'b1111;
                    blue_port = 4'b0000;
                end else if (x_pixel < 273) begin //Cyan
                    red_port = 4'b0000;
                    green_port = 4'b1111;
                    blue_port = 4'b1111;
                end else if (x_pixel < 364) begin //Green
                    red_port = 4'b0000;
                    green_port = 4'b1111; 
                    blue_port = 4'b0000;
                end else if (x_pixel < 455) begin //Magenta
                    red_port = 4'b1111;
                    green_port = 4'b0000;
                    blue_port = 4'b1111;
                end else if (x_pixel < 546) begin  //Red
                    red_port = 4'b1111;
                    green_port = 0;
                    blue_port = 0;
                end else if (x_pixel <= 639) begin //Blue
                    red_port = 0;
                    green_port = 0;
                    blue_port = 4'b1111;
                end
            //2번째 줄 
            end else if(y_pixel < 375) begin
                if(x_pixel < 91) begin      //blue
                    red_port = 0;
                    green_port = 0;
                    blue_port = 4'b1111;
                end else if (x_pixel < 182) begin //black
                    red_port = 0;
                    green_port = 0;
                    blue_port = 0;
                end else if (x_pixel < 273) begin //magenta
                    red_port = 4'b1111;
                    green_port = 0;
                    blue_port = 4'b1111;
                end else if (x_pixel < 364) begin //black
                    red_port = 0;
                    green_port = 0;
                    blue_port = 0;
                end else if (x_pixel < 455) begin //Cyan
                    red_port = 0;
                    green_port = 4'b1111;
                    blue_port = 4'b1111;
                end else if (x_pixel < 546) begin //black
                    red_port = 0;
                    green_port = 0;
                    blue_port = 0;
                end else if (x_pixel <= 639) begin //white
                    red_port = 4'b1111;
                    green_port = 4'b1111;
                    blue_port = 4'b1111;
                end
            //3번째 줄
            end else if(y_pixel <= 479) begin
                if(x_pixel < 100) begin //navy
                    red_port = 4'b0000;
                    green_port = 4'b0101;
                    blue_port = 4'b1111;
                end else if (x_pixel < 200) begin //white
                    red_port = 4'b1111;
                    green_port = 4'b1111;
                    blue_port = 4'b1111;
                end else if (x_pixel < 300) begin //purple
                    red_port = 4'b1101;
                    green_port = 4'b0001;
                    blue_port = 4'b1111;
                end else if (x_pixel < 400) begin //black
                    red_port = 0;
                    green_port = 0;
                    blue_port = 4'b0001;
                //3분할 시작
                end else if (x_pixel < 448) begin //black
                    red_port = 0;
                    green_port = 0;
                    blue_port = 0;
                end else if (x_pixel < 496) begin //charcol
                    red_port = 0;
                    green_port = 0;
                    blue_port = 4'b0001;
                end else if (x_pixel < 546) begin //more white
                    red_port = 0;
                    green_port = 4'b0001;
                    blue_port = 4'b0001;
                //3분할 종료
                end else if (x_pixel <= 639) begin //black
                    red_port = 0;
                    green_port = 0;
                    blue_port = 0;
                end
            end
        end
endmodule