`timescale 1ns / 1ps

module I2C_Slave_Intf(
    //Global Signals
    input clk,
    input reset,
    //External Signals
    input [7:0] rx_data,
    input reg SCL,
    inout SDA
    );

    parameter IDLE = ;
    reg [:0]state, state_next;

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            state <= IDLE;
        end else begin
            state <= state_next;
        end
    end

    always @(*) begin
        state_next = state;
        case(state)
            IDLE :
        endcase
    end
endmodule
