`timescale 1ns / 1ps

`define LEN_PRNG 256

`ifndef TYPES
    `define TYPES
    package TYPES;
        typedef logic[`LEN_PRNG - 1:0] prng_t;

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

`ifndef FUNCS
    `define FUNCS
    package FUNCS;
        import TYPES::prng_t;
        import TYPES::width_t;
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
    endpackage
`endif 