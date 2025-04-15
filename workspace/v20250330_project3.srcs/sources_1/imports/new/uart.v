`timescale 1ns / 1ps

module uart(
    input  clk,
    input  rst,
    input  btn_start,
    input rx,
    input [7:0] tx_data_in,
    output tx,
    output tx_done,
    output rx_done,
    output [7:0] rx_data
);

    wire w_tick;

    uart_tx U_uart_tx (
        .clk (clk),
        .rst (rst),
        .tick(w_tick),
        .start_trigger(btn_start),
        .data_in(tx_data_in), 
        .o_tx(tx),
        .tx_done(tx_done)
    );

    uart_rx U_uart_rx(
        .clk(clk),
        .rst(rst),
        .tick(w_tick),
        .rx(rx),
        .rx_done(rx_done),
        .rx_data(rx_data)
    );

    baud_tick_gen U_baud_tick_gen (
        .clk(clk),
        .rst(rst),
        .baud_tick(w_tick)
    );
endmodule

module uart_tx (
    input clk,
    input rst,
    input tick,
    input start_trigger,
    input [7:0] data_in,
    output o_tx,
    output tx_done
);
    // fsm
    parameter IDLE = 4'h0, START = 4'h1, DATA = 4'h2, STOP = 4'h3;
    parameter COUNT_BIT = 8;
    parameter BAUD_SPEED = 16;

    reg [3:0] state, next;
    reg tx_reg, tx_next, tx_done_reg, r_tx_done_next;
    reg [3:0]bit_count_reg, bit_count_next;
    reg [3:0] tick_count_reg, tick_count_next;

    assign o_tx = tx_reg;
    assign tx_done = tx_done_reg;

    // tx data in buffer
    reg [7:0] temp_data_reg, temp_data_next;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state  <= 0;
            tx_reg <= 1'b1; // Uart tx line을 초기에 항상 1로 만들기 위함.
            tx_done_reg <= 0;
            bit_count_reg <= 0;
            tick_count_reg <= 0;
            temp_data_reg <= 0;
        end else begin
            state  <= next;
            tx_reg <= tx_next;
            tx_done_reg <= r_tx_done_next;
            bit_count_reg <= bit_count_next;
            tick_count_reg <= tick_count_next;
            temp_data_reg <= temp_data_next;
        end
    end

    // next

    always @(*) begin
        next = state;
        tx_next = tx_reg;
        r_tx_done_next = tx_done_reg;
        bit_count_next = bit_count_reg;
        tick_count_next = tick_count_reg;
        temp_data_next = temp_data_reg;
        case (state)
            IDLE: begin
                tx_next = 1'b1;
                r_tx_done_next = 1'b0;
                tick_count_next = 4'h0;
                if (start_trigger) begin
                    next = START;    
                    // start trigger 순간 data를 update
                    temp_data_next = data_in;
                end
            end
            START: begin
                r_tx_done_next = 1'b1;
                tx_next = 1'b0;  // 출력을 0으로 유지                     
                if (tick == 1'b1) begin
                    if(tick_count_reg == BAUD_SPEED-1) begin
                        next = DATA;
                        bit_count_next = 0;
                        tick_count_next = 0;       
                    end
                    else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            DATA: begin
                tx_next = temp_data_reg[bit_count_reg];
                if(tick == 1'b1) begin
                    if(tick_count_reg == BAUD_SPEED-1) begin
                        tick_count_next = 0;   
                        if(bit_count_reg == COUNT_BIT-1) begin
                            next = STOP;
                        end
                        else begin
                            bit_count_next = bit_count_reg + 1;
                            next = DATA; 
                        end
                    end
                    else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            STOP: begin
                tx_next = 1'b1;
                if (tick == 1'b1) begin
                    if(tick_count_reg == BAUD_SPEED-1) begin
                        next = IDLE;
                        tick_count_next = 0;   
                    end
                    else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule

// UART RX
module uart_rx (
    input clk,
    input rst,
    input tick,
    input rx,
    output rx_done,
    output [7:0] rx_data
);
    
    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;
    reg [1:0] state, next;
    reg rx_done_reg, rx_done_next;
    reg [2:0] bit_count_reg, bit_count_next;
    reg [4:0] tick_count_reg, tick_count_next; 
    reg [7:0] rx_data_reg, rx_data_next;

    assign rx_done = rx_done_reg;
    assign rx_data = rx_data_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= 0;
            rx_done_reg <= 0;
            bit_count_reg <= 0;
            tick_count_reg <= 0;
            rx_data_reg <= 0;
        end
        else begin
            state <= next;
            rx_done_reg <= rx_done_next;
            bit_count_reg <= bit_count_next;
            tick_count_reg <= tick_count_next;
            rx_data_reg <= rx_data_next;
        end
    end

    always @(*) begin
        next = state;
        rx_done_next = rx_done_reg;
        bit_count_next = bit_count_reg;
        tick_count_next = tick_count_reg;
        rx_data_next = rx_data_reg;
        rx_done_next = 0;
        case (state)
            IDLE: begin
                tick_count_next = 0;
                bit_count_next = 0;
                rx_done_next = 0;
                if (rx == 0) begin
                    next = START;
                end
            end  
            START: begin
                if(tick) begin
                    if(tick_count_reg == 7) begin
                        next = DATA;
                        tick_count_next = 0;
                    end
                    else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
                
            end  
            DATA: begin
                rx_data_next[bit_count_reg] = rx;
                if (tick) begin
                    if(tick_count_reg == 15) begin
                        // read data
                        tick_count_next = 0;
                        if (bit_count_reg == 7) begin
                            next = STOP;
                        end
                        else begin
                            next = DATA;
                            bit_count_next = bit_count_reg + 1;
                        end
                    end
                    else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end  
            STOP: begin
                if(tick) begin
                    if (tick_count_reg == 23) begin
                        rx_done_next = 1;
                        next = IDLE;
                    end
                    else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end  
        endcase
    end

endmodule

module baud_tick_gen (
    input  clk,
    input  rst,
    output baud_tick
);
    parameter BAUD_RATE = 9600;  // BAUD_RATE_192000 = 192000
    localparam BAUD_COUNT = (100_000_000 / BAUD_RATE)/16;
    reg [$clog2(BAUD_COUNT)-1:0] count_reg, count_next;
    reg tick_reg, tick_next;
    // output
    assign baud_tick = tick_reg;
    always @(posedge clk, posedge rst) begin
        if (rst == 1) begin
            count_reg <= 0;
            tick_reg  <= 0;
        end else begin
            count_reg <= count_next;
            tick_reg  <= tick_next;
        end
    end

    //next
    always @(*) begin
        count_next = count_reg;
        tick_next  = tick_reg;
        if (count_reg == BAUD_COUNT - 1) begin
            count_next = 0;
            tick_next  = 1'b1;
        end else begin
            count_next = count_reg + 1;
            tick_next  = 1'b0;
        end
    end
endmodule
