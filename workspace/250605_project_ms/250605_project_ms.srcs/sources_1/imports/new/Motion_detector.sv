`timescale 1ns / 1ps

module Motion_Detector (
    input  logic        clk,
    input  logic        enable,
    input  logic [11:0] curr_pixel,
    input  logic [11:0] prev_pixel,
    output logic        motion_detected
);
    localparam THRESHOLD_MOTION = 5;
    logic [3:0] diff;

    assign diff = (curr_pixel[3:0] > prev_pixel[3:0]) ? (curr_pixel[3:0] - prev_pixel[3:0]) : (prev_pixel[3:0] - curr_pixel[3:0]);

    always_ff @(posedge clk) begin
        if (enable)
            motion_detected <= (diff > THRESHOLD_MOTION);
        else motion_detected <= 0;
    end
endmodule
