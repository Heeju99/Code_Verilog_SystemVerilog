`timescale 1ns / 1ps

module btn_debounce(
    input clk,
    input reset,
    input i_btn,
    output o_btn
    );

    // state 
    
    reg [7:0] q_reg, q_next;  // shift register
    reg edge_detect;
    wire btn_debounce;

    // 1khz clk
    parameter COUNT_BIT = 100_000; //100_000
    reg [$clog2(COUNT_BIT)-1:0] counter_reg, counter_next; 
    reg r_1khz;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
        end else begin
            counter_reg <= counter_next;
        end
    end
    // next
    always @(*) begin  // 100_000_000 = 100M
        counter_next = counter_reg;
        r_1khz = 0;
        if (counter_reg == COUNT_BIT) begin
            counter_next = 0;
            r_1khz = 1'b1;
        end else begin // 1khz 1tick.
            // 다음번 카운트 에는 현재 카운트 값에 1을 더해라
            counter_next = counter_reg + 1;
            r_1khz = 1'b0; 
        end
    end

    // state logic , shift register
    always @(posedge r_1khz, posedge reset) begin
        if (reset) begin
            q_reg <= 0;
        end else begin
            q_reg <= q_next;
        end
    end

    // next logic
    always @(i_btn, r_1khz) begin  // event i_btn, r_1khz
        // q_reg 현재의 상위 7bit를 다음 하위 7비트를 넣고,
        // 최상에는 i_btn을 넣어라라
        q_next = {i_btn, q_reg[7:1]};  // 8 shift 의 동작 설명.
    end

    // 8 input AND gate
    assign btn_debounce = &q_reg;

    // edge_detector , 100Mhz
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            edge_detect <= 0;
        end else begin
            edge_detect <= btn_debounce;
        end
    end

    assign o_btn = btn_debounce & (~edge_detect);

endmodule
