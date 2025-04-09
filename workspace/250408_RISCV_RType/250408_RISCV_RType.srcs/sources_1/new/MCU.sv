`timescale 1ns / 1ps

module MCU(
    input logic clk,
    input logic reset
    );

    logic [31:0] instrCode;
    logic [31:0] instrMemaddr;

    RV32_Core u_RV32_Core(
        .clk(clk),
        .reset(reset),
        .instrCode(instrCode),
        .instrMemAddr(instrMemaddr)
    );

    rom u_rom(
        .addr(instrMemaddr),
        .data(instrCode)
    );
endmodule
