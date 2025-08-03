`timescale 1ns / 1ps

module btn_debounce(
    input       i_btn, clk, reset,
    output      o_btn
    );
    localparam  DEBOUNCE_COUNT = 1_000;
    // state
    //         state, next;
    reg         [7:0] q_reg, q_next; // shift register
    reg         edge_detect;
    wire        btn_debounce;

    // 100kHz clk, state
    reg         [$clog2(DEBOUNCE_COUNT)-1:0] counter;
    reg         r_1kHz;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter <= 0;
            r_1kHz <= 0;
        end else begin
            if (counter == DEBOUNCE_COUNT - 1) begin
                counter <= 0;
                r_1kHz <= 1'b1;
            end else begin // 1kHz 1thick
                counter <= counter + 1;
                r_1kHz <= 1'b0;
            end
        end
    end

    // state logic, shift register
    always @(posedge r_1kHz, posedge reset) begin
        if (reset) begin
            q_reg <= 0;
        end else q_reg <= q_next;
    end

    // next logic
    always @(i_btn, r_1kHz) begin // event i_btn, r_1kHz
        // q_reg 현재의 상위 7비트를 다음 하위 7비트에 넣고 최상위에는 i_btn을 넣어라
        q_next = {i_btn,q_reg[7:1]}; // 8shift 동작 
    end

    // 8 input AND gate
    assign btn_debounce = &q_reg;

    // edge_detector, 100MHz -> F/F 추가
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            edge_detect <= 1'b0;
        end else edge_detect <= btn_debounce;
    end

    // 최종 출력
    assign o_btn = btn_debounce & (~edge_detect);
endmodule