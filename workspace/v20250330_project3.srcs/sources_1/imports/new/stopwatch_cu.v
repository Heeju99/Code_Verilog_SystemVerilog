`timescale 1ns / 1ps

module stopwatch_cu(
    input clk, reset,
    input btn_left, btn_right,
    input [1:0] sw_mode,
    output reg o_run, o_clear
    );

    parameter STOP = 2'b00, RUN = 2'b01, CLEAR = 2'b10;

    reg [1:0] state, next;

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            state <= STOP;
        end else begin
            state <= next;
        end
    end
    
    // next
    always @(*) begin
        next = state;
        if (sw_mode == 2'b00) begin 
            case (state)
                STOP : begin
                    if(btn_left == 1) begin
                        next = RUN;
                    end 
                    else if (btn_right == 1) begin
                        next = CLEAR;
                    end
                end
                RUN : begin
                    if(btn_left == 1) begin
                        next = STOP;
                    end
                end
                CLEAR : begin
                    if (btn_right == 0) begin
                        next = STOP;
                    end
                end
            endcase
        end
    end

    //output
    always @(*) begin
        o_run = 0;
        o_clear = 0;
        case (state)
            STOP : begin
                o_run = 1'b0;
                o_clear = 1'b0;
            end 
            RUN : begin
                o_run = 1'b1;
                o_clear = 1'b0;
            end
            CLEAR : begin
                o_clear = 1'b1;
            end
        endcase
    end 
endmodule
