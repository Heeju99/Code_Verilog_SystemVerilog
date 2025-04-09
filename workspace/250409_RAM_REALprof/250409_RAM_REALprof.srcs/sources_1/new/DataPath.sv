`timescale 1ns / 1ps

`include "define.sv"

module DataPath (
    input  logic        clk,
    input  logic        reset,
    //control unit side port
    input  logic [31:0] instrCode,
    output logic [31:0] instrMemAddr,
    input  logic        regFileWe,
    input  logic [ 3:0] aluControl,
    input  logic        aluSrcMuxSel,
    input  logic        RFWDSrcMuxSel,
    output logic [31:0] dataAddr,
    output logic [31:0] dataWData,
    //additional
    input logic  [31:0] dataRData
);
    logic [31:0] aluResult, RFData1, RFData2;
    logic [31:0] PCSrcData, PCOutData;
    logic [31:0] immExt, aluSrcMuxOut;
    //additional
    logic [31:0] RFWDSrcMuxOut;

    assign instrMemAddr = PCOutData; //to ROM
    assign dataAddr = aluResult; // to RAM
    assign dataWData = RFData2; // to RAM



    RegisterFile U_RegFile (
        .clk(clk),
        .we(regFileWe),
        .RAddr1(instrCode[19:15]),
        .RAddr2(instrCode[24:20]),
        .WAddr(instrCode[11:7]),
        .WData(RFWDSrcMuxOut), //change aluResult
        .RData1(RFData1),
        .RData2(RFData2)
    );

    mux_2x1 U_ALUSrcMux(
        .sel(aluSrcMuxSel),
        .x0(RFData2),
        .x1(immExt),
        .y(aluSrcMuxOut)
);

    alu U_ALU (
        .aluControl(aluControl),
        .a(RFData1),
        .b(aluSrcMuxOut),
        .result(aluResult)
    );

    mux_2x1 u_RFWDSrcMux(
        .sel(RFWDSrcMuxSel), //앞단 MUX
        .x0(aluResult), //Ram에서 나오는 Rdata
        .x1(dataRData), // ALU에서 나오는거 
        .y(RFWDSrcMuxOut) //regfile WD로 들어오는것
);

    extend U_extend(
        .instrCode(instrCode),
        .immExt(immExt)
);
    register U_PC (
        .clk(clk),
        .reset(reset),
        .d(PCSrcData),
        .q(PCOutData)
    );

    adder U_PC_Adder (
        .a(32'd4),
        .b(PCOutData),
        .y(PCSrcData)
    );


endmodule

module alu (
    input  logic [ 3:0] aluControl,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] result
);
    always_comb begin
        case (aluControl)
            `ADD:   result = a + b; //ADD
            `SUB:   result = a - b; //SUB
            `SLL:   result = a << b; //SLL
            `SRL:   result = a >> b; //SRL
            `SRA:   result = $signed(a) >>> b[4:0]; //SRA
            `SLT:   result = ($signed(a) < $signed(b)) ? 1 : 0; //SLT
            `SLTU:   result = (a < b) ? 1 : 0; //SLTU
            `XOR:   result = a ^ b; //XOR
            `OR:   result = a | b; //OR
            `AND:   result = a & b; //AND
            default: result = 32'bx;
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
        for (int i=0; i<32; i++) begin
            RegFile[i] = 10 + i;
        end
    end

    always_ff @(posedge clk) begin
        if (we) RegFile[WAddr] <= WData;
    end

    assign RData1 = (RAddr1 != 0) ? RegFile[RAddr1] : 32'b0;
    assign RData2 = (RAddr2 != 0) ? RegFile[RAddr2] : 32'b0;
endmodule

module mux_2x1 (
    input logic sel,
    input logic [31:0] x0,
    input logic [31:0] x1,
    output logic [31:0] y
);
    always_comb begin
        case(sel)
            1'b0 : y = x0;
            1'b1 : y = x1;
            default : y = 32'bx;
        endcase
    end
endmodule

module extend(
    input logic [31:0] instrCode,
    output logic [31:0] immExt
);
    wire [6:0] opcode = instrCode[6:0];

    always_comb begin
        immExt = 32'b0; //change -> 32'bx
        case(opcode)
            `OP_TYPE_R : immExt = 32'bx;
            `OP_TYPE_L : immExt = {{20{instrCode[31]}},instrCode[31:20]}; //32bit 확장을 위함 + (+,-) 나타내기 
            `OP_TYPE_S : immExt = {{20{instrCode[31]}},instrCode[31:25], instrCode[11:7]}; //떨어져 있어도 12개 동일
            //additional
            `OP_TYPE_I : begin
                if(instrCode[14:12] == (3'b001 ||3'b101)) 
                immExt = {{27{instrCode[24]}},instrCode[24:20]};
                else
                immExt = {{20{instrCode[31]}},instrCode[31:20]};
            end
            default: immExt = 32'b0; //change -> 32'bx
        endcase
    end
endmodule
