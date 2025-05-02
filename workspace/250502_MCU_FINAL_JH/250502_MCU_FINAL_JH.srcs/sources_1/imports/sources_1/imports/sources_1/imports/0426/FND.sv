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
    output logic [ 3:0] fndCom,
    output logic [ 7:0] fndFont

);
    logic [1:0] o_sel;
    logic fcr;
    logic [13:0] fdr;
    logic [3:0] fpr;
    logic [3:0] digit_1;
    logic [3:0] digit_10;
    logic [3:0] digit_100;
    logic [3:0] digit_1000;
    logic [3:0] bcd;
    logic [7:0] bcd_out;

    APB_SlaveIntf_FND U_APB_Intf_FND (.*);
    FndController U_FND_IP (.*);

    counter_4 u_counter_4 (
        .clk  (o_clk),
        .reset(PRESET),
        .o_sel(o_sel)
    );
    decoder_2x4 u_decoder_2x4 (
        .seg_sel (o_sel),
        .fcr(fcr),
        .seg_comm(fndCom)
    );

    clock_div u_clock_div (
        .clk  (PCLK),
        .reset(PRESET),
        .o_clk(o_clk)
    );

    digit_splitter u_digit_splitter (
        .sum       (fdr),
        .digit_1   (digit_1),
        .digit_10  (digit_10),
        .digit_100 (digit_100),
        .digit_1000(digit_1000)
    );

    mux_4x1 u_mux_4x1 (
        .sel       (fndCom),
        .digit_1   (digit_1),
        .digit_10  (digit_10),
        .digit_100 (digit_100),
        .digit_1000(digit_1000),
        .bcd       (bcd)
    );

    clock_div2hz u_clock_div2hz (
        .clk  (PCLK),
        .reset(PRESET),
        .o_clk(clk_2hz)
    );

    bcd_mux u_bcd_mux (
        .seg_comm(fndCom),
        .clk_2hz (clk_2hz),
        .fpr     (fpr),
        .bcd     (bcd_out),
        .seg_out (fndFont)
    );



endmodule

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
    output logic        fcr,
    output logic [13:0] fdr,
    output logic [ 3:0] fpr
);



    logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;

    assign fcr = slv_reg0[0];
    assign fdr = slv_reg1[13:0];
    assign fpr = slv_reg2[3:0];

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0;
            slv_reg1 <= 0;
            slv_reg2 <= 0;
            // slv_reg3 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: slv_reg0 <= PWDATA;
                        2'd1: slv_reg1 <= PWDATA % 10000;
                        2'd2: slv_reg2 <= PWDATA;
                        // 2'd3: slv_reg3 <= PWDATA;
                    endcase
                end else begin
                    PRDATA <= 32'bx;
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        2'd1: PRDATA <= slv_reg1;
                        2'd2: PRDATA <= slv_reg2;
                        // 2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end

endmodule

module clock_div2hz (
    input  clk,
    input  reset,
    output o_clk
);
    parameter FCOUNT = 50000000;  //default 50000000
    reg [$clog2(FCOUNT)-1:0] r_counter;
    reg r_clk;
    assign o_clk = r_clk;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
            r_clk <= 1'b0;
        end else begin
            if (r_counter == FCOUNT - 1) begin
                r_counter <= 0;
                r_clk <= 1;
            end else if (r_counter == FCOUNT / 2 - 1) begin
                r_clk <= 0;
                r_counter <= r_counter + 1;
            end else begin
                r_counter <= r_counter + 1;
            end
        end
    end
endmodule


module bcd_mux (
    input [3:0] seg_comm,
    input clk_2hz,
    input [3:0] fpr,
    input [7:0] bcd,
    output reg [7:0] seg_out
);
    wire [7:0] clk_2hz_bcd;
    assign clk_2hz_bcd = {1'b1, 7'b0};
    always @(*) begin
        seg_out = bcd;
        if (fpr[0] == 1 && seg_comm == 4'b1110) begin
            seg_out = bcd - clk_2hz_bcd;
        end
        if (fpr[1] == 1 && seg_comm == 4'b1101) begin
            seg_out = bcd - clk_2hz_bcd;
        end
        if (fpr[2] == 1 && seg_comm == 4'b1011) begin
            seg_out = bcd - clk_2hz_bcd;
        end
        if (fpr[3] == 1 && seg_comm == 4'b0111) begin
            seg_out = bcd - clk_2hz_bcd;
        end
    end
endmodule


// module bcd_mux (
//     input [3:0] seg_comm,
//     input clk_2hz,
//     input [3:0] fpr,
//     input [7:0] bcd,
//     output reg [7:0] seg_out
// );
//     wire [7:0] clk_2hz_bcd;
//     assign clk_2hz_bcd = {clk_2hz, 7'b0};
//     always @(*) begin
//         seg_out = bcd;
//         if (fpr[0] == 1 && seg_comm == 4'b1110) begin
//             seg_out = bcd - clk_2hz_bcd;
//         end
//         if (fpr[1] == 1 && seg_comm == 4'b1101) begin
//             seg_out = bcd - clk_2hz_bcd;
//         end
//         if (fpr[2] == 1 && seg_comm == 4'b1011) begin
//             seg_out = bcd - clk_2hz_bcd;
//         end
//         if (fpr[3] == 1 && seg_comm == 4'b0111) begin
//             seg_out = bcd - clk_2hz_bcd;
//         end
//     end
// endmodule


module mux_4x1 (
    input  [3:0] sel,
    input  [3:0] digit_1,
    input  [3:0] digit_10,
    input  [3:0] digit_100,
    input  [3:0] digit_1000,
    output [3:0] bcd
);
    reg [3:0] r_bcd;
    assign bcd = r_bcd;
    always @(sel, digit_1, digit_10, digit_100, digit_1000) begin
        case (sel)
            4'b1110: r_bcd = digit_1;
            4'b1101: r_bcd = digit_10;
            4'b1011: r_bcd = digit_100;
            4'b0111: r_bcd = digit_1000;
            default: r_bcd = 4'bx;
        endcase
    end
endmodule

module digit_splitter (
    input  [13:0] sum,
    output [ 3:0] digit_1,
    output [ 3:0] digit_10,
    output [ 3:0] digit_100,
    output [ 3:0] digit_1000
);
    assign digit_1 = sum % 10;
    assign digit_10 = sum / 10 % 10;
    assign digit_100 = sum / 100 % 10;
    assign digit_1000 = sum / 1000 % 10;

endmodule

module clock_div (
    input  clk,
    input  reset,
    output o_clk
);
    parameter FCOUNT = 1_00_000;
    reg [$clog2(FCOUNT)-1:0] r_counter;
    reg r_clk;
    assign o_clk = r_clk;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
            r_clk <= 1'b0;
        end else begin
            if (r_counter == FCOUNT - 1) begin
                r_counter <= 0;
                r_clk <= 1;
            end else begin
                r_counter <= r_counter + 1;
                r_clk <= 1'b0;
            end
        end
    end
endmodule

module counter_4 (  //10hz
    input clk,
    input reset,
    output [1:0] o_sel
);
    reg [1:0] r_counter;
    assign o_sel = r_counter;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
        end else begin
            r_counter <= r_counter + 1;  //0,1,2,3,0,1,2,3....
        end

    end
endmodule

module decoder_2x4 (
    input [1:0] seg_sel,
    input fcr,
    output reg [3:0] seg_comm
);
    always_comb begin
        seg_comm = 4'b1111;
        if (fcr) begin
        case (seg_sel)
            2'b00:   seg_comm = 4'b1110;
            2'b01:   seg_comm = 4'b1101;
            2'b10:   seg_comm = 4'b1011;
            2'b11:   seg_comm = 4'b0111;
            default: seg_comm = 4'b1111;
        endcase
        end
    end
endmodule

module FndController (
    input logic fcr,
    input logic [3:0] bcd,
    output logic [7:0] bcd_out

);



    always_comb begin
        if (fcr == 0) begin
            bcd_out = 8'hff;
        end else begin
            case (bcd)
                4'h0: bcd_out = 8'hC0;
                4'h1: bcd_out = 8'hF9;
                4'h2: bcd_out = 8'hA4;
                4'h3: bcd_out = 8'hB0;
                4'h4: bcd_out = 8'h99;
                4'h5: bcd_out = 8'h92;
                4'h6: bcd_out = 8'h82;
                4'h7: bcd_out = 8'hf8;
                4'h8: bcd_out = 8'h80;
                4'h9: bcd_out = 8'h90;
                4'hA: bcd_out = 8'h88;
                4'hB: bcd_out = 8'h83;
                4'hC: bcd_out = 8'hC6;
                4'hD: bcd_out = 8'hA1;
                4'hE: bcd_out = 8'h86;
                4'hF: bcd_out = 8'h8E;
                default: bcd_out = 8'hff;
            endcase
        end
    end

    /*
    always_comb begin
        for (int i=0; i<8; i++) begin
            outPort[i] = moder[i] ? odr[i] : 1'bz;
        end
    end
*/
    /*
    assign outPort = moder[0] ? odr[0] : 1'bz;
    assign outPort = moder[1] ? odr[1] : 1'bz;
    assign outPort = moder[2] ? odr[2] : 1'bz;
    assign outPort = moder[3] ? odr[3] : 1'bz;
    assign outPort = moder[4] ? odr[4] : 1'bz;
    assign outPort = moder[5] ? odr[5] : 1'bz;
    assign outPort = moder[6] ? odr[6] : 1'bz;
    assign outPort = moder[7] ? odr[7] : 1'bz;
    */
endmodule
