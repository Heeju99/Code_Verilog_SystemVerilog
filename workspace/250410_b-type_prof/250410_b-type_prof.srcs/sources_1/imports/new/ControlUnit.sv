`timescale 1ns / 1ps

`include "define.sv"

module ControlUnit (
    input  logic [31:0] instrCode,
    output logic        regFileWe,
    output logic [ 3:0] aluControl,
    output logic        aluSrcMuxSel,
    output logic        dataWe,
    output logic        LUIMuxSel, //LUI를 위한 MUX
    output logic        branch,  //btype을 위한 비교기
    output logic [ 1:0] RFWDSrcMuxSel
);
    wire [6:0] opcode = instrCode[6:0];
    wire [3:0] operators = {
        instrCode[30], instrCode[14:12]
    };  // {func7[5], func3}

    logic [6:0] signals;
    assign {regFileWe, aluSrcMuxSel, dataWe, RFWDSrcMuxSel, branch, LUIMuxSel} = signals;

    always_comb begin
        signals = 7'b0;
        case (opcode)
            // {regFileWe, aluSrcMuxSel, dataWe, RFWDSrcMuxSel, branch, LUIMuxSel} = signals
            `OP_TYPE_R: signals =  7'b1_0_0_00_0_0;
            `OP_TYPE_S: signals =  7'b0_1_1_00_0_0;
            `OP_TYPE_L: signals =  7'b1_1_0_01_0_0;
            `OP_TYPE_I: signals =  7'b1_1_0_00_0_0;
            `OP_TYPE_B: signals =  7'b0_0_0_00_1_0;
            `OP_TYPE_LU: signals = 7'b1_0_0_10_0_1; //RFWDSrcMuxSel : 10 -> imm < 12 
            `OP_TYPE_AU: signals = 7'b1_0_0_11_0_1; //RFWDSrcMuxSel : 11 -> pc + imm < 12
        endcase
    end

    always_comb begin
        aluControl = 4'bx;
        case (opcode)
            `OP_TYPE_R: aluControl = operators;  // {func7[5], func3}begin
            `OP_TYPE_S: aluControl = `ADD;
            `OP_TYPE_L: aluControl = `ADD;
            `OP_TYPE_I: begin
                if (operators == 4'b1101) aluControl = operators; // {1'b1, func3}
                else aluControl = {1'b0, operators[2:0]};  // {1'b0, func3}
            end
            `OP_TYPE_B : aluControl = operators;
            `OP_TYPE_LU: aluControl = 4'bx;
            `OP_TYPE_AU: aluControl = 4'bx;
        endcase
    end
endmodule
