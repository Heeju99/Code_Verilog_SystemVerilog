`timescale 1ns / 1ps

module FIFO(
    input clk,
    input reset,
    //write
    input wr,
    input [7:0] wdata,
    output full,
    //read
    input rd,
    output [7:0] rdata,
    output empty

    );
    wire [3:0] w_waddr, w_raddr;

    register_file u_register_file(   // 그림 상 register Data_path
    .clk(clk),
    .wr({wr & ~full}),   //wr과 ~full의 AND연산으로 바꿔야함
    .waddr(w_waddr),
    .wdata(wdata),
    .raddr(w_raddr),
    .rdata(rdata)
);

    fifo_control_unit u_fifo_cu(
    .clk(clk),
    .reset(reset),
    .wr(wr),
    .waddr(w_waddr), //그림상 wptr과 동일
    .full(full),
    .rd(rd),
    .raddr(w_raddr), //그림상 rptr과 동일
    .empty(empty)
);

endmodule

module register_file(   // 그림 상 register Data_path
    input clk,
    input wr,
    input [3:0] waddr,
    input [7:0] wdata,
    //read
    input [3:0] raddr,
    output [7:0] rdata
);
    reg [7:0] mem [0:2**4-1]; //4bit address 저장소

    //write
    always@(posedge clk)
        if(wr == 1) begin
            mem[waddr] = wdata;
        end

    //read  그냥 읽기만 하면 됨
    assign rdata = mem[raddr];

endmodule

module fifo_control_unit(
    input clk,
    input reset,
    //write
    input wr,
    output [3:0] waddr, //그림상 wptr과 동일
    output full,
    //read
    input rd,
    output [3:0] raddr, //그림상 rptr과 동일
    output empty
);
    //output을 위한 FSM 구조
    reg full_reg, full_next;
    reg empty_reg, empty_next;
    // write or read address 관리용 
    reg [3:0] wptr_reg, wptr_next;
    reg [3:0] rptr_reg, rptr_next;

    assign waddr = wptr_reg;
    assign raddr = rptr_reg;
    assign full = full_reg;
    assign empty = empty_reg;

    //state
    always@(posedge clk, posedge reset)
        begin
            if(reset) begin
                full_reg <= 0;
                empty_reg <= 1;
                wptr_reg <= 0;
                rptr_reg <= 0;
            end else begin
                full_reg <= full_next;
                empty_reg <= empty_next;
                wptr_reg <= wptr_next;
                rptr_reg <= rptr_next;
            end    
        end

    //next
    always@(*)
        begin
            full_next = full_reg;
            empty_next = empty_reg;
            wptr_next = wptr_reg;
            rptr_next = rptr_reg;
            case({wr,rd})  //state 외부에서 입력으로 변경됨
                //rd가 1일 때, read
                2'b01: begin
                    if(empty_reg == 1'b0) begin
                        full_next = 1'b0;
                        rptr_next = rptr_reg + 1;
                        if(wptr_reg == rptr_next) begin
                            empty_next = 1'b1;
                        end
                    end
                end
                //wr가 1일 때, write
                2'b10: begin
                    if(full_reg == 1'b0) begin
                        empty_next = 1'b0;
                        wptr_next = wptr_reg + 1;
                        if(wptr_next == rptr_reg) begin
                            full_next = 1'b1;
                        end
                    end
                end 
                //rd, wr 둘 다 1일 때, read + write
                2'b11 : begin
                    //read, pop 먼저 조건
                    if(empty_reg == 1'b1) begin
                        wptr_next = wptr_reg + 1;
                        empty_next = 1'b0;
                    end else if(full_reg == 1'b1)begin
                        rptr_next = rptr_reg + 1;
                        full_next = 1'b0;
                    end else begin
                        wptr_next = wptr_reg + 1;
                        rptr_next = rptr_reg + 1;
                    end              
                end
            endcase 
        end
endmodule