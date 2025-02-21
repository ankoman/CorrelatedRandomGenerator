`timescale 1ns / 1ps

`define LEN_PRNG 256
`define LEN_KEY 128
`define LEN_MAX_CR 32
`define ML_KEM_K 2
`define ML_KEM_Q 3329
`define ML_KEM_LEN_Q 12

`ifndef TYPES
    `define TYPES
    package TYPES;
        typedef logic [`LEN_PRNG - 1:0] prng_t;
        typedef logic [`LEN_KEY - 1:0] key_t;
        typedef logic [7:0][31:0] prng_split32_t;
        typedef logic [`LEN_MAX_CR - 1:0] cr_cnt_t;

        typedef struct packed {
                logic carry;
                logic [31:0] val;
        } u32_w_c_t;

        typedef struct packed {
            logic a;
            logic b;
            logic e;
        } mode_t;

        typedef struct packed {
            ///////////////////////////
            // 32 bits: 0b000
            // 64 bits: 0b001
            //128 bits: 0b011
            //256 bits: 0b111
            ///////////////////////////
            logic is256;
            logic is128;
            logic is64;
        } width_t;
    endpackage
`endif 

`ifndef TYPES_KEM
    `define TYPES_KEM
    package TYPES_KEM;

        parameter ML_KEM_K = `ML_KEM_K;
        parameter ML_KEM_LEN_Q = `ML_KEM_LEN_Q;
        parameter ML_KEM_Q = `ML_KEM_Q;

        typedef logic [255:0][ML_KEM_LEN_Q - 1:0] poly_t;
        typedef poly_t [`ML_KEM_K-1:0][`ML_KEM_K-1:0] polymat_t;
        typedef logic [4:0][4:0][64 - 1:0] keccak_1600_t;

        typedef enum logic [2:0] {
            NTT_a, NTT_b, PWM,
        } ntt_mode_t;

        typedef struct packed {
            logic keygen;
            logic encap;
            logic decap;
        } kem_mode_t;

        typedef struct packed {
            logic trng;
            logic sampleA;
            logic sampleCBD_2k;
            logic ntt;
            logic hashG;
        } kem_module_t;
    endpackage
`endif 

`ifndef FUNCS
    `define FUNCS
    package FUNCS;
        import TYPES::prng_t;
        import TYPES::width_t;
        import TYPES_KEM::keccak_1600_t;
        function automatic prng_t make_carry_mask;
            input width_t width_i;

            make_carry_mask =   {31'd0, !width_i.is64, 31'd0, !width_i.is128, 
                                31'd0, !width_i.is64, 31'd0, !width_i.is256,
                                31'd0, !width_i.is64, 31'd0, !width_i.is128, 
                                31'd0, !width_i.is64, 32'd0}; 

        endfunction

        function automatic [63:0] urand_64();
            urand_64 = {$urandom(), $urandom()};
        endfunction
    
        function automatic [127:0] urand_128();
            urand_128 = {$urandom(), $urandom(), $urandom(), $urandom()};
        endfunction

        function automatic [255:0] urand_256();
            urand_256 = {$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()};
        endfunction
    
    	function automatic logic [255:0] reverse_endian_256(input logic [255:0] data);
		logic [255:0] reversed = '0;

		for (int i = 0; i < 32; i++) begin
			reversed[i*8 +: 8] = data[(32-1-i)*8 +: 8];
    	end
    	return reversed;
	    endfunction

        function automatic keccak_1600_t keccak_1600_conv(input keccak_1600_t din);
            for (int i = 0; i < 5; i++) begin
                for (int j = 0; j < 5; j++) begin
                    keccak_1600_conv[j][i] = din[i][j]; 
                end
            end
        endfunction
    endpackage
`endif 
