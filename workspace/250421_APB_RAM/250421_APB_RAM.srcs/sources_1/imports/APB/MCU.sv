`timescale 1ns / 1ps

module MCU (
    input logic clk,
    input logic reset,
    output logic [7:0] GPOA
);
    logic [31:0] instrCode;
    logic [31:0] instrMemAddr;

    //global Signals
    logic        PCLK;
    logic        PRESET;
    // APB Interface Signals
    logic [31:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PENABLE;
    logic        PSEL_RAM;
    logic        PSEL_GPO;
    logic        PSEL2;
    logic        PSEL3;
    logic [31:0] PRDATA_RAM;
    logic [31:0] PRDATA_GPO;
    logic [31:0] PRDATA2;
    logic [31:0] PRDATA3;
    logic        PREADY_RAM;
    logic        PREADY_GPO;
    logic        PREADY2;
    logic        PREADY3;

    //CPU - APB_Master signals
    // Internal Interface Signals
    logic        transfer;  // trigger signal
    logic        ready;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic        write;      // 1:write, 0:read
    logic        dataWe;
    logic [31:0] dataAddr;
    logic [31:0] dataWData;
    logic [31:0] dataRData;

    assign PCLK = clk;
    assign PRESET = reset;
    assign addr = dataAddr;
    assign wdata = dataWData;
    assign dataRData = rdata;
    assign write = dataWe;

    RV32I_Core U_Core (.*);

    rom U_ROM (
        .addr(instrMemAddr),
        .data(instrCode)
    );

    ram U_RAM (
        .*,
        .PSEL(PSEL_RAM),
        .PRDATA(PRDATA_RAM),
        .PREADY(PREADY_RAM)
    );

    APB_Master U_APB_Master (
        .*,
        .PSEL0(PSEL_RAM),
        .PSEL1(PSEL_GPO),
        .PSEL2(),
        .PSEL3(),
        .PRDATA0(PRDATA_RAM),
        .PRDATA1(PRDATA_GPO),
        .PRDATA2(),
        .PRDATA3(),
        .PREADY0(PREADY_RAM),
        .PREADY1(PREADY_GPO),
        .PREADY2(),
        .PREADY3()
    );

    GPO_Periph U_GPOA(
        .*,
        .PSEL(PSEL_GPO),
        .PRDATA(PRDATA_GPO),
        .PREADY(PREADY_GPO),
    // export signals
        .outPort(GPOA) 
);

endmodule
