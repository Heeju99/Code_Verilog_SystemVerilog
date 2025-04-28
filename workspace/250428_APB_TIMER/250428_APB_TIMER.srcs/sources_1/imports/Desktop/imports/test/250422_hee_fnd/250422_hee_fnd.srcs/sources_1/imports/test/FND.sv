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
    logic [3:0] fmr;
    logic [3:0] fdr;

    APB_SlaveIntf_FND U_APB_Intf_FND (.*);
    FND U_FND_IP (.*);
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
    output logic        fcr_en,
    output logic [ 3:0] fmr,
    output logic [ 3:0] fdr
);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2; //, slv_reg3;

    assign fcr_en = slv_reg0[0];   // 출력 여부 사용 (1: 사용 , 0: 비활성화)
    assign fmr    = slv_reg1[3:0]; // fndComm을 통해 어떤 자릿수 켤지 선택
    assign fdr    = slv_reg2[3:0]; // fndFont를 통해 어떤 숫자를 표시할지 선택

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0; //FCR
            slv_reg1 <= 0; //FMR
            slv_reg2 <= 0; //FDR
            // slv_reg3 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: slv_reg0 <= PWDATA; //FCR
                        2'd1: slv_reg1 <= PWDATA; //FMR
                        2'd2: slv_reg2 <= PWDATA; //FDR
                        // 2'd3: slv_reg3 <= PWDATA;
                    endcase
                end else begin
                    PRDATA <= 32'bx;
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;  //FCR
                        2'd1: PRDATA <= slv_reg1;  //FMR
                        2'd2: PRDATA <= slv_reg2;  //FDR
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
    input  logic       fcr_en,
    input  logic [3:0] fmr,
    input  logic [3:0] fdr,
    output logic [3:0] fndComm,
    output logic [7:0] fndFont
);

    assign fndComm = fcr_en ? ~fmr : 4'b1111;

    always_comb begin
        case(fdr)
            4'h0: fndFont = 8'hc0; //8비트의 헥사c0값
            4'h1: fndFont = 8'hF9;
            4'h2: fndFont = 8'hA4;
            4'h3: fndFont = 8'hB0;
            4'h4: fndFont = 8'h99;
            4'h5: fndFont = 8'h92;
            4'h6: fndFont = 8'h82;
            4'h7: fndFont = 8'hf8;
            4'h8: fndFont = 8'h80;
            4'h9: fndFont = 8'h90;
            default: fndFont = 8'hff;
        endcase
    end
endmodule
