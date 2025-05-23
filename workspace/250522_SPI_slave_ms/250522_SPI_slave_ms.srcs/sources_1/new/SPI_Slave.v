`timescale 1ns / 1ps

module SPI_Slave (
    input  clk,
    input  reset,
    input  SCLK,
    input  MOSI,
    output MISO,
    input  SS,
    input  done,
    output [7:0] led
);

    wire [7:0] si_data;
    wire       si_done;
    wire [7:0] so_data;
    wire       so_start;
    wire       so_done;

    SPI_Slave_Intf U_SPI_Slave_Intf (
        .clk     (clk),
        .reset   (reset),
        .SCLK    (SCLK),
        .MOSI    (MOSI),
        .MISO    (MISO),
        .SS      (SS),
        .si_data (si_data),
        .si_done (si_done),
        .so_data (so_data),
        .so_start(so_start),
        .so_done (so_done)
    );

    SPI_Slave_Reg U_SPI_Slave_Reg (
        .clk     (clk),
        .reset   (reset),
        .SS      (SS),
        .si_data (si_data),
        .si_done (si_done),
        .so_data (so_data),
        .so_start(so_start),
        .so_done (so_done),
        .done(done)
        // input            so_ready
    );

    SPI_Slave_Reg_led U_SPI_Slave_Reg_led(
        .clk(clk),
        .reset(reset),
        .so_data(so_data),
        .led(led)
);

endmodule

module SPI_Slave_Intf (
    // global singals
    input        clk,
    input        reset,
    // SPI signals
    input        SCLK,
    input        MOSI,
    output       MISO,
    input        SS,
    //internal signals
    output [7:0] si_data,
    output       si_done,
    input  [7:0] so_data,
    input        so_start,
    input        so_done
);

    reg sclk_sync0, sclk_sync1;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            sclk_sync0 <= 0;
            sclk_sync1 <= 0;
        end else begin
            sclk_sync0 <= SCLK;
            sclk_sync1 <= sclk_sync0;
        end
    end

    wire sclk_rising, sclk_falling;
    // assign sclk_rising  = sclk_sync0 & ~sclk_sync1;
    // assign sclk_falling = ~sclk_sync0 & sclk_sync1;
    assign sclk_rising  = SCLK & ~sclk_sync0;
    assign sclk_falling = ~SCLK & sclk_sync0;

    // Slave Input Circuit (MOSI)
    localparam SI_IDLE = 0, SI_PHASE = 1;

    reg si_state, si_state_next;
    reg [7:0] si_data_reg, si_data_next;
    reg [2:0] si_bit_cnt_reg, si_bit_cnt_next;
    reg si_done_reg, si_done_next;

    assign si_data = si_data_reg;
    assign si_done = si_done_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            si_state       <= SI_IDLE;
            si_data_reg    <= 0;
            si_bit_cnt_reg <= 0;
            si_done_reg    <= 0;
        end else begin
            si_state       <= si_state_next;
            si_data_reg    <= si_data_next;
            si_bit_cnt_reg <= si_bit_cnt_next;
            si_done_reg    <= si_done_next;
        end
    end

    always @(*) begin
        si_state_next   = si_state;
        si_data_next    = si_data_reg;
        si_bit_cnt_next = si_bit_cnt_reg;
        si_done_next    = 0;
        case (si_state)
            SI_IDLE: begin
                if (!SS) begin
                    si_bit_cnt_next = 0;
                    si_state_next   = SI_PHASE;
                end
            end
            SI_PHASE: begin
                if (!SS) begin
                    if (sclk_rising) begin
                        si_data_next = {si_data_reg[6:0], MOSI};
                        if (si_bit_cnt_reg == 7) begin
                            si_done_next    = 1'b1;
                            si_bit_cnt_next = 0;
                            si_state_next   = SI_IDLE;
                        end else begin
                            si_bit_cnt_next = si_bit_cnt_reg + 1;
                        end
                    end
                end else begin
                    si_state_next = SI_IDLE;
                end
            end
        endcase
    end

    // Slave Output Circuit(MISO)
    localparam SO_IDLE = 0, SO_WAIT = 1, SO_PHASE = 2;

    reg [1:0] so_state, so_state_next;
    reg [7:0] so_data_reg, so_data_next;
    reg [2:0] so_bit_cnt_reg, so_bit_cnt_next;
    reg so_done_reg, so_done_next;

    assign so_done = so_done_reg;
    assign MISO = ~SS ? so_data_reg[7] : 1'bz;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            so_state       <= SO_IDLE;
            so_data_reg    <= 0;
            so_bit_cnt_reg <= 0;
            so_done_reg    <= 0;
        end else begin
            so_state       <= so_state_next;
            so_data_reg    <= so_data_next;
            so_bit_cnt_reg <= so_bit_cnt_next;
            so_done_reg    <= so_done_next;
        end
    end

    always @(*) begin
        so_state_next   = so_state;
        so_data_next    = so_data_reg;
        so_bit_cnt_next = so_bit_cnt_reg;
        so_done_next    = 0;
        case (so_state)
            SO_IDLE: begin
                if (!SS && so_start) begin
                    so_bit_cnt_next = 0;
                    so_state_next   = SO_WAIT;
                end
            end
            SO_WAIT: begin
                so_data_next    = so_data;
                so_state_next = SO_PHASE;
            end
            SO_PHASE: begin
                if (!SS) begin
                    // MISO = so_data_next[7];
                    if (sclk_falling) begin
                        so_data_next = {so_data_reg[6:0], 1'b0};
                        if (so_bit_cnt_reg == 7) begin
                            so_done_next    = 1'b1;
                            so_bit_cnt_next = 0;
                            so_state_next   = SO_IDLE;
                        end else begin
                            so_bit_cnt_next = so_bit_cnt_reg + 1;
                        end
                    end
                end else begin
                    so_state_next = SO_IDLE;
                end
            end
        endcase
    end
endmodule

module SPI_Slave_Reg (
    // global signals
    input            clk,
    input            reset,
    // internal signals
    input            SS,
    input      [7:0] si_data,
    input            si_done,
    output reg [7:0] so_data,
    output           so_start,
    input            so_done,
    input            done
    // input            so_ready
);
    localparam IDLE = 0, ADDR_PHASE = 1, WRITE_PHASE = 2, READ_PHASE = 3;

    reg [1:0] state, state_next;
    reg [7:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;
    reg [1:0] addr_reg, addr_next;
    reg so_start_reg, so_start_next;

    assign so_start = so_start_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            addr_reg     <= 0;
            so_start_reg <= 0;
        end else begin
            state        <= state_next;
            addr_reg     <= addr_next;
            so_start_reg <= so_start_next;
        end
    end

    always @(*) begin
        state_next    = state;
        addr_next     = addr_reg;
        so_start_next = so_start_reg;
        case (state)
            IDLE: begin
                so_start_next = 1'b0;
                if (!SS) begin
                    state_next = ADDR_PHASE;
                end
            end
            ADDR_PHASE: begin
                if (!SS) begin
                    if (si_done) begin
                        addr_next = si_data[1:0];
                        if (si_data[7]) begin
                            state_next = WRITE_PHASE;
                        end else begin
                            state_next = READ_PHASE;
                        end
                    end
                end else begin
                    state_next = IDLE;
                end
            end
            WRITE_PHASE: begin
                if (!SS) begin
                    if (si_done) begin
                        case (addr_reg)
                            2'd0: slv_reg0 = si_data;
                            2'd1: slv_reg1 = si_data;
                            2'd2: slv_reg2 = si_data;
                            2'd3: slv_reg3 = si_data;
                        endcase
                        if (addr_reg == 2'd3) begin
                            addr_next = 0;
                        end else begin
                            addr_next = addr_reg + 1;
                        end
                    end
                end else begin
                    state_next = IDLE;
                end
            end
            READ_PHASE: begin
                if (!SS) begin
                    // if (so_ready) begin
                    if(done) begin
                        so_start_next = 1'b1;
                    end
                    case (addr_reg)
                        2'd0: so_data = slv_reg0;
                        2'd1: so_data = slv_reg1;
                        2'd2: so_data = slv_reg2;
                        2'd3: so_data = slv_reg3;
                    endcase
                    // end
                    if (so_done) begin
                        if (addr_reg == 2'd3) begin
                            addr_next = 0;
                        end else begin
                            addr_next = addr_reg + 1;
                        end
                    end
                end else begin
                    state_next = IDLE;
                end

            end
        endcase
    end
endmodule

module SPI_Slave_Reg_led (
    // global signals
    input            clk,
    input            reset,
    // internal signals
    input  [7:0] so_data,
    output  [7:0]    led
    // input            so_ready
);

    assign led[7:0] = so_data[7:0]; 
endmodule
