`timescale 1ns / 1ps

module tb_memory();
    
    parameter DATA_WIDTH = 8, ADDR_WIDTH = 4;
    reg clk, wr;
    reg [DATA_WIDTH-1:0] wdata;
    reg [ADDR_WIDTH-1:0] waddr;
    wire [DATA_WIDTH-1:0] rdata;

    ram_ip dut(
    .clk(clk),
    .waddr(waddr),
    .wdata(wdata),
    .wr(wr),
    .rdata(rdata)
    );

    always #5 clk = ~clk;
    integer  i;
    reg [DATA_WIDTH-1:0] random_data; //난수 저장용
    reg [ADDR_WIDTH-1:0] random_addr;

    initial begin
        clk = 0;
        waddr = 0;
        wdata = 0;
        wr = 0;

        #10;
        for(i=0; i<50; i= i+1) begin
            @(posedge clk);
            // 난수 발생기
            random_addr = $random%16;  //난수 16 
            random_data = $random%256; //난수의 모수가 256
            //쓰기 주소 설정
            wr = 1;
            waddr = random_addr;
            wdata = random_data;
            //한클럭 기다리기(이벤트 제어문)
            @(posedge clk);
            // 읽기전용 주소 설정 한번 더!!!!
            waddr = random_addr;
            #10;
            // == 값비교, === case 비교 (0,1,z 다 비교)
            if(rdata === wdata) begin //출력 데이터가 write 데이터랑 같은지 비교
                $display("pass");
            end else begin
                $display("fail addr = %d, data = %h", waddr, rdata);
            end
        end
        #100;
        $stop;
    end
endmodule
