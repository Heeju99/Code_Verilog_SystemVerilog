`timescale 1ns / 1ps

module DataPath(
    input logic clk,
    input logic reset,
    input logic [31:0] instrCode, //Instruction Memory에서 들어오는 32bit
    output logic [31:0] instrMemAddr, //pc에서 나오는 값
    input logic regfilewe,
    input logic [3:0] aluControl //4bit로 change
    );

    logic [31:0] aluResult, RFData1, RFData2,
                 PCSrcData, PCOutData;

    assign instrMemAddr = PCOutData;

    registerfile u_registerfile(
        .clk(clk),
        .we(regfilewe),
        .rAddr1(instrCode[19:15]), //32bit Instruction Memory[19:15]
        .rAddr2(instrCode[24:20]), //32bit Instruction Memory[24:20]
        .wAddr(instrCode[11:7]),  //32bit Instruction Memory[11:7]
        .wData(aluResult),  //32bit ALU result
        .rData1(RFData1),
        .rData2(RFData2)
);

    alu u_alu(
        .aluControl(aluControl),
        .a(RFData1),  // rData1
        .b(RFData2),  //rData2
        .result(aluResult)
);

    register u_ProgramCounter(
        .clk(clk),
        .reset(reset),
        .d(PCSrcData),
        .q(PCOutData)
);

    adder u_adder(
        .a(32'd4), //4
        .b(PCOutData), //pc값
        .y(PCSrcData)  //pc(d)
);

endmodule

module alu(
    input logic [3:0] aluControl,
    input logic [31:0] a, 
    input logic [31:0] b, 
    output logic [31:0] result
);
    always_comb begin
        case(aluControl)
            4'b0000 : result = a + b; //ADD,0
            4'b0001 : result = a - b; //SUB,1
            4'b0010 : result = a | b; //OR,2
            4'b0011 : result = a & b; //AND,3
            4'b0100 : result = a << b; //SLL,4
            4'b0101 : result = a >> b; //SRL,5
            4'b0110 : result = a >>> b; //SRA,6, MSB extend
            4'b0111 : result = ($signed(a) < $signed(b)) ? 1 : 0; //SLT,7
            4'b1000 : result = ($unsigned(a) < $unsigned(b)) ? 1 : 0; //SLTU,8
            4'b1001 : result = a ^ b; //XOR,9
            default : result = 32'bx;
        endcase
    end
endmodule

module register(
    input logic clk,
    input logic reset,
    input logic [31:0] d,
    output logic [31:0] q
);
    always_ff @(posedge clk, posedge reset) begin
        if(reset) q <= 0;
        else q <= d;
    end
endmodule

module adder(
    input logic [31:0] a,
    input logic [31:0] b,
    output logic [31:0] y
);
    assign y = a + b; 
endmodule

module registerfile(
    input logic clk,
    input logic we,
    input logic [4:0] rAddr1,
    input logic [4:0] rAddr2,
    input logic [4:0] wAddr,
    input logic [31:0] wData,
    output logic [31:0] rData1,
    output logic [31:0] rData2
);
    logic [31:0] regfile[0:2**5-1]; //32bit짜리 공간이 32개 있음

    //임의로 test하기 위해
    initial begin
        for(int i = 0; i < 32; i++) begin
            regfile[i] = 10 + i;
        end
    end
    /////
    always_ff @(posedge clk) begin
        if(we) regfile[wAddr] <= wData;
    end

    assign rData1 = (rAddr1 != 0) ? regfile[rAddr1] : 32'b0;
    assign rData2 = (rAddr2 != 0) ? regfile[rAddr2] : 32'b0;
endmodule