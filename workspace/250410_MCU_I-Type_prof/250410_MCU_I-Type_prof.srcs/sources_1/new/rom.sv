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
        //rom[x]=32'b imm7  _ rs2 _ rs1 _f3 _ imm5_ opcode; // S-Type
        rom[2] = 32'b0000000_00010_00000_010_01000_0100011; // sw x2, 8(x0);
        //rom[x]=32'b imm12      _ rs1 _f3 _ rd  _ opcode; // L-Type
        rom[3] = 32'b000000001000_00000_010_00011_0000011; // lw x3, 8(x0);
        //rom[x]=32'b imm12      _ rs1 _f3 _ rd  _ opcode; // I-Type
        rom[4] = 32'b000000001000_00010_000_00110_0010011; // ADDI x6, x2, 8(x0);
        //rom[x]=32'b imm7 _ rs2 _ rs1 _f3 _ imm5 _ opcode; // B-Type
        rom[5] = 32'b0000000_00010_00010_000_01000_1100011; // BEQ x2, x2, imm = 8  ->8
        //rom[x]=32'b imm7 _ rs2 _ rs1 _f3 _ imm5 _ opcode; // B-Type
        //건너뜀
        rom[6] = 32'b0000000_00010_00010_001_01000_1100011; // BNE x2, x2, imm = 8  ->4
        //rom[x]=32'b imm7 _ rs2 _ rs1 _f3 _ imm5 _ opcode; // B-Type
        rom[7] = 32'b0000000_00011_00010_100_01000_1100011; // BLT x2, x3, imm = 8
        //rom[x]=32'b imm7 _ rs2 _ rs1 _f3 _ imm5 _ opcode; // B-Type
        rom[8] = 32'b0000000_01001_01000_110_01100_1100011; // BLTU x16, x17, imm = 12 ->12
        //rom[x]=32'b imm7 _ rs2 _ rs1 _f3 _ imm5 _ opcode; // B-Type
        rom[11] = 32'b0000000_00111_01000_101_01000_1100011; // BGE x8, x7, imm = 8 ->8
        //rom[x]=32'b imm7 _ rs2 _ rs1 _f3 _ imm5 _ opcode; // B-Type
        //rom[10] = 32'b0000000_01000_01001_111_01000_1100011; // BGEU x17, x16, imm = 8 ->8
        //rom[x]=32'b imm7 _ rs2 _ rs1 _f3 _ imm5 _ opcode; // B-Type
        //rom[10] = 32'b0000000_01001_01000_111_01100_1100011; // BGEU x16, x17, imm = 12 ->12
    end
    assign data = rom[addr[31:2]];
endmodule
