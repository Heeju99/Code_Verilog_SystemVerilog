`timescale 1ns / 1ps

module I2C_Master(
    input        clk,
    input        reset,
    output       SCL,
    output [7:0] SDA
    );

    localparam IDLE = 1, WRITE_PHASE = 2, READ_PHASE = 3;
    reg [1:0] state, state_next;
  
    assign SDA = 8'hff;
    assign SCL = 1'b1;
    assign start = ~SDA[7] && SCL;
    assign stop  = SDA[7]  && ~SCL;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= state_next;
        end
    end

    always @(*) begin
        state_next = state;
        case(state)
            IDLE : begin
                if(start) begin
                    if(SDA[0] == 1) begin
                        state_next = READ_PHASE;
                    end else begin
                        state_next = WRITE_PHASE;
                    end
                end 
            end
            WRITE_PHASE : begin 
            end
            READ_PHASE  : begin 
            end
        endcase
    end
endmodule
