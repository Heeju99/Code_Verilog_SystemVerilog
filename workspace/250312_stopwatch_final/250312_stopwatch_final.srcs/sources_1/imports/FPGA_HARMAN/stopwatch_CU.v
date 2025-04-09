`timescale 1ns / 1ps

module stopwatch_CU(
    input clk,
    input reset,
    input i_btn_up,
    input i_btn_down,
    input chip_select,
    output reg o_run,
    output reg o_clear
    );

    // fsm 구조로 CU 설계
    parameter STOP = 2'b00, RUN = 2'b01, CLEAR = 2'b10;
    reg [1:0] state, next;

    always@(posedge clk, posedge reset)
        begin
            if(reset) begin
                state <= STOP;
            end
            else begin
                state <= next;
            end
        end
    
    // next
    always@(*)
        begin
            next = state; 
            if (chip_select == 1'b0) begin
                case(state)
                    STOP : begin
                        if(i_btn_up == 1'b1) begin
                            next = RUN; 
                        end
                        else if (i_btn_down == 1'b1) begin
                            next = CLEAR;
                        end
                        else begin
                            next = state;
                        end
                    end
                    RUN :begin
                        if(i_btn_up == 1'b1) begin
                            next = STOP;
                        end
                    end
                    CLEAR : begin
                        if(i_btn_down == 1'b1)begin
                            next = STOP;
                        end
                    end
                endcase
        end
    end

    // output logic
    always@(*)
        begin
            o_run = 0;
            o_clear = 0;
            case(state)
                STOP: begin
                    o_run = 1'b0;
                    o_clear = 1'b0;
                end
                RUN: begin
                    o_run = 1'b1;
                    o_clear = 1'b0;
                end
                CLEAR: begin
                    o_clear = 1'b1;
                end
            endcase
        end
endmodule
