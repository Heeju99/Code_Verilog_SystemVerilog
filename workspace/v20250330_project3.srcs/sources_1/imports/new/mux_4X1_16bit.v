`timescale 1ns / 1ps

//sw_mode[3] ==0 HCSR04, ==1 DHT11,  sw_mode[0] ==0 msec_sec, ==1 min_hour
module mux_4X1_16bit(
    input [2:0] sw_mode, 
    input [15:0] sec_msec,
    input [15:0] hour_min,
    input [15:0] distance,
    input [15:0] temp_hum,
    output reg [15:0] data_in_fnd
);
    always @(*) begin
        case (sw_mode)
            3'b000:  data_in_fnd = sec_msec;
            3'b001:  data_in_fnd = hour_min;
            3'b010:  data_in_fnd = sec_msec;
            3'b011:  data_in_fnd = hour_min;
            3'b100:  data_in_fnd = distance;
            3'b101:  data_in_fnd = distance;
            3'b110:  data_in_fnd = temp_hum;
            3'b111:  data_in_fnd = temp_hum;
            default: data_in_fnd = 0;
        endcase
    end
endmodule
