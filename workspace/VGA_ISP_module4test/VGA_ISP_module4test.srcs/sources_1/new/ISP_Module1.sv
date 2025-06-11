`timescale 1ns / 1ps

module ISP_Module1(
    input logic clk,
    input logic reset,
    input logic [11:0] r_data1,
    input logic [11:0] r_data2,
    output logic motion_detected
    );

    logic [11:0] g_data1, g_data2, m_data1, m_data2;
    logic [9:0] x_pixel, y_pixel;
    logic v_sync, h_sync;
    logic DE;

    VGA_Controller U_VGA_Controller(
        .clk(clk),
        .reset(reset),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .DE(DE)
);

    Gray_filtering U_grayfiltering(
        .rData_diff1(r_data1),
        .rData_diff2(r_data2),
        .Gray_diff1(g_data1),
        .Gray_diff2(g_data2)
    );

    Mopology_Filter #(.IMG_WIDTH(640), .ADDR_WIDTH(10)) U_Mopology_Filter1(
        .clk(clk),
        .reset(reset),
        .i_data(g_data1),   
        .x_coor(x_pixel),
        .y_coor(y_pixel),
        .DE(DE),
        .o_data(m_data1)  
);

    Mopology_Filter #(.IMG_WIDTH(640), .ADDR_WIDTH(10)) U_Mopology_Filter2(
        .clk(clk),
        .reset(reset),
        .i_data(g_data2),   
        .x_coor(x_pixel),
        .y_coor(y_pixel),
        .DE(DE),
        .o_data(m_data2)  
);

    Motion_Detector U_Motion_Detector(
        .clk(clk),
        .reset(reset),
        .DE(DE),
        .curr_pixel(m_data1),
        .prev_pixel(m_data2),  
        .motion_detected(motion_detected),
        .motion_pixel_out(),
        .v_sync(v_sync)
);
endmodule


module Mopology_Filter #(
    parameter IMG_WIDTH = 640,
    parameter ADDR_WIDTH = 10  // log2(640) ≈ 10
)(
    input logic clk,
    input logic reset,
    input logic [11:0] i_data,   
    input logic [9:0] x_coor,
    input logic [9:0] y_coor,
    input logic DE,
    output logic [11:0] o_data  
);

    // Line buffers using inferred block RAM
    logic [0:0] erode_line1_ram [0:IMG_WIDTH-1];
    logic [0:0] erode_line2_ram [0:IMG_WIDTH-1];

    logic erode_read1, erode_read2;
    logic [0:0] erode_line1_pixel, erode_line2_pixel;

    // 3x3 windows
    logic erode_p11, erode_p12, erode_p13;
    logic erode_p21, erode_p22, erode_p23;
    logic erode_p31, erode_p32, erode_p33;

    logic [2:0] erode_valid_pipeline;
    logic [11:0] erode_o_data_internal;
    logic erode_oe_internal;

    logic [0:0] dilate_line1_ram [0:IMG_WIDTH-1];
    logic [0:0] dilate_line2_ram [0:IMG_WIDTH-1];
    logic [0:0] dilate_line1_pixel, dilate_line2_pixel;

    logic dilate_p11, dilate_p12, dilate_p13;
    logic dilate_p21, dilate_p22, dilate_p23;
    logic dilate_p31, dilate_p32, dilate_p33;

    logic [2:0] dilate_valid_pipeline;

    // === Erode ===
    // 윤곽선을 제거하고, 노이즈 제거 및 객체 축소
    // 3x3 픽셀에서 모든 값이 1(흰색)이면 중심 픽셀을 1로 설정, 
    always_ff @(posedge clk) begin
        if (reset) begin
            erode_valid_pipeline <= 3'b0;
        end else if (DE) begin
            // shift 2 lines: line2 <= line1, line1 <= new
            erode_line2_ram[x_coor] <= erode_line1_ram[x_coor];
            erode_line1_ram[x_coor] <= i_data[11]; // use MSB as binarized

            // read for 3x3 window
            erode_line2_pixel <= erode_line2_ram[x_coor];
            erode_line1_pixel <= erode_line1_ram[x_coor];

            erode_p13 <= erode_line2_pixel;
            erode_p12 <= erode_p13;
            erode_p11 <= erode_p12;

            erode_p23 <= erode_line1_pixel;
            erode_p22 <= erode_p23;
            erode_p21 <= erode_p22;

            erode_p33 <= i_data[11];
            erode_p32 <= erode_p33;
            erode_p31 <= erode_p32;

            erode_valid_pipeline <= {erode_valid_pipeline[1:0], (x_coor >= 2 && y_coor >= 2)};
        end else begin
            erode_valid_pipeline <= {erode_valid_pipeline[1:0], 1'b0};
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            erode_o_data_internal <= 12'h000;
            erode_oe_internal <= 1'b0;
        end else if (erode_valid_pipeline[2]) begin
            erode_oe_internal <= 1'b1;
            if (&{erode_p11, erode_p12, erode_p13, erode_p21, erode_p22, erode_p23, erode_p31, erode_p32, erode_p33})
                erode_o_data_internal <= 12'hFFF;
            else
                erode_o_data_internal <= 12'h000;
        end else begin
            erode_oe_internal <= 1'b0;
            erode_o_data_internal <= 12'h000;
        end
    end

    // === Dilate ===
    // 객체의 외곽 확장, 객체 확대 or 노이즈 제거
    // 3x3 픽셀 내 하나라도 1이면 중심 픽셀 = 1(흰색)
    // 결과적으로 : 흰색 노이즈 제거 + 객체 남기고 경계 다듬기
    always_ff @(posedge clk) begin
        if (reset) begin
            dilate_valid_pipeline <= 3'b0;
        end else if (erode_oe_internal) begin
            dilate_line2_ram[x_coor] <= dilate_line1_ram[x_coor];
            dilate_line1_ram[x_coor] <= erode_o_data_internal[11];

            dilate_line2_pixel <= dilate_line2_ram[x_coor];
            dilate_line1_pixel <= dilate_line1_ram[x_coor];

            dilate_p13 <= dilate_line2_pixel;
            dilate_p12 <= dilate_p13;
            dilate_p11 <= dilate_p12;

            dilate_p23 <= dilate_line1_pixel;
            dilate_p22 <= dilate_p23;
            dilate_p21 <= dilate_p22;

            dilate_p33 <= erode_o_data_internal[11];
            dilate_p32 <= dilate_p33;
            dilate_p31 <= dilate_p32;

            dilate_valid_pipeline <= {dilate_valid_pipeline[1:0], (x_coor >= 2 && y_coor >= 2)};
        end else begin
            dilate_valid_pipeline <= {dilate_valid_pipeline[1:0], 1'b0};
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            o_data <= 12'h000;
        end else if (dilate_valid_pipeline[2]) begin
            if (|{dilate_p11, dilate_p12, dilate_p13, dilate_p21, dilate_p22, dilate_p23, dilate_p31, dilate_p32, dilate_p33})
                o_data <= 12'hFFF;
            else
                o_data <= 12'h000;
        end else begin
            o_data <= 12'h000;
        end
    end

endmodule

module Gray_filtering(
    input logic [11:0] rData_diff1,
    input logic [11:0] rData_diff2,
    output logic [11:0] Gray_diff1,
    output logic [11:0] Gray_diff2
    );

    logic [11:0] Grayscale1, Grayscale2;

    assign Grayscale1 = (77*(rData_diff1[11:8])) + (150*(rData_diff1[7:4])) + (29*(rData_diff1[3:0]));
    assign Grayscale2 = (77*(rData_diff2[11:8])) + (150*(rData_diff2[7:4])) + (29*(rData_diff2[3:0]));

    assign Gray_diff1 = {Grayscale1[11:8], Grayscale1[11:8], Grayscale1[11:8]}; 
    assign Gray_diff2 = {Grayscale2[11:8], Grayscale2[11:8], Grayscale2[11:8]}; 
endmodule

module Motion_Detector (
    input  logic        clk,
    input  logic        reset,
    input  logic        DE,
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


module VGA_Controller (
    input  logic       clk,
    input  logic       reset,
    // output logic       rclk,
    output logic       h_sync,
    output logic       v_sync,
    output logic [9:0] x_pixel,
    output logic [9:0] y_pixel,
    output logic       DE
    //output logic       DE1,
    //output logic       DE2
);

    logic pclk;
    logic [9:0] h_counter, v_counter;

    assign rclk = clk;

    pixel_counter U_Pixel_Counter (
        .pclk(clk),
        .reset(reset),
        .h_counter(h_counter),
        .v_counter(v_counter)
    );

    vga_decoder U_vga_decoder (
        .h_counter(h_counter),
        .v_counter(v_counter),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .DE(DE)
    );

endmodule

module pixel_counter (
    input  logic       pclk,
    input  logic       reset,
    output logic [9:0] h_counter,
    output logic [9:0] v_counter
);

    localparam H_MAX = 800, V_MAX = 525;

    always_ff @(posedge pclk) begin : Horizontal_counter
        if (reset) begin
            h_counter <= 0;
        end else begin
            if (h_counter == H_MAX - 1) begin
                h_counter <= 0;
            end else begin
                h_counter <= h_counter + 1;
            end
        end
    end

    always_ff @(posedge pclk) begin : Vertical_counter
        if (reset) begin
            v_counter <= 0;
        end else begin
            if (h_counter == H_MAX - 1) begin
                if (v_counter == V_MAX - 1) begin
                    v_counter <= 0;
                end else begin
                    v_counter <= v_counter + 1;
                end
            end
        end
    end

endmodule

module vga_decoder (
    input  [9:0] h_counter,
    input  [9:0] v_counter,
    output       h_sync,
    output       v_sync,
    output [9:0] x_pixel,
    output [9:0] y_pixel,
    output       DE
    //output       DE1,
    //output       DE2
);

    localparam H_Visible_area = 640;
    localparam H_Front_porch = 16;
    localparam H_Sync_pulse = 96;
    localparam H_Back_porch = 48;
    localparam H_Whole_line = 800;

    localparam V_Visible_area = 480;
    localparam V_Front_porch = 10;
    localparam V_Sync_pulse = 2;
    localparam V_Back_porch = 33;
    localparam V_Whole_line = 525;

    assign h_sync = !((h_counter >= (H_Visible_area + H_Front_porch)) && (h_counter < (H_Visible_area + H_Front_porch + H_Sync_pulse)));
    assign v_sync = !((v_counter >= (V_Visible_area + V_Front_porch)) && (v_counter < (V_Visible_area + V_Front_porch + V_Sync_pulse)));
    assign DE = (h_counter < H_Visible_area) && (v_counter < V_Visible_area);
    //assign DE1 = (h_counter < 320) && (v_counter < 480);
    //assign DE2 = (h_counter > 320) && (h_counter < 640) && (v_counter < 480);
    assign x_pixel = h_counter;
    assign y_pixel = v_counter;

endmodule
