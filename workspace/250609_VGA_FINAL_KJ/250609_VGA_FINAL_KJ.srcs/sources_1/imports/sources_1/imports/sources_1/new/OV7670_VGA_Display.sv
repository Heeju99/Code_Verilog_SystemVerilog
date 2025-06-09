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
    input logic play,
    input logic [2:0] sw,
    output logic h_sync,
    output logic v_sync,
    output logic h_sync_debug,
    output logic v_sync_debug,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port,
    output logic DE_debug,
    output logic ov7670_href_debug,
    output logic ov7670_v_sync_debug,
    output logic PWM_signal,

    //additional
    output logic out_text_en,
    output logic [4:0] led1,
    output logic [4:0] led2
);

    logic [9:0] x_pixel, y_pixel;
    logic we, DE;
    logic [16:0] wAddr1, rAddr1;
    logic [16:0] wAddr2, rAddr2;
    logic [15:0] wData;
    logic w_rclk, d_en, rclk;
    logic [3:0] red, green, blue;
    logic [3:0] red_filter, green_filter, blue_filter;
    logic [3:0] red_gray, green_gray, blue_gray;
    logic btn_start;
    logic clk_100Mhz, clk_25Mhz;
    logic en;
    logic locked;
    logic system_reset;

    logic [11:0] rData, rData_real, rData_diff1, rData_diff2, motion_diff_red1, motion_diff_red2;
    logic [11:0] interpol1, interpol2, Gray_diff1, Gray_diff2;
    logic [11:0] sobel_out1, sobel_out2;
    logic [11:0] mopol_out1, mopol_out2;

    

    //additional
    logic text_en;
    logic btn_play;
    logic buzzer_done, buzzer_start;
    logic buzzer_start1, buzzer_start2;
    logic motion_done, motion_detected1, motion_detected2;
    logic text_pixel_score1;
    logic text_pixel_score2;
    logic text_pixel_result1;
    logic text_pixel_result2;
    logic text_en_surv1;
    logic text_en_surv2;
    logic text_en_over1;
    logic text_en_over2;
    logic [2:0] score1;
    logic [2:0] score2;
    logic sel_text1;
    logic sel_text2;
    logic DE1, DE2;

    // assign out_text_en = sel_text ? text_en_surv : text_en_over;
    // assign out_text_en = motion_detected;

    assign w_rclk = clk_100Mhz;

    assign ov7670_xclk = clk_25Mhz;

    assign h_sync_debug = h_sync;
    assign v_sync_debug = v_sync;
    assign DE_debug = DE;
    assign ov7670_href_debug = ov7670_href;
    assign ov7670_v_sync_debug = ov7670_v_sync;

    assign buzzer_start = buzzer_start1 || buzzer_start2;

    // Clocking Wizard (MMCM)
    clk_wiz_2 U_clk_wiz_2(
        .clk_in1(clk),
        .reset(reset),
        .locked(locked),
        .clk_100Mhz(clk_100Mhz),
        .clk_25Mhz(clk_25Mhz)
    );

    // Button debounce uses MMCM 출력을 사용하는 게 더 안전함
    btn_debounce U_btn_debounce1(
        .clk(clk_100Mhz),         
        .reset(reset),
        .i_btn(start),
        .o_btn(btn_start)
    );

    btn_debounce U_btn_debounce2(
        .clk(clk_100Mhz),         
        .reset(reset),
        .i_btn(play),
        .o_btn(btn_play)
    );

    buzzer_PWM U_buzzer_PWM(
        .clk(clk_100Mhz),
        .reset(reset),
        .button(buzzer_start),
        .PWM_signal(PWM_signal),
        .buzzer_done(buzzer_done)
    );

    play_fsm U_play_fsm1(
        .clk(clk_100Mhz),
        .reset(reset),
        .start_btn(btn_play),
        .buzzer_done(buzzer_done),
        .buzzer_start(buzzer_start1),
        .motion_detected(motion_detected1),
        .text_en_surv(text_en_surv1),
        .text_en_over(text_en_over1),
        .score(score1),
        .sel_text(sel_text1),
        .led(led1)
    );

    play_fsm U_play_fsm2(
        .clk(clk_100Mhz),
        .reset(reset),
        .start_btn(btn_play),
        .buzzer_done(buzzer_done),
        .buzzer_start(buzzer_start2),
        .motion_detected(motion_detected2),
        .text_en_surv(text_en_surv2),
        .text_en_over(text_en_over2),
        .score(score2),
        .sel_text(sel_text2),
        .led(led2)
    );

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
        .wAddr1      (wAddr1),
        .wAddr2      (wAddr2),
        .wData      (wData)
    );

    frame_buffer_top U_frame_buffer_top(
        .wclk(ov7670_pclk),
        .reset(reset),
        .we(we),
        .wAddr1(wAddr1),
        .wAddr2(wAddr2),
        .wData(wData),
        .rclk(clk_25Mhz),
        .oe(d_en),
        .rAddr1(rAddr1),
        .rAddr2(rAddr2),
        .rData_real(rData_real),
        .rData_diff1(rData_diff1),
        .rData_diff2(rData_diff2),
        .v_sync(v_sync) // v_sync
    );

    // ISP
    // Grayscale 필터
    Gray_filtering U_Gray_filtering(
        .rData_diff1(rData_diff1), 
        .rData_diff2(rData_diff2), 
        .Gray_diff1(Gray_diff1),
        .Gray_diff2(Gray_diff2)
    );

//     sobel_filter_top U_sobel_filter_top (
//         .clk(clk_25Mhz),
//         .reset(reset),
//         // input  logic [7:0] threshold,
//         .g_filter_diff1(Gray_diff1),
//         .g_filter_diff2(Gray_diff1),
//         .DE(DE),
//         .x_pixel(x_pixel),
//         .y_pixel(y_pixel),
//         .sobel_out1(sobel_out1),
//         .sobel_out2(sobel_out2)
// );

    Mopology_Filter_TOP U_Mopology_Filter_TOP(
        .clk(clk_25Mhz),
        .reset(reset),
        .i_data1(Gray_diff1),   
        .i_data2(Gray_diff2),   
        .x_coor(x_pixel),
        .y_coor(y_pixel),
        .DE(DE),            
        .o_data1(mopol_out1),
        .o_data2(mopol_out2)
    );

    Motion_Detector U_Motion_Detector1(
        .clk(clk_25Mhz),
        .reset(reset),               // 추가: 리셋 신호
        .play(btn_play),
        .DE(DE1),
        .threshold(threshold),
        .curr_pixel(sobel_out1), //mopol_out1
        .prev_pixel(sobel_out2),  //mopol_out2
        .motion_detected(motion_detected1),
        .motion_pixel_out(motion_diff_red1),
        .v_sync(v_sync)
    );
    
    Motion_Detector U_Motion_Detector2(
        .clk(clk_25Mhz),
        .reset(reset),               // 추가: 리셋 신호
        .play(btn_play),
        .DE(DE2),
        .threshold(threshold),
        .curr_pixel(mopol_out1),
        .prev_pixel(mopol_out2),  
        .motion_detected(motion_detected2),
        .motion_pixel_out(motion_diff_red2),
        .v_sync(v_sync)
    );

    vga_text U_vga_text(
        .clk(clk_100Mhz),
        .reset(reset),
        .DE1(DE1),
        .DE2(DE2),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .text_en_surv1(text_en_surv1),
        .text_en_surv2(text_en_surv2),
        .text_en_over1(text_en_over1),
        .text_en_over2(text_en_over2),
        .text_pixel_score1(text_pixel_score1),
        .text_pixel_score2(text_pixel_score2),
        .text_pixel_result1(text_pixel_result1),
        .text_pixel_result2(text_pixel_result2),
        .sel_text1(sel_text1),
        .sel_text2(sel_text2),
        .score1(score1),
        .score2(score2)
);

    assign rData = sw[2] ? (motion_diff_red1||motion_diff_red2) : rData_real;
    // Frame Buffer reader
    QVGA_MemController U_QVGA_MemController (
        .sw         (sw[1:0]),
        .text_pixel_score1(text_pixel_score1),
        .text_pixel_score2(text_pixel_score2),
        .text_pixel_result1(text_pixel_result1),
        .text_pixel_result2(text_pixel_result2),
        // .clk        (w_rclk),
        .x_pixel    (x_pixel),
        .y_pixel    (y_pixel),
        .DE         (DE),
        .DE1        (DE1),
        .DE2        (DE2),
        // .rclk       (rclk),
        .d_en       (d_en),
        .rAddr1      (rAddr1),
        .rAddr2      (rAddr2),
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
        .DE     (DE),
        .DE1     (DE1),
        .DE2     (DE2)
    );

endmodule