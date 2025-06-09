`timescale 1ns / 1ps

module Motion_Detector (
    input  logic        clk,
    input  logic        reset,
    input  logic        play,
    input  logic        DE,
    input  logic [ 7:0] threshold,
    input  logic [11:0] curr_pixel,
    input  logic [11:0] prev_pixel,  
    output logic        motion_detected,
    output logic [11:0] motion_pixel_out,
    input  logic        v_sync
);
    
    localparam int MOTION_LIMIT = 15000;//640 * 480 * 3 / 100

    logic [11:0] diff;
    logic [17:0] motion_pixel_count;

    assign diff = (curr_pixel > prev_pixel) ? (curr_pixel - prev_pixel) : (prev_pixel - curr_pixel);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            motion_pixel_count <= 0;
            motion_detected    <= 0;
        end 
        else if (play) begin
            motion_pixel_count <= 0;
            motion_detected    <= 0;
        end
        else begin
            if (DE) begin
                if (diff > 2048) begin
                    motion_pixel_out <= 12'hF00;
                    motion_pixel_count <= motion_pixel_count + 1;

                    if ((motion_pixel_count + 1 >= MOTION_LIMIT) && motion_detected == 0 ) begin
                        motion_detected <= 1;
                    end
                    else motion_detected <= 0;


                end else begin
                    motion_pixel_out <= curr_pixel;
                end
            end else begin
                motion_pixel_out <= curr_pixel;
            end

            // 프레임 경계에서 motion 카운트 초기화
            if (v_sync == 0)
                motion_pixel_count <= 0;
        end
    end

endmodule