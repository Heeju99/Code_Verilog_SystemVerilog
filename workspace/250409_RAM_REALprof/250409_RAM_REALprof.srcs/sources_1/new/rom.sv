`timescale 1ns / 1ps

module rom (
    input  logic [31:0] addr,
    output logic [31:0] data
);
    logic [31:0] rom[0:15];

    initial begin
        //rom[x]=32'b fucn7 _ rs2 _ rs1 _f3 _ rd  _opcode; // R-Type
        rom[0] = 32'b0000000_00001_00010_000_00100_0110011; // add x4, x2, x1
        rom[1] = 32'b0100000_00001_00010_000_00101_0110011; // sub x5, x2, x1
        //rom[x]=32'b imm7 _ rs2 _ rs1 _ f3 _ imm5 _opcode // S-Type
        rom[2] = 32'b0000000_00010_00000_010_01000_0100011; // sw x2, 8(x0);
        //rom[x]=32'b imm12      _ rs1 _ f3 _ rd _opcode // L-Type
        rom[3] = 32'b000000001000_00000_010_00011_0000011; // lw x3 8(x0)

        //rom[x]=32'b imm12      _ rs1 _ f3 _ rd _opcode // I-Type ADDI
        rom[4] = 32'b000000001000_00010_000_10000_0010011; // Addi rd = x16, rs1 = 2, 8(x0) 
        //rom[x]=32'b fucn7 _ shamt _ rs1 _f3 _ rd  _opcode; // I-Type SLLI
        rom[5] = 32'b0000000_00101_00010_001_10001_0010011; // SLLI rx = x17, rs1 = 2, shamt = 10101
        rom[6] = 32'b0100000_00001_00000_000_00111_0110011; // sub x7, x0, x1
        //rom[x]=32'b fucn7 _ shamt _ rs1 _f3 _ rd  _opcode; // I-Type SRAI
        rom[7] = 32'b0100000_00101_00111_101_10010_0010011; // SRAI rx = x18, rs1 = 7, shamt = 10101  
    end
    assign data = rom[addr[31:2]];
endmodule
