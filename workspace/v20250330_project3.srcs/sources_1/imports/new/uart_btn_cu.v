`timescale 1ns / 1ps

module uart_btn_cu(
    input clk,
    input reset,
    input [7:0] data_in,
    input empty_rx_b,
    input btn_left,
    input btn_right,
    input btn_down,
    input [1:0] sw_mode,
    output left,
    output right,
    output down
    );
    reg [1:0] state, next;
    reg [7:0] data_in_reg, data_in_next;

    reg [3:0] count_reg, count_next;

    parameter STOP = 2'b00, LEFT = 2'b01, RIGHT = 2'b10, DOWN = 2'b11;

    reg uart_left, uart_right, uart_down;

    assign left = btn_left || uart_left;
    assign right = btn_right || uart_right;
    assign down = btn_down || uart_down;

    tick_1us #(.TICK_COUNT(1_000_000), .BIT_WIDTH(19)) U_Tick_1s(
        .clk(clk),
        .reset(reset),
        .o_tick(w_tick_1s)
    );

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            state <= STOP;
            count_reg <= 0;
        end
        else begin
            state <= next;
            count_reg <= count_next;
        end
    end

    always @(*) begin
        next = state;
        count_next = count_reg;
        case (state)
            STOP: begin
                if (empty_rx_b) begin
                    if (data_in == "R" || data_in == "S" || data_in == "T" || data_in == "E") begin
                        next = LEFT;
                    end
                    else if(sw_mode == 2'b11) begin 
                        if(count_reg == 10) begin
                            next = LEFT;
                        end
                        else begin
                            if(w_tick_1s) begin
                                count_next = count_reg + 1;
                            end
                        end
                    end
                    else if(data_in == "C" || data_in == "H") begin
                        next = RIGHT;
                    end
                    else if(data_in == "M") begin
                        next = DOWN;
                    end
                end
            end
            LEFT: begin
                next = STOP;
            end
            RIGHT: begin
                next = STOP;
            end
            DOWN: begin
                next = STOP;
            end
        endcase
    end

    always @(*) begin
        uart_left = 0;
        uart_right = 0;
        uart_down = 0;
        case (state)
            STOP: begin
                uart_left = 0;
                uart_right = 0;
                uart_down = 0;
            end
            LEFT: begin
                uart_left = 1;
                uart_right = 0;
            end
            RIGHT: begin
                uart_right = 1;
            end
            DOWN: begin
                uart_down = 1;
            end
        endcase
    end
endmodule
