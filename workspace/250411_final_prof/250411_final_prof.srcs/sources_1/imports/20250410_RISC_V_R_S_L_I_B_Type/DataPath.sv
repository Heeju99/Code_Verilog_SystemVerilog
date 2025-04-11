`timescale 1ns / 1ps

`include "defines.sv"

module DataPath (
    input  logic        clk,
    input  logic        reset,
    // control unit side port
    input  logic        regFileWe,
    input  logic [ 3:0] aluControl,
    input  logic        aluSrcMuxSel,
    input  logic [ 2:0] RFWDSrcMuxSel,
    input  logic        branch,
    input  logic        jal,
    input  logic        jalr,
    //caution
    // instr memory side port
    output logic [31:0] instrMemAddr,
    input  logic [31:0] instrCode,
    // data memory side port
    output logic [31:0] dataAddr,
    //output logic [31:0] dataWData,
    //additional
    output logic [31:0] divideWData,
    //
    input  logic [31:0] dataRData
);
    logic [31:0] aluResult, RFData1, RFData2;
    logic [31:0] PCSrcData, PCOutData;
    logic [31:0] immExt, aluSrcMuxOut, RFWDSrcMuxOut;
    logic btaken, PCSrcMuxSel;
    logic [31:0] PC_Imm_AdderResult, PC_4_AdderResult, PCSrcMuxOut, PC_Imm_Adder_SrcMuxOut;
    //additional
    logic [31:0] divideRData, dataWData;
    //
    assign instrMemAddr = PCOutData;
    assign dataAddr     = aluResult;
    assign dataWData    = RFData2;
    assign PCSrcMuxSel = jal | (btaken & branch) ;

    RegisterFile U_RegFile (
        .clk(clk),
        .we(regFileWe),
        .RAddr1(instrCode[19:15]),
        .RAddr2(instrCode[24:20]),
        .WAddr(instrCode[11:7]),
        .WData(RFWDSrcMuxOut),
        .RData1(RFData1),
        .RData2(RFData2)
    );

    mux_2x1 U_ALUSrcMux (
        .sel(aluSrcMuxSel),
        .x0 (RFData2),
        .x1 (immExt),
        .y  (aluSrcMuxOut)
    );

// additional
    divider U_rdatadivider(
        .instrCode(instrCode),
        .dataRData(dataRData),
        .divideRData(divideRData)
);
//additional

    mux_5x1 U_RFWDSrcMux(
        .sel(RFWDSrcMuxSel),
        .x0(aluResult),
        .x1(divideRData), //dataRData
        .x2(immExt), //이미 Extend 모듈에서 12shift해준 상태
        .x3(PC_Imm_AdderResult),
        .x4(PC_4_AdderResult),
        .y(RFWDSrcMuxOut)
);
/*
    mux_2x1 U_RFWDSrcMux (
        .sel(RFWDSrcMuxSel),
        .x0 (aluResult),
        .x1 (dataRData),
        .y  (RFWDSrcMuxOut)
    );
*/
    alu U_ALU (
        .aluControl(aluControl),
        .a(RFData1),
        .b(aluSrcMuxOut),
        .btaken(btaken),
        .result(aluResult)
    );

// additional
    divider U_bitdivider(
        .instrCode(instrCode),
        .dataRData(dataWData),
        .divideRData(divideWData)
);
//additional

    extend U_ImmExtend (
        .instrCode(instrCode),
        .immExt(immExt)
    );

    mux_2x1 U_PC_Imm_Adder_SrcMux (
        .sel(jalr),
        .x0 (PCOutData),
        .x1 (RFData1),
        .y  (PC_Imm_Adder_SrcMuxOut)
    );

    adder U_PC_Imm_Adder (
        .a(immExt),
        .b(PC_Imm_Adder_SrcMuxOut),
        .y(PC_Imm_AdderResult)
    );

    adder U_PC_4_Adder (
        .a(32'd4),
        .b(PCOutData),
        .y(PC_4_AdderResult)
    );


    mux_2x1 U_PCSrcMux (
        .sel(PCSrcMuxSel),
        .x0 (PC_4_AdderResult),
        .x1 (PC_Imm_AdderResult),
        .y  (PCSrcMuxOut)
    );

    register U_PC (
        .clk(clk),
        .reset(reset),
        .d(PCSrcMuxOut),
        .q(PCOutData)
    );

endmodule

module divider(
    input  logic [31:0] instrCode,
    input  logic [31:0] dataRData,
    output logic [31:0] divideRData
);
    always_comb begin
        divideRData = dataRData;
        if(instrCode[6:0] == 7'b0000011 || instrCode[6:0] == 7'b0100011) begin
            case(instrCode[14:12])         
                3'b000 : divideRData = {{24{dataRData[7]}} ,dataRData[7:0]};
                3'b001 : divideRData = {{16{dataRData[15]}} ,dataRData[15:0]};
                3'b100 : divideRData = {24'b0, dataRData[7:0]};
                3'b101 : divideRData = {16'b0, dataRData[15:0]};
                default : divideRData = dataRData;
        endcase
        end
    end
endmodule


module alu (
    input  logic [ 3:0] aluControl,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic        btaken,
    output logic [31:0] result
);
    always_comb begin
        case (aluControl)
            `ADD:    result = a + b;
            `SUB:    result = a - b;
            `SLL:    result = a << b;
            `SRL:    result = a >> b;
            `SRA:    result = $signed(a) >>> b[4:0];
            `SLT:    result = ($signed(a) < $signed(b)) ? 1 : 0;
            `SLTU:   result = (a < b) ? 1 : 0;
            `XOR:    result = a ^ b;
            `OR:     result = a | b;
            `AND:    result = a & b;
            default: result = 32'bx;
        endcase
    end

    always_comb begin : branch_processor
        btaken = 1'b0;
        case (aluControl[2:0])
            `BEQ:    btaken = (a == b);
            `BNE:    btaken = (a != b);
            `BLT:    btaken = ($signed(a) < $signed(b));
            `BGE:    btaken = ($signed(a) >= $signed(b));
            `BLTU:   btaken = (a < b);
            `BGEU:   btaken = (a >= b);
            default: btaken = 1'b0;
        endcase
    end
endmodule

module register (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] d,
    output logic [31:0] q
);
    always_ff @(posedge clk, posedge reset) begin
        if (reset) q <= 0;
        else q <= d;
    end
endmodule

module adder (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] y
);
    assign y = a + b;
endmodule

module RegisterFile (
    input  logic        clk,
    input  logic        we,
    input  logic [ 4:0] RAddr1,
    input  logic [ 4:0] RAddr2,
    input  logic [ 4:0] WAddr,
    input  logic [31:0] WData,
    output logic [31:0] RData1,
    output logic [31:0] RData2
);
    logic [31:0] RegFile[0:2**5-1];
    initial begin
        for (int i = 0; i < 31; i++) begin
            RegFile[i] = 10 + i;
        end
    end
    assign RegFile[31] = 32'b1100_0110_0011_1100_0110_0011_1100_0110;

    always_ff @(posedge clk) begin
        if (we) RegFile[WAddr] <= WData;
    end

    assign RData1 = (RAddr1 != 0) ? RegFile[RAddr1] : 32'b0;
    assign RData2 = (RAddr2 != 0) ? RegFile[RAddr2] : 32'b0;
endmodule

module mux_2x1 (
    input  logic        sel,
    input  logic [31:0] x0,
    input  logic [31:0] x1,
    output logic [31:0] y
);
    always_comb begin
        case (sel)
            1'b0:    y = x0;
            1'b1:    y = x1;
            default: y = 32'bx;
        endcase
    end
endmodule

module mux_5x1 (
    input  logic [ 2:0] sel,
    input  logic [31:0] x0,
    input  logic [31:0] x1,
    input  logic [31:0] x2,
    input  logic [31:0] x3,
    input  logic [31:0] x4,
    output logic [31:0] y
);
    always_comb begin
        y = 32'bx;
        case (sel)
            3'b000:    y = x0;
            3'b001:    y = x1;
            3'b010:    y = x2;
            3'b011:    y = x3;
            3'b100:    y = x4;
        endcase
    end
endmodule


module extend (
    input  logic [31:0] instrCode,
    output logic [31:0] immExt
);
    wire [6:0] opcode = instrCode[6:0];
    wire [2:0] func3 = instrCode[14:12];

    always_comb begin
        immExt = 32'bx;
        case (opcode)
            `OP_TYPE_R: immExt = 32'bx;
            `OP_TYPE_L: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
            `OP_TYPE_S:
            immExt = {{20{instrCode[31]}}, instrCode[31:25], instrCode[11:7]};
            `OP_TYPE_I: begin
                case (func3)
                    3'b001:  immExt = {27'b0, instrCode[24:20]};
                    3'b101:  immExt = {27'b0, instrCode[24:20]};
                    3'b011:  immExt = {20'b0, instrCode[31:20]};
                    default: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
                endcase
            end
            `OP_TYPE_B:
            immExt = {
                {20{instrCode[31]}},
                instrCode[7],
                instrCode[30:25],
                instrCode[11:8],
                1'b0
            };

            `OP_TYPE_LU: immExt = {instrCode[31:12], 12'b0}; //뒤에 0을 붙혀 shift 수행
            `OP_TYPE_AU: immExt = {instrCode[31:12], 12'b0}; //뒤에 0을 붙혀 shift 수행

            `OP_TYPE_J: 
            immExt = {
                {12{instrCode[31]}},
                instrCode[19:12],
                instrCode[20],
                instrCode[30:21],
                1'b0
            };
            `OP_TYPE_JL: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
            default: immExt = 32'bx;
        endcase
    end
endmodule
