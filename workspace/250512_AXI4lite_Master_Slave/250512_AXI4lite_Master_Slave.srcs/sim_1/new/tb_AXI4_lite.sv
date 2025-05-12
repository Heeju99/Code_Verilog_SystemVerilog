`timescale 1ns / 1ps

module tb_AXI4_lite();
    // Global Signal
    logic ACLK;
    logic ARESETn;
    // WRITE Transaction, AW Channel
    logic [3:0]  AWADDR;
    logic        AWVALID;
    logic        AWREADY;
    // WRITE Transaction, W Channel
    logic [31:0] WDATA;
    logic        WVALID;
    logic        WREADY;
    // WRITE Transaction, B Channel
    logic [1:0]  BRESP;
    logic        BVALID;
    logic        BREADY;
    // READ Transaction, AR Channel
    logic [3:0] ARADDR; 
    logic       ARVALID; 
    logic       ARREADY; 

    // READ Transaction, R Channel
    logic [31:0] RDATA;
    logic        RVALID;
    logic        RREADY;

    // internal Signals
    logic        transfer;
    logic        ready;
    logic [ 3:0] addr;
    logic [31:0] wdata;
    logic        write;
    logic [31:0] rdata;

    AXI4_lite_Master dut_master(.*);
    AXI4_lite_Slave dut_slave(.*);

    always #5 ACLK = ~ACLK;

    initial begin
        ACLK = 0;
        ARESETn = 0;
        #10 ARESETn = 1;

        @(posedge ACLK);
        #1; addr = 0; wdata = 10; write = 1; transfer = 1;
        @(posedge ACLK);
        #1; transfer = 0;
        wait(ready == 1);

        @(posedge ACLK);
        #1; addr = 4; wdata = 11; write = 1; transfer = 1;
        @(posedge ACLK);
        #1; transfer = 0;
        wait(ready == 1);

        @(posedge ACLK);
        #1; addr = 8; wdata = 12; write = 1; transfer = 1;
        @(posedge ACLK);
        #1; transfer = 0;
        wait(ready == 1);
        
        @(posedge ACLK);
        #1; addr = 12; wdata = 13; write = 1; transfer = 1;
        @(posedge ACLK);
        #1; transfer = 0;
        wait(ready == 1);

        //read
        @(posedge ACLK);
        #1; addr = 12; write = 0; transfer = 1;
        @(posedge ACLK);
        #1; transfer = 0;
        wait(ready == 1);

        @(posedge ACLK);
        #1; addr = 8; write = 0; transfer = 1;
        @(posedge ACLK);
        #1; transfer = 0;
        wait(ready == 1);

        @(posedge ACLK);
        #1; addr = 4; write = 0; transfer = 1;
        @(posedge ACLK);
        #1; transfer = 0;
        wait(ready == 1);

        @(posedge ACLK);
        #1; addr = 0; write = 0; transfer = 1;
        @(posedge ACLK);
        #1; transfer = 0;
        wait(ready == 1);

        #100;
    end
endmodule
