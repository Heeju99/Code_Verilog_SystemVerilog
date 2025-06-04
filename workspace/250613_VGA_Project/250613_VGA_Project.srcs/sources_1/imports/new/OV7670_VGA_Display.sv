`timescale 1ns / 1ps

module OV7670_VGA_Display (
    // global signals
    input logic clk,
    input logic reset,
    //button
    input logic sccb_start,
    //switch
    input logic c_chroma,
    input logic sw1,
    input logic [2:0] sw_mode,
    input logic sw_chroma,
    // ov7670 signals
    output logic ov7670_xclk,
    input logic ov7670_pclk,
    input logic ov7670_href,
    input logic ov7670_v_sync,
    input logic [7:0] ov7670_data,
    // export signals
    output logic h_sync,
    output logic v_sync,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port,
    //SCCB
    output logic SCL,
    output logic SDA,
    //OUTX
    output logic r_SCL,
    output logic r_SDA
);

    //add
    logic btn_start;
    logic clk_pixel;


    logic [9:0] x_pixel, y_pixel;
    logic we, DE;
    logic [16:0] wAddr, rAddr;
    logic [15:0] wData, rData;
    logic w_rclk, d_en, rclk;
    logic [3:0] r_red_port, r_blue_port, r_green_port;
    logic [3:0] m_red_port, m_blue_port, m_green_port;
    logic [3:0] r_filter_red, r_filter_blue,r_filter_green;
    logic [3:0] g_filter_red, g_filter_green, g_filter_blue;

    assign r_SCL = SCL;
    assign r_SDA = SDA;

    assign ov7670_xclk = clk_pixel;


    // 25.175 MHz 생성
    clk_wiz_0 u_clk_wiz (
        .clk_in1(clk),
        .reset(reset),
        .clk_pixel(clk_pixel),
        .locked()
    );    
/*
    pixel_clk_gen U_OV7670_CLK_Gen (
        .clk  (clk),
        .reset(reset),
        .pclk (ov7670_xclk)
    );
*/
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

    Frame_Buffer U_Frame_Buffer (
        .wclk (ov7670_pclk),
        .we   (we),
        .wAddr(wAddr),
        .wData(wData),
        .rclk (rclk),
        .oe   (d_en),
        .rAddr(rAddr),
        .rData(rData)
    );

    VGA_Controller U_VGA_Controller (
        .clk    (clk),
        .clk_pixel    (clk_pixel),
        .reset  (reset),
        .rclk   (w_rclk),
        .h_sync (h_sync),
        .v_sync (v_sync),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .DE     (DE)
    );

    QVGA_MemController U_QVGA_MemController (
        .c_chroma   (c_chroma),
        .sw_chroma     (sw_chroma),
        .clk       (w_rclk),
        .x_pixel   (x_pixel),
        .y_pixel   (y_pixel),
        .DE        (DE),
        .rclk      (rclk),
        .d_en      (d_en),
        .rAddr     (rAddr),
        .rData     (rData),
        .red_port  (m_red_port),
        .green_port(m_green_port),
        .blue_port (m_blue_port)
    );

    grayscale_converter U_grayscale(
        .red_port(m_red_port),
        .green_port(m_green_port),
        .blue_port(m_blue_port),
        .g_filter_red(g_filter_red),
        .g_filter_green(g_filter_green),
        .g_filter_blue(g_filter_blue)
);

    rgb_filter U_rgb_filter(
        .sw_mode(sw_mode),
        .red_port(m_red_port),
        .green_port(m_green_port),
        .blue_port(m_blue_port),
        .r_filter_red(r_filter_red),
        .r_filter_green(r_filter_green),
        .r_filter_blue(r_filter_blue)
);

    mux_2x1 U_Mux_2x1(
        .sw1(sw1),
        //Grayscale
        .g_filter_red(g_filter_red),
        .g_filter_green(g_filter_green),
        .g_filter_blue(g_filter_blue),
        //Colour
        .r_filter_red(r_filter_red),
        .r_filter_green(r_filter_green),
        .r_filter_blue(r_filter_blue),
        //output
        .filter_red(red_port),
        .filter_green(green_port),
        .filter_blue(blue_port)
);

    SCCB_intf U_SCCB_intf(
        .clk(clk),
        .reset(reset),
        .startSig(btn_start),
        .SCL(SCL),
        .SDA(SDA)
);

    button_debounce U_button_debounce(
        .clk(clk),
        .reset(reset),
        .i_btn(sccb_start),
        .o_btn(btn_start)
    );

endmodule


module mux_2x1(
    input  logic sw1,
    //Grayscale
    input  logic [3:0] g_filter_red,
    input  logic [3:0] g_filter_green,
    input  logic [3:0] g_filter_blue,
    //Colour
    input  logic [3:0] r_filter_red,
    input  logic [3:0] r_filter_green,
    input  logic [3:0] r_filter_blue,
    //output
    output logic [3:0] filter_red,
    output logic [3:0] filter_green,
    output logic [3:0] filter_blue
);

    always_comb begin
        if(sw1) begin  //0 = gray
            filter_red   = g_filter_red; //grascale
            filter_green = g_filter_green;
            filter_blue  = g_filter_blue;
        end else begin // 1 = colour
            filter_red   = r_filter_red; //rgb filter
            filter_green = r_filter_green;
            filter_blue  = r_filter_blue;
        end
    end
endmodule

module grayscale_converter(
    input  logic [3:0] red_port,
    input  logic [3:0] green_port,
    input  logic [3:0] blue_port,
    output logic [3:0] g_filter_red,
    output logic [3:0] g_filter_green,
    output logic [3:0] g_filter_blue
);
    logic [11: 0] gray;
    assign gray = (77 * red_port) + (150 * green_port) + (29 * blue_port);
    assign g_filter_red = gray[11:8];
    assign g_filter_green = gray[11:8];
    assign g_filter_blue = gray[11:8];
endmodule


module rgb_filter(
    input logic [2:0] sw_mode,
    input logic [3:0] red_port,
    input logic [3:0] green_port,
    input logic [3:0] blue_port,
    output logic [3:0] r_filter_red,
    output logic [3:0] r_filter_green,
    output logic [3:0] r_filter_blue
);
    always_comb begin
        if(sw_mode == 3'b001) begin   //RGB
            r_filter_red = 4'b0;
            r_filter_green = 4'b0;
            r_filter_blue = blue_port;
        end else if (sw_mode == 3'b010) begin //RGB
            r_filter_red = 4'b0;
            r_filter_green = green_port;
            r_filter_blue = 4'b0;
        end else if (sw_mode == 3'b011) begin //RGB
            r_filter_red = 4'b0;
            r_filter_green = green_port;
            r_filter_blue = blue_port;
        end else if (sw_mode == 3'b100) begin //RGB
            r_filter_red = red_port;
            r_filter_green = 4'b0;
            r_filter_blue = 4'b0;
        end else if (sw_mode == 3'b101) begin //RGB
            r_filter_red = red_port;
            r_filter_green = 4'b0;
            r_filter_blue = blue_port;
        end else if (sw_mode == 3'b110) begin //RGB
            r_filter_red = red_port;
            r_filter_green = green_port;
            r_filter_blue = 4'b0000;
        end else if (sw_mode == 3'b111)begin
            r_filter_red = red_port;
            r_filter_green = green_port;
            r_filter_blue = blue_port;
        end else begin
            r_filter_red = 4'b0;
            r_filter_green = 4'b0;
            r_filter_blue = 4'b0000;
        end
    end
endmodule 