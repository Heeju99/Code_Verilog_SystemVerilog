`timescale 1ns / 1ps

module OV7670_VGA_Display (
    // global signals
    input logic clk,   // 수정됨
    input logic reset,
    input  logic [7:0] threshold,
    // ov7670 signals
    output logic ov7670_xclk,
    output logic SCL,
    output logic SDA,
    input logic ov7670_pclk,
    input logic ov7670_href,
    input logic ov7670_v_sync,
    input logic [7:0] ov7670_data,

    // export signals
    input logic start,
    input logic [5:0] sw,
    output logic h_sync,
    output logic v_sync,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port,
    output logic SCL_debug,
    output logic SDA_debug
);

    logic [9:0] x_pixel, y_pixel;
    logic we, DE;
    logic [16:0] wAddr, rAddr;
    logic [15:0] wData;
    logic w_rclk, d_en, rclk;
    logic [3:0] red, green, blue;
    logic [3:0] red_filter, green_filter, blue_filter;
    logic [3:0] red_gray, green_gray, blue_gray;
    logic btn_start;
    logic clk_100Mhz, clk_25Mhz;
    logic en;

    logic [11:0] rData, rData_real, rData_diff1, rData_diff2;
    logic [11:0] Gray_diff1, Gray_diff2;
    logic [11:0] sobel_out1, sobel_out2;

    // assign red_port   = sw[3] ? red_gray   : red_filter; 
    // assign green_port = sw[3] ? green_gray : green_filter; 
    // assign blue_port  = sw[3] ? blue_gray  : blue_filter; 

    assign SCL_debug = SCL;
    assign SDA_debug = SDA;

    assign w_rclk = clk_100Mhz;

    assign ov7670_xclk = clk_25Mhz;

    // Clocking Wizard (MMCM)
    clk_wiz_1 U_clk_wiz_1(
        .clk_in1(clk),
        .reset(reset),
        .clk_100Mhz(clk_100Mhz),
        .clk_25Mhz(clk_25Mhz)
    );

    // Button debounce uses MMCM 출력을 사용하는 게 더 안전함
    btn_debounce U_btn_debounce(
        .clk(clk_100Mhz),          // 수정됨
        .reset(reset),
        .i_btn(start),
        .o_btn(btn_start)
    );

    // // OV7670 XCLK 생성
    // pixel_clk_gen U_OV7670_CLK_Gen (
    //     .clk(clk_100Mhz),    // 수정됨
    //     .reset(reset),
    //     .pclk(ov7670_xclk)
    // );

    // OV7670 설정용 SCCB 컨트롤
    OV7670_Master U_OV7670_Master(
        .clk(clk_100Mhz),    // 수정됨
        .reset(reset),
        .startSig(btn_start),
        .SCL(SCL),
        .SDA(SDA)
    );

    // Camera → Frame Buffer write controller
    OV7670_MemController U_OV7670_MemController (
        .pclk       (ov7670_pclk),
        .reset      (reset),
        .href       (ov7670_href),
        .v_sync     (ov7670_v_sync),
        .ov7670_data(ov7670_data),
        .we         (we),
        .wAddr      (wAddr),
        .wData      (wData)
    );

    frame_buffer_top U_frame_buffer_top(
        .wclk(ov7670_pclk),
        .reset(reset),
        .we(we),
        .wAddr(wAddr),
        .wData(wData),
        .rclk(clk_25Mhz),
        .oe(d_en),
        .rAddr(rAddr),
        .rData_real(rData_real),
        .rData_diff1(rData_diff1),
        .rData_diff2(rData_diff2),
        .v_sync(ov7670_v_sync)
    );

    // ISP
    // Grayscale 필터
    Gray_filtering U_Gray_filtering(
        .rData_diff1(rData_diff1),
        .rData_diff2(rData_diff2),
        .Gray_diff1(Gray_diff1),
        .Gray_diff2(Gray_diff2)
    );

    // Sobel filter
    sobel_filter_top U_sobel_filter_top(
        .clk(clk_25Mhz),
        .reset(reset),
        .threshold(threshold),
        .g_filter_diff1(Gray_diff1),
        .g_filter_diff2(Gray_diff2),
        .DE(DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .sobel_out1(sobel_out1),
        .sobel_out2(sobel_out2)
    );

    // Diff_detect

    // text_print

    // MUX
    // assign rData = sw[2] ? rData_real : sobel_out1;
    assign rData = sw[3] ? sobel_out2 : rData_real;
    // Frame Buffer reader
    QVGA_MemController U_QVGA_MemController (
        .sw         (sw[1:0]),
        // .clk        (w_rclk),
        .x_pixel    (x_pixel),
        .y_pixel    (y_pixel),
        .DE         (DE),
        // .rclk       (rclk),
        .d_en       (d_en),
        .rAddr      (rAddr),
        .rData      (rData),
        .red_port   (red_port),
        .green_port (green_port),
        .blue_port  (blue_port)
    );

    // VGA 컨트롤러
    VGA_Controller U_VGA_Controller (
        .clk    (clk_25Mhz),       // 수정됨
        .reset  (reset),
        .h_sync (h_sync),
        .v_sync (v_sync),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .DE     (DE)
    );

    // RGB 필터
    // RGB_filtering U_RGB_filtering(
    //     .sw(sw[2:0]),
    //     .red(red),
    //     .green(green),
    //     .blue(blue),
    //     .red_filter(red_filter),
    //     .green_filter(green_filter),
    //     .blue_filter(blue_filter)
    // );

endmodule
