`timescale 1ns / 1ps

module Buffer_sel (
    input  logic pclk,
    input  logic reset,
    input  logic v_sync,
    output logic en
);

    logic v_sync_d1, v_sync_d2;

    always_ff @(posedge pclk or posedge reset) begin
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

// module Buffer_sel(
//     input logic pclk,
//     input logic reset,
//     input logic v_sync,
//     output logic en
//     );

//     logic pre_v_sync, now_v_sync, done;

//     // assign done = !pre_v_sync && now_v_sync;

//     always_ff @( posedge pclk, posedge reset ) begin
//         if(reset) begin
//             pre_v_sync <= 1'b0;
//         end
//         else begin
//             pre_v_sync <= now_v_sync;
//         end
//     end

//     always_ff @( posedge pclk, posedge reset ) begin
//         if(reset) begin
//             en <= 1'b0;
//             now_v_sync <= 1'b0;
//         end
//         else begin
//             now_v_sync <= v_sync;
//             if(!pre_v_sync && now_v_sync) begin
//                 en <= ~en;
//             end
//             else begin
//                 en <= en;
//             end
//         end
//     end

// endmodule
