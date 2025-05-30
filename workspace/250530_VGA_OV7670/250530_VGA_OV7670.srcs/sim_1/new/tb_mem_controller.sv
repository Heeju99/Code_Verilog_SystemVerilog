`timescale 1ns / 1ps

module tb_mem_controller();

    logic         PCLK;
    logic         reset;
    logic         HREF; //WE
    logic         v_sync;
    logic [7:0]   data;

    //Send to FrameBuffer
    logic        FCLK; //yes or no
    logic [ 7:0] waddr;
    logic [15:0] wdata;
    logic        we;


    Mem_Controller DUT(
    .PCLK(PCLK),
    .reset(reset),
    .HREF(HREF), //WE
    .v_sync(v_sync),
    .data(data),

    //Send to FrameBuffer
    .FCLK(FCLK), //yes or no
    .waddr(waddr),
    .wdata(wdata),
    .we(we)
);
endmodule
