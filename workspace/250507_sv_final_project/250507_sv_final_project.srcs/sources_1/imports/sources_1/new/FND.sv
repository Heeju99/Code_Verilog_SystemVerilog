`timescale 1ns / 1ps

module FND_Periph (
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
    // export signals
    output logic [ 3:0] fndComm,
    output logic [ 7:0] fndFont
);

    logic       fcr_en;
    logic [13:0] fdr;
    logic [3:0]  fpr;

    APB_SlaveIntf_FND U_APB_Intf_FND (.*);
    FND U_FND_IP (.*);
endmodule
//
module APB_SlaveIntf_FND (
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
    output logic        fcr_en,
    output logic [13:0] fdr,
    output logic [ 3:0] fpr
);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2; //, slv_reg3;

    assign fcr_en = slv_reg0[0];
    assign fdr    = slv_reg1[13:0];
    assign fpr    = slv_reg2[3:0];

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0; //FCR
            slv_reg1 <= 0; //FDR
            slv_reg2 <= 0; //FPR
            // slv_reg3 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: slv_reg0 <= PWDATA; //FCR
                        2'd1: slv_reg1 <= PWDATA; //FDR
                        2'd2: slv_reg2 <= PWDATA; //FPR
                        // 2'd3: slv_reg3 <= PWDATA;
                    endcase
                end else begin
                    PRDATA <= 32'bx;
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;  //FCR
                        2'd1: PRDATA <= slv_reg1;  //FDR
                        2'd2: PRDATA <= slv_reg2;  //FPR
                        // 2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end

endmodule

module FND (
    input  logic       PCLK,
    input  logic       PRESET,
    input  logic       fcr_en,
    input  logic [13:0] fdr,
    input  logic [3:0] fpr,
    output logic [3:0] fndComm,
    output logic [7:0] fndFont
);

    logic [3:0] digit_1, digit_10, digit_100, digit_1000;
    logic [3:0] o_fdr;
    logic [1:0] digit_sel, o_tick;
    logic fndDp;
    logic [6:0] fndSegData;

    assign fndFont = {~fndDp, fndSegData[6:0]}; //dot은 최상위 비트

    clk_div_1khz U_clk_div_1khz(
        .clk(PCLK),
        .reset(PRESET),
        .tick(o_tick)
);
//
    counter_2bit  U_counter_2bit(
        .clk(PCLK),
        .reset(PRESET),
        .tick(o_tick),
        .count(digit_sel)
);

    decoder_2x4 U_Dec_2x4 (
        .fcr_en(fcr_en),
        .x(digit_sel),
        .y(fndComm)
    );

    digitSplitter U_digitSplitter(
        .fndData(fdr),
        .digit_1(digit_1),
        .digit_10(digit_10),
        .digit_100(digit_100),
        .digit_1000(digit_1000)
);

    mux_4x1 U_mux_4x1(
        .sel(digit_sel),
        .x0(digit_1),
        .x1(digit_10),
        .x2(digit_100),
        .x3(digit_1000),
        .y(o_fdr)
);

    mux_4x1_1bit U_mux_4x1_1bit(
        .sel(digit_sel),
        .x(fpr),
        .y(fndDp)
);

    always_comb begin
        case(o_fdr)
            4'd0:  fndSegData = 8'hc0; //8비트의 헥사c0값 
            4'd1:  fndSegData = 8'hF9; //fndFont
            4'd2:  fndSegData = 8'hA4;
            4'd3:  fndSegData = 8'hB0;
            4'd4:  fndSegData = 8'h99;
            4'd5:  fndSegData = 8'h92;
            4'd6:  fndSegData = 8'h82;
            4'd7:  fndSegData = 8'hf8;
            4'd8:  fndSegData = 8'h80;
            4'd9:  fndSegData = 8'h90;
            4'd10: fndSegData = 8'h88;
            4'd11: fndSegData = 8'h83;
            4'd12: fndSegData = 8'hc6;
            4'd13: fndSegData = 8'ha1;
            4'd14: fndSegData = 8'h86;
            4'd15: fndSegData = 8'h8e;
            default: fndSegData = 8'hff;
        endcase
    end
endmodule

module clk_div_1khz (
    input  logic clk,
    input  logic reset,
    output logic tick
);
    reg [$clog2(100_000)-1 : 0] div_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            div_counter <= 0;
            tick <= 1'b0;
        end else begin
            if (div_counter == 100_000 - 1) begin
                div_counter <= 0;
                tick <= 1'b1;
            end else begin
                div_counter <= div_counter + 1;
                tick <= 1'b0;
            end
        end
    end
endmodule

module counter_2bit (
    input  logic       clk,
    input  logic       reset,
    input  logic       tick,
    output logic [1:0] count
);
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count <= 0;
        end else begin
            if(tick) begin
                count <= count + 1;
            end
        end
    end
endmodule
//
module digitSplitter (
    input  logic [13:0] fndData,
    output logic [ 3:0] digit_1,
    output logic [ 3:0] digit_10,
    output logic [ 3:0] digit_100,
    output logic [ 3:0] digit_1000
);
    assign digit_1    = fndData % 10;
    assign digit_10   = fndData / 10 % 10;
    assign digit_100  = fndData / 100 % 10;
    assign digit_1000 = fndData / 1000 % 10;
endmodule

module mux_4x1 (
    input  logic [1:0] sel,
    input  logic [3:0] x0,
    input  logic [3:0] x1,
    input  logic [3:0] x2,
    input  logic [3:0] x3,
    output logic [3:0] y
);
    always @(*) begin
        y = 4'b0000;
        case (sel)
            2'b00: y = x0;
            2'b01: y = x1;
            2'b10: y = x2;
            2'b11: y = x3;
        endcase
    end
endmodule
///
module decoder_2x4 (
    input  logic fcr_en,
    input  logic [1:0] x,
    output logic [3:0] y
);
    always @(*) begin
        y = 4'b1111;
        if(fcr_en) begin
            case (x)
                2'b00: y = 4'b1110;
                2'b01: y = 4'b1101;
                2'b10: y = 4'b1011;
                2'b11: y = 4'b0111;
            endcase
        end
    end
endmodule
       
module mux_4x1_1bit(
    input [1:0] sel,
    input [3:0] x,
    output reg y
);
    always@(*) begin
        case(sel)
            2'b00 : y = x[0];
            2'b01 : y = x[1];
            2'b10 : y = x[2];
            2'b11 : y = x[3];
        endcase
    end
endmodule

/*
module BCDtoSEG_decoder (
    input      [3:0] bcd,
    output reg [7:0] seg
);
    always @(bcd) begin
        case (bcd)
            4'h0: seg = 8'hc0;
            4'h1: seg = 8'hf9;
            4'h2: seg = 8'ha4;
            4'h3: seg = 8'hb0;
            4'h4: seg = 8'h99;
            4'h5: seg = 8'h92;
            4'h6: seg = 8'h82;
            4'h7: seg = 8'hf8;
            4'h8: seg = 8'h80;
            4'h9: seg = 8'h90;
            4'ha: seg = 8'h88;
            4'hb: seg = 8'h83;
            4'hc: seg = 8'hc6;
            4'hd: seg = 8'ha1;
            4'he: seg = 8'h86;
            4'hf: seg = 8'h8e;
            default: seg = 8'hff;
        endcase
    end
endmodule
*/