`timescale 1ns / 1ps

module led_on_off (
    input [2:0] sw_mode,
    output reg [4:0] led
);

    always @(*) begin
        if (sw_mode == 3'b000) begin
            led = 5'b00001;
        end else if (sw_mode == 3'b001) begin
            led = 5'b00010;
        end else if (sw_mode == 3'b010) begin
            led = 5'b00100;
        end else if (sw_mode == 3'b011) begin
            led = 5'b01000;
        end else begin
            led = 5'b10000;
        end
    end
endmodule