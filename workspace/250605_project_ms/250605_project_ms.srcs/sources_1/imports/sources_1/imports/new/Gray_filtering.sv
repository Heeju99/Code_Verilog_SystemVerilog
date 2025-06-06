`timescale 1ns / 1ps

module Gray_filtering(
    input logic [11:0] rData_diff1,
    input logic [11:0] rData_diff2,
    // input logic [3:0] red,
    // input logic [3:0] green,
    // input logic [3:0] blue,
    // input logic [3:0] red_Gray,
    // input logic [3:0] green_Gray,
    // input logic [3:0] blue_Gray
    output logic [11:0] Gray_diff1,
    output logic [11:0] Gray_diff2
    );

    assign Gray_diff1 = (77*(rData_diff1[11:8])) + (150*(rData_diff1[7:4])) + (29*(rData_diff1[3:0]));
    assign Gray_diff2 = (77*(rData_diff2[11:8])) + (150*(rData_diff2[7:4])) + (29*(rData_diff2[3:0]));
endmodule