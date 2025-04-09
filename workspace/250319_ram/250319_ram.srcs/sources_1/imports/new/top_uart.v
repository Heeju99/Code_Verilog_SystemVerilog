`timescale 1ns / 1ps

/*module HIGH_Module(
    input clk,
    input reset,
    input rx,
    output tx,
    output [7:0] fnd_seg,
    output [3:0] fnd_comm
); 
    wire w_rx_done;
    wire [7:0] w_rx_data;

    top_uart u_top_uart(
        .clk(clk),
        .reset(reset),
        .btn_start(w_rx_done),
        .tx_data_in(w_rx_data),
        .tx(tx),
        .tx_done(),
        .rx(rx),
        .rx_done(w_rx_done),
        .rx_data(w_rx_data)
    );
    fnd_controller_seg u_fnd_controller_seg(
        .bcd(w_rx_data),
        .seg(fnd_seg),
        .fnd_comm(fnd_comm)
);

endmodule
*/

module top_uart(
        input clk,
        input reset,
        //tx
        input btn_start,
        input [7:0] tx_data_in,
        output tx,
        output tx_done,
        //rx
        input rx,
        output rx_done,
        output [7:0] rx_data
    );

    wire w_baud_tick;

    Baud_Tick_Gen u_Baud_Tick_Gen(
    .clk(clk),
    .reset(reset),
    .baud_tick(w_baud_tick)
);
    Uart_TX u_Uart_Tx(
    .clk(clk),
    .reset(reset),
    .data(tx_data_in),  //ASCII 값 하나 넣음
    .tick(w_baud_tick),
    .start_trigger(btn_start),
    .o_tx(tx),
    .o_tx_done(tx_done)
);
    Uart_RX u_UART_RX(
    .clk(clk),
    .reset(reset),
    .tick(w_baud_tick),
    .rx(rx),
    .rx_done(rx_done),
    .rx_data(rx_data)
);
endmodule

module Uart_TX(
    input clk,
    input reset,
    input [7:0] data,
    input tick,
    input start_trigger,
    output o_tx,
    output o_tx_done
);
    parameter IDLE = 4'h0, SEND = 4'h1, START = 4'h2, DATA = 4'h3, STOP = 4'h4 ;

    reg [3:0] state, next;
    reg tx_reg, tx_next;
    reg tx_done_reg, tx_done_next;
    reg [3:0]bit_count_reg, bit_count_next;
    reg [3:0] tick_count_reg, tick_count_next; 

    //tx_data_in buffer
    reg [7:0] temp_data_reg, temp_data_next;

    assign o_tx = tx_reg;
    assign o_tx_done = tx_done_reg;
    always@(posedge clk, posedge reset)
        begin
            if(reset) begin
                state <= 0;
                tx_reg <= 1'b1; //uart tx line을 초기에 항상 1로 만들기 위함.
                tx_done_reg <= 0;
                bit_count_reg <= 0; // 데이터 수를 세기위함(==cnt)
                tick_count_reg <= 0; //속도를 16배 해서 틱의 개수를 세기 위함
            end else begin
                state <= next;
                tx_reg <= tx_next;
                tx_done_reg <= tx_done_next;
                bit_count_reg <= bit_count_next;
                tick_count_reg <= tick_count_next;
                temp_data_reg <= temp_data_next;
            end
        end
    
    always@(*)
        begin
            next = state;
            tx_next = tx_reg;
            tx_done_next = tx_done_reg;
            bit_count_next = bit_count_reg;
            tick_count_next = tick_count_reg;
                case(state)
                    IDLE : begin
                        tx_next = 1'b1;
                        tx_done_next = 1'b0;
                        if(start_trigger) begin
                            next = START;
                            // start trigger 순간 data를 buffering
                            temp_data_next = data;
                        end
                    end
                    SEND : begin  //첫번째 틱을 잡기 위함 START 가기 전
                        if(tick == 1'b1) begin 
                            next = START;
                        end
                    end
                    START : begin
                        tx_done_next = 1'b1;
                        tx_next = 1'b0;
                        if(tick == 1'b1) begin 
                            if(tick_count_reg == 15) begin
                                bit_count_next = 1'b0; //state 넘어가기 전에 데이터 세는 거 초기화 필요
                                tick_count_next = 1'b0;
                                next = DATA;
                            end else begin
                                tick_count_next = tick_count_reg + 1;
                            end
                        end
                    end
                    DATA : begin
                        //tx_next = data[bit_count_reg];
                        tx_next = temp_data_reg[bit_count_reg];
                        if(tick == 1'b1) begin
                            if (tick_count_reg == 15) begin
                                tick_count_next = 0;
                                if(bit_count_reg == 7) begin
                                    next = STOP;                              
                                end else begin
                                    next = DATA;
                                    bit_count_next = bit_count_reg + 1;
                                end
                            end else begin
                                tick_count_next = tick_count_reg + 1;
                            end
                        end
                    end 
                    STOP : begin
                        tx_next = 1'b1;
                        if(tick == 1'b1) begin
                            if(tick_count_reg == 15) begin
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
module Uart_RX (
    input clk,
    input reset,
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

    always @(posedge clk, posedge reset) begin
        if (reset) begin
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
        case (state)
            IDLE: begin
                tick_count_next = 0;
                bit_count_next = 0;
                rx_done_next = 1'b0;
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
                        rx_done_next = 1'b1;
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


module Baud_Tick_Gen(
    input clk,
    input reset,
    output baud_tick
);
    parameter BAUD_RATE = 9_600;
    localparam BAUD_COUNT = (100_000_000 / BAUD_RATE) / 16; //Hz 계산하기 위해서 + 속도 16배

    reg [$clog2(BAUD_COUNT)-1 :0] count_reg, count_next;
    reg tick_reg, tick_next;

    assign baud_tick = tick_reg;

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
            tick_next = tick_reg;
                if(count_reg == BAUD_COUNT-1) begin
                    count_next = 0;
                    tick_next = 1'b1;
                end
                else begin
                    count_next = count_reg + 1;
                    tick_next = 1'b0;
                end
            end
endmodule