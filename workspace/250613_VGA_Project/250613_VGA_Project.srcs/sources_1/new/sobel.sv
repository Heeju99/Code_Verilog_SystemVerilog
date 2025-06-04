`timescale 1ns / 1ps

module sobel_heeju(
    input logic clk,
    input logic reset,
    //input gray
    input logic [3:0] g_filter_red,
    input logic [3:0] g_filter_green,
    input logic [3:0] g_filter_blue,

    input logic       DE,
    input logic [9:0] x_pixel, 
    input logic [9:0] y_pixel,

    output logic [3:0] s_filter_red, 
    output logic [3:0] s_filter_green, 
    output logic [3:0] s_filter_blue
);
    localparam IMG_WIDTH = 640;
    localparam THRESHOLD = 5; 

    //additional
    logic [11:0] sobel_out;
    logic [11:0] gray_in = {g_filter_red + g_filter_green + g_filter_blue};

    logic [3:0] line_buffer_1[0:IMG_WIDTH-1];
    logic [3:0] line_buffer_2[0:IMG_WIDTH-1];

    logic [3:0] p11, p12, p13;
    logic [3:0] p21, p22, p23;
    logic [3:0] p31, p32, p33;

    logic [2:0] valid_pipeline;

    logic signed [10:0] gx, gy;
    logic [10:0] mag;

    integer i;

    assign s_filter_red = sobel_out[3:0];      //((mag_sobel_0[12:5] > threshold) && sobel_en) ? 4'hF : 4'h0;
    assign s_filter_blue = sobel_out[3:0];     //((mag_sobel_1[12:5] > threshold) && sobel_en) ? 4'hF : 4'h0;
    assign s_filter_green = sobel_out[3:0];    //((mag_sobel_2[12:5] > threshold) && sobel_en) ? 4'hF : 4'h0;


    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                line_buffer_1[i] <= 0;
                line_buffer_2[i] <= 0;
            end
        end else if (DE) begin
            line_buffer_2[x_pixel] <= line_buffer_1[x_pixel];
            line_buffer_1[x_pixel] <= gray_in[3:0];
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            {p11, p12, p13, p21, p22, p23, p31, p32, p33} <= 0;
            valid_pipeline <= 0;
        end else if (DE) begin
            p13 <= line_buffer_2[x_pixel];
            p12 <= p13;
            p11 <= p12;

            p23 <= line_buffer_1[x_pixel];
            p22 <= p23;
            p21 <= p22;

            p33 <= gray_in[3:0];
            p32 <= p33;
            p31 <= p32;

            valid_pipeline <= {
                valid_pipeline[1:0], (x_pixel >= 2 && y_pixel >= 2)
            };
        end else begin
            valid_pipeline <= {valid_pipeline[1:0], 1'b0};
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            gx        <= 0;
            gy        <= 0;
            mag       <= 0;
            sobel_out <= 0;
        end else if (valid_pipeline[2]) begin
            gx <= (p13 + (p23 << 1) + p33) - (p11 + (p21 << 1) + p31);
            gy <= (p31 + (p32 << 1) + p33) - (p11 + (p12 << 1) + p13);
            mag <= (gx[10] ? -gx : gx) + (gy[10] ? -gy : gy);
            sobel_out <= (mag > THRESHOLD) ? 12'hFFF : 12'h0;
        end else begin
            sobel_out <= 0;
        end
    end
endmodule


module sobel_filter_5x5 (
    input  logic        clk,
    input  logic        reset,
    input  logic [3:0]  gray_4bit_0,
    input  logic [3:0]  gray_4bit_1,
    input  logic [3:0]  gray_4bit_2,

    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic        display_enable,
    input  logic [7:0]  threshold,

    output logic [ 3:0] sobel_out_0,
    output logic [ 3:0] sobel_out_1,
    output logic [ 3:0] sobel_out_2
);
    localparam IMAGE_WIDTH = 320;

    logic [3:0] line_buffer_1_0[0:IMAGE_WIDTH-1];
    logic [3:0] line_buffer_2_0[0:IMAGE_WIDTH-1];
    logic [3:0] line_buffer_3_0[0:IMAGE_WIDTH-1];
    logic [3:0] line_buffer_4_0[0:IMAGE_WIDTH-1];

    logic [3:0] line_buffer_1_1[0:IMAGE_WIDTH-1];
    logic [3:0] line_buffer_2_1[0:IMAGE_WIDTH-1];
    logic [3:0] line_buffer_3_1[0:IMAGE_WIDTH-1];
    logic [3:0] line_buffer_4_1[0:IMAGE_WIDTH-1];

    logic [3:0] line_buffer_1_2[0:IMAGE_WIDTH-1];
    logic [3:0] line_buffer_2_2[0:IMAGE_WIDTH-1];
    logic [3:0] line_buffer_3_2[0:IMAGE_WIDTH-1];
    logic [3:0] line_buffer_4_2[0:IMAGE_WIDTH-1];


    logic [7:0] w_0_0_0, w_1_0_0, w_2_0_0, w_3_0_0, w_4_0_0;
    logic [7:0] w_0_1_0, w_1_1_0, w_2_1_0, w_3_1_0, w_4_1_0;
    logic [7:0] w_0_2_0, w_1_2_0, w_2_2_0, w_3_2_0, w_4_2_0;
    logic [7:0] w_0_3_0, w_1_3_0, w_2_3_0, w_3_3_0, w_4_3_0;
    logic [7:0] w_0_4_0, w_1_4_0, w_2_4_0, w_3_4_0, w_4_4_0;

    logic [7:0] w_0_0_1, w_1_0_1, w_2_0_1, w_3_0_1, w_4_0_1;
    logic [7:0] w_0_1_1, w_1_1_1, w_2_1_1, w_3_1_1, w_4_1_1;
    logic [7:0] w_0_2_1, w_1_2_1, w_2_2_1, w_3_2_1, w_4_2_1;
    logic [7:0] w_0_3_1, w_1_3_1, w_2_3_1, w_3_3_1, w_4_3_1;
    logic [7:0] w_0_4_1, w_1_4_1, w_2_4_1, w_3_4_1, w_4_4_1;

    logic [7:0] w_0_0_2, w_1_0_2, w_2_0_2, w_3_0_2, w_4_0_2;
    logic [7:0] w_0_1_2, w_1_1_2, w_2_1_2, w_3_1_2, w_4_1_2;
    logic [7:0] w_0_2_2, w_1_2_2, w_2_2_2, w_3_2_2, w_4_2_2;
    logic [7:0] w_0_3_2, w_1_3_2, w_2_3_2, w_3_3_2, w_4_3_2;
    logic [7:0] w_0_4_2, w_1_4_2, w_2_4_2, w_3_4_2, w_4_4_2;


    logic [2:0] valid_pipeline;

    logic signed [15:0] gx_sobel_0, gy_sobel_0, gx_sobel_1, gy_sobel_1;
    logic signed [15:0] gx_sobel_2, gy_sobel_2;
    logic [15:0] mag_sobel_0, mag_sobel_1, mag_sobel_2;

    logic sobel_en;

    integer i;

   
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            for (i = 0; i < IMAGE_WIDTH; i = i + 1) begin
                line_buffer_4_0[i] <= 0;
                line_buffer_3_0[i] <= 0;
                line_buffer_2_0[i] <= 0;
                line_buffer_1_0[i] <= 0;

                line_buffer_4_1[i] <= 0;
                line_buffer_3_1[i] <= 0;
                line_buffer_2_1[i] <= 0;
                line_buffer_1_1[i] <= 0;

                line_buffer_4_2[i] <= 0;
                line_buffer_3_2[i] <= 0;
                line_buffer_2_2[i] <= 0;
                line_buffer_1_2[i] <= 0;

            end
        end else if (display_enable) begin
            line_buffer_4_0[x_pixel] <= line_buffer_3_0[x_pixel];
            line_buffer_3_0[x_pixel] <= line_buffer_2_0[x_pixel];
            line_buffer_2_0[x_pixel] <= line_buffer_1_0[x_pixel];
            line_buffer_1_0[x_pixel] <= gray_4bit_0;

            line_buffer_4_1[x_pixel] <= line_buffer_3_1[x_pixel];
            line_buffer_3_1[x_pixel] <= line_buffer_2_1[x_pixel];
            line_buffer_2_1[x_pixel] <= line_buffer_1_1[x_pixel];
            line_buffer_1_1[x_pixel] <= gray_4bit_1;

            line_buffer_4_2[x_pixel] <= line_buffer_3_2[x_pixel];
            line_buffer_3_2[x_pixel] <= line_buffer_2_2[x_pixel];
            line_buffer_2_2[x_pixel] <= line_buffer_1_2[x_pixel];
            line_buffer_1_2[x_pixel] <= gray_4bit_2;
        end
    end

    // Window Shift Logic for 4 Frames
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            // Reset window values for all 4 frames
            {w_0_0_0, w_1_0_0, w_2_0_0, w_3_0_0, w_4_0_0} <= 0;
            {w_0_1_0, w_1_1_0, w_2_1_0, w_3_1_0, w_4_1_0} <= 0;
            {w_0_2_0, w_1_2_0, w_2_2_0, w_3_2_0, w_4_2_0} <= 0;
            {w_0_3_0, w_1_3_0, w_2_3_0, w_3_3_0, w_4_3_0} <= 0;
            {w_0_4_0, w_1_4_0, w_2_4_0, w_3_4_0, w_4_4_0} <= 0;

            {w_0_0_1, w_1_0_1, w_2_0_1, w_3_0_1, w_4_0_1} <= 0;
            {w_0_1_1, w_1_1_1, w_2_1_1, w_3_1_1, w_4_1_1} <= 0;
            {w_0_2_1, w_1_2_1, w_2_2_1, w_3_2_1, w_4_2_1} <= 0;
            {w_0_3_1, w_1_3_1, w_2_3_1, w_3_3_1, w_4_3_1} <= 0;
            {w_0_4_1, w_1_4_1, w_2_4_1, w_3_4_1, w_4_4_1} <= 0;

            {w_0_0_2, w_1_0_2, w_2_0_2, w_3_0_2, w_4_0_2} <= 0;
            {w_0_1_2, w_1_1_2, w_2_1_2, w_3_1_2, w_4_1_2} <= 0;
            {w_0_2_2, w_1_2_2, w_2_2_2, w_3_2_2, w_4_2_2} <= 0;
            {w_0_3_2, w_1_3_2, w_2_3_2, w_3_3_2, w_4_3_2} <= 0;
            {w_0_4_2, w_1_4_2, w_2_4_2, w_3_4_2, w_4_4_2} <= 0;

            valid_pipeline <= 0;

        end else if (display_enable) begin
            // Frame 0
            w_4_0_0 <= line_buffer_4_0[x_pixel] << 4;
            w_4_1_0 <= line_buffer_3_0[x_pixel] << 4;
            w_4_2_0 <= line_buffer_2_0[x_pixel] << 4;
            w_4_3_0 <= line_buffer_1_0[x_pixel] << 4;
            w_4_4_0 <= {gray_4bit_0, 4'b0};

            // Frame 1
            w_4_0_1 <= line_buffer_4_1[x_pixel] << 4;
            w_4_1_1 <= line_buffer_3_1[x_pixel] << 4;
            w_4_2_1 <= line_buffer_2_1[x_pixel] << 4;
            w_4_3_1 <= line_buffer_1_1[x_pixel] << 4;
            w_4_4_1 <= {gray_4bit_1, 4'b0};

            // Frame 2
            w_4_0_2 <= line_buffer_4_2[x_pixel] << 4;
            w_4_1_2 <= line_buffer_3_2[x_pixel] << 4;
            w_4_2_2 <= line_buffer_2_2[x_pixel] << 4;
            w_4_3_2 <= line_buffer_1_2[x_pixel] << 4;
            w_4_4_2 <= {gray_4bit_2, 4'b0};


            // Update valid pipeline for each frame
            valid_pipeline <= {
                valid_pipeline[1:0], 
                (x_pixel >= 4 && y_pixel >= 4 && x_pixel < 320 && y_pixel < 240)
            };
        end else begin
            valid_pipeline <= {valid_pipeline[2:0], 1'b0};
        end
    end

    // Sobel Calculation for 4 Frames
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            gx_sobel_0 <= 0; gy_sobel_0 <= 0; mag_sobel_0 <= 0;
            gx_sobel_1 <= 0; gy_sobel_1 <= 0; mag_sobel_1 <= 0;
            gx_sobel_2 <= 0; gy_sobel_2 <= 0; mag_sobel_2 <= 0;
        end else if (valid_pipeline[1]) begin
            // Frame 0 Sobel Calculation
            gx_sobel_0 <=
                (-w_0_0_0 - (w_1_0_0 << 1) + (w_3_0_0 << 1) + w_4_0_0) +
                (-(w_0_1_0 << 2) - (w_1_1_0 << 3) + (w_3_1_0 << 3) + (w_4_1_0 << 2)) +
                (-(w_0_2_0 * 6) - (w_1_2_0 * 12) + (w_3_2_0 * 12) + (w_4_2_0 * 6)) +
                (-(w_0_3_0 << 2) - (w_1_3_0 << 3) + (w_3_3_0 << 3) + (w_4_3_0 << 2)) +
                (-w_0_4_0 - (w_1_4_0 << 1) + (w_3_4_0 << 1) + w_4_4_0);

            gy_sobel_0 <=
                (-w_0_0_0 + -(w_1_0_0 << 2) + -(w_2_0_0 * 6) + -(w_3_0_0 << 2) + -w_4_0_0) +
                (-(w_0_1_0 << 1) + -(w_1_1_0 << 3) + -(w_2_1_0 * 12) + -(w_3_1_0 << 3) + -(w_4_1_0 << 1)) +
                ((w_0_3_0 << 1) + (w_1_3_0 << 3) + (w_2_3_0 * 12) + (w_3_3_0 << 3) + (w_4_3_0 << 1)) +
                (w_0_4_0 + (w_1_4_0 << 2) + (w_2_4_0 * 6) + (w_3_4_0 << 2) + w_4_4_0);

            mag_sobel_0 <= (gx_sobel_0[15] ? (~gx_sobel_0 + 1) : gx_sobel_0) +
                         (gy_sobel_0[15] ? (~gy_sobel_0 + 1) : gy_sobel_0);


            gx_sobel_1 <=
                (-w_0_0_1 - (w_1_0_1 << 1) + (w_3_0_1 << 1) + w_4_0_1) +
                (-(w_0_1_1 << 2) - (w_1_1_1 << 3) + (w_3_1_1 << 3) + (w_4_1_1 << 2)) +
                (-(w_0_2_1 * 6) - (w_1_2_1 * 12) + (w_3_2_1 * 12) + (w_4_2_1 * 6)) +
                (-(w_0_3_1 << 2) - (w_1_3_1 << 3) + (w_3_3_1 << 3) + (w_4_3_1 << 2)) +
                (-w_0_4_1 - (w_1_4_1 << 1) + (w_3_4_1 << 1) + w_4_4_1);

            gy_sobel_1 <=
                (-w_0_0_1 + -(w_1_0_1 << 2) + -(w_2_0_1 * 6) + -(w_3_0_1 << 2) + -w_4_0_1) +
                (-(w_0_1_1 << 1) + -(w_1_1_1 << 3) + -(w_2_1_1 * 12) + -(w_3_1_1 << 3) + -(w_4_1_1 << 1)) +
                ((w_0_3_1 << 1) + (w_1_3_1 << 3) + (w_2_3_1 * 12) + (w_3_3_1 << 3) + (w_4_3_1 << 1)) +
                (w_0_4_1 + (w_1_4_1 << 2) + (w_2_4_1 * 6) + (w_3_4_1 << 2) + w_4_4_1);

            mag_sobel_1 <= (gx_sobel_1[15] ? (~gx_sobel_1 + 1) : gx_sobel_1) +
                         (gy_sobel_1[15] ? (~gy_sobel_1 + 1) : gy_sobel_1);

    
            gx_sobel_2 <=
                (-w_0_0_2 - (w_1_0_2 << 1) + (w_3_0_2 << 1) + w_4_0_2) +
                (-(w_0_1_2 << 2) - (w_1_1_2 << 3) + (w_3_1_2 << 3) + (w_4_1_2 << 2)) +
                (-(w_0_2_2 * 6) - (w_1_2_2 * 12) + (w_3_2_2 * 12) + (w_4_2_2 * 6)) +
                (-(w_0_3_2 << 2) - (w_1_3_2 << 3) + (w_3_3_2 << 3) + (w_4_3_2 << 2)) +
                (-w_0_4_2 - (w_1_4_2 << 1) + (w_3_4_2 << 1) + w_4_4_2);

            gy_sobel_2 <=
                (-w_0_0_2 + -(w_1_0_2 << 2) + -(w_2_0_2 * 6) + -(w_3_0_2 << 2) + -w_4_0_2) +
                (-(w_0_1_2 << 1) + -(w_1_1_2 << 3) + -(w_2_1_2 * 12) + -(w_3_1_2 << 3) + -(w_4_1_2 << 1)) +
                ((w_0_3_2 << 1) + (w_1_3_2 << 3) + (w_2_3_2 * 12) + (w_3_3_2 << 3) + (w_4_3_2 << 1)) +
                (w_0_4_2 + (w_1_4_2 << 2) + (w_2_4_2 * 6) + (w_3_4_2 << 2) + w_4_4_2);

            mag_sobel_2 <= (gx_sobel_2[15] ? (~gx_sobel_2 + 1) : gx_sobel_2) +
                         (gy_sobel_2[15] ? (~gy_sobel_2 + 1) : gy_sobel_2);

        end
    end

    // Sobel Enable and Output Logic
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            sobel_en <= 0;
        end else begin
            sobel_en <= valid_pipeline[2];
        end
    end

    // Output Assignment
    assign sobel_out_0 = ((mag_sobel_0[12:5] > threshold) && sobel_en) ? 4'hF : 4'h0;
    assign sobel_out_1 = ((mag_sobel_1[12:5] > threshold) && sobel_en) ? 4'hF : 4'h0;
    assign sobel_out_2 = ((mag_sobel_2[12:5] > threshold) && sobel_en) ? 4'hF : 4'h0;

endmodule




///////////////////
module sobel_filter (
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] gray_in,
    input  logic [7:0] threshold,
    input  logic [9:0] x_pixel,
    input  logic [9:0] y_pixel,
    //input  logic       display_enable,           /// sjkim 2025-03-27
    output logic [7:0] sobel_out
);
    localparam IMG_WIDTH = 640;  /// 640 -> 160 -> 640 sjkim 2025-03-27

    logic       display_enable;     /// sjkim 2025-03-27

    logic [7:0] line_top[0:IMG_WIDTH-1];
    logic [7:0] line_mid[0:IMG_WIDTH-1];

    logic [7:0] p11, p12, p13;
    logic [7:0] p21, p22, p23;
    logic [7:0] p31, p32, p33;

    logic [2:0] valid_shift;
    logic [9:0] x_delay[0:2];
    logic [9:0] y_delay[0:2];

    logic signed [10:0] gx, gy;
    logic [10:0] G_abs;
    logic [9:0] x_pixel_d;

    integer i;

    assign display_enable = (x_pixel > 160) && (y_pixel > 120) && (x_pixel < 480) && (y_pixel < 360);  /// sjkim 2025-03-27

    // x_pixel 딜레이 저장
    always_ff @(posedge clk) begin
        if (reset) begin
            x_pixel_d <= 0;
        end else begin
            if(x_pixel > 160) begin
                x_pixel_d <= x_pixel-160;
            end else begin
                x_pixel_d <= 10'bz;
            end
            
        end
    end

    // 라인 버퍼 저장
    always_ff @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < IMG_WIDTH; i++) begin
                line_top[i] <= 0;
                line_mid[i] <= 0;
            end
        end else if (display_enable) begin
            // line_mid[x_pixel_d] <= line_top[x_pixel_d];
            // line_top[x_pixel_d] <= gray_in;

            // gray_in => line_mid
            // line_mid => line_top

            
            line_top[x_pixel_d] <= line_mid[x_pixel_d];
            line_mid[x_pixel_d] <= gray_in;
            
        end
    end

    // 유효 위치 판별 및 픽셀 이동
    always_ff @(posedge clk) begin
        if (reset) begin
            {p11, p12, p13, p21, p22, p23, p31, p32, p33} <= 0;
            valid_shift <= 0;
        end else if (display_enable) begin
            p13 <= line_top[x_pixel_d];
            p12 <= p13;
            p11 <= p12;

            p23 <= line_mid[x_pixel_d];
            p22 <= p23;
            p21 <= p22;

            p33 <= gray_in;
            p32 <= p33;
            p31 <= p32;

            x_delay[0] <= x_pixel;
            y_delay[0] <= y_pixel;
            for (i = 1; i < 3; i++) begin
                x_delay[i] <= x_delay[i-1];
                y_delay[i] <= y_delay[i-1];
            end

            valid_shift <= {valid_shift[1:0], (x_pixel >= 2 && x_pixel < IMG_WIDTH - 2 && y_pixel >= 2)};
        end else begin
            valid_shift <= {valid_shift[1:0], 1'b0};
        end
    end

    // 소벨 계산
    always_ff @(posedge clk) begin
        if (reset) begin
            gx        <= 0;
            gy        <= 0;
            G_abs     <= 0;
            sobel_out <= 0;
        end else if (valid_shift[1]) begin
            gx = (p11 + 2 * p21 + p31) - (p13 + 2 * p23 + p33);
            gy = (p11 + 2 * p12 + p13) - (p31 + 2 * p32 + p33);
            G_abs <= (gx[10] ? -gx : gx) + (gy[10] ? -gy : gy);

            sobel_out <= (G_abs > threshold) ? 8'hFF : 8'h00;
        end else begin
             sobel_out <= 8'h00;     //sobel_out <= G_abs[7:0];    sjkim 2025-03-27
        end
    end

endmodule


module Sobel_Filter1 #(
    parameter THRESHOLD = 5  
)(
    input  logic       clk,
    input  logic       reset,
    input  logic [11:0] gray_in,
    input  logic [9:0] x_coor,
    input  logic [8:0] y_coor,
    input  logic       de,
    output logic [11:0] sobel_out
);
    localparam IMG_WIDTH = 640;

    logic [3:0] line_buffer_1[0:IMG_WIDTH-1];
    logic [3:0] line_buffer_2[0:IMG_WIDTH-1];

    logic [3:0] p11, p12, p13;
    logic [3:0] p21, p22, p23;
    logic [3:0] p31, p32, p33;

    logic [2:0] valid_pipeline;

    logic signed [10:0] gx, gy;
    logic [10:0] mag;

    integer i;

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                line_buffer_1[i] <= 0;
                line_buffer_2[i] <= 0;
            end
        end else if (de) begin
            line_buffer_2[x_coor] <= line_buffer_1[x_coor];
            line_buffer_1[x_coor] <= gray_in[3:0];
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            {p11, p12, p13, p21, p22, p23, p31, p32, p33} <= 0;
            valid_pipeline <= 0;
        end else if (de) begin
            p13 <= line_buffer_2[x_coor];
            p12 <= p13;
            p11 <= p12;

            p23 <= line_buffer_1[x_coor];
            p22 <= p23;
            p21 <= p22;

            p33 <= gray_in[3:0];
            p32 <= p33;
            p31 <= p32;

            valid_pipeline <= {
                valid_pipeline[1:0], (x_coor >= 2 && y_coor >= 2)
            };
        end else begin
            valid_pipeline <= {valid_pipeline[1:0], 1'b0};
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            gx        <= 0;
            gy        <= 0;
            mag       <= 0;
            sobel_out <= 0;
        end else if (valid_pipeline[2]) begin
            gx <= (p13 + (p23 << 1) + p33) - (p11 + (p21 << 1) + p31);
            gy <= (p31 + (p32 << 1) + p33) - (p11 + (p12 << 1) + p13);
            mag <= (gx[10] ? -gx : gx) + (gy[10] ? -gy : gy);
            sobel_out <= (mag > THRESHOLD) ? 12'hFFF : 12'h0;
        end else begin
            sobel_out <= 0;
        end
    end

endmodule

// module sobel_filter (
//     input  logic       clk,
//     input  logic       reset,
//     input  logic [7:0] gray_in,
//     input  logic [7:0] threshold,
//     input  logic [9:0] x_pixel,
//     input  logic [9:0] y_pixel,
//     input  logic       display_enable,
//     output logic [7:0] sobel_out
// );

//     localparam IMG_WIDTH = 640;

//     logic [7:0] line_top[0:IMG_WIDTH-1];
//     logic [7:0] line_mid[0:IMG_WIDTH-1];

//     // gray_in 파이프라인 추가 (변경)
//     logic [7:0] gray_in_d1, gray_in_d2;

//     logic signed [10:0] gx, gy;
//     logic [10:0] G_abs;

//     logic [2:0] valid_shift;

//     // 딜레이된 x_pixel, y_pixel
//     logic [9:0] x_d[0:2];
//     logic [9:0] y_d[0:2];

//     integer i;

//     // x_pixel/y_pixel 파이프라인 (변경)
//     always_ff @(posedge clk) begin
//         x_d[0] <= x_pixel;
//         y_d[0] <= y_pixel;
//         x_d[1] <= x_d[0];
//         y_d[1] <= y_d[0];
//         x_d[2] <= x_d[1];
//         y_d[2] <= y_d[1];
//     end

//     // gray_in 파이프라인 (변경)
//     always_ff @(posedge clk) begin
//         gray_in_d1 <= gray_in;
//         gray_in_d2 <= gray_in_d1;
//     end

//     // 라인 버퍼 유지 (기존 유지)
//     always_ff @(posedge clk) begin
//         if (display_enable) begin
//             line_mid[x_pixel] <= line_top[x_pixel];
//             line_top[x_pixel] <= gray_in;
//         end
//     end

//     // valid shift 로직 (기존 유지)
//     always_ff @(posedge clk) begin
//         valid_shift <= {
//             valid_shift[1:0],
//             (x_pixel >= 2 && x_pixel < IMG_WIDTH - 2 && y_pixel >= 2)
//         };
//     end

//     // Sobel 연산 (p11~p33 위치 접근 방식으로 변경)
//     always_ff @(posedge clk) begin
//         if (reset) begin
//             gx        <= 0;
//             gy        <= 0;
//             G_abs     <= 0;
//             sobel_out <= 0;
//         end else if (valid_shift[2]) begin
//             // 위치 기반 픽셀 접근 (변경된 핵심 부분)
//             logic [7:0] p11, p12, p13;
//             logic [7:0] p21, p22, p23;
//             logic [7:0] p31, p32, p33;

//             p11 = line_top[x_d[2]-1];
//             p12 = line_top[x_d[2]];
//             p13 = line_top[x_d[2]+1];

//             p21 = line_mid[x_d[2]-1];
//             p22 = line_mid[x_d[2]];
//             p23 = line_mid[x_d[2]+1];

//             p31 = gray_in_d2;
//             p32 = gray_in_d1;
//             p33 = gray_in;

//             // Sobel 계산 (유지)
//             gx <= (p13 + (p23 << 1) + p33) - (p11 + (p21 << 1) + p31);
//             gy <= (p31 + (p32 << 1) + p33) - (p11 + (p12 << 1) + p13);
//             G_abs <= (gx[10] ? -gx : gx) + (gy[10] ? -gy : gy);


//             sobel_out <= (G_abs > threshold) ? 255 : 0;


//             // sobel_out <= (G_abs > threshold) ? 8'hFF : 8'h00;
//             // if (G_abs > threshold + 40) sobel_out <= 8'hFF;  // 강한 엣지
//             // else if (G_abs > threshold + 20)
//             //     sobel_out <= 8'hA0;  // 중간 엣지
//             // else if (G_abs > threshold) sobel_out <= 8'h50;  // 약한 엣지
//             // else sobel_out <= 8'h00;  // 배경

//             // if (G_abs > threshold)
//             //     sobel_out <= (G_abs > 8'd255) ? 8'd255 : G_abs;
//             // else sobel_out <= 8'd0;

//         end else begin
//             // sobel_out <= 8'h00;
//             sobel_out <= G_abs[7:0];

//         end
//     end

// endmodule
