`timescale 1ns / 1ps

module entire(
    input clk,
    input reset,
    input bit1,
    input bit2,
    //input [1:0] sw;
    output [7:0] seg,
    output [3:0] seg_comm
);
    wire[13:0] w_counter;
    wire w_o_clk1 , w_run_stop, w_clear;
    //assign w_run_stop = sw[0] & clk;
    //assign w_clear = sw[1] | reset;

    bitcounter_9999 u_bitcounter_9999(
        .clk(w_o_clk1),
        .reset(reset/*w_clear*/),
        .count(w_counter)
    );
    fnd_controller u_fnd_controller(
        .clk(clk),
        .reset(reset),
        .count(w_counter),
        .seg(seg),
        .seg_comm(seg_comm)
    );
    clk_divider1 u_clk_divider1(
        .clk(clk),
        .bit1(bit1),
        .bit2(bit2),
        .reset(reset/*w_clear*/),
        .o_clk1(w_o_clk1)
    );

endmodule

module clk_divider1(
    input clk,
    input reset,
    input bit1,
    input bit2,
    output o_clk1
);
    parameter FCOUNT = 10_000_000;
    reg [$clog2(FCOUNT)-1:0] r_counter;
    reg r_clk1;
    assign o_clk1 = r_clk1;
    always@(posedge clk, posedge reset)
        begin
            if(reset) begin
                r_counter <= 0;
                r_clk1 <= 1'b0;
            end
            else if(bit1) begin
                r_counter <=0;
            end
            else if(bit2) begin
                r_counter <= r_counter;
            end
            else begin
                if(r_counter == FCOUNT - 1) begin //clk divider, 100MHz ->10Hz
                    r_counter <= 0;
                    r_clk1 <= 1'b1; 
                end
                else begin
                    r_counter <= r_counter + 1;
                    r_clk1 <= 1'b0;
                end
            end
        end
endmodule

module bitcounter_9999(
    input clk,
    input reset,
    output [13:0] count
);
    parameter FCOUNT = 10_000;
    reg [$clog2(FCOUNT)-1:0] r_counter;
    assign count = r_counter;

    always@(posedge clk, posedge reset)
        begin
            if(reset) begin
                r_counter <= 0;
            end
            else begin
                if(r_counter == FCOUNT - 1) begin
                    r_counter <= 0;
                end
                else begin
                    r_counter <= r_counter + 1;
                end
            end
        end
endmodule