`timescale 1ns / 1ps

module send_tx_btn(
    input clk,
    input reset,
    input btn_start,
    output tx
    );

    wire w_start, w_tx_done;
    wire [7:0] w_tx_data_in;
    reg [7:0] send_tx_data_reg, send_tx_data_next; 

    button_debounce u_button_debounce(
    .clk(clk),
    .reset(reset),
    .i_btn(btn_start),
    .o_btn(w_start)
    );

    top_uart u_top_uart(
    .clk(clk),
    .reset(reset),
    .btn_start(w_start),
    .tx_data_in(send_tx_data_reg),
    .tx(tx),
    .tx_done(w_tx_done)
    );

    // send tx ascii to PC

    always@(posedge clk, posedge reset)
        begin
            if(reset) begin 
                send_tx_data_reg <= 8'h30; //데이터이기 때문에 "0"으로
            end
            else begin
                send_tx_data_reg <= send_tx_data_next;
            end
        end
    
    always@(*)
        begin
            send_tx_data_next = send_tx_data_reg;
            if(w_start == 1'b1) begin
                if (send_tx_data_reg == "z") begin
                    send_tx_data_next = "0";
                end else begin
                    send_tx_data_next = send_tx_data_reg + 1;
                end 
            end
        end
endmodule
