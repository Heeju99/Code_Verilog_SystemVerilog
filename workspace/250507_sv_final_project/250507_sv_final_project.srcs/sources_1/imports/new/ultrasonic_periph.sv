`timescale 1ns / 1ps

module ultrasonic_periph(
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,

    // export signals
    output logic        trigger,
    input  logic        echo,
    //additional
    output logic  [8:0] distance
);
    logic        fcr_en;
    //for tb
    //logic  [8:0] distance;
    logic        echo_done;

    APB_SlaveIntf_sensor U_APB_Intf_sensor (.*);
    sensor_dp U_sensor_IP (.*);
endmodule

module APB_SlaveIntf_sensor (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // internal signals
    output logic        fcr_en,
    input  logic [ 8:0] distance,
    //additional
    input  logic        echo_done
);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2;//, slv_reg3;

    assign fcr_en = slv_reg0[0];   // 출력 여부 사용 (1: 사용 , 0: 비활성화)
    assign slv_reg1[8:0] = distance;
    assign slv_reg2[0] = echo_done;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0; //fcr_en
            //slv_reg1 <= 0; //dist
            //slv_reg2 <= 0; 
            // slv_reg3 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                    if (PWRITE) begin
                        case (PADDR[3:2])
                            2'd0: slv_reg0 <= PWDATA;   //fcr_en
                            2'd1: ;                     //dist
                            2'd2: ;                     //echo_done
                            // 2'd3: slv_reg3 <= PWDATA;
                        endcase
                    end else begin
                        PRDATA <= 32'bx;
                            case (PADDR[3:2])
                                2'd0: PRDATA <= slv_reg0;  //fcr_en
                                2'd1: PRDATA <= slv_reg1;  //dist
                                2'd2: PRDATA <= slv_reg2;  
                                // 2'd3: PRDATA <= slv_reg3;
                        endcase
                    end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end

endmodule

module sensor_dp(
    input  logic PCLK,
    input  logic PRESET,
    input  logic echo,
    //input btn_start,
    //additional
    input  logic fcr_en,
    output logic trigger,
    output logic [8:0] distance,
    //additional
    output logic echo_done
    );

    clk_div_100 u_clk_div_100(
    .clk(PCLK), 
    .reset(PRESET),
    .o_tick(o_tick)
);

    parameter IDLE = 2'b00, START = 2'b01, HIGH_COUNT = 2'b10, DIST_CAL = 2'b11;
    logic [1:0] state, next;
    logic trigger_reg, trigger_next; //tick register
    logic trigger_1us_reg, trigger_1us_next;
    logic [3:0] tick_count_reg, tick_count_next;
    logic [14:0]tick_1us_count_reg, tick_1us_count_next; 
    logic [8:0] dist_reg, dist_next;
    //additional
    logic echo_done_reg, echo_done_next;

    assign echo_done = echo_done_reg;
    assign trigger = trigger_reg;
    assign distance = dist_reg;
    always_ff@(posedge PCLK, posedge PRESET)
        begin
            if(PRESET) begin
                state <= 0;
                tick_count_reg <= 0;
                tick_1us_count_reg <= 0;
                trigger_reg <= 0;
                trigger_1us_reg <=0;
                dist_reg <= 0;
                echo_done_reg <= 0; 
            end
            else begin
                state <= next;
                tick_count_reg <= tick_count_next;
                tick_1us_count_reg <= tick_1us_count_next;
                trigger_reg <= trigger_next;
                trigger_1us_reg <= trigger_1us_next;
                dist_reg <= dist_next;
                echo_done_reg <= echo_done_next;
            end
        end

    always_comb begin
        next = state;
        trigger_next = trigger_reg;
        trigger_1us_next = trigger_1us_reg;
        tick_count_next = tick_count_reg;
        tick_1us_count_next = tick_1us_count_reg;
        dist_next = dist_reg;
        //additional
        echo_done_next = echo_done_reg;
            case(state)
                IDLE: begin
                    trigger_next = 0;
                    echo_done_next = 0;
                    if(fcr_en) begin
                        next = START;
                    end
                end
                START : begin
                    if(o_tick) begin
                        if(tick_count_reg == 10) begin
                            trigger_next = 0;
                            tick_count_next = 0;
                         
                            next = HIGH_COUNT;
                       
                        end else begin
                            trigger_next = 1;
                            tick_count_next = tick_count_reg + 1;
                        end
                    end
                end
                HIGH_COUNT : begin
                    dist_next = 0; 
                    tick_1us_count_next = 0;
                    if(echo) begin
                        next = DIST_CAL;
                    end
                end
                DIST_CAL : begin
                    if(o_tick) begin
                        tick_1us_count_next = tick_1us_count_reg + 1;   
                    end
                    if(echo == 0) begin
                        echo_done_next = 1;
                        if(dist_reg > 400) begin
                            dist_next = 400;
                        end else if (tick_1us_count_reg > 23500)begin
                            next = IDLE;
                        end else begin
                            dist_next = tick_1us_count_reg /58;
                            next = IDLE;
                        end
                    end
                end
        endcase
    end
endmodule

module clk_div_100(
    input  logic clk,
    input  logic reset,
    output logic o_tick
);
    parameter FCOUNT = 100; //1us tick generate
    logic [$clog2(FCOUNT)-1:0] count_reg, count_next;
    logic tick_reg, tick_next; 

    assign o_tick = tick_reg;

    always_ff @(posedge clk, posedge reset) begin
        if(reset) begin
            count_reg <= 0;
            tick_reg <= 0;
        end else begin 
            count_reg <= count_next;
            tick_reg <= tick_next;
        end
    end

    always_comb begin
        count_next = count_reg;
        tick_next = 1'b0; // clk_reg;
            if(count_reg == (FCOUNT - 1)) begin
                count_next = tick_reg;
                tick_next = 1'b1; // 출력 high
            end else begin
                count_next = count_reg + 1;
                tick_next = 1'b0;
            end 
    end
endmodule