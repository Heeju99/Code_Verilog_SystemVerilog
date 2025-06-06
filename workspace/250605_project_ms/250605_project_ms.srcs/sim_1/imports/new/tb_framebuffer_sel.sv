`timescale 1ns / 1ps

module tb_frame_buffer_top;

    // 신호 정의
    logic wclk, rclk, reset;
    logic we, oe;
    logic [16:0] wAddr, rAddr;
    logic [15:0] wData;
    logic [11:0] rData_real, rData_diff1, rData_diff2;
    logic v_sync;
    logic [16:0] addr_diff1_0, addr_diff1_1;
    logic [16:0] addr_diff2_0, addr_diff2_1;

    // DUT
    frame_buffer_top DUT (
        .wclk(wclk),
        .reset(reset),
        .we(we),
        .wAddr(wAddr),
        .wData(wData),
        .rclk(rclk),
        .oe(oe),
        .rAddr(rAddr),
        .rData_real(rData_real),
        .rData_diff1(rData_diff1),
        .rData_diff2(rData_diff2),
        .v_sync(v_sync)
    );

    // 클럭 생성
    initial begin
        wclk = 0; rclk = 0;
        forever #5 wclk = ~wclk;
    end

    initial begin
        forever #10 rclk = ~rclk;
    end

    // 시나리오
    initial begin
        // 초기화
        reset = 1;
        we = 0; oe = 0;
        v_sync = 0;
        wAddr = 0; rAddr = 0; wData = 0;
        #50;
        reset = 0;

        // ================================
        // ▶ Phase 1: diff1 write + read
        // ================================
        @(posedge wclk); v_sync = 1;  // en = 1 → diff1 활성화
        @(posedge wclk); v_sync = 0;

        @(posedge wclk); we = 1;
        wAddr = 17'd1000; addr_diff1_0 = wAddr;
        wData = 16'hAAAA;
        @(posedge wclk);
        wAddr = 17'd1001; addr_diff1_1 = wAddr;
        wData = 16'hA0A0;
        @(posedge wclk); we = 0;

        // 읽기: diff1
        #30;  // 여유
        oe = 1;
        rAddr = addr_diff1_0;
        repeat (2) @(posedge rclk);
        $display("[READ diff1-0 @ %t] real=%h, diff1=%h, diff2=%h", $time, rData_real, rData_diff1, rData_diff2);
        rAddr = addr_diff1_1;
        repeat (2) @(posedge rclk);
        $display("[READ diff1-1 @ %t] real=%h, diff1=%h, diff2=%h", $time, rData_real, rData_diff1, rData_diff2);
        oe = 0;

        // ================================
        // ▶ Phase 2: diff2 write + read
        // ================================
        @(posedge wclk); v_sync = 1;  // en 토글 → en = 0 → diff2 활성화
        @(posedge wclk); v_sync = 0;

        @(posedge wclk); we = 1;
        wAddr = 17'd2000; addr_diff2_0 = wAddr;
        wData = 16'hBBBB;
        @(posedge wclk);
        wAddr = 17'd2001; addr_diff2_1 = wAddr;
        wData = 16'hB0B0;
        @(posedge wclk); we = 0;

        // 읽기: diff2
        #30;
        oe = 1;
        rAddr = addr_diff2_0;
        repeat (2) @(posedge rclk);
        $display("[READ diff2-0 @ %t] real=%h, diff1=%h, diff2=%h", $time, rData_real, rData_diff1, rData_diff2);
        rAddr = addr_diff2_1;
        repeat (2) @(posedge rclk);
        $display("[READ diff2-1 @ %t] real=%h, diff1=%h, diff2=%h", $time, rData_real, rData_diff1, rData_diff2);
        oe = 0;

        // ================================
        // ▶ DONE
        // ================================
        $display("✅ Simulation completed at %t", $time);
        $finish;
    end

endmodule
