module motion (
    input logic clk,
    input logic reset,
    input logic DE,
    input logic [11:0] data1,
    input logic [11:0] data2,
    output logic motion_detected
);

    VGA_Controller U_VGA_Controller(
        .clk(clk),
        .reset(reset),
        .h_sync(),
        .v_sync(v_sync),
        .x_pixel(),
        .y_pixel(),
        .DE(DE)
);

    Motion_Detector U_Motion_Detector(
        .clk(clk),
        .reset(reset),
        .DE(DE),
        .curr_pixel(data1),
        .prev_pixel(data2),  
        .motion_detected(motion_detected),
        .motion_pixel_out(),
        .v_sync(v_sync)
);

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
    
    localparam int MOTION_LIMIT = 100;//640 * 480 * 3 / 100


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
                    else begin
                        motion_detected <= 0;
                    end
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
