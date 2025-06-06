`timescale 1ns / 1ps

module RGB_filtering(
    input logic [2:0] sw,
    input logic [3:0] red,
    input logic [3:0] green,
    input logic [3:0] blue,
    output logic [3:0] red_filter,
    output logic [3:0] green_filter,
    output logic [3:0] blue_filter
    );

    always_comb begin
        if(sw == 0) begin
            red_filter = 0;
            green_filter = 0;
            blue_filter = 0;
        end 
        if(sw[0] == 1) begin
            blue_filter = blue;
        end 
        if(sw[1] == 1) begin
            green_filter = green;
        end 
        if(sw[2] == 1) begin
            red_filter = red;
        end 
    end
endmodule
