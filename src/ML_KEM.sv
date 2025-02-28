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
     import FUNCS::reverse_endian_256;
    (
        input clk_i,
        input rst_n_i,
        input run_i,
        input kem_mode_t mode_i
    );

    kem_mode_t done, en_kem_funcs_o, en_kem_funcs_prev, run_kem_func;;

    always_ff @(posedge clk_i) begin
        en_kem_funcs_prev <= en_kem_funcs_o;
    end
    assign run_kem_func = (~en_kem_funcs_prev) & en_kem_funcs_o;// Rising edge


    FSM_KEM u_fsm_kem (
        .clk_i,
        .rst_n_i,
        .run_i,
        .mode_i,
        .done_i(done),
        .en_kem_funcs_o
    );

    kem_module_t en_kem_modules_o, en_kem_modules_prev, module_done, run_module;
    wire [1:0] sel_keygen, sel_all;
    assign sel_all = sel_keygen;

    always_ff @(posedge clk_i) begin
        en_kem_modules_prev <= en_kem_modules_o;
    end
    assign run_module = (~en_kem_modules_prev) & en_kem_modules_o; // Rising edge

    FSM_KEM_KEYGEN u_fsm_kem_keygen (
        .clk_i,
        .rst_n_i,
        .run_i(run_kem_func.keygen),
        .module_done_i(module_done),
        .done_o(done.keygen),
        .sel_o(sel_keygen),
        .en_kem_modules_o
    );

    logic [255:0] trng_out, r_z, r_d;

    TRNG_256 u_trng(
        .clk_i,
        .rst_n_i,
        .run_i(run_module.trng),
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

    //Hash_G module
    logic [511:0] hash_G_out;
    logic [255:0] r_rho, r_sigma;

    hash_G_KEM u_hash_G(
         .clk_i,
         .rst_n_i,
         .run_i(run_module.hashG),
         .in_sel_i(sel_all), // 0: din = 32 bytes, i: din = 64 bytes
         .k_i(8'(ML_KEM_K)),    // 8 bits of ML_KEM_K
         .din_i((sel_all) ? 512'hx : {256'hx, reverse_endian_256(r_d)}),
         .done_o(module_done.hashG),
         .do_o(hash_G_out)
    );

    always_ff @(posedge clk_i) begin : DEMUX_hashG
        if(!rst_n_i) begin
            r_rho <= '0;
            r_sigma <= '0;
        end
        else begin
            if(module_done.hashG) begin
                {r_sigma, r_rho} <= hash_G_out;
            end
        end
    end

    //SampleA module
    sampleA uu0_sampleA(
        .clk_i,
        .rst_n_i,
        .run_i(run_module.sampleA),
        .rho_i(r_rho),
        .done_o(module_done.sampleA),
        .polymat_A_o()
    );

    //SampleCBD module
    poly_t [2*ML_KEM_K-1:0] w_polyvec, polyvec, polyvec_ntt;
    sampleCBD_2k u_sampleCBD_2k(
        .clk_i,
        .rst_n_i,
        .run_i(run_module.sampleCBD_2k),
        .seed_i(r_sigma),
        .eta_i(),    // 0: eta1, 1: eta2
        .done_o(module_done.sampleCBD_2k),
        .polyvec_o(polyvec) //  2k polynomials
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
        IDLE, TRNG1, TRNG2, WAIT1, GEN_SEED, SAMPLE_A, SAMPLE_CBD_2K, NTT
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
                    next_state = GEN_SEED;
            end
            GEN_SEED: begin
                if (module_done_i.hashG)
                    next_state = SAMPLE_A;
            end
            SAMPLE_A: begin
                if (module_done_i.sampleA)
                    next_state = SAMPLE_CBD_2K;
            end
            SAMPLE_CBD_2K: begin
                if (module_done_i.sampleCBD_2k)
                    next_state = NTT;
            end
            NTT: begin
                if (module_done_i.ntt)
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
            TRNG1:   en_kem_modules_o.trng = 1'b1;
            TRNG2:   en_kem_modules_o.trng = 1'b1;
            GEN_SEED:   en_kem_modules_o.hashG = 1'b1;
            SAMPLE_A:   en_kem_modules_o.sampleA = 1'b1;
            SAMPLE_CBD_2K:   en_kem_modules_o.sampleCBD_2k = 1'b1;
            NTT:   en_kem_modules_o.ntt = 1'b1;
            default: en_kem_modules_o = '0; // default
        endcase
    end

    always_comb begin : FSM_KEM_KEYGEN_sel_output
        case (current_state)
            TRNG1:   sel_o = 2'b00; //r_d
            TRNG2:   sel_o = 2'b01; //r_z
            GEN_SEED:   sel_o = 2'b00;
            default: sel_o = '0; // default
        endcase
    end

endmodule

module hash_G_KEM
     import TYPES_KEM::*;
    (
        input clk_i,
        input rst_n_i,
        input run_i,
        input in_sel_i, // 0: din = 32 bytes, i: din = 64 bytes
        input [7:0] k_i,    // 8 bits of ML_KEM_K
        input [7:0][63:0] din_i,
        output done_o,
        output [511:0] do_o
    );
    
    //SHA3-512
    keccak_1600_t hash_in, hash_out, hash_out_conv;
    logic [256+8-1:0] hash_msg_msb;
    logic [8:0][63:0] hash_pad_msg;
    assign hash_msg_msb = (in_sel_i) ? {8'h06, din_i[7:4]} : {248'd0, 8'h06, k_i};
    assign hash_pad_msg = {8'h80, 48'd0, hash_msg_msb, din_i[3:0]};
    assign hash_out_conv = keccak_1600_conv(hash_out);
    assign do_o = hash_out_conv[511:0];

    assign hash_in[0][0] = hash_pad_msg[0]; // [63:0]
    assign hash_in[1][0] = hash_pad_msg[1]; // [127:64]
    assign hash_in[2][0] = hash_pad_msg[2]; // [191:128]
    assign hash_in[3][0] = hash_pad_msg[3]; // [255:192]
    assign hash_in[4][0] = hash_pad_msg[4]; // [319:256]
    assign hash_in[0][1] = hash_pad_msg[5]; // [383:320]
    assign hash_in[1][1] = hash_pad_msg[6]; // [447:384]
    assign hash_in[2][1] = hash_pad_msg[7]; // [511:448]
    assign hash_in[3][1] = hash_pad_msg[8]; 
    assign hash_in[4][1] = '0;

    generate
        for(genvar i = 2; i < 5; i = i + 1) begin
            for (genvar j = 0; j < 5; j = j + 1) begin
                    assign hash_in[j][i] = 64'h0;
            end
        end
    endgenerate

    logic hash_rdy, hash_rdy_prev;

    always_ff @(posedge clk_i) begin
        hash_rdy_prev <= hash_rdy;
    end
    assign done_o = !hash_rdy_prev & hash_rdy; // Rising edge.

	keccak_top #(.d(0), .b(1600), .W(64)) sha3_512 (
		.Clock(clk_i), 
		.Reset(run_i), 
		.InData(hash_in), 
		.FreshRand(), 
		.Ready(hash_rdy), 
		.OutData(hash_out)
	);

    function automatic keccak_1600_t keccak_1600_conv(input keccak_1600_t din);
        for (int i = 0; i < 5; i++) begin
            keccak_1600_conv[0][i] = din[i][0]; // [63:0]
            keccak_1600_conv[1][i] = din[i][1]; // [127:64]
            keccak_1600_conv[2][i] = din[i][2]; // [191:128]
            keccak_1600_conv[3][i] = din[i][3]; // [255:192]
            keccak_1600_conv[4][i] = din[i][4]; // [319:256]
        end
    endfunction
endmodule
