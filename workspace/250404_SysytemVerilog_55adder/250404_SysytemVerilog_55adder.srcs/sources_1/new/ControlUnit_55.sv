`timescale 1ns / 1ps

module ControlUnit_55(
    input logic clk,
    input logic reset,
    input logic Alt10,
    output logic ASrcMuxSel,
    output logic AEn,
    output logic OutBuf
    );

 
    localparam S0 = 0, S1 = 1, S2 = 2, S3 = 3, S4 = 4;
    logic [2:0] state, next;

    // 상태 전이
    always_ff @(posedge clk, posedge reset) begin
        if (reset)
            state <= S0;
        else
            state <= next;
    end

    always_comb begin
        ASrcMuxSel = 0;
        AEn = 0;
        OutBuf = 0;
        next = state;

        case(state)
            S0: begin 
                ASrcMuxSel = 0;
                AEn = 1;
                OutBuf = 0;
                next = S1;
            end
            S1: begin
                ASrcMuxSel = 0;
                AEn = 0;
                OutBuf = 1;
                if (Alt10)
                    next = S2;
                else
                    next = S4;
            end
            S2: begin
                ASrcMuxSel = 0;
                AEn = 0; 
                OutBuf = 0;
                next = S3;
            end
            S3: begin 
                ASrcMuxSel = 1;
                AEn = 1;
                OutBuf = 0;
                next = S1;
            end
            S4: begin
                ASrcMuxSel = 0; 
                AEn = 0;
                OutBuf = 0;   
                next = S4;
            end
        endcase
    end
endmodule
