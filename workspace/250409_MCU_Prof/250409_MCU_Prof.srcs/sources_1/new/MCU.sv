`timescale 1ns / 1ps

module MCU (
    input logic clk,
    input logic reset
);
    logic [31:0] instrCode;
    logic [31:0] instrMemAddr;
    logic        dataWe;
    logic [31:0] dataAddr;
    logic [31:0] dataWdata;

    RV32I_Core U_Core (.*);

    rom U_ROM (
        .addr(instrMemAddr),
        .data(instrCode)
    );

    ram U_RAM(
    .clk(clk),
    .we(dataWe),
    .addr(dataAddr),
    .wData(dataWdata),
    .rData()
    );
endmodule
