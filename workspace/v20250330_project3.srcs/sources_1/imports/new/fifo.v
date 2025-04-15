`timescale 1ns / 1ps

module fifo(
    input clk,
    input reset,
    input [7:0] wdata,
    input wr,
    input rd,
    output full,
    output empty,
    output [7:0] rdata
    );

    wire [3:0] w_waddr, w_raddr;
    wire w_wr;
    assign w_wr = wr&(~full);

    register_file #(.ADDR_WIDTH(4), .DATA_WIDTH(8)) U_Register_file (
        .clk(clk),
        .waddr(w_waddr),
        .raddr(w_raddr), 
        .wdata(wdata),
        .wr(w_wr),
        .rdata(rdata)
    );

    fifo_control_unit #(.ADDR_WIDTH(4)) U_FIFO_Ctrl_Unit(
        .clk(clk),
        .reset(reset),
        .wr(wr),
        .rd(rd),
        .waddr(w_waddr),
        .raddr(w_raddr),
        .full(full),
        .empty(empty)
    );
endmodule

// register(Data Path)
module register_file #(parameter ADDR_WIDTH = 4, DATA_WIDTH = 8)(
    input clk,
    input [ADDR_WIDTH-1:0] waddr, raddr, 
    input [DATA_WIDTH-1:0] wdata,
    input wr,
    output [DATA_WIDTH-1:0] rdata
);
    
    reg [DATA_WIDTH-1:0] mem [0:2**ADDR_WIDTH-1]; // 4bit address 

    //write
    always @(posedge clk) begin
        if(wr) begin
            mem[waddr] <= wdata;
        end
    end

    //read
    assign rdata = mem[raddr];
endmodule

module fifo_control_unit #(parameter ADDR_WIDTH = 4)(
    input clk,
    input reset,
    input wr,
    input rd,
    output [ADDR_WIDTH-1:0]waddr,
    output [ADDR_WIDTH-1:0]raddr,
    output full,
    output empty
);
    //1bit state output
    reg full_reg, full_next, empty_reg, empty_next;
    
    //manage w,r address
    reg [ADDR_WIDTH-1:0] wptr_reg, wptr_next, rptr_reg, rptr_next;
    assign waddr = wptr_reg;
    assign raddr = rptr_reg;
    assign full = full_reg;
    assign empty = empty_reg;
    
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            full_reg <= 0;
            empty_reg <= 1;
            wptr_reg <= 0;
            rptr_reg <= 0;
        end
        else begin
            full_reg <= full_next;
            empty_reg <= empty_next;
            wptr_reg <= wptr_next;
            rptr_reg <= rptr_next;
        end
    end

    always @(*) begin
        full_next = full_reg;
        empty_next = empty_reg;
        wptr_next = wptr_reg;
        rptr_next = rptr_reg;
        case ({wr,rd})  
            2'b01: begin
                if(empty_reg == 0) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 0;
                    if(wptr_reg == rptr_next) begin
                        empty_next = 1;
                    end 
                end
            end
            2'b10: begin
                if(full_reg == 0) begin
                    wptr_next = wptr_reg + 1;
                    empty_next = 0;
                    if(rptr_reg == wptr_next) begin
                        full_next = 1;
                    end
                end
            end
            2'b11: begin
                if(empty_reg == 1) begin
                    wptr_next = wptr_reg + 1;
                    empty_next = 0;
                end
                else if (full_reg == 1) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 0;
                end
                else begin
                    wptr_next = wptr_reg + 1;
                    rptr_next = rptr_reg + 1;
                end
            end
        endcase
    end
endmodule