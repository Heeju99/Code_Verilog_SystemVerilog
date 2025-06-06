`timescale 1ns / 1ps

module frame_buffer_top (
    // write side
    input  logic        wclk,
    input  logic        reset,
    input  logic        we,
    input  logic [16:0] wAddr,
    input  logic [15:0] wData,
    // read side
    input  logic        rclk,
    input  logic        oe,
    input  logic [16:0] rAddr,
    output logic [11:0] rData_real,
    output logic [11:0] rData_diff1,
    output logic [11:0] rData_diff2,
    input  logic        v_sync
);

    logic en;

    Buffer_sel U_Buffer_sel (
        .pclk(wclk),
        .reset(reset),
        .v_sync(v_sync),
        .en(en)
    );

    // Dual-port Frame Buffer
    Frame_Buffer U_Frame_Buffer_real (
        .wclk (wclk),
        .we   (we),
        .wAddr(wAddr),
        .wData(wData),
        .rclk (rclk),
        .oe   (oe),
        .rAddr(rAddr),
        .rData(rData_real)
    );

    Frame_Buffer U_Frame_Buffer1 (
        .wclk (wclk),
        .we   (we && en),
        .wAddr(wAddr),
        .wData(wData),
        .rclk (rclk),
        .oe   (oe),
        .rAddr(rAddr),
        .rData(rData_diff1)
    );

    Frame_Buffer U_Frame_Buffer2 (
        .wclk (wclk),
        .we   (we && ~en),
        .wAddr(wAddr),
        .wData(wData),
        .rclk (rclk),
        .oe   (oe),
        .rAddr(rAddr),
        .rData(rData_diff2)
    );

endmodule
