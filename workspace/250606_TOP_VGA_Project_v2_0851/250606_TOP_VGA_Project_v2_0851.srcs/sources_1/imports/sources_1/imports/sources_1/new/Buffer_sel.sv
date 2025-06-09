`timescale 1ns / 1ps

module Buffer_sel (
    input  logic pclk,
    input  logic reset,
    input  logic v_sync,
    output logic en
);

    logic v_sync_d1, v_sync_d2;

    always_ff @(posedge pclk) begin
        if (reset) begin
            v_sync_d1 <= 0;
            v_sync_d2 <= 0;
            en        <= 0;
        end else begin
            v_sync_d1 <= v_sync;
            v_sync_d2 <= v_sync_d1;

            // rising edge detect
            if (~v_sync_d2 && v_sync_d1)
                en <= ~en;
        end
    end

endmodule
