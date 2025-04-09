`timescale 1ns / 1ps

module RV32_Core(
    input logic clk,
    input logic reset,
    input logic [31:0] instrCode,
    output logic [31:0] instrMemAddr
    );

    logic regfilewe;
    logic [3:0] aluControl;

    DataPath u_DataPath(
        .*
    );

    ControlUnit u_ControlUnit(
        .*
    );
endmodule
