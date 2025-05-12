`timescale 1ns / 1ps

module AXI4_lite_Slave(
    // Global Signal
    input logic ACLK,
    input logic ARESETn,
    // WRITE Transaction, AW Channel
    input  logic [3:0]  AWADDR,
    input  logic        AWVALID,
    output logic        AWREADY,
    // WRITE Transaction, W Channel
    input  logic [31:0] WDATA,
    input  logic        WVALID,
    output logic        WREADY,
    // WRITE Transaction, B Channel
    output logic [1:0]  BRESP,
    output logic        BVALID,
    input  logic        BREADY,

    // READ Transaction, AR Channel
    input  logic [3:0] ARADDR, 
    input  logic       ARVALID, 
    output logic       ARREADY, 

    // READ Transaction, R Channel
    output logic [31:0] RDATA,
    output logic        RVALID,
    input  logic        RREADY
    );

    logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;
    logic [ 3:0] aw_addr_reg, aw_addr_next;
    logic [ 3:0] ar_addr_reg, ar_addr_next;

    //WRITE Transaction, AW Channel transfer
    typedef enum {AW_IDLE_S, AW_READY_S} aw_state_e;
    aw_state_e aw_state, aw_state_next;

    always_ff @(posedge ACLK) begin
        if(!ARESETn) begin
            aw_state <= AW_IDLE_S;
            aw_addr_reg <= 0;
        end else begin
            aw_state <= aw_state_next;
            aw_addr_reg <= aw_addr_next;
        end
    end

    always_comb begin
        aw_state_next = aw_state;
        aw_addr_next = aw_addr_reg;
        AWREADY = 1'b0;
        case(aw_state)
            AW_IDLE_S : begin
                AWREADY = 1'b0;
                if(AWVALID) begin
                    aw_state_next = AW_READY_S;
                    aw_addr_next = AWADDR; //address 값을 latching(저장)
                end
            end
            AW_READY_S : begin
                AWREADY = 1'b1;
                //aw_addr_next = AWADDR;      여기도 가능
                if(AWVALID && AWREADY) begin
                    aw_state_next = AW_IDLE_S;
                end
            end
        endcase
    end


    //WRITE Transaction, W Channel transfer
    typedef enum {W_IDLE_S, W_READY_S} w_state_e;
    w_state_e w_state, w_state_next;

    always_ff @(posedge ACLK) begin
        if(!ARESETn) begin
            w_state <= W_IDLE_S;
        end else begin
            w_state <= w_state_next;
        end
    end

    always_comb begin
        w_state_next = w_state;
        WREADY = 1'b0; 
        case(w_state)
            W_IDLE_S : begin
                WREADY = 1'b0;
                if(AWVALID) begin
                    w_state_next = W_READY_S;
                end
            end
            W_READY_S : begin  // select register and write
                WREADY = 1'b1;
                if(WVALID) begin
                    w_state_next = W_IDLE_S;
                    case(aw_addr_reg[3:2])
                        2'd0 : slv_reg0 = WDATA;
                        2'd1 : slv_reg1 = WDATA;
                        2'd2 : slv_reg2 = WDATA;
                        2'd3 : slv_reg3 = WDATA;
                    endcase
                end
            end
        endcase
    end


    //WRITE Transaction, B Channel transfer
    typedef enum {B_IDLE_S, B_VALID_S} b_state_e;
    b_state_e b_state, b_state_next;

    always_ff @(posedge ACLK) begin
        if(!ARESETn) begin
            b_state <= B_IDLE_S;
        end else begin
            b_state <= b_state_next;
        end
    end

    always_comb begin
        b_state_next = b_state;
        BRESP = 2'b00;
        BVALID = 1'b0;
        case(b_state)
            B_IDLE_S : begin
                BVALID = 1'b0;
                if(WVALID && WREADY) begin
                    b_state_next = B_VALID_S;
                end
            end
            B_VALID_S : begin
                BRESP = 2'b00; //ok
                BVALID = 1'b1;
                if(BREADY) begin
                    b_state_next = B_IDLE_S;
                end
            end
        endcase
    end


    //READ Transaction, AR Channel transfer
    typedef enum {AR_IDLE_S, AR_READY_S} ar_state_e;
    ar_state_e ar_state, ar_state_next;

    always_ff @(posedge ACLK) begin
        if(!ARESETn) begin
            ar_state <= AR_IDLE_S;
            ar_addr_reg <= 0; 
        end else begin
            ar_state <= ar_state_next;
            ar_addr_reg <= ar_addr_next;
        end
    end

    always_comb begin
        ar_state_next = ar_state;
        ar_addr_next = ar_addr_reg;
        ARREADY = 1'b0;
        case(ar_state)
            AR_IDLE_S : begin
                ARREADY = 1'b0;
                if(ARVALID) begin
                    ar_state_next = AR_READY_S;
                    ar_addr_next = ARADDR;
                end
            end
            AR_READY_S : begin
                ARREADY = 1'b1;
                if(ARVALID && ARREADY) begin  
                    ar_state_next = AR_IDLE_S;
                end
            end
        endcase
    end


    //READ Transaction, R Channel transfer
    typedef enum {R_IDLE_S, R_VALID_S} r_state_e;
    r_state_e r_state, r_state_next;

    always_ff @(posedge ACLK) begin
        if(!ARESETn) begin
            r_state <= R_IDLE_S;
        end else begin
            r_state <= r_state_next;
        end
    end

    always_comb begin
        r_state_next = r_state;
        RVALID = 1'b0;
        
        case(r_state)
            R_IDLE_S : begin
                RVALID = 1'b0;
                if(ARVALID && ARREADY) begin
                    r_state_next = R_VALID_S;
                end
            end
            R_VALID_S : begin
                if(RREADY) begin
                RVALID = 1'b1;
                r_state_next = R_IDLE_S;
                    case(ar_addr_reg[3:2])
                        2'd0 : RDATA = slv_reg0;
                        2'd1 : RDATA = slv_reg1;
                        2'd2 : RDATA = slv_reg2;
                        2'd3 : RDATA = slv_reg3;
                    endcase
                end
            end
        endcase
    end
endmodule
