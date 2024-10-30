
`define LEN_PRNG 256;


`ifndef TYPES
    `define TYPES
    package TYPES;
        typedef logic[`LEN_PRNG - 1:0] prng_t;

        typedef struct packed {
            logic a;
            logic b;
            logic e;
        } mode_t;

        typedef struct packed {
            ///////////////////////////
            // 32 bits: 0b000
            // 64 bits: 0b100
            //128 bits: 0b110
            //256 bits: 0b111
            ///////////////////////////
            logic is64;
            logic is128;
            logic is256;
        } width_t;
    endpackage
`endif 

`ifndef FUNCS
    `define FUNCS
    package FUNCS;
        import TYPES::prng_t;
        import TYPES::width_t;
        function prng_t make_carry_mask;
            input width_t width_i;

            make_carry_mask = {31'd0, !width_i.is64, 31'd0, !width_i.is128, 31'd0, !width_i.is64, 31'd0, !width_i.is256, 31'd0, !width_i.is64, 31'd0, !width_i.is128, 31'd0, !width_i.is64, 32'd0}; 

        endfunction
    endpackage
`endif 
