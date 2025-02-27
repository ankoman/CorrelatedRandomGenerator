`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2025/02/21
// Module Name: LOM
// Target Devices: U250
// Tool Versions: Vivado 2024.1
//////////////////////////////////////////////////////////////////////////////////

// Linear Operation Module
module LOM 
     import TYPES_KEM::*;
    (
        input clk_i,
        input rst_n_i,
        input run_i,
        input poly_t [ML_KEM_K-1:0] polyvec_s_i,
        input poly_t [ML_KEM_K-1:0] polyvec_e_i,
        input poly_t [ML_KEM_K-1:0] polyvec_r_i,
        input poly_t [ML_KEM_K*ML_KEM_K-1:0] polymat_A_i,
        input poly_t [ML_KEM_K-1:0] polyvec_t_i,
        input kem_mode_t mode_i
    );

    typedef enum logic [3:0] {
        IDLE, 
        NTT_s, NTT_e, MUL_As,   // Keygen
        NTT_r,                  // Enc
        NTT_u                   // Dec
    } state_lom_t;

    state_lom_t current_state, next_state;
    wire run_submod = current_state != next_state;

    always_comb begin : FSM_LOM
        next_state = current_state;     //default
        case (current_state)
            IDLE: begin
                if (run_i)
                    next_state = (mode_i.keygen) ? NTT_s : (mode_i.encap) ? NTT_r : IDLE;
            end
            // Enc
            NTT_s: begin
                if (polyvec_ntt_done)
                    next_state = NTT_e;
            end
            NTT_e: begin
                if (polyvec_ntt_done)
                    next_state = MUL_As;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    always_ff @(posedge clk_i) begin : FSM_LOM_update
        if (!rst_n_i)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    logic [ML_KEM_K:0] sreg_k;
    wire polyvec_ntt_done = sreg_k[ML_KEM_K];

    always @(posedge clk_i) begin
        if(!rst_n_i) begin
            sreg_k <= '0;
        end
        else if (run_submod || 1) begin
            sreg_k <= {sreg_k[$bits(sreg_k)-2:0], run_submod};
        end
    end

    logic [8:0] cnt_256;
    wire cnt_256_busy = |cnt_256[7:0] || run_submod;
    wire cnt_256_done = cnt_256[8];

    always @(posedge clk_i) begin
        if(!rst_n_i || cnt_256_done)
            cnt_256 <= '0;
        else if (cnt_256_busy)
            cnt_256 <= cnt_256 + 1'b1;
    end

endmodule

module NTT_wrapper
     import TYPES_KEM::*;
    (
        input clk_i,
        input rst_n_i,
        input run_i,
        input poly_t poly_a_i,
        input poly_t poly_b_i,
        input ntt_mode_t mode_i,
        output poly_t poly_c_o,
        output done_o
    );

    logic load_a, load_b;
    assign load_a = run_i;
    assign load_b = cnt_256_done_d & (mode_i == PWM);

    logic [8:0] cnt_256;
    wire cnt_256_busy = |cnt_256[7:0] || run_i || done_nttmod_d;
    wire cnt_256_done = cnt_256[8];
    logic cnt_256_done_d, done_nttmod, done_nttmod_d;
    always @(posedge clk_i) begin
        cnt_256_done_d <= cnt_256_done;
        done_nttmod_d <= done_nttmod;
    end

    always @(posedge clk_i) begin
        if(!rst_n_i || cnt_256_done)
            cnt_256 <= '0;
        else if (cnt_256_busy)
            cnt_256 <= cnt_256 + 1'b1;
    end

    poly_t poly_in;
    wire [11:0] din = poly_in[255];
    always @(posedge clk_i)begin
        if(load_a)
            poly_in <= poly_a_i;
        else if (load_b)
            poly_in <= poly_b_i;
        else
            poly_in <= {poly_in[254:0], 12'd0};
    end

    logic [11:0] dout;
    always @(posedge clk_i) begin
        if(!rst_n_i)
            poly_c_o <= '0;
        else
            poly_c_o <= {dout, poly_c_o[255:1]};
    end

    logic state_is_ntt;
    //NTT module
    KyberHPM1PE u_NTT_pe1 (
        .clk(clk_i),
        .reset(!rst_n_i),
        .load_a_f(load_a),
        .load_a_i(1'b0),
        .load_b_f(load_b),
        .load_b_i(1'b0),
        .read_a(done_nttmod_d),
        .read_b(1'b0),
        .start_ab(1'b0),
        .start_fntt(cnt_256_done_d & state_is_ntt),
        .start_pwm2(1'b0),
        .start_intt(1'b0),
        .din,
        .dout,
        .done(done_nttmod)
    );

    //FSM
    typedef enum logic [2:0] {
        IDLE, LOAD_B, LOAD_A, NTT, INTT, PWM, READ_A
    } state_ntt_t;
    assign state_is_ntt = current_state == NTT;

    state_ntt_t current_state, next_state;

    always_comb begin : FSM_NTT
        next_state = current_state;     //default
        case (current_state)
            IDLE: begin
                if (run_i)
                    next_state = (mode_i == NTT_a) ? LOAD_A : IDLE;
            end
            LOAD_A: begin
                if (cnt_256_done)
                    next_state = NTT;
            end
            NTT: begin
                if (done_nttmod)
                    next_state = READ_A;
            end
            READ_A: begin
                if (cnt_256_done)
                    next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    always_ff @(posedge clk_i) begin : FSM_NTT_update
        if (!rst_n_i)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

endmodule

module FSM_NTT
     import TYPES_KEM::*;
    (
        input clk_i,
        input rst_n_i,
        input run_i,
        input ntt_mode_t mode_i,
        output kem_mode_t en_kem_funcs_o
    );


endmodule