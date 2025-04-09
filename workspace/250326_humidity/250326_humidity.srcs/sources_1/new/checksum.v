`timescale 1ns / 1ps
module checksum(
    input [39:0] data,
    output reg led
    );

    wire [7:0] humid_int, humid_flt,temp_int, temp_flt, total;

    assign humid_int = data[39:32];
    assign humid_flt = data[31:24];
    assign temp_int = data[23:16];
    assign temp_flt = data[15:8];
    assign total = humid_int + humid_flt + temp_int + temp_flt;

    always@(*) begin
        if(total == data[7:0]) begin
            led = 1'b1;
        end else begin
            led = 1'b0;
        end
    end
endmodule
