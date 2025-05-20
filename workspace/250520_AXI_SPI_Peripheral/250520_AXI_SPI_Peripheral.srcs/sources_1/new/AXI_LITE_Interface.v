`timescale 1ns / 1ps

module AXI4_LITE_Interface(
   //Global Signals
    input  ACLK,
    input  ARESETn,

    //WRITE Transaction, AW Channel
    input   [3:0]  AWADDR,
    input          AWVALID,
    output   reg   AWREADY,

    //WRITE Transaction, W Channel
    input   [31:0] WDATA,
    input          WVALID,
    output   reg   WREADY,

    //WRITE Transaction, B Channel
    output  reg [1:0]  BRESP,
    output   reg   BVALID,
    input          BREADY,
 
    //READ Transaction, AR Channel
    input   [3:0]  ARADDR,
    input          ARVALID,
    output   reg   ARREADY,

    //READ Transaction, R Channel
    output  reg [31:0] RDATA,
    output  reg   RVALID,
    input          RREADY,
    output  reg [1:0]  RRESP,

    //internal Signals
    output  [7:0]  cr,
    output  [7:0]  sod,
    input   [7:0]  sid,
    input          sr
);
    wire [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3, slv_reg4;

    assign cr            = slv_reg0[7:0];
    assign sod           = slv_reg1[7:0];
    assign slv_reg2[7:0] = sid;
    assign slv_reg3[7:0] = sr;

    //AW Channel StateMachine
    localparam AW_IDLE_S = 0 , AW_READY_S = 1;
    reg aw_state, aw_state_next;

    reg [3:0] aw_addr_reg, aw_addr_next; //latch address

    always @(posedge ACLK) begin 
        if(!ARESETn) begin
            aw_state <= AW_IDLE_S;
            aw_addr_reg <= 0;
        end else begin
            aw_state <= aw_state_next;
            aw_addr_reg <= aw_addr_next;
        end
    end

    always@(*)begin
        aw_state_next = aw_state;
        aw_addr_next = aw_addr_reg;
        AWREADY = 1'b0;
        case(aw_state)
            AW_IDLE_S : begin
                AWREADY = 1'b0;
                if(AWVALID) begin
                    aw_addr_next = AWADDR;
                    aw_state_next = AW_READY_S;
                end
            end
            AW_READY_S : begin
                AWREADY = 1'b1;
                aw_addr_next = AWADDR; //값을 유지하기 위함, 없어도 됨
                aw_state_next = AW_IDLE_S;
            end
        endcase
    end


    //W Channel StateMachine
    localparam W_IDLE_S = 0, W_READY_S = 1;
    reg  w_state, w_state_next;


    always@(posedge ACLK) begin 
        if(!ARESETn) begin
            w_state <= W_IDLE_S;
        end else begin
            w_state <= w_state_next;
        end
    end

    always@(*) begin
        w_state_next = w_state;
        WREADY = 1'b0;
        case(w_state)
            W_IDLE_S : begin
                WREADY = 1'b0;
                if(AWVALID) begin
                    w_state_next = W_READY_S;
                end
            end
            W_READY_S : begin
                WREADY = 1'b1;
                if(WVALID) begin
                    w_state_next = W_IDLE_S;
                    case(aw_addr_reg[3:2])
                        2'd0: slv_reg0 = WDATA;
                        2'd1: slv_reg1 = WDATA;
                        2'd2: ;//slv_reg2 = WDATA; Write 불가, Read Only SID
                        2'd3: ;//slv_reg3 = WDATA; Write 불가, Read Only SR
                    endcase
                end
            end
        endcase
    end


    //B Channel StateMachine
    localparam B_IDLE_S = 0, B_VALID_S = 1;
    reg  b_state, b_state_next;


    always@(posedge ACLK) begin 
        if(!ARESETn) begin
            b_state <= B_IDLE_S;
        end else begin
            b_state <= b_state_next;
        end
    end

    always@(*)begin
        b_state_next = b_state;
        BVALID = 1'b0;
        BRESP = 2'b00;
        case(b_state)
            B_IDLE_S : begin
                BVALID = 1'b0;
                if(WVALID && WREADY) begin
                    b_state_next = B_VALID_S;
                end
            end
            B_VALID_S : begin
                BVALID = 1'b1;
                BRESP = 2'b00; //ok
                if(BREADY) begin
                    b_state_next = B_IDLE_S;
                end
            end
        endcase
    end

    //AR Channel StateMachine
    localparam AR_IDLE_S = 0, AR_READY_S = 1;
    reg  ar_state, ar_state_next;

    reg [3:0] ar_addr_reg, ar_addr_next;

    always@(posedge ACLK) begin 
        if(!ARESETn) begin
            ar_state <= AR_IDLE_S;
            ar_addr_reg <= 0;
        end else begin
            ar_state <= ar_state_next;
            ar_addr_reg <= ar_addr_next;
        end
    end

    always@(*)begin
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
                ar_addr_next = ARADDR;
                ar_state_next = AR_IDLE_S;
            end
        endcase
    end


    //R Channel StateMachine
    localparam R_IDLE_S = 0, R_VALID_S = 1;
    reg  r_state, r_state_next;


    always@(posedge ACLK) begin 
        if(!ARESETn) begin
            r_state <= R_IDLE_S;
        end else begin
            r_state <= r_state_next;
        end
    end

    always@(*)begin
        r_state_next = r_state;
        RVALID = 1'b0;
        RRESP = 2'b00;
        case(r_state)
            R_IDLE_S : begin
                RVALID = 1'b0;
                if(ARVALID && ARREADY) begin
                    r_state_next = R_VALID_S;
                end
            end
            R_VALID_S : begin
                RVALID = 1'b1;
                RRESP = 2'b00; //OK
                case(ar_addr_reg[3:2])
                    2'd0: RDATA = slv_reg0;
                    2'd1: RDATA = slv_reg1;
                    2'd2: RDATA = slv_reg2;
                    2'd3: RDATA = slv_reg3;
                endcase
                if(RREADY) begin
                    r_state_next = R_IDLE_S;
                end
            end
        endcase
    end
endmodule

