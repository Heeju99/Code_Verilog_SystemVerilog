`timescale 1ns / 1ps

`include "define.sv"

module ControlUnit (
    input  logic [31:0] instrCode,
    output logic        regFileWe,
    output logic [ 3:0] aluControl,
    output logic        aluSrcMuxSel,
    output logic        dataWe
);
    wire [6:0] opcode = instrCode[6:0];
    wire [3:0] operators = {instrCode[30], instrCode[14:12]};  // {func7[5], func3}

    logic [2:0] signals;
    assign {regFileWe, aluSrcMuxSel, dataWe} = signals;

    always_comb begin
        signals = 3'b0;
        case (opcode)
            `OP_TYPE_R: signals = 3'b1_0_0;  // R-Type
            `OP_TYPE_S: begin
                signals = 3'b0_1_1;
                //regFileWe       = 1'b0; // S-Type, regfile에 값을 안쓰니깐
                //aluSrcMuxSel    = 1'b1; //immExt를 받아오기 위해
                //dataWe          = 1'b1; //RAM에 저장하기 위해
            end
        endcase
    end

    //ALU CONTROL Signal
    always_comb begin
        aluControl = 4'bx;
        case(opcode)
            `OP_TYPE_R : aluControl = operators; //{func7[5], func3}
            `OP_TYPE_S : aluControl = `ADD; // S Type에서는 더하기만 함
        endcase
    end
endmodule