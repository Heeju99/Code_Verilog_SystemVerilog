`timescale 1ns / 1ps

module watch_stopwatch(
    input clk,
    input reset,
    output tick,
    output o_clk
    );


    wire w_tick_msec, w_tick_sec;
    time_counter #(.FCOUNT(100), .BIT_WIDTH(7))u_time_msec(
    .clk(clk),
    .reset(reset),
    .tick(),
    .o_clk(o_clk), 
    .o_tick(w_tick_msec)
);

time_counter #(.FCOUNT(60), .BIT_WIDTH(6))u_time_sec(
    .clk(clk),
    .reset(reset),
    .tick(w_tick_msec),
    .o_clk(o_clk), 
    .o_tick(w_tick_sec)
);

time_counter #(.FCOUNT(9), .BIT_WIDTH(4))u_time_min(
    .clk(clk),
    .reset(reset),
    .tick(w_tick_sec),
    .o_clk(o_clk), 
    .o_tick()
);
endmodule


module time_counter #(parameter FCOUNT = 100, BIT_WIDTH = 7)(
    input clk,
    input reset,
    input tick,
    output [BIT_WIDTH-1 :0] o_clk, 
    output o_tick
);

    reg[$clog2(FCOUNT-1):0] counter_reg, counter_next;
    reg tick_reg , tick_next; 

    assign o_tick = tick_reg;
    assign o_clk = counter_reg;

    always@(posedge clk, posedge reset)
    begin
        if(reset) begin
            counter_reg <= 0;
            tick_reg <= 0;
        end else begin
            counter_reg <= counter_next;
            tick_reg <= tick_next;
        end
    end
    always@(*)begin
        counter_next = counter_reg;
        tick_next <= tick_reg;
        if(tick)begin
            if(counter_reg == FCOUNT -1) begin
                tick_next = 1'b1;
                counter_next =0;
            end else begin
                counter_next = counter_reg + 1;
                tick_next = 1'b0;
            end
        end
    end
endmodule