`timescale 1ns / 1ps

module watch_cu(
    input clk, reset,
    input btn_left, btn_right, btn_down, 
    input [1:0] sw_mode,
    output reg o_sec_up, o_min_up, o_hour_up 
    );

    parameter STOP = 2'b00, SEC = 2'b01, MIN = 2'b10, HOUR=2'b11;

    reg [1:0] state, next;

    // state register
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
        if(sw_mode == 2'b01) begin
            case (state)
                STOP : begin
                    if(btn_left == 1) begin
                        next = SEC;
                    end 
                    else if (btn_down == 1) begin
                        next = MIN;
                    end 
                    else if (btn_right == 1) begin
                        next = HOUR;
                    end
                end
                SEC : begin
                    if(btn_left == 0) begin
                        next = STOP;
                    end 
                end
                MIN : begin
                    if(btn_down == 0) begin
                        next = STOP;
                    end 
                end
                HOUR : begin
                    if(btn_right == 0) begin
                        next = STOP;
                    end 
                end
        
            endcase
        end
    end

    //output
    always @(*) begin
        o_sec_up=0; o_min_up=0; o_hour_up=0; 
        case (state)
            STOP : begin
                o_sec_up = 1'b0;
                o_min_up = 1'b0;
                o_hour_up= 1'b0;
            end 
            SEC : begin
                o_sec_up = 1'b1;
                o_min_up = 1'b0;
                o_hour_up= 1'b0;
            end
            MIN : begin
                o_sec_up = 1'b0;
                o_min_up = 1'b1;
                o_hour_up= 1'b0;
            end
            HOUR : begin
                o_sec_up = 1'b0;
                o_min_up = 1'b0;
                o_hour_up= 1'b1;
            end
        endcase
    end 
endmodule