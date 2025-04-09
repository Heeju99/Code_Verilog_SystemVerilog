`timescale 1ns / 1ps

module watch_cu(
    input clk,
    input reset,
    input i_btn_left,
    input i_btn_up,
    input i_btn_down,
    input chip_select,
    output reg o_sec,
    output reg o_min,
    output reg o_hour
    );

    parameter STOP = 2'b00, SEC = 2'b01, MIN = 2'b10, HOUR = 2'b11;
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
            if(chip_select == 1'b1)begin
                case(state)
                    STOP : begin
                        if(i_btn_up == 1'b1) begin
                            next = SEC; 
                        end
                        else if (i_btn_left == 1'b1) begin
                            next = MIN;
                        end
                        else if (i_btn_down == 1'b1) begin
                            next = HOUR;
                        end
                        else begin
                            next = state;
                        end
                    end
                    SEC :begin
                        if(i_btn_up == 1'b0) begin
                            next = STOP;
                        end
                    end
                    MIN : begin
                        if(i_btn_left == 1'b0)begin
                            next = STOP;
                        end
                    end
                    HOUR : begin
                        if(i_btn_down == 1'b0)begin
                            next = STOP;
                        end
                    end
                endcase
            end
        end

    // output logic
    always@(*)
        begin
            o_sec = 0;
            o_min = 0;
            o_hour = 0;
            case(state)
                STOP: begin
                    o_sec = 1'b0;
                    o_min = 1'b0;
                    o_hour = 1'b0;
                end
                SEC: begin
                    o_sec = 1'b1;
                    o_min = 1'b0;
                    o_hour = 1'b0;
                end
                MIN: begin
                    o_sec = 1'b0;
                    o_min = 1'b1;
                    o_hour = 1'b0;
                end
                HOUR: begin
                    o_sec = 1'b0;
                    o_min = 1'b0;
                    o_hour = 1'b1;
                end            
            endcase
        end
endmodule
