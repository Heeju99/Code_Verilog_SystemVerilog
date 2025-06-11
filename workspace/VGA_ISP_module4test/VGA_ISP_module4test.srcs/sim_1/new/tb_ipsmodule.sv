`timescale 1ns / 1ps

module tb_ispmodule;

    // Inputs
    logic clk;
    logic reset;
    logic [11:0] r_data1;
    logic [11:0] r_data2;

    // Outputs
    logic motion_detected;

    // Instantiate the Unit Under Test (UUT)
    ISP_Module1 uut (
        .clk(clk),
        .reset(reset),
        .r_data1(r_data1),
        .r_data2(r_data2),
        .motion_detected(motion_detected)
    );

    // Clock generation
    always #5 clk = ~clk; // 100MHz clock

    // Task to apply one frame of constant input (no motion)
    task apply_static_frame(input [11:0] pixel_value);
        integer i;
        begin
            for (i = 0; i < 640*480; i = i + 1) begin
                r_data1 = pixel_value;
                r_data2 = pixel_value;
                @(posedge clk);
            end
        end
    endtask

    // Task to apply motion frame (difference between r_data1 and r_data2)
    task apply_motion_frame(input [11:0] val1, input [11:0] val2);
        integer i;
        begin
            for (i = 0; i < 640*480; i = i + 1) begin
                r_data1 = val1;
                r_data2 = val2;
                @(posedge clk);
            end
        end
    endtask

    initial begin
        // Initialize Inputs
        clk = 0;
        reset = 1;
        r_data1 = 12'h000;
        r_data2 = 12'h000;

        // Apply reset
        repeat(5) @(posedge clk);
        reset = 0;

        $display("Apply static frame (no motion)");
        apply_static_frame(12'h0F0); // gray image, no motion
        $display("Motion Detected: %0d", motion_detected);

        $display("Apply motion frame");
        apply_motion_frame(12'h0F0, 12'hF00); // motion (red vs green diff)
        $display("Motion Detected: %0d", motion_detected);

        #1000;
        $finish;
    end

endmodule
