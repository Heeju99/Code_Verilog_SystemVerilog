`timescale 1ns / 1ps

module btn_debounce (
    input  logic clk,        // 100 MHz
    input  logic reset,
    input  logic i_btn,
    output logic o_btn
);

    // Parameters
    parameter integer COUNT_MAX = 100_000; // 100MHz / 1kHz = 100,000
    parameter integer SHIFT_LEN = 8;

    // 1kHz clock enable
    logic [$clog2(COUNT_MAX)-1:0] count;
    logic tick_1khz;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 0;
            tick_1khz <= 0;
        end else if (count == COUNT_MAX - 1) begin
            count <= 0;
            tick_1khz <= 1;
        end else begin
            count <= count + 1;
            tick_1khz <= 0;
        end
    end

    // Shift register for debouncing
    logic [SHIFT_LEN-1:0] shift_reg;

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            shift_reg <= 0;
        else if (tick_1khz)
            shift_reg <= {shift_reg[SHIFT_LEN-2:0], i_btn};
    end

    // Debounced output: all 1's in shift_reg
    logic btn_debounced;
    assign btn_debounced = &shift_reg;

    // Rising edge detector
    logic btn_debounced_d;
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            btn_debounced_d <= 0;
        else
            btn_debounced_d <= btn_debounced;
    end

    assign o_btn = btn_debounced & ~btn_debounced_d;

endmodule


// `timescale 1ns / 1ps

// module btn_debounce(
//     input logic clk,
//     input logic reset,
//     input logic i_btn,
//     output logic o_btn
//     );

//     // state 
    
//     reg [7:0] q_reg, q_next;  // shift register
//     reg edge_detect;
//     wire btn_debounce;

//     // 1khz clk
//     parameter COUNT_BIT = 100_000; //100_000
//     reg [$clog2(COUNT_BIT)-1:0] counter_reg, counter_next; 
//     reg r_1khz;
//     always @(posedge clk, posedge reset) begin
//         if (reset) begin
//             counter_reg <= 0;
//         end else begin
//             counter_reg <= counter_next;
//         end
//     end
//     // next
//     always @(*) begin  // 100_000_000 = 100M
//         counter_next = counter_reg;
//         r_1khz = 0;
//         if (counter_reg == COUNT_BIT) begin
//             counter_next = 0;
//             r_1khz = 1'b1;
//         end else begin // 1khz 1tick.
//             // 다음번 카운트 에는 현재 카운트 값에 1을 더해라
//             counter_next = counter_reg + 1;
//             r_1khz = 1'b0; 
//         end
//     end

//     // state logic , shift register
//     always @(posedge r_1khz, posedge reset) begin
//         if (reset) begin
//             q_reg <= 0;
//         end else begin
//             q_reg <= q_next;
//         end
//     end

//     // next logic
//     always @(i_btn, r_1khz) begin  // event i_btn, r_1khz
//         // q_reg 현재의 상위 7bit를 다음 하위 7비트를 넣고,
//         // 최상에는 i_btn을 넣어라라
//         q_next = {i_btn, q_reg[7:1]};  // 8 shift 의 동작 설명.
//     end

//     // 8 input AND gate
//     assign btn_debounce = &q_reg;

//     // edge_detector , 100Mhz
//     always @(posedge clk, posedge reset) begin
//         if (reset) begin
//             edge_detect <= 0;
//         end else begin
//             edge_detect <= btn_debounce;
//         end
//     end

//     assign o_btn = btn_debounce & (~edge_detect);

// endmodule
