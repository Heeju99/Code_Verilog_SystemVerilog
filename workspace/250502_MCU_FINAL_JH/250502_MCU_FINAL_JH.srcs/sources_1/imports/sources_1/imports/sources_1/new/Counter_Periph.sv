`timescale 1ns / 1ps

module Counter_Periph (
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

    logic [1:0] TCR;
    logic [31:0] TCNR;
    logic [31:0] PSC;
    logic [31:0] ARR;
    logic clear;
    logic en;
    assign {clear, en} = TCR;

    APB_SlaveIntf_counter U_APB_Intf (.*);
    clock_div1ms u_clock_div1ms (
        .clk  (PCLK),
        .reset(PRESET),
        .en   (en),
        .clear(clear),
        .o_clk(tick),
        .PSC  (PSC)
    );





    Counter u_Counter (
        .clk  (PCLK),
        .tick (tick),
        .count(TCNR),
        .reset(PRESET),
        .clear(clear),
        .ARR  (ARR)
    );

endmodule



module APB_SlaveIntf_counter (
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
    output logic [ 1:0] TCR,
    output logic [31:0] PSC,
    output logic [31:0] ARR,
    input  logic [31:0] TCNR
);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;


    assign TCR = slv_reg0[1:0];
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

module Counter (
    input logic clk,
    input logic tick,
    input logic reset,
    output logic [31:0] count,
    input logic [31:0] ARR,
    input logic clear



);
    always_ff @(posedge clk) begin
        if (reset | clear) begin
            count <= 0;
        end else begin
            if (tick) begin
                if (count == ARR) begin
                    count <= 0;
                end else begin
                    count <= count + 1;
                end
            end
        end

    end


endmodule



module clock_div1ms (
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
