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


endmodule

module FSM_KEM
     import TYPES_KEM::*;
    (
        input clk_i,
        input rst_n_i,
        input run_i,
        input kem_mode_t mode_i,
        input kem_mode_t done_i,
        output kem_mode_t en_kem_modules_o
    );

    typedef enum logic [2:0] {
        IDLE, KEYGEN, ENCAP, DECAP, WAIT4DECAP
    } state_kem_t;

    state_kem_t current_state, next_state;

    always_comb begin : FSM_KEM
        next_state = current_state;
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
            KEYGEN:  en_kem_modules_o = 3'b100;
            ENCAP:   en_kem_modules_o = 3'b010;
            ENCAP:   en_kem_modules_o = 3'b001;
            default: en_kem_modules_o = 3'b000; // default
        endcase
    end
endmodule

module FSM_KEM_KEYGEN
     import TYPES_KEM::*;
    (
        input clk_i,
        input rst_n_i,
        input run_i,
        output done_o
    );

    typedef enum logic [3:0] {
        IDLE, TRNG1, TRNG2,
    } state_kem_keygen_t;

    state_kem_t current_state, next_state;

    always_comb begin : FSM_KEM_KEYGEN
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (run_i)
                    next_state = TRNG1;
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

    always_comb begin : FSM_KEM_KEYGEN_output
        case (current_state)
            KEYGEN:  en_kem_modules_o = 3'b100;
            ENCAP:   en_kem_modules_o = 3'b010;
            ENCAP:   en_kem_modules_o = 3'b001;
            default: en_kem_modules_o = 3'b000; // default
        endcase
    end
endmodule