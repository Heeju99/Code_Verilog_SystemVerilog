`timescale 1ns / 1ps

module frame_buffer_top (
    // write side
    input  logic        wclk,
    input  logic        reset,
    input  logic        we,
    input  logic [16:0] wAddr1,
    input  logic [16:0] wAddr2,
    input  logic [15:0] wData,
    // read side
    input  logic        rclk,
    input  logic        oe,
    input  logic [16:0] rAddr1,
    input  logic [16:0] rAddr2,
    output logic [11:0] rData_real,
    output logic [11:0] rData_diff1,
    output logic [11:0] rData_diff2,
    input  logic        v_sync
);

    logic en;

    Buffer_sel U_Buffer_sel (
        .pclk(wclk),
        .reset(reset),
        .v_sync(v_sync),
        .en(en)
    );

    // Dual-port Frame Buffer
    Frame_Buffer U_Frame_Buffer_real (
        .wclk (wclk),
        .we   (we),
        .wAddr(wAddr1),
        .wData(wData),
        .rclk (rclk),
        .oe   (oe),
        .rAddr(rAddr1),
        .rData(rData_real)
    );

    Frame_Buffer_QQQ U_Frame_Buffer1 (
        .wclk (wclk),
        .we   (we && en),
        .wAddr(wAddr2),
        .wData(wData),
        .rclk (rclk),
        .oe   (oe),
        .rAddr(rAddr2),
        .rData(rData_diff1)
    );

    Frame_Buffer_QQQ U_Frame_Buffer2 (
        .wclk (wclk),
        .we   (we && ~en),
        .wAddr(wAddr2),
        .wData(wData),
        .rclk (rclk),
        .oe   (oe),
        .rAddr(rAddr2),
        .rData(rData_diff2)
    );

endmodule


module Frame_Buffer_QQQ (
    // write side
    input  logic        wclk,
    input  logic        we,
    input  logic [16:0] wAddr,
    input  logic [15:0] wData,
    // read side
    input  logic        rclk,
    input  logic        oe,
    input  logic [16:0] rAddr,
    output logic [11:0] rData
);
    logic [11:0] wData_12bit;
    logic [11:0] mem[0:(80*60-1)];

    assign wData_12bit = {wData[15:12], wData[10:7], wData[4:1]};

    // write side
    always_ff @(posedge wclk) begin : write_side
        if (we) begin
            mem[wAddr] <= wData_12bit;
        end
    end

    // read side(Asynchronous)
    always_ff @( posedge rclk ) begin : blockName
        if(oe) begin
            rData <= mem[rAddr];
        end
    end
endmodule