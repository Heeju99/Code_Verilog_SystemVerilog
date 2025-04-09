`timescale 1ns / 1ps

module fsm_led(
    input clk,
    input reset,
    input [2:0] sw,
    output [1:0] led
    );

    parameter [1:0] IDLE = 2'b00, LED1 = 2'b01, LED2 = 2'b10;
    reg [1:0] r_led;
    reg [1:0] state, next; //next는 state의 다음 상태 예측
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
                            next = LED1; 
                            end
                        end
                LED1 : begin   
                        if(sw == 3'b011) begin
                            next = LED2;
                            end
                        end 
                LED2 : begin
                            if(sw == 3'b110) begin
                                next = LED1; 
                            end
                            else if (sw == 3'b111) begin
                                next = IDLE;
                            end
                            else begin
                                next = state;
                            end
                        end
                default: next = state;
            endcase
        end

    //output logics
    always@(*)begin
        case(next)
            IDLE : begin 
                r_led = 2'b00;
            end
            LED1 :begin 
                r_led = 2'b10;
            end
            LED2 : begin
                r_led = 2'b01;
            end
            default : begin
                r_led = 2'b00;
            end
        endcase
    end
endmodule
