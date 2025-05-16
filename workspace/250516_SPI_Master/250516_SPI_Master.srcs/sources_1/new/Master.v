`timescale 1ns / 1ps

module Master(
    input clk,
    input reset,
    input btn,
    input [13:0] number,
    output start,
    output [7:0] data
    );
    
    parameter IDLE = 2'b00, L_BYTE = 2'b01, H_BYTE = 2'b10;
    reg [7:0] data_reg, data_next;
    reg [1:0] state_reg, state_next;
    reg start_reg, start_next;

    assign start = start_reg;
    assign data = data_reg;

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            state_reg <= IDLE;
            start_reg <= 0;
        end else begin
            state_reg <= state_reg;
            start_reg <= start_next;
        end
    end

    always @(*) begin
        state_next = state_reg;
        start_next = start_reg;
        case(state_reg)
            IDLE : begin
                start_next = 1'b0;
                if(btn) begin
                    start_next = 1'b1;
                    state_next = L_BYTE;
                end
            end
            L_BYTE : begin
                    data_next = {2'b00,number[13:8]};
                    state_next = H_BYTE;
            end
            H_BYTE : begin
                    data_next = {number[7:0]};
                    state_next = IDLE;
            end
        endcase
    end
endmodule
