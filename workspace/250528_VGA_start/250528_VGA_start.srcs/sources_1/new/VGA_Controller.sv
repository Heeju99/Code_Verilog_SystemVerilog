`timescale 1ns / 1ps

module VGA_Controller(

        input   logic clk,
        input   logic reset,
        //
        //input   logic [3:0] sw_red,
        //input   logic [3:0] sw_green,
        //input   logic [3:0] sw_blue,
        output  logic  h_sync,
        output  logic  v_sync,
        output  logic [3:0] red_port,
        output  logic [3:0] green_port,
        output  logic [3:0] blue_port
    );

    logic DE;
    logic [9:0] x_pixel, y_pixel;


vga_rgb_display U_RGB_DISPLAY (
        .DE        (DE),
        .x_pixel   (x_pixel),
        .y_pixel   (y_pixel),
        .red_port  (red_port),
        .green_port(green_port),
        .blue_port (blue_port)
    );

/*
    vga_jojung U_vga_jojung(
    .DE(DE),
    .x_pixel(x_pixel),
    .y_pixel(y_pixel),
    .red_port2(red_port),
    .green_port2(green_port),
    .blue_port2(blue_port)
);

    vga_rgb_switch U_VGA_RGB_Switch(
        .sw_red(sw_red),
        .sw_green(sw_green),
        .sw_blue(sw_blue),
        .DE(DE),  
        .red_port(red_port),
        .green_port(green_port),
        .blue_port(blue_port)
 );
*/
    VGA_Decoder U_VGA_Decoder(
        .clk(clk),
        .reset(reset),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .DE(DE),
        .x_pixel(x_pixel), //아직 필요 x
        .y_pixel(x_pixel)  //아직 필요 x
);
endmodule

//jeong
module vga_rgb_display(
    input  logic       DE,
    input  logic [9:0] x_pixel,
    input  logic [9:0] y_pixel,
    output logic [3:0] red_port, 
    output logic [3:0] green_port, 
    output logic [3:0] blue_port 
    );

    logic [11:0] color;
    logic [ 3:0] red, green, blue;

    assign {red, green, blue} = color;
    assign red_port   = DE ? red : 4'b0;
    assign green_port = DE ? green : 4'b0;
    assign blue_port  = DE ? blue : 4'b0;

    always_comb begin 
       if (y_pixel <320) begin
            if (x_pixel < 91) begin //w
                color = 12'hfff;
            end
            else if (x_pixel < 183) begin //y
                color = 12'hff0;
            end
            else if (x_pixel < 274) begin //m
                color = 12'h0ff;
            end
            else if (x_pixel < 365) begin //g
                color = 12'h0f0;
            end
            else if (x_pixel < 457) begin //p
                color = 12'hf0f;
            end
            else if (x_pixel < 549) begin //r
                color = 12'hf00;
            end
            else begin //b
                color = 12'h00f; 
            end
        end
        else if (y_pixel < 360) begin
            if (x_pixel < 91) begin //b
                color = 12'h00f;
            end
            else if (x_pixel < 183) begin //bl
                color = 12'h000;
            end
            else if (x_pixel < 274) begin //p
                color = 12'hf0f;
            end
            else if (x_pixel < 365) begin //bl
                color = 12'h000;
            end
            else if (x_pixel < 457) begin //m
                color = 12'h0ff;
            end
            else if (x_pixel < 549) begin //bl
                color = 12'h0;
            end
            else begin //w
                color = 12'hfff;
            end
        end
        else begin
            if (x_pixel < 107) begin //navy
                color = 12'h003;
            end
            else if (x_pixel < 213) begin //w
                color = 12'hfff;
            end
            else if (x_pixel < 320) begin //purple
                color = 12'hc0f;
            end
            else if (x_pixel < 427) begin //bl2
                color = 12'h111;
            end
            else if (x_pixel < 463) begin //bl
                color = 12'h000;
            end
            else if (x_pixel < 498) begin //bl2
                color = 12'h111;
            end
            else if (x_pixel < 533) begin //bl3
                color = 12'h222;
            end
            else begin //bl
                color = 12'h0;
            end
        end
    end
endmodule

///

module VGA_Decoder(
    input  logic        clk,
    input  logic        reset,
    output logic        h_sync,
    output logic        v_sync,
    output logic        DE,
    output logic [9:0]  x_pixel,
    output logic [9:0]  y_pixel
);

    logic pclk;
    logic [9:0] h_counter;
    logic [9:0] v_counter;

    pixel_clk_gen U_Pix_Clk_Gen(   // = 250MHz clk_div
        .clk(clk),
        .reset(reset),
        .pclk(pclk)
);

    pixel_counter U_Pixel_Counter(
        .pclk(pclk),
        .reset(reset),
        .h_counter(h_counter),  //count 800
        .v_counter(v_counter)   //count 525
);

    vga_decoder U_Vga_Decoder(
        .h_counter(h_counter),
        .v_counter(v_counter),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .DE(DE), 
        .x_pix(x_pixel),  //display area -> 640
        .y_pix(y_pixel)   //display area -> 480
);

endmodule

module pixel_clk_gen(   // = 250MHz clk_div
    input logic clk,
    input logic reset,
    output logic pclk
);
    logic [1:0] p_counter;

    always_ff @(posedge clk, posedge reset) begin
        if(reset) begin
            p_counter <= 0;
            pclk   <= 1'b0;
        end else begin
            if(p_counter == 3) begin
                p_counter <= 0;
                pclk      <= 1'b1;
            end else begin
                p_counter <= p_counter + 1;
                pclk      <= 1'b0;
            end
        end
    end
endmodule

module pixel_counter(
    input logic pclk,
    input logic reset,
    output logic [9:0] h_counter,  //count 800
    output logic [9:0] v_counter   //count 525
);

    localparam H_MAX = 800, V_MAX = 525;

    always_ff @(posedge pclk, posedge reset) begin : Horizontal_counter
        if(reset) begin
            h_counter <= 0;
        end else begin
            if(h_counter == H_MAX - 1) begin
                h_counter <= 0;
            end else begin
                h_counter <= h_counter + 1;
            end
        end
    end

    always_ff @(posedge pclk, posedge reset) begin : Vertical_counter
        if(reset) begin
            v_counter <= 0;
        end else begin
            if(h_counter == H_MAX - 1) begin      // 1개의 Horizontal Line이 끝나면
                if(v_counter == V_MAX - 1) begin  // Vertical Line을 동작해라
                    v_counter <= 0;
                end else begin
                    v_counter <= v_counter + 1;
                end
            end else begin
                v_counter <= v_counter;
            end
        end
    end
endmodule

module vga_decoder (
    input logic [9:0] h_counter,
    input logic [9:0] v_counter,
    output logic h_sync,
    output logic v_sync,
    output logic DE, 
    output logic [9:0] x_pix,  //display area -> 640
    output logic [9:0] y_pix   //display area -> 480
);

    localparam H_Visible_area = 640;
    localparam H_Front_porch  = 16;
    localparam H_Sync_pulse   = 96;
    localparam H_Back_porch = 48;
    localparam H_Whole_line = 800;

    localparam V_Visible_area = 480;
    localparam V_Front_porch = 10;
    localparam V_Sync_pulse = 2;
    localparam V_Back_porch = 33;
    localparam V_Whole_frame = 525;

    // h_sync(값이 0)가 발생하는 구간
    assign h_sync = !(h_counter >= (H_Visible_area + H_Front_porch) &&  
                    (h_counter < H_Visible_area + H_Front_porch + H_Sync_pulse));

    // v_sync(값이 0)가 발생하는 구간
    assign v_sync = !(v_counter >= (V_Visible_area + V_Front_porch) &&  
                    (v_counter < V_Visible_area + V_Front_porch + V_Sync_pulse));

    // display area
    assign DE = (h_counter < H_Visible_area) && (v_counter < V_Visible_area);

    assign x_pix = DE ? h_counter : 10'bz;
    assign y_pix = DE ? v_counter : 10'bz;

endmodule