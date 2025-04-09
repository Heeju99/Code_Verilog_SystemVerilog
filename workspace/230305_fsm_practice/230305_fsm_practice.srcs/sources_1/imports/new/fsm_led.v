`timescale 1ns / 1ps

module fsm_led(
    input clk,
    input reset,
    input [2:0] sw,
    output [2:0] led
    );

    parameter [2:0] IDLE = 3'b000, ST1 = 3'b001, ST2 = 3'b010, ST3 = 3'b011, ST4 = 3'b100;
    reg [2:0] r_led;
    reg [2:0] state, next; //next는 state의 다음 상태 예측
    assign led = r_led;

    always@(posedge clk, posedge reset)
        begin
            if(reset) begin
                state <= 0; 
            end
            else begin
                //상태 관리, 현재 상태를 next state로 바꿔라
                state <= next;
            end 
        end
    
    //next combinational logic
    always@(*)
        begin
            next = state;
            case(state)
                IDLE : begin    
                        if(sw == 3'b001) begin
                            next = ST1; 
                            end
                        else if (sw == 3'b010)begin
                            next = ST2;
                            end
                        else begin
                            next = state;
                            end
                        end
                ST1 : begin   
                        if(sw == 3'b010) begin
                            next = ST2;
                            end
                        end 
                ST2 : begin
                            if(sw == 3'b100) begin
                                next = ST3; 
                            end
                        end
                ST3 : begin    
                        if(sw == 3'b001) begin
                            next = ST1; 
                            end
                        else if (sw == 3'b000)begin
                            next = IDLE;
                            end
                        else if (sw == 3'b111) begin
                            next = ST4;
                            end
                        else begin
                            next = state;
                            end 
                        end
                ST4 : begin
                            if(sw == 3'b100) begin
                                next = ST3; 
                            end
                        end
                default: next = state;
            endcase
        end

    //output logics
    always@(*)begin
        case(next)
            IDLE : begin 
                r_led = 3'b000;
            end
            ST1 :begin 
                r_led = 3'b001;
            end
            ST2 : begin
                r_led = 3'b010;
            end
            ST3 : begin
                r_led = 3'b100;
            end
            ST4 : begin
                r_led = 3'b111;
            end
            default : begin
                r_led = 3'b000;
            end
        endcase
    end
endmodule
