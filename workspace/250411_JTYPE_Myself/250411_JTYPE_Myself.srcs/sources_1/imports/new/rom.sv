`timescale 1ns / 1ps

module rom (
    input  logic [31:0] addr,
    output logic [31:0] data
);
    logic [31:0] rom[0:15];

    initial begin
        //rom[x]=32'b fucn7 _ rs2 _ rs1 _f3 _ rd  _opcode; // R-Type
        //rom[0] = 32'b0000000_00001_00010_000_00100_0110011; // add x4, x2, x1
        //rom[1] = 32'b0100000_00001_00010_000_00101_0110011; // sub x5, x2, x1
        //rom[x]=32'b imm7  _ rs2 _ rs1 _f3 _ imm5_ opcode; // B-Type
        //rom[2] = 32'b0000000_00010_00010_000_01100_1100011; // BEQ x2, x2, (12)/3->3 +2 = 5

        //rom[x]=32'b imm7  _ rs2 _ rs1 _f3 _ imm5_ opcode; // S-Type
        //rom[3] = 32'b0000000_00010_00000_010_01000_0100011; // sw x2, 8(x0); 
        //rom[x]=32'b imm12      _ rs1 _f3 _ rd  _ opcode; // L-Type
        //rom[4] = 32'b000000001000_00000_010_00011_0000011; // lw x3, 8(x0);
        //rom[x]=32'b imm12      _ rs1 _f3 _ rd  _ opcode; // I-Type
        //rom[5] = 32'b000000000001_00000_000_00001_0010011; // addi x1, x0, 1;
        //rom[6] = 32'b000000000010_00001_001_00110_0010011; // slli x6, x1, 2;


        //rom[x]=32'b imm20              _ rd  _ opcode; // LU-Type
        //rom[7] = 32'b00000000000000000001_00111_0110111; // LUI x7, imm1
        //rom[x]=32'b imm20              _ rd  _ opcode; // AU-Type
        //rom[8] = 32'b00000000000000000001_01000_0010111; // AUIPC x8, imm1 
        //rom[x]=32'b imm20              _ rd  _ opcode; // J-Type
        rom[0] = 32'b00000000010000000000_00010_1101111; // JAL rd = x2 , imm4
        //rom[x]=32'b imm12       _ rs1 _000_ rd _ opcode; // JL-Type
        rom[1] = 32'b000000000100_00110_000_00011_1100111; // JALR rd = 3 rs1 = 16, imm4
        
    end
    assign data = rom[addr[31:2]];
endmodule
