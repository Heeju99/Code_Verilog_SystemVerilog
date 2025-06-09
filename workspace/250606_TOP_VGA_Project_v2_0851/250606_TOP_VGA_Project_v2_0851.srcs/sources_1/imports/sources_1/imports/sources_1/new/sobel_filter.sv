`timescale 1ns / 1ps

module sobel_filter_top (
    input  logic        clk,
    input  logic        reset,
    // input  logic [7:0] threshold,
    input  logic [11:0] g_filter_diff1,
    input  logic [11:0] g_filter_diff2,
    input  logic        DE,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    output logic [11:0] sobel_out1,
    output logic [11:0] sobel_out2
);
    logic pclk;

    // pixel_clk_gen U_Pix_CLK_Gen (
    //     .clk  (clk),
    //     .reset(reset),
    //     .pclk (pclk)
    // );

    sobel_filter U_sobel_filter1 (
        .clk(clk),
        .reset(reset),
        // .threshold(threshold),
        .g_filter_diff(g_filter_diff1),
        .DE(DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .sobel_out(sobel_out1)
    );

    sobel_filter U_sobel_filter2 (
        .clk(clk),
        .reset(reset),
        // .threshold(threshold),
        .g_filter_diff(g_filter_diff2),
        .DE(DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .sobel_out(sobel_out2)
    );

endmodule

// module sobel_filter #(
//     parameter IMG_WIDTH = 640
// )(
//     input  logic        clk,
//     input  logic        reset,
//     input  logic [7:0]  threshold,        // 동적으로 조절 가능한 threshold
//     input  logic [11:0] g_filter_diff,    // 입력: Grayscale pixel (green 채널 우선 사용)
//     input  logic        DE,               // Display Enable (화면 유효 영역에서만 처리)
//     output logic [11:0] sobel_out         // 출력: 에지 강조된 grayscale pixel
// );

//     // grayscale의 green 채널 (4비트) 추출
//     logic [3:0] gray_in;
//     assign gray_in = g_filter_diff[7:4];

//     // 2개의 라인 버퍼 (프레임 저장 불필요, 행 간 픽셀 저장용)
//     logic [3:0] line_buf1 [0:IMG_WIDTH-1];
//     logic [3:0] line_buf2 [0:IMG_WIDTH-1];

//     // 시프트 레지스터들 (3x3 커널 구성용)
//     logic [3:0] shift0, shift1, shift2;
//     logic [3:0] shift0_l1, shift1_l1, shift2_l1;
//     logic [3:0] shift0_l2, shift1_l2, shift2_l2;

//     // X 좌표 카운터
//     logic [9:0] x_count;

//     // Sobel 연산 변수 (signed 13비트로 overflow 방지)
//     logic signed [12:0] gx, gy;
//     logic [12:0] mag;

//     // Pipeline 유효 신호
//     logic [2:0] valid_pipeline;

//     // 메인 동기 로직
//     always_ff @(posedge clk) begin
//         if (reset) begin
//             x_count         <= 0;
//             sobel_out       <= 0;
//             gx              <= 0;
//             gy              <= 0;
//             mag             <= 0;
//             valid_pipeline  <= 0;

//             shift0 <= 0; shift1 <= 0; shift2 <= 0;
//             shift0_l1 <= 0; shift1_l1 <= 0; shift2_l1 <= 0;
//             shift0_l2 <= 0; shift1_l2 <= 0; shift2_l2 <= 0;
//         end else if (DE) begin
//             // X 좌표 관리
//             x_count <= (x_count == IMG_WIDTH - 1) ? 0 : x_count + 1;

//             // 라인 버퍼 업데이트
//             line_buf2[x_count] <= line_buf1[x_count];
//             line_buf1[x_count] <= gray_in;

//             // 시프트 레지스터 이동
//             shift2_l2 <= shift1_l2;
//             shift1_l2 <= shift0_l2;
//             shift0_l2 <= line_buf2[x_count];

//             shift2_l1 <= shift1_l1;
//             shift1_l1 <= shift0_l1;
//             shift0_l1 <= line_buf1[x_count];

//             shift2    <= shift1;
//             shift1    <= shift0;
//             shift0    <= gray_in;

//             // 유효 파이프라인 제어
//             valid_pipeline <= {valid_pipeline[1:0], (x_count > 1)};

//             // Sobel 계산
//             if (valid_pipeline[2]) begin
//                 gx <= (shift2_l2 + (shift2_l1 << 1) + shift2) -
//                       (shift0_l2 + (shift0_l1 << 1) + shift0);

//                 gy <= (shift0 + (shift1 << 1) + shift2) -
//                       (shift0_l2 + (shift1_l2 << 1) + shift2_l2);

//                 mag <= (gx[12] ? -gx : gx) + (gy[12] ? -gy : gy);

//                 sobel_out <= (mag > threshold) ? 12'hFFF : 12'h000;
//             end else begin
//                 sobel_out <= 12'h000;
//             end
//         end else begin
//             // 비유효 상태 처리
//             valid_pipeline <= {valid_pipeline[1:0], 1'b0};
//             sobel_out <= 12'h000;
//         end
//     end

// endmodule




// module sobel_filter #(
//     parameter IMG_WIDTH = 640
// )(
//     input  logic clk,
//     input  logic reset,
//     input logic [7:0] threshold,
//     input  logic [11:0] g_filter_diff,
//     input  logic        DE,
//     input  logic [9:0]  x_pixel,
//     input  logic [9:0]  y_pixel,
//     output logic [11:0] sobel_out
// );
//     localparam THRESHOLD = 5;

//     logic [3:0] gray_in;
//     assign gray_in = g_filter_diff[7:4];  // green 채널만 사용

//     // 3 line buffers (shift registers)
//     logic [3:0] line1[0:2];  // top
//     logic [3:0] line2[0:2];  // middle
//     logic [3:0] line3[0:2];  // bottom (현재 입력)

//     logic [2:0] valid_pipeline;
//     logic signed [10:0] gx, gy;
//     logic [10:0] mag;

//     always_ff @(posedge clk) begin
//         if (reset) begin
//             line1[0] <= 0; line1[1] <= 0; line1[2] <= 0;
//             line2[0] <= 0; line2[1] <= 0; line2[2] <= 0;
//             line3[0] <= 0; line3[1] <= 0; line3[2] <= 0;
//             valid_pipeline <= 0;
//             sobel_out <= 0;
//         end else if (DE) begin
//             // Shift line buffers
//             line1[0] <= line1[1];
//             line1[1] <= line1[2];
//             line1[2] <= line2[0];

//             line2[0] <= line2[1];
//             line2[1] <= line2[2];
//             line2[2] <= line3[0];

//             line3[0] <= line3[1];
//             line3[1] <= line3[2];
//             line3[2] <= gray_in;

//             // Pipeline valid control
//             valid_pipeline <= {valid_pipeline[1:0], 1'b1};

//             if (valid_pipeline[2]) begin
//                 gx <= (line1[2] + (line2[2] << 1) + line3[2]) -
//                       (line1[0] + (line2[0] << 1) + line3[0]);

//                 gy <= (line3[0] + (line3[1] << 1) + line3[2]) -
//                       (line1[0] + (line1[1] << 1) + line1[2]);

//                 mag <= (gx < 0 ? -gx : gx) + (gy < 0 ? -gy : gy);

//                 sobel_out <= (mag > threshold) ? 12'hFFF : 12'h000;
//             end else begin
//                 sobel_out <= 0;
//             end
//         end else begin
//             valid_pipeline <= {valid_pipeline[1:0], 1'b0};
//             sobel_out <= 0;
//         end
//     end
// endmodule


module sobel_filter (
    input logic clk,
    input logic reset,
    input logic [11:0] g_filter_diff,
    input logic       DE,
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    output logic [11:0] sobel_out
);
    localparam IMG_WIDTH = 640;
    localparam THRESHOLD = 24;

    //additional
    logic [11:0] gray_in = g_filter_diff;

    logic [3:0] line_buffer_1[0:IMG_WIDTH-1];
    logic [3:0] line_buffer_2[0:IMG_WIDTH-1];

    logic [3:0] p11, p12, p13;
    logic [3:0] p21, p22, p23;
    logic [3:0] p31, p32, p33;

    logic [2:0] valid_pipeline;
    logic display_en;

    logic signed [10:0] gx, gy;
    logic [10:0] mag;

    integer i;

    // assign display_en = (x_pixel < 320) && (120 < y_pixel) && (y_pixel < 360);

    // assign s_filter_red = sobel_out[3:0];      //((mag_sobel_0[12:5] > threshold) && sobel_en) ? 4'hF : 4'h0;
    // assign s_filter_blue = sobel_out[3:0];     //((mag_sobel_1[12:5] > threshold) && sobel_en) ? 4'hF : 4'h0;
    // assign s_filter_green = sobel_out[3:0];    //((mag_sobel_2[12:5] > threshold) && sobel_en) ? 4'hF : 4'h0;


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
            //if((x_pixel < 320 - 2) && (120 < y_pixel) && (y_pixel < 360)) begin
                sobel_out <= (mag > THRESHOLD) ? 12'hFFF : 12'h0;
            //end //else begin
                //sobel_out <= 0;
            //end
        end else begin
            sobel_out <= 0;
        end
    end

endmodule
