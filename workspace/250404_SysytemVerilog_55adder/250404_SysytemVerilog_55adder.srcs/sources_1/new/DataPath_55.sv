`timescale 1ns / 1ps

module DataPath_55(
    input logic clk,
    input logic reset,
    output logic Alt10,
    input logic ASrcMuxSel,
    input logic AEn,
    input logic OutBuf,
    output logic [7:0] OutPort
    );

    logic w_Alt10;
    logic [7:0] w_y, w_q, w_sum, w_OutPort, w_acc;

    assign Alt10 = w_Alt10; 
    assign OutPort = w_OutPort;

    MUX_2X1 u_MUX_2X1(
        .sel(ASrcMuxSel), 
        .x0(8'd0),
        .x1(w_sum),
        .y(w_y)
    );

    Register u_Register(
        .clk(clk),
        .reset(reset),
        .en(AEn), 
        .d(w_y),
        .q(w_q)
    );

    Adder u_Adder(
        .a(w_q),
        .b(8'd1),
        .sum(w_sum)    
    );

    Accum u_Accum(
        .clk(clk),
        .reset(reset),
        .en(AEn),
        .sum(w_q),
        .acc(w_acc)    
);

    Comparator u_comparator(
        .a(w_q),
        .b(8'd11),
        .lt(w_Alt10) 
    );

    buf_comp u_buf_comp(
        .clk(clk),
        .reset(reset),
        .en(OutBuf),
        .d(w_acc),
        .q(w_OutPort)
    );

endmodule

module Accum(
    input logic clk,
    input logic reset,
    input logic en,
    input logic [7:0] sum,
    output logic [7:0] acc    
);
    logic [7:0] acc_sum; 
    assign acc = acc_sum;

    always_ff @(posedge clk, posedge reset) begin
        if(reset) begin
            acc_sum <= 0;
        end else if(en) begin
            acc_sum <= acc_sum + sum;
        end
    end
endmodule

module buf_comp(
    input logic clk,
    input logic reset,
    input logic en,
    input logic [7:0] d,
    output logic [7:0] q
);

    always_ff @(posedge clk, posedge reset) begin
        if(reset) begin
            q <= 0;
        end else if(en) begin
            q <= d;
        end
    end
endmodule

module MUX_2X1(
    input logic sel,
    input logic [7:0] x0,
    input logic [7:0] x1,
    output logic [7:0] y
);
    always@(*) begin
        case(sel)
            1'b0 : y = x0;
            1'b1 : y = x1;
        endcase
    end
endmodule

module Register(
    input logic clk,
    input logic reset,
    input logic en,
    input logic [7:0] d,
    output logic [7:0] q
);
    always_ff @(posedge clk, posedge reset) begin
        if(reset) begin
            q <= 0;
        end else if(en) begin
            q <= d;
        end
    end
endmodule

module Adder(
    input logic [7:0] a,
    input logic [7:0] b,
    output logic [7:0] sum    
);
    assign sum = a + b;
endmodule

module Comparator(
    input logic [7:0] a,
    input logic [7:0] b,
    output logic lt
);
    assign lt = (a < b);
endmodule
