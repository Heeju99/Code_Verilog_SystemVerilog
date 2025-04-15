`timescale 1ns / 1ps

module trigger_10us(
    input clk,
    input reset,
    input btn_trig,
    output o_tick
);
    parameter TICK_COUNT = 1000, BIT_WIDTH = 10;
    parameter STOP = 0, RUN = 1;
    reg [$clog2(TICK_COUNT)-1:0] count_reg, count_next;
    reg tick_reg, tick_next;  // 출력용
    reg state, next;
    
    assign o_tick = tick_reg;
    
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= 0;
            count_reg <= 0;
            tick_reg  <= 0;
        end else begin
            state <= next;
            count_reg <= count_next;
            tick_reg  <= tick_next;
        end
    end

    always @(*) begin
        next = state;
        count_next = count_reg;
        tick_next = tick_reg;
        case (state)
            STOP: begin
                tick_next  = 1'b0;
                if(btn_trig == 1) begin
                    next = RUN;
                end 
            end 
            RUN: begin
                if (count_reg == TICK_COUNT - 1) begin
                    count_next = 0;
                    next = STOP;
                end
                else begin
                    count_next = count_reg + 1;
                    tick_next  = 1'b1; 
                end 
            end 
        endcase
    end
endmodule