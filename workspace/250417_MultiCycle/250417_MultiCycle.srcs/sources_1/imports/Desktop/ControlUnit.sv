`timescale 1ns / 1ps

`include "defines.sv"

module ControlUnit (
    input clk,
    input reset,
    input  logic [31:0] instrCode,
    output logic        regFileWe,
    output logic [ 3:0] aluControl,
    output logic        aluSrcMuxSel,
    output logic        dataWe,
    output logic [ 2:0] RFWDSrcMuxSel,
    output logic        branch,
    output logic        jal,
    output logic        jalr,
    //additional
    input logic        PC_en
);
    wire [6:0] opcode = instrCode[6:0];
    wire [3:0] operators = {
        instrCode[30], instrCode[14:12]
    };  // {func7[5], func3}

    logic [9:0] signals;
    assign {regFileWe, aluSrcMuxSel, dataWe, RFWDSrcMuxSel, branch, jal, jalr} = signals;

    always_comb begin
        signals = 9'b0;
            case (opcode)
                // {regFileWe, aluSrcMuxSel, dataWe, RFWDSrcMuxSel(3), branch, jal, jalr} = signals
                `OP_TYPE_R:  signals = 9'b1_0_0_000_0_0_0;
                `OP_TYPE_S:  signals = 9'b0_1_1_000_0_0_0;
                `OP_TYPE_L:  signals = 9'b1_1_0_001_0_0_0;
                `OP_TYPE_I:  signals = 9'b1_1_0_000_0_0_0;
                `OP_TYPE_B:  signals = 9'b0_0_0_000_1_0_0;
                `OP_TYPE_LU: signals = 9'b1_0_0_010_0_0_0;
                `OP_TYPE_AU: signals = 9'b1_0_0_011_0_0_0;
                `OP_TYPE_J:  signals = 9'b1_0_0_100_0_1_0;
                `OP_TYPE_JL: signals = 9'b1_0_0_100_0_1_1;
            endcase
    end

    always_comb begin
        aluControl = 4'bx;
            case (opcode)
                `OP_TYPE_S:  aluControl = `ADD;
                `OP_TYPE_L:  aluControl = `ADD;
                `OP_TYPE_JL: aluControl = `ADD;  // {func7[5], func3}
                `OP_TYPE_I: begin
                    if (operators == 4'b1101)
                        aluControl = operators;  // {1'b1, func3}
                    else aluControl = {1'b0, operators[2:0]};  // {1'b0, func3}
                end
                default : aluControl = operators;  // {func7[5], func3}
                // `OP_TYPE_R:  aluControl = operators;  // {func7[5], func3}
                // `OP_TYPE_B:  aluControl = operators;  // {func7[5], func3}
                // `OP_TYPE_LU: aluControl = operators;  // {func7[5], func3}
                // `OP_TYPE_AU: aluControl = operators;  // {func7[5], func3}
                // `OP_TYPE_J:  aluControl = operators;  // {func7[5], func3}
            endcase
    end


//additional

    parameter FETCH = 0, DECODE = 1, R_TYPE_EXE = 2, L_TYPE_EXE = 3, I_TYPE_EXE = 4,
              S_TYPE_EXE = 5, B_TYPE_EXE = 6, S_MEMACC =7, L_MEMACC = 8, WRITEBACK = 9;
    logic [4:0] state, next;
    logic PC_en_reg, PC_en_next;

    always_ff@(posedge clk, posedge reset) begin
        if(reset) begin
            state           <= 0;
            PC_en_reg       <= 0;
        end else begin
            state           <= next;
            PC_en_reg       <= PC_en_next;
        end
    end

    always_ff @(posedge clk, posedge reset) begin
        PC_en_next = PC_en_reg;
        next = state;
        case(state)
            FETCH: begin
                PC_en_next = 1;
                if(PC_en) begin
                    next = DECODE;
                end
            end
            DECODE: begin
                PC_en_next = 0;
                if(instrCode[6:0] == 7'b0110011) begin //R-Type
                    next = R_TYPE_EXE;
                end else if(instrCode[6:0] == 7'b0010011)begin //L-Type
                    next = L_TYPE_EXE;
                end else if(instrCode[6:0] == 7'b0000011)begin //I-Type
                    next = I_TYPE_EXE;
                end else if(instrCode[6:0] == 7'b0100011)begin //S-Type
                    next = S_TYPE_EXE;
                end else if(instrCode[6:0] == 7'b1100011)begin //B-Type
                    next = B_TYPE_EXE;
                end
            end
            R_TYPE_EXE: begin
                next = FETCH;
            end
            L_TYPE_EXE: begin 
                next = L_MEMACC;
            end
            I_TYPE_EXE: begin
                next = FETCH;
            end
            S_TYPE_EXE: begin
                next = S_MEMACC;
            end
            B_TYPE_EXE: begin
                next = FETCH;
            end
            L_MEMACC: begin
                next = WRITEBACK;
            end
            S_MEMACC: begin
                next = FETCH;
            end
            WRITEBACK: begin
                next = FETCH;
            end  
        endcase 
    end
endmodule
