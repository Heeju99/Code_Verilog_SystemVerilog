`timescale 1ns / 1ps

module OV7670_VGA_Display (
    // linear vilter switch
    input logic [1:0] sw_mode,

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
    output logic SDA_debug,

    //additional
    output logic out_text_en
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

    logic [11:0] rData, rData_real, rData_diff1, rData_diff2, motion_diff_red;
    logic [11:0] interpol1, interpol2, Gray_diff1, Gray_diff2;
    logic [11:0] sobel_out1, sobel_out2;

    

    //additional
    logic text_en;
    assign out_text_en = text_en;

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
        .v_sync(v_sync) // v_sync
    );
/*
    upscale U_upscale(
        .clk(clk_25Mhz),
        .reset(reset),
        .rData_diff1(rData_diff1),   // 12bit 컬러 데이터 가정
        .rData_diff2(rData_diff2),   // 12bit 컬러 데이터 가정
        .DE(DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .interpol1(interpol1),
        .interpol2(interpol2)
);
*/

    // ISP
    // Grayscale 필터
    Gray_filtering U_Gray_filtering(
        .rData_diff1(rData_diff1), //rData_diff1
        .rData_diff2(rData_diff2), //rData_diff2
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

//     Motion_Detector U_Motion_Detector(
//         .clk(clk_25Mhz),
//         .reset(reset),               // 추가: 리셋 신호
//         .DE(DE),
//         .curr_pixel(sobel_out1),
//         .prev_pixel(sobel_out2),  
//         .motion_detected(text_en),
//         .motion_pixel_out(motion_diff_red),
//         .v_sync(v_sync)
// );

    Motion_Detector U_Motion_Detector(
        .clk(clk_25Mhz),
        .reset(reset),               // 추가: 리셋 신호
        .DE(DE),
        .threshold(threshold),
        .curr_pixel(sobel_out1),
        .prev_pixel(sobel_out2),  
        .motion_detected(text_en),
        .motion_pixel_out(motion_diff_red),
        .v_sync(v_sync)
);

    vga_text U_vga_text(
        .clk(clk_100Mhz),
        .DE(DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .text_en(text_en),
        .text_pixel(text_pixel)
);


//     Motion_Detector U_Motion_Detector(
//         .clk(clk_25Mhz),
//         .DE(DE),
//         .curr_pixel(sobel_out1),
//         .prev_pixel(sobel_out2),  
//         .motion_detected(),                 //text 출력용
//         .motion_pixel_out(motion_diff_red)  //차이 확인용
// );

    // text_print

    // MUX
    // assign rData = sw[2] ? rData_real : sobel_out1;
    assign rData = sw[3] ? motion_diff_red : rData_real;
    // Frame Buffer reader
    QVGA_MemController U_QVGA_MemController (
        .sw         (sw[1:0]),
        .text_pixel (text_pixel),
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

module vga_text(
    input  logic       clk,
    input  logic       DE,
    input  logic [9:0] x_pixel,
    input  logic [9:0] y_pixel,
    input  logic       text_en,
    output logic       text_pixel
);

    logic [7:0] message_ram[0:8];

    initial begin
      message_ram[0] = "G";
      message_ram[1] = "A";
      message_ram[2] = "M";
      message_ram[3] = "E";
      message_ram[4] = " ";
      message_ram[5] = "O";
      message_ram[6] = "V";
      message_ram[7] = "E";
      message_ram[8] = "R";
    end

    vga_text_renderer #(
        .X_START(124),
        .Y_START(240)
    ) U_TextRenderer (
        .clk           (clk), //clk_100MHz
        .DE            (DE),
        .x_pixel       (x_pixel),
        .y_pixel       (y_pixel),
        .text_en       (text_en),
        .message_ram   (message_ram),
        .text_pixel    (text_pixel)
    );

endmodule


module vga_text_renderer #(
    parameter int X_START   = 124,
    parameter int Y_START   = 240,
    parameter int NUM_CHARS = 9,
    parameter int SCALE     = 2
) (
    input  logic       clk,
    input  logic       DE,
    input  logic [9:0] x_pixel,
    input  logic [9:0] y_pixel,
    input  logic       text_en,
    input  logic [7:0] message_ram [0:NUM_CHARS-1],
    output logic       text_pixel
);

    localparam int CHAR_WIDTH  = 8 * SCALE;
    localparam int CHAR_HEIGHT = 8 * SCALE;
  
    // 폰트 ROM
    logic [7:0] font_rom[0:2047];  // 256 characters * 8 rows
  
    initial begin
      $readmemh("font8x8.mem", font_rom);
    end
  
    logic [ 4:0] char_col;
    logic [ 3:0] char_row;
    logic [ 7:0] char_ascii;
    logic [ 7:0] char_bitmap;
    logic [10:0] font_addr;
  
    assign char_col = (x_pixel - X_START) / CHAR_WIDTH;
    assign char_row = (y_pixel - Y_START) / CHAR_HEIGHT;
  
    always_comb begin
        text_pixel = 1'b0;
    
        if (text_en &&
            x_pixel >= X_START && x_pixel < X_START + NUM_CHARS * CHAR_WIDTH &&
            y_pixel >= Y_START && y_pixel < Y_START + CHAR_HEIGHT) begin
            
            char_ascii  = message_ram[char_col];
            font_addr   = char_ascii * 8 + ((y_pixel - Y_START)/SCALE) % CHAR_HEIGHT;
            char_bitmap = font_rom[font_addr];
    
            if (char_bitmap[((x_pixel - X_START)/SCALE) % CHAR_WIDTH]) begin
              text_pixel = 1'b1;
            end
        end
    end

endmodule