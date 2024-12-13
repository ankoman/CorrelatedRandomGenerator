`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2024/12/11
// Module Name: ML_KEM
// Target Devices: U250
// Tool Versions: Vivado 2024.1
//////////////////////////////////////////////////////////////////////////////////


module ML_KEM 
     import TYPES_KEM::*;
    (
        input clk_i,
        input rst_n_i,
        input run_i,
        input kem_mode_t mode_i
    );

    kem_mode_t done, en_kem_funcs_o, en_kem_funcs_prev;
    wire run_keygen, run_encap, run_decap;

    always_ff @(posedge clk_i) begin
        en_kem_funcs_prev <= en_kem_funcs_o;
    end
    assign run_keygen = ({en_kem_funcs_prev[2], en_kem_funcs_o[2]} == 2'b01) ? 1'b1 : 1'b0; // Rising edge
    assign run_encap  = ({en_kem_funcs_prev[1], en_kem_funcs_o[1]} == 2'b01) ? 1'b1 : 1'b0; // Rising edge
    assign run_decap  = ({en_kem_funcs_prev[0], en_kem_funcs_o[0]} == 2'b01) ? 1'b1 : 1'b0; // Rising edge

    FSM_KEM u_fsm_kem (
        .clk_i,
        .rst_n_i,
        .run_i,
        .mode_i,
        .done_i(done),
        .en_kem_funcs_o
    );

    kem_module_t en_kem_modules_o, en_kem_modules_prev, module_done;
    wire run_trng, run_sampler, run_ntt;
    wire [1:0] sel_keygen, sel_all;
    assign sel_all = sel_keygen;

    always_ff @(posedge clk_i) begin
        en_kem_modules_prev <= en_kem_modules_o;
    end
    assign run_trng     = ({en_kem_modules_prev[2], en_kem_modules_o[2]} == 2'b01) ? 1'b1 : 1'b0; // Rising edge
    assign run_sampler  = ({en_kem_modules_prev[1], en_kem_modules_o[1]} == 2'b01) ? 1'b1 : 1'b0; // Rising edge
    assign run_ntt      = ({en_kem_modules_prev[0], en_kem_modules_o[0]} == 2'b01) ? 1'b1 : 1'b0; // Rising edge

    FSM_KEM_KEYGEN u_fsm_kem_keygen (
        .clk_i,
        .rst_n_i,
        .run_i(run_keygen),
        .module_done_i(module_done),
        .done_o(done.keygen),
        .sel_o(sel_keygen),
        .en_kem_modules_o
    );

    logic [255:0] trng_out, r_z, r_d;

    TRNG_256 u_trng(
        .clk_i,
        .rst_n_i,
        .run_i(run_trng),
        .dvld_o(module_done.trng),
        .dout_o(trng_out)
    );

    always_ff @(posedge clk_i) begin : DEMUX_TRNG
        if(!rst_n_i) begin
            r_d <= '0;
            r_z <= '0;
        end
        else begin
            if(module_done.trng) begin
                if(sel_all[0]) 
                    r_z <= trng_out;
                else
                    r_d <= trng_out;
            end
        end
    end

endmodule

module FSM_KEM
     import TYPES_KEM::*;
    (
        input clk_i,
        input rst_n_i,
        input run_i,
        input kem_mode_t mode_i,
        input kem_mode_t done_i,
        output kem_mode_t en_kem_funcs_o
    );

    typedef enum logic [2:0] {
        IDLE, KEYGEN, ENCAP, DECAP, WAIT4DECAP
    } state_kem_t;

    state_kem_t current_state, next_state;

    always_comb begin : FSM_KEM
        next_state = current_state;     //default
        case (current_state)
            IDLE: begin
                if (run_i)
                    next_state = (mode_i.keygen == 1'b1) ? KEYGEN : (mode_i.encap == 1'b1) ? ENCAP : IDLE;
            end
            KEYGEN: begin
                if (done_i.keygen)
                    next_state = WAIT4DECAP;
            end
            WAIT4DECAP: begin
                if (run_i)
                    next_state = (mode_i.decap == 1'b1) ? DECAP : IDLE;
            end
            DECAP: begin
                if (done_i.decap)
                    next_state = IDLE;
            end
            ENCAP: begin
                if (done_i.encap)
                    next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    always_ff @(posedge clk_i) begin : FSM_KEM_update
        if (!rst_n_i)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    always_comb begin : FSM_KEM_output
        case (current_state)
            KEYGEN:  en_kem_funcs_o = 3'b100;
            ENCAP:   en_kem_funcs_o = 3'b010;
            DECAP:   en_kem_funcs_o = 3'b001;
            default: en_kem_funcs_o = 3'b000; // default
        endcase
    end
endmodule

module FSM_KEM_KEYGEN
     import TYPES_KEM::*;
    (
        input clk_i,
        input rst_n_i,
        input run_i,
        input kem_module_t module_done_i,
        output done_o,
        output logic [1:0] sel_o,
        output kem_module_t en_kem_modules_o
    );

    typedef enum logic [3:0] {
        IDLE, TRNG1, TRNG2, WAIT1
    } state_kem_keygen_t;

    state_kem_keygen_t current_state, next_state;

    always_comb begin : FSM_KEM_KEYGEN
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (run_i)
                    next_state = TRNG1;
            end
            TRNG1: begin
                if (module_done_i.trng)
                    next_state = WAIT1;
            end
            WAIT1: begin    // This state is for updating en_kem_modules_o. Consecutive execution TRNG1 and TRNG2 never updates en_kem_modules_o.
                next_state = TRNG2;
            end
            TRNG2: begin
                if (module_done_i.trng)
                    next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    always_ff @(posedge clk_i) begin : FSM_KEM_KEYGEN_update
        if (!rst_n_i)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    always_comb begin : FSM_KEM_KEYGEN_en_output
        case (current_state)
            TRNG1:   en_kem_modules_o = 3'b100;
            TRNG2:   en_kem_modules_o = 3'b100;
            default: en_kem_modules_o = 3'b000; // default
        endcase
    end

    always_comb begin : FSM_KEM_KEYGEN_sel_output
        case (current_state)
            TRNG1:   sel_o = 2'b00;
            TRNG2:   sel_o = 2'b01;
            default: sel_o = 2'b00; // default
        endcase
    end

endmodule
