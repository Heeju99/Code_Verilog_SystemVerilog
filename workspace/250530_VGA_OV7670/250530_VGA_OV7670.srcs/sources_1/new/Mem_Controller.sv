`timescale 1ns / 1ps

module ov7670_Mem_Controller(
    input  logic         pclk,
    input  logic         reset,
    input  logic         href,
    input  logic         v_sync,
    input  logic  [7:0]  ov7670_data,
    output logic         we,
    output logic [16:0]  wAddr,
    output logic [15:0]  wData
);
    logic [ 9:0] h_counter;  //320 * 2 = 640 pixel
    logic [ 7:0] v_counter;  //240
    logic [15:0] pixel_data;

    assign wAddr = v_counter * 320 + h_counter[9:1]; //shift를 통해 %2를 해줌
    assign wData = pixel_data;

    always_ff @(posedge pclk, posedge reset) begin : Horizon_Sequence
        if(reset) begin
            h_counter <= 0;
            we        <= 0;
        end else begin
            if(href == 1'b0) begin
                h_counter <= 0;
                we        <= 1'b0;
            end else begin
                h_counter <= h_counter + 1;
                if(h_counter[0] == 1'b0) begin //even_data
                    pixel_data[15:8] <= ov7670_data;
                    we               <= 1'b0;
                end else begin //od_data
                    pixel_data[ 7:0] <= ov7670_data;
                    we               <= 1'b1;
                end
            end
        end
    end

    always_ff @(posedge pclk, posedge reset) begin : Vertical_Sequence
        if(reset) begin
            v_counter <= 0;
        end else begin
            if(v_sync) begin
                v_counter <= 0;
            end else begin
                if(h_counter == 639) begin
                    v_counter <= v_counter + 1;
                end
            end
        end
    end
endmodule
