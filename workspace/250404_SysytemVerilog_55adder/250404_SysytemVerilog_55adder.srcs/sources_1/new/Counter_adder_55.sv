`timescale 1ns / 1ps

module Counter_adder_55(
    input logic clk,
    input logic reset,
    output logic [7:0] OutPort
    );

    wire w_Alt10, w_ASrcMuxSel, w_AEn, w_OutBuf;

    ControlUnit_55 u_controlunit(
    .clk(clk),
    .reset(reset),
    .Alt10(w_Alt10),
    .ASrcMuxSel(w_ASrcMuxSel),
    .AEn(w_AEn),
    .OutBuf(w_OutBuf)
    );

    DataPath_55 u_DataPath(
    .clk(clk),
    .reset(reset),
    .Alt10(w_Alt10),
    .ASrcMuxSel(w_ASrcMuxSel),
    .AEn(w_AEn),
    .OutBuf(w_OutBuf),
    .OutPort(OutPort)
    );
endmodule