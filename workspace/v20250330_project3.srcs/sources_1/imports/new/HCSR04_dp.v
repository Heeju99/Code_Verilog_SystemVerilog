`timescale 1ns / 1ps

module HCSR04_dp(
    input clk,
    input reset,
    input echo_done,
    input [11:0] distance_digit,
    output wr_tx,
    output [7:0] data_sensor_tx
    );

    parameter STOP = 0, DIGIT_100 = 1, DIGIT_10 = 2, DIGIT_1 = 3,
              WAIT_100 = 4, WAIT_10 = 5, WAIT_1 = 6,
              PRINT_C = 7, PRINT_M = 8, PRINT_SPACE = 9,
              WAIT_C = 10, WAIT_M = 11, WAIT_SPACE = 12;

    reg [3:0] state, next;
    reg [7:0] data_sensor_tx_reg, data_sensor_tx_next;  
    reg wr_tx_reg, wr_tx_next;
    reg [2:0]count_reg, count_next;

    wire [7:0] r_data_digit_100, r_data_digit_10, r_data_digit_1;
    wire [3:0] w_data_digit_100, w_data_digit_10, w_data_digit_1;

    assign w_data_digit_100 = distance_digit[11:8];
    assign w_data_digit_10 = distance_digit[7:4];
    assign w_data_digit_1 = distance_digit[3:0];
   
   assign data_sensor_tx = data_sensor_tx_reg;
   assign wr_tx = wr_tx_reg;

    deci_to_ASCII U_Deci_to_ASCII_1 (
        .data_digit(w_data_digit_1),
        .data_ASCII(r_data_digit_1)
    );

    deci_to_ASCII U_Deci_to_ASCII_10 (
        .data_digit(w_data_digit_10),
        .data_ASCII(r_data_digit_10)
    );

    deci_to_ASCII U_Deci_to_ASCII_100 (
        .data_digit(w_data_digit_100),
        .data_ASCII(r_data_digit_100)
    );

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            state <= 0;
            data_sensor_tx_reg <= 0;
            wr_tx_reg <= 0;
            count_reg <= 0;
        end
        else begin
            state <= next;
            data_sensor_tx_reg <= data_sensor_tx_next;
            wr_tx_reg <= wr_tx_next;
            count_reg <= count_next;
        end
    end

    always @(*) begin
        next = state;
        data_sensor_tx_next = data_sensor_tx_reg;
        wr_tx_next = wr_tx_reg;
        count_next = count_reg;
        case (state)
            STOP: begin
                //data_sensor_tx_next = 0;
                if(echo_done) begin
                    count_next = 0;
                    next = DIGIT_100;
                end
            end  
            DIGIT_100: begin // 100의 자리 처리
                data_sensor_tx_next = r_data_digit_100;
                wr_tx_next = 1;
                next = WAIT_100;
            end  
            WAIT_100: begin
                wr_tx_next = 0;
                next =DIGIT_10;
            end
            DIGIT_10: begin // 100의 자리 처리
                data_sensor_tx_next = r_data_digit_10;
                wr_tx_next = 1;
                next = WAIT_10;
            end  
            WAIT_10: begin
                wr_tx_next = 0;
                next = DIGIT_1;
            end
            DIGIT_1: begin // 100의 자리 처리
                data_sensor_tx_next = r_data_digit_1;
                wr_tx_next = 1;
                next = WAIT_1;
            end  
            WAIT_1: begin
                wr_tx_next = 0;
                next = PRINT_C;
            end
            PRINT_C: begin
                data_sensor_tx_next = 8'h63;  //c
                wr_tx_next = 1;
                next = WAIT_C;
            end
            WAIT_C: begin
                wr_tx_next = 0;
                next = PRINT_M;
            end
            PRINT_M: begin
                data_sensor_tx_next = 8'h6D; //m
                wr_tx_next = 1;
                next = WAIT_M;
            end
            WAIT_M: begin
                wr_tx_next = 0;
                next = PRINT_SPACE;
            end
            PRINT_SPACE: begin
                data_sensor_tx_next = 8'h20; //space
                wr_tx_next = 1;
                next = WAIT_SPACE;
            end
            WAIT_SPACE: begin
                wr_tx_next = 0;
                next = STOP;
            end
        endcase
    end
endmodule

