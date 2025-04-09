`timescale 1ns / 1ps

module send_tx_btn(
    input clk,
    input reset,
    input btn_start,
    output tx
    );

    wire w_start, w_tx_done;
    //wire [7:0] w_tx_data_in;
    reg [7:0] send_tx_data_reg, send_tx_data_next;
    reg send_reg, send_next; //start trigger 출력
    reg [1:0] state, state_next; //send char fsm state
    reg [3:0] send_count_reg, send_count_next; //보낸 데이터 세려고

    parameter IDLE = 2'b00, START = 2'b01, SEND = 2'b10;

    button_debounce u_button_debounce(
    .clk(clk),
    .reset(reset),
    .i_btn(btn_start),
    .o_btn(w_start)
    );

    top_uart u_top_uart(
    .clk(clk),
    .reset(reset),
    .btn_start(send_reg),
    .tx_data_in(send_tx_data_reg),
    .tx(tx),
    .tx_done(w_tx_done)
    );

   // send tx ascii to PC
    always@(posedge clk, posedge reset)
        begin
            if(reset) begin 
                send_tx_data_reg <= 8'h30; //데이터이기 때문에 "0"으로
                state <= IDLE;
                send_reg <= 1'b0; //tx_done을 틱처럼
                send_count_reg <= 4'b0; 
            end
            else begin
                send_tx_data_reg <= send_tx_data_next;
                state <= state_next;
                send_reg <= send_next;
                send_count_reg <= send_count_next;
            end
        end

    always@(*)
        begin
            send_tx_data_next = send_tx_data_reg;
            state_next = state;
            send_next = 1'b0;  //1tick을 만들기 위함
            send_count_next = send_count_reg; 
            case(state)
                IDLE: begin
                    //send_next = 1'b0;
                    send_count_next = 4'b0;
                    if(w_start == 1) begin
                        state_next = START;
                        send_next = 1'b1;
                    end
                end 
                START: begin
                    //send_next = 1'b0;
                    if(w_tx_done == 1) begin
                        state_next = SEND;
                    end
                end
                SEND: begin
                    if(w_tx_done == 0) begin
                        send_count_next = send_count_reg + 1;
                        if(send_count_reg == 15)begin
                            state_next = IDLE;
                        end else if (send_tx_data_reg == "z") begin
                            send_tx_data_next = "0";
                        end else begin
                            state_next = START;
                            send_tx_data_next = send_tx_data_reg + 1;
                            send_next = 1'b1;
                        end 
                    end
                end
            endcase
        end
endmodule