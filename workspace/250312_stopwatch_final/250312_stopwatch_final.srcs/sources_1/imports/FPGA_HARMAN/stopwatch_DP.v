`timescale 1ns / 1ps

module stopwatch_DP(
    input clk,
    input reset,
    input clear,
    input run,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
    );

    wire w_clk_100hz;
    wire w_msec_tick, w_sec_tick, w_min_tick;

    time_counter #(.TICK_COUNT(100), .BIT_WIDTH(7)) U_time_msec( 
    .clk(clk),
    .reset(reset),
    .clear(clear),
    .tick(w_clk_100hz), //100_divider에서 들어옴
    .o_time(msec), //splitter로 들어감
    .o_tick(w_msec_tick)  //출력틱
    );

    time_counter #(.TICK_COUNT(60), .BIT_WIDTH(6)) U_time_sec( 
    .clk(clk),
    .reset(reset),
    .clear(clear),
    .tick(w_msec_tick), //msec_counter에서 들어옴
    .o_time(sec), //splitter로 들어감
    .o_tick(w_sec_tick) // 출력틱
    );

    time_counter #(.TICK_COUNT(60), .BIT_WIDTH(6)) U_time_min( 
    .clk(clk),
    .reset(reset),
    .clear(clear),
    .tick(w_sec_tick), //sec_counter에서 들어옴
    .o_time(min), //splitter로 들어감
    .o_tick(w_min_tick) // 출력틱
    );

    time_counter #(.TICK_COUNT(24), .BIT_WIDTH(5)) U_time_hour( 
    .clk(clk),
    .reset(reset),
    .clear(clear),
    .tick(w_min_tick), //min_counter에서 들어옴
    .o_time(hour), //splitter로 들어감
    .o_tick() // 출력틱
    );

    clk_div_100 U_clk_divider(
    .clk(clk),
    .reset(reset),
    .run(run),
    .clear(clear),
    .o_clk(w_clk_100hz)
);
endmodule

module time_counter #(parameter TICK_COUNT = 100, BIT_WIDTH = 7)( //100 까지니깐 2^7비트폭
    input clk,
    input reset,
    input clear,
    input tick,
    //output [6:0] o_time,
    output [BIT_WIDTH -1 :0] o_time,
    output o_tick
);
    //parameter TICK_COUNT = 100;
    reg [$clog2(TICK_COUNT -1) : 0] count_reg, count_next;
    reg tick_reg, tick_next; //출력용

    assign o_time = count_reg;
    assign o_tick = tick_reg;

    always@(posedge clk, posedge reset)
        begin
            if(reset) begin
                count_reg <= 0;
                tick_reg <= 0;
            end
            else begin
                count_reg <= count_next;
                tick_reg <= tick_next;
            end
        end

    always@(*)
        begin
            count_next = count_reg;
            tick_next = 0; // 0 - 1 - 0 : 틱이 0으로 내려가게 수동으로 제어
            if(clear == 1'b1) begin
                count_next = 0;
                end else if(tick == 1'b1) begin
                    if(count_reg == TICK_COUNT -1)begin
                        count_next = 0;
                        tick_next = 1'b1;
                    end
                    else begin
                        count_next = count_reg + 1;
                        tick_next = 1'b0;
                    end
            end
        end
endmodule

module clk_div_100(
    input clk,
    input reset,
    input run,
    input clear,
    output o_clk
);
    parameter FCOUNT = 1_000_000;
    reg [$clog2(FCOUNT)-1 :0] count_reg, count_next;
    reg clk_reg, clk_next; //출력을 F/F로 보내기 위해서

    assign o_clk = clk_reg; //최종 출력

    always@(posedge clk, posedge reset)
        begin
            if(reset) begin
                count_reg <= 0;
                clk_reg <= 0;
            end
            else begin
                count_reg <= count_next;
                clk_reg <= clk_next;
            end
        end
    
    always@(*)
        begin
            count_next = count_reg;
            clk_next = 1'b0;  //틱이 발생하고, 초기화를 통해 다시 발생하지 않도록 함.
            if (run == 1'b1) begin
                if(count_reg == FCOUNT-1) begin
                    count_next = 0;
                    clk_next = 1'b1;
                end
                else begin
                    count_next = count_reg + 1;
                    clk_next = 1'b0;
                end
            end
            else if (clear == 1'b1) begin
                count_next = 0;
                clk_next = 0;
            end
        end
endmodule

