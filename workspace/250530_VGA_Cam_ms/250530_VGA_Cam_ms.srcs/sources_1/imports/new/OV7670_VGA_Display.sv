`timescale 1ns / 1ps

module OV7670_VGA_Display (
    // global signals
    input logic clk,
    input logic reset,
    //switch
    input logic sw1,
    input logic [2:0] sw_mode,
    input logic sw_up,
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
    output logic [3:0] blue_port
);

    logic [9:0] x_pixel, y_pixel;
    logic we, DE;
    logic [16:0] wAddr, rAddr;
    logic [15:0] wData, rData;
    logic w_rclk, d_en, rclk;
    logic [3:0] r_red_port, r_blue_port, r_green_port;
    logic [3:0] m_red_port, m_blue_port, m_green_port;
    logic [3:0] r_filter_red, r_filter_blue,r_filter_green;
    logic [3:0] g_filter_red, g_filter_green, g_filter_blue;
    logic [3:0] s_filter_red, s_filter_green, s_filter_blue;

    pixel_clk_gen U_OV7670_CLK_Gen (
        .clk  (clk),
        .reset(reset),
        .pclk (ov7670_xclk)
    );

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
        .reset  (reset),
        .rclk   (w_rclk),
        .h_sync (h_sync),
        .v_sync (v_sync),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .DE     (DE)
    );

    QVGA_MemController U_QVGA_MemController (
        .sw_up     (sw_up),
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

    sobel_heeju U_sobel_heeju(
    .clk(clk),
    .reset(reset),
    //input gray
    .g_filter_red(g_filter_red),
    .g_filter_green(g_filter_green),
    .g_filter_blue(g_filter_blue),

    .DE(DE),
    .x_pixel(x_pixel), 
    .y_pixel(y_pixel),

    .s_filter_red(s_filter_red), 
    .s_filter_green(s_filter_green), 
    .s_filter_blue(s_filter_blue)
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
    .g_filter_red(s_filter_red),
    .g_filter_green(s_filter_green),
    .g_filter_blue(s_filter_blue),
    //Colour
    .r_filter_red(r_filter_red),
    .r_filter_green(r_filter_green),
    .r_filter_blue(r_filter_blue),
    //output
    .filter_red(red_port),
    .filter_green(green_port),
    .filter_blue(blue_port)
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