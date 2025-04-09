`timescale 1ns / 1ps

module ControlUnit(
    input logic [31:0] instrCode,
    output logic regfilewe,
    output logic [3:0] aluControl
    );

    //instrCode를 뜯어어서 R-Type/ Add, Sub, Or, And 위함
    wire [6:0] opcode = instrCode[6:0];
    wire [3:0] operator = {instrCode[30], instrCode[14:12]}; //fuction7[5]+function3

    always_comb begin
        regfilewe = 1'b0;
        case(opcode)
            7'b0110011: regfilewe = 1'b1; //R-Type
        endcase
    end

    always_comb begin
        aluControl = 4'bx; 
        case(opcode)
            7'b0110011: begin //R-Type
            aluControl = 4'bx;
                case(operator)
                    4'b0000 : aluControl = 4'b0000;  //add
                    4'b1000 : aluControl = 4'b0001;  //sub
                    4'b0110 : aluControl = 4'b0010;  //or
                    4'b0111 : aluControl = 4'b0011;  //and
                    4'b0001 : aluControl = 4'b0100;  //SLL
                    4'b0101 : aluControl = 4'b0101;  //SRL
                    4'b1101 : aluControl = 4'b0110;  //SRA, instrcode[30] = 1;
                    4'b0010 : aluControl = 4'b0111;  //SLT
                    4'b0011 : aluControl = 4'b1000;  //SLTU
                    4'b0100 : aluControl = 4'b1001;  //XOR
                endcase
            end
        endcase
    end
endmodule
