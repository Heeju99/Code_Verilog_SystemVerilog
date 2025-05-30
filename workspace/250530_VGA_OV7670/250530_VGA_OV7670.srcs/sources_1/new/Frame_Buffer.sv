`timescale 1ns / 1ps

module Frame_Buffer(
    //write Side
    input  logic         wclk,
    input  logic [16:0]  wAddr,   //76800(320 * 240) 
    input  logic [15:0]  wData,
    input  logic         we,
    //read Side
    input  logic         rclk,
    input  logic         oe,      //output enable
    input  logic [16:0]  rAddr,
    output logic [15:0]  rData
);
    logic [15:0] mem[0:(320 * 240 -1)];

    //write mode
    always_ff @(posedge wclk) begin : write_side
        if(we) begin
            mem[wAddr] <= wData;
        end
    end

    //read mode
    always_ff @(posedge rclk) begin : read_side
        if (oe) begin
            rData = mem[rAddr];
        end
    end
endmodule
