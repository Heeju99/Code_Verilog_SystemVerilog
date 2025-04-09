`timescale 1ns / 1ps

module counter_9( 
    input logic clk,
    input logic reset,
    output logic [7:0] OutPort
    );

    wire w_Alt10, w_ASrcMuxSel, w_AEn, w_OutBuf;
    wire [7:0] w_OutPort;

    assign OutPort = w_OutPort;

    controlunit u_controlunit(
    .clk(clk),
    .reset(reset),
    .Alt10(w_Alt10),
    .ASrcMuxSel(w_ASrcMuxSel),
    .AEn(w_AEn),
    .OutBuf(w_OutBuf)
    );

    DataPath u_DataPath(
    .clk(clk),
    .reset(reset),
    .Alt10(w_Alt10),
    .ASrcMuxSel(w_ASrcMuxSel),
    .AEn(w_AEn),
    .OutBuf(w_OutBuf),
    .OutPort(w_OutPort)
    );
endmodule
