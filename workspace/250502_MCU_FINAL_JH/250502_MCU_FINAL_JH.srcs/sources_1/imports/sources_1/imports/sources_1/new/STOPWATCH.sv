`timescale 1ns / 1ps

module STOPWATCH_Periph (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY

);

    logic [2:0] TCR;
    logic [31:0] TCNR;
    logic [31:0] PSC;
    logic [31:0] ARR;
    logic clear;
    logic en;
    logic reverse;
    assign {reverse, clear, en} = TCR;

    APB_SlaveIntf_STOPWATCH U_APB_Intf_stopwatch (.*);
    clock_div1ms_STOPWATCH u_clock_div1ms (
        .clk  (PCLK),
        .reset(PRESET),
        .en   (en),
        .clear(clear),
        .o_clk(tick),
        .PSC  (PSC)
    );





    Counter_STOPWATCH u_Counter (
        .clk(PCLK),
        .tick(tick),
        .count(TCNR),
        .reset(PRESET),
        .clear(clear),
        .ARR(ARR),
        .reverse(reverse)
    );

endmodule



module APB_SlaveIntf_STOPWATCH (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // internal signals
    output logic [ 2:0] TCR,
    output logic [31:0] PSC,
    output logic [31:0] ARR,
    input  logic [31:0] TCNR
);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;


    assign TCR = slv_reg0[2:0];
    assign slv_reg1[31:0] = TCNR;
    assign PSC = slv_reg2[31:0];
    assign ARR = slv_reg3[31:0];


    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0;
            //slv_reg1 <= 0;
            slv_reg2 <= 0;
            slv_reg3 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: slv_reg0 <= PWDATA;
                        // 2'd1: ;
                        2'd2: slv_reg2 <= PWDATA;
                        2'd3: slv_reg3 <= PWDATA;
                    endcase
                end else begin
                    PRDATA <= 32'bx;
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        2'd1: PRDATA <= slv_reg1;
                        2'd2: PRDATA <= slv_reg2;
                        2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end

endmodule

module Counter_STOPWATCH (
    input logic clk,
    input logic tick,
    input logic reset,
    output logic [31:0] count,
    input logic [31:0] ARR,
    input logic clear,
    input logic reverse



);
    always_ff @(posedge clk) begin
        if (reset | clear) begin
            if (reverse) begin
                count <= ARR;
            end else begin
                count <= 0;
            end
        end else begin
            if (tick) begin
                if (reverse) begin
                    if (count != 0) begin 
                        count <= count - 1;
                    end
                end else begin
                    if (count != ARR) begin
                        count <= count + 1;
                    end
                end
            end
        end

    end
endmodule


//stopwatch 


module clock_div1ms_STOPWATCH (
    input clk,
    input reset,
    input en,
    input [31:0] PSC,
    input clear,
    output o_clk
);
    reg [31:0] FCOUNT = PSC;
    reg [31:0] r_counter;
    reg r_clk;
    assign o_clk = r_clk;
    always @(posedge clk, posedge reset) begin
        if (reset | clear) begin
            r_counter <= 0;
            r_clk <= 1'b0;
        end else begin
            if (en) begin
                if (r_counter == FCOUNT) begin
                    r_counter <= 0;
                    r_clk <= 1;
                end else begin
                    r_counter <= r_counter + 1;
                    r_clk <= 1'b0;
                end
            end
        end
    end
endmodule
