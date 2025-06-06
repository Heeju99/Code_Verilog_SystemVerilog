`timescale 1ns / 1ps

module Motion_Detector (
    input  logic        clk,
    input  logic        reset,               // 추가: 리셋 신호
    input  logic        DE,
    input logic [7:0] threshold,
    input  logic [11:0] curr_pixel,
    input  logic [11:0] prev_pixel,  
    output logic        motion_detected,
    output logic [11:0] motion_pixel_out,
    output logic        v_sync
);

    // localparam THRESHOLD = 32;
    localparam MOTION_LIMIT = 160 * 120 * 50 / 100; // QQVGA 해상도의 절반 = 38400 픽셀

    logic [11:0] diff;
    logic [17:0] motion_pixel_count;

    assign diff = (curr_pixel > prev_pixel) ? (curr_pixel - prev_pixel) : (prev_pixel - curr_pixel);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            motion_pixel_count <= 0;
            motion_detected <= 0;
        end else begin
            if (DE) begin
                if (diff > threshold) begin
                    motion_pixel_out <= 12'hF00;  // 빨간색 출력
                    motion_pixel_count <= motion_pixel_count + 1;

                    if (motion_pixel_count + 1 >= MOTION_LIMIT)
                        motion_detected <= 1;
                end else begin
                    motion_pixel_out <= curr_pixel;
                end
            end 
            else if(v_sync == 0) begin
                motion_pixel_count <= 0;
            end 
            else begin
                motion_pixel_out <= curr_pixel;
            end
        end
    end

endmodule
