`timescale 1ns / 1ps

module ram_ip #(parameter ADDR_WIDTH = 4, DATA_WIDTH = 8)(
    input clk,
    input [ADDR_WIDTH -1:0] waddr,
    input [DATA_WIDTH -1:0] wdata,
    input wr,
    output [DATA_WIDTH-1:0] rdata
    );

    reg [DATA_WIDTH-1:0] ram[0:2**ADDR_WIDTH-1]; //2의 4승은 메모리의 주소 수(배열의 크기)
    reg [DATA_WIDTH-1:0] rdata_reg;
    //write mode
    always@(posedge clk)
        begin
            if(wr) begin 
                ram[waddr] <= wdata;
            end
        end
    assign rdata = ram[waddr];        
    /*
    assign r_data = rdata_reg;
    //read mode 
    always@(posedge clk)
        begin
            if(!wr) begin
                rdata_reg <= ram[waddr];
            end
        end
        */
endmodule
