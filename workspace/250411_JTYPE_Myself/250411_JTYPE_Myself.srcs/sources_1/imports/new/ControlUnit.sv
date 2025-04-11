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
    output logic [ 2:0] RFWDSrcMuxSel,
    //additional
    output logic PCAdder_4_MUX_Sel,
    output logic FinalMuxSel
    //
);
    wire [6:0] opcode = instrCode[6:0];
    wire [3:0] operators = {
        instrCode[30], instrCode[14:12]
    };  // {func7[5], func3}

    logic [9:0] signals;
    assign {regFileWe, aluSrcMuxSel, dataWe, RFWDSrcMuxSel,
             branch, LUIMuxSel, PCAdder_4_MUX_Sel, FinalMuxSel} = signals;

    always_comb begin
        signals = 10'b0;
        case (opcode)
            // {regFileWe, aluSrcMuxSel, dataWe, RFWDSrcMuxSel,
            //  branch, LUIMuxSel , PCAdder_4_MUX_Sel, FinalMuxSel} = signals
            `OP_TYPE_R: signals =  10'b1_0_0_000_0_0_0_0;
            `OP_TYPE_S: signals =  10'b0_1_1_000_0_0_0_0;
            `OP_TYPE_L: signals =  10'b1_1_0_001_0_0_0_0;
            `OP_TYPE_I: signals =  10'b1_1_0_000_0_0_0_0;
            `OP_TYPE_B: signals =  10'b0_0_0_000_1_0_0_0;
            `OP_TYPE_LU: signals = 10'b1_0_0_010_0_1_0_0; //RFWDSrcMuxSel : 10 -> imm < 12 
            `OP_TYPE_AU: signals = 10'b1_0_0_011_0_1_0_0; //RFWDSrcMuxSel : 11 -> pc + imm < 12
            //additional
            `OP_TYPE_J: signals =  10'b1_0_0_100_0_0_1_0; 
            `OP_TYPE_JL: signals = 10'b1_1_0_100_0_0_1_1; 
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
            `OP_TYPE_B :  aluControl = operators;
            `OP_TYPE_LU:  aluControl = 4'bx;
            `OP_TYPE_AU:  aluControl = 4'bx;
            ////additional
            `OP_TYPE_J :  aluControl = 4'bx;
            `OP_TYPE_JL : aluControl = `ADD;
            ////
        endcase
    end
endmodule
