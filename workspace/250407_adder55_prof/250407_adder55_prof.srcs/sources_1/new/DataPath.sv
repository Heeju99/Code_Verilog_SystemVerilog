`timescale 1ns / 1ps

module Data_Path (
    input  logic       clk,
    input  logic       reset,
    input  logic       SumSrcMuxSel,
    input  logic       iSelMuxSel,
    input  logic       SumEn,
    input  logic       iEn,
    input  logic       adderSrcMuxSel,
    input  logic       outBuf,
    output logic       iLe10,
    output logic [7:0] outPort
);
    logic [7:0] adderResult, SumSrcMuxData, iSrcMuxData, SumRegData;
    logic [7:0] iRegData, adderSrcMuxData;

    mux_2x1 U_SumSrcMux (
        .sel(SumSrcMuxSel),
        .x0 (0),
        .x1 (adderResult),
        .y  (SumSrcMuxData)
    );

    mux_2x1 U_iSrcMux (
        .sel(iSelMuxSel),
        .x0 (0),
        .x1 (adderResult),
        .y  (iSrcMuxData)
    );

    register U_SumReg (
        .clk(clk),
        .reset(reset),
        .en(SumEn),
        .d(SumSrcMuxData),
        .q(SumRegData)
    );

    register U_iReg (
        .clk(clk),
        .reset(reset),
        .en(iEn),
        .d(iSrcMuxData),
        .q(iRegData)
    );

    mux_2x1 U_adderSrcMux (
        .sel(adderSrcMuxSel),
        .x0 (SumRegData),
        .x1 (1),
        .y  (adderSrcMuxData)
    );
    
    comparator U_Comp_Le(
        .a(iRegData),
        .b(10),
        .le(iLe10)
    );

    adder U_adder(
        .a(adderSrcMuxData),
        .b(iRegData),
        .sum(adderResult)
    );

    //assign outPort = outBuf ? SumRegData : 8'bz;  // high 임피던스 나가는게 표준
    register U_outBufReg (
        .clk(clk),
        .reset(reset),
        .en(outBuf),
        .d(SumRegData),
        .q(outPort)
    );
endmodule

module mux_2x1 (
    input  logic       sel,
    input  logic [7:0] x0,
    input  logic [7:0] x1,
    output logic [7:0] y
);
    always_comb begin : mux
        y = 8'b0;
        case (sel)
            0: y = x0;
            1: y = x1;
        endcase
    end
endmodule

module register (
    input  logic       clk,
    input  logic       reset,
    input  logic       en,
    input  logic [7:0] d,
    output logic [7:0] q
);
    always_ff @(posedge clk, posedge reset) begin : register
        if (reset) begin
            q <= 0;
        end else begin
            if (en) q <= d;
        end
    end
endmodule

module comparator (
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic       le
);
    assign le = (a <= b);
endmodule

module adder (
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [7:0] sum
);
    assign sum = a + b;
endmodule

