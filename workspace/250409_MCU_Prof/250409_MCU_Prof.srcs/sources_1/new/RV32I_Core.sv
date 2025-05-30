`timescale 1ns / 1ps

module RV32I_Core (
    input logic clk,
    input logic reset,
    input logic [31:0] instrCode,
    output logic [31:0] instrMemAddr,
    output logic        dataWe,
    output logic [31:0] dataAddr,
    output logic [31:0] dataWData,
    //additional
    input logic [31:0] rData
);
    logic       regFileWe;
    logic [3:0] aluControl;
    logic       aluSrcMuxSel;

    ControlUnit U_ControlUnit (.*);
    DataPath U_DataPath (.*);

endmodule
