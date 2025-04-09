`timescale 1ns / 1ps

module mooremealy(
    input clk,
    input rst_n,
    input x,
    output z
    );
    parameter A = 4'h1;
    parameter B = 4'h2;
    parameter C = 4'h3;
    parameter D = 4'h4;

    reg [3:0] state, next;
    always@(posedge clk, posedge rst_n)
        begin
            if(!rst_n) begin
                state <= A;
            end
            else begin
                state <= next;
            end
        end

    always@(state or x) begin
        case(state)
            A: begin
                if(x == 0) next = A;
                else next = B;
            end
            B: begin
                if(x == 0) next = C;
                else next = B;
            end
            C: begin
                if(x == 0) next = A;
                else next = D;
            end
            D: begin
                if(x == 0) next = A;
                else next = B;
            end
            default:
                next = A;
        endcase
    end
    assign z = (state == D) && (x == 0) ? 1:0;
endmodule
