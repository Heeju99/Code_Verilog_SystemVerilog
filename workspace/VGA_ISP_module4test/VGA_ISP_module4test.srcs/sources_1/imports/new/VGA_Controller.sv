`timescale 1ns / 1ps

module VGA_Controller (
    input  logic       clk,
    input  logic       reset,
    // output logic       rclk,
    output logic       h_sync,
    output logic       v_sync,
    output logic [9:0] x_pixel,
    output logic [9:0] y_pixel,
    output logic       DE,
    output logic       DE1,
    output logic       DE2
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
        .DE(DE),
        .DE1(DE1),
        .DE2(DE2)
    );

endmodule

module pixel_clk_gen (
    input  logic clk,
    input  logic reset,
    output logic pclk
);
    logic [1:0] clk_div;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            clk_div <= 2'd0;
            pclk <= 1'b0;
        end else begin
            clk_div <= clk_div + 1;

            if (clk_div == 2'd3) begin
                clk_div <= 2'd0;   
                pclk <= ~pclk;      
            end
        end
    end
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
    output       DE,
    output       DE1,
    output       DE2
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
    assign DE1 = (h_counter < 320) && (v_counter < 480);
    assign DE2 = (h_counter > 320) && (h_counter < 640) && (v_counter < 480);
    assign x_pixel = h_counter;
    assign y_pixel = v_counter;

endmodule
