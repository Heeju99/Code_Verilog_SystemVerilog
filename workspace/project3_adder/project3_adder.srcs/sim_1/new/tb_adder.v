`timescale 1ns / 1ps

module adder_4bit_tb;

    reg [3:0] a, b;
    wire [3:0] s;
    wire cout;
    
    adder_4bit uut (
        .a(a),
        .b(b),
        .s(s), 
        .cout(cout)
    );
    
    initial
      begin
        #10 a = 4'b0000; b = 4'b0001; //cin = 0;
        #10 a = 4'b0001; b = 4'b0101; //cin = 0;
        #10 a = 4'b0010; b = 4'b0011; //cin = 1;
        #10 a = 4'b1000; b = 4'b0001; //cin = 0;
        #10 a = 4'b1000; b = 4'b1001; //cin = 1;   
      end
endmodule
