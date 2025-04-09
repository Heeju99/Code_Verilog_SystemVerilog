`timescale 1ns / 1ps

module machine(
    input clk,
    input reset,
    input i_bit,
    output reg o_bit
    );

    parameter START = 3'b000, rd0_once = 3'b001, rd1_once = 3'b010, rd0_twice = 3'b011, rd1_twice = 3'b100;
    reg [2:0] state, next;

    always@(posedge clk, posedge reset) begin
        if(reset) begin
            state <= START;
        end
        else begin
            state <= next;
        end
    end

    always@(*)begin
        next = state;
            case(state)
                START: if(i_bit == 0) begin
                        next = rd0_once;
                        o_bit = 1'b0;
                    end
                    else if(i_bit == 1) begin
                        next = rd1_once;
                        o_bit = 1'b0;
                    end
                    else begin
                        next = state;
                    end
                rd0_once: if(i_bit == 0) begin
                        next = rd0_twice;
                        o_bit = 1'b1;
                    end
                    else if(i_bit == 1) begin
                        next = rd1_once;
                        o_bit = 1'b0;
                    end
                    else begin
                        next = state;
                    end
                rd1_once: if(i_bit == 0) begin
                        next = rd0_once;
                        o_bit = 1'b0;
                    end
                    else if(i_bit == 1) begin
                        next = rd1_twice;
                        o_bit = 1'b1;
                    end
                    else begin
                        next = state;
                    end
                rd0_twice: if(i_bit == 1) begin
                        next = rd1_once;
                        o_bit = 1'b0;
                    end
                    else begin
                        next = state;
                        o_bit = 1'b1;
                    end
                rd1_twice: if(i_bit == 0) begin
                        next = rd0_once;
                        o_bit = 1'b0;
                    end
                    else begin
                        next = state;
                        o_bit = 1'b1;
                    end
                default : begin
                    next = state;
                end   
            endcase
    end 
endmodule
