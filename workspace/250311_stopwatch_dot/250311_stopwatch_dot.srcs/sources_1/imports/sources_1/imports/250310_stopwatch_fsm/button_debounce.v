`timescale 1ns / 1ps

module button_debounce(
        input clk,
        input reset,
        input i_btn,
        output o_btn
    );
    //state   state, next
    reg [7:0] q_reg, q_next; //shift register
    reg edge_detect;
    wire btn_debounce;


    //1khz clk 만들기
    // state       , next
    reg [$clog2(100_000)-1 : 0] counter;
    reg r_1khz;
    always@(posedge clk, posedge reset) begin
        if(reset) begin
            counter <= 0;
            r_1khz <= 0;
        end else begin
            if(counter == 100_000 -1)begin
                counter <= 0;
                r_1khz <= 1'b1; //1khz 1tick  ==flag
        end else begin
            //다음 번 카운트에는 현재 카운트 값에 1을 더해라
            counter <= counter + 1;
            r_1khz <= 1'b0;
        end
        end
    end


    //state logic, shift register
    always @(posedge r_1khz, posedge reset) begin
        if(reset) begin
            q_reg <= 0;
        end
        else begin
            q_reg <= q_next;
        end
    end

    //next logic 
    always@(i_btn, r_1khz)begin //event i_btn, r_1khz
        // q_reg의 상위 7비트를 다음 하위 7비트에 넣고, 
        // 최상위에는 i_btn을 넣어라
        q_next = {i_btn, q_reg[7:1]}; //8shift의 동작 
    end

    // 8input AND gate
    assign btn_debounce = &q_reg;

    //edge detector
    always @(posedge clk, posedge reset)begin
        if(reset) begin
            edge_detect <= 1'b0;
        end
        else begin
            edge_detect <= btn_debounce;
        end
    end
    // final output 그림대로 연결
    assign o_btn = (~edge_detect) & btn_debounce;

endmodule
