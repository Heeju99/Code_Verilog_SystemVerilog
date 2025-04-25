`timescale 1ns / 1ps

module FIFO_Periph (
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

    // inport signals
    output logic real_ready
);

    logic [1:0] FSR;
    logic [7:0] FWD;
    logic [7:0] FRD;

    // fifo
    logic [7:0] wdata;
    logic       wr_en;
    logic       full;
    // read side
    logic [7:0] rdata;
    logic       rd_en;
    logic       empty;

    assign FSR = {empty, full};
    assign wdata = FWD;
    assign FRD = rdata;
    

    APB_SlaveIntf_FIFO U_APB_Intf_FIFO (.*);
    FIFO_Ctrl U_FIFO_ctrl (.*);
    fifo U_FIFO (
        .clk  (PCLK),
        .reset(PRESET),
        .*
    );

endmodule

module APB_SlaveIntf_FIFO (
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
    input  logic [ 1:0] FSR,
    output logic [ 7:0] FWD,
    input  logic [ 7:0] FRD,
    //fifo
    output logic        wr_en,
    output logic        rd_en

);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2;  //, slv_reg2, slv_reg3;


    assign slv_reg0[1:0] = FSR;
    assign FWD = slv_reg1[7:0];
    assign slv_reg2[7:0] = FRD;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            //slv_reg0 <= 0;
            slv_reg1 <= 0;
            //slv_reg2 <= 0;
            // slv_reg3 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: ;  //slv_reg0 <= PWDATA;
                        2'd1: slv_reg1 <= PWDATA;
                        2'd2: ;  //slv_reg2 <= PWDATA;
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

module FIFO_Ctrl (    //to control READ/WRITE & make new ready signal, because of timing
    input logic PCLK,
    input logic PRESET,
    input logic PWRITE,
    input logic [3:0] PADDR,
    input logic PREADY,
    output logic wr_en,
    output logic rd_en,
    output logic real_ready
);
    parameter IDLE = 0, WRITE = 1, READ = 2, WAIT = 3;
    logic [1:0] state, next;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            state <= 1'b0;
        end else begin
            state <= next;
        end
    end

    always_comb begin
        next  = state;
        wr_en = 0;
        rd_en = 0;
        real_ready = 0;
        case (state)
            IDLE: begin
                wr_en = 0;
                rd_en = 0;
                if (PREADY && ~(PADDR[3:2] == 2'd0)) begin
                    if (PWRITE) begin
                        next = WRITE;
                    end else begin
                        next = READ;
                    end
                end
            end
            WRITE: begin
                wr_en = 1;
                rd_en = 0;
                next = WAIT;
                real_ready = 1;
            end
            READ: begin
                wr_en = 0;
                rd_en = 1;
                next = WAIT;
                real_ready = 1;
            end

            WAIT: begin
                next = IDLE;
            end
        endcase
    end
endmodule

// module GPIO_FIFO (
//     input  logic [7:0] moder,
//     output logic [7:0] idr,
//     input  logic [7:0] odr,
//     inout  logic [7:0] inoutPort
// );

//     genvar i;
//     generate
//         for (i = 0; i < 8; i++) begin
//             assign inoutPort[i] = moder[i] ? odr[i] : 1'bz;  // output mode
//             assign idr[i] = ~moder[i] ? inoutPort[i] : 1'bz;  // input  mode
//         end
//     endgenerate
// endmodule
