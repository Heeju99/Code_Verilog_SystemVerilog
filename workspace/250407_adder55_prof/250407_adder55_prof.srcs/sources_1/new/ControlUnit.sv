
//localparam S0 = 0, S1 = 1, S2 = 2, S3 = 3, S4 = 4, S5 = 5;
//typedef enum {S0, S1, S2, S3, S4, S5} state_e;
//state_e state, next;
//logic [2:0] state, next;
`timescale 1ns / 1ps

module Control_Unit (
    input  logic clk,
    input  logic reset,
    output logic SumSrcMuxSel,
    output logic iSelMuxSel,
    output logic SumEn,
    output logic iEn,
    output logic adderSrcMuxSel,
    output logic outBuf,
    input  logic iLe10
);
    //localparam S0 = 0, S1 = 1, S2 = 2, S3 = 3, S4 = 4, S5 = 5;
    typedef enum {S0, S1, S2, S3, S4, S5} state_e;
    state_e state, state_next;
    //logic [2:0] state, state_next;

    always_ff @(posedge clk, posedge reset) begin : state_reg
        if (reset) begin
            state <= S0;
        end else begin
            state <= state_next;
        end
    end

    always_comb begin : state_next_logic
        state_next = state;
        SumSrcMuxSel   = 0;
        iSelMuxSel     = 0;
        SumEn          = 0;
        iEn            = 0;
        adderSrcMuxSel = 0;
        outBuf         = 0;
        case (state)
            S0: begin
                SumSrcMuxSel   = 0;
                iSelMuxSel     = 0;
                SumEn          = 1;
                iEn            = 1;
                adderSrcMuxSel = 1'bx;
                outBuf         = 0;
                state_next     = S1;
            end
            S1: begin
                SumSrcMuxSel   = 1'bx;
                iSelMuxSel     = 1'bx;
                SumEn          = 0;
                iEn            = 0;
                adderSrcMuxSel = 1'bx;
                outBuf         = 0;
                if (iLe10) state_next = S2;
                else state_next = S5;
            end
            S2: begin
                SumSrcMuxSel   = 1;
                iSelMuxSel     = 1'bx;
                SumEn          = 1;
                iEn            = 0;
                adderSrcMuxSel = 0;
                outBuf         = 0;
                state_next     = S3;
            end
            S3: begin
                SumSrcMuxSel   = 1'bx;
                iSelMuxSel     = 1;
                SumEn          = 0;
                iEn            = 1;
                adderSrcMuxSel = 1;
                outBuf         = 0;
                state_next     = S4;
            end
            S4: begin
                SumSrcMuxSel   = 1'bx;
                iSelMuxSel     = 1'bx;
                SumEn          = 0;
                iEn            = 0;
                adderSrcMuxSel = 1'bx;
                outBuf         = 1;
                state_next     = S1;
            end
            S5: begin
                SumSrcMuxSel   = 1'bx;
                iSelMuxSel     = 1'bx;
                SumEn          = 0;
                iEn            = 0;
                adderSrcMuxSel = 1'bx;
                outBuf         = 0;
                state_next     = S5;
            end
        endcase
    end
endmodule
