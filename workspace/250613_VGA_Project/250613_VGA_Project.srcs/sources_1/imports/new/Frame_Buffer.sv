`timescale 1ns / 1ps

module Frame_Buffer (
    // write side
    input  logic        wclk,
    input  logic        we,
    input  logic [16:0] wAddr,
    input  logic [15:0] wData,
    // read side
    input  logic        rclk,
    input  logic        oe,
    input  logic [16:0] rAddr,
    output logic [15:0] rData
);

    logic [15:0] mem[0:(160*120-1)];

    // write side
    always_ff @(posedge wclk) begin : write_side
        if (we) begin
            mem[wAddr] <= wData;
        end
    end

    // read side(Asynchronous)
    always_ff @( posedge rclk ) begin : blockName
        if(oe) begin
            rData <= mem[rAddr];
        end
    end
endmodule
