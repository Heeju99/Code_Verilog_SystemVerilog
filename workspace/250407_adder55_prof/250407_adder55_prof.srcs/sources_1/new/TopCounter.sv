`timescale 1ns / 1ps

module TopCounter(
    input logic clk,
    input logic reset,
    output logic [7:0] outPort
    );

    logic SumSrcMuxSel;
    logic iSelMuxSel;
    logic SumEn;
    logic iEn;
    logic adderSrcMuxSel;
    logic outBuf;
    logic iLe10;

    Control_Unit u_Control_Unit(.*);

    Data_Path u_DataPath(.*);
endmodule
