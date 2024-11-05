`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2024/10/24
// Module Name: simd_subxor
// Target Devices: U250
// Tool Versions: Vivado 2020.1
//////////////////////////////////////////////////////////////////////////////////


module simd_subxor
    import TYPES::*;
    import FUNCS:: make_carry_mask;
    (
    input           clk_i,
                    rst_n_i,
    input   prng_t  x_i,
    input   prng_t  y_i,
    input   mode_t  mode_i,
    input   width_t width_i,
    output  prng_t  z_o
    );

    wire sub = ~mode_i.b;
    prng_t ps_1, sc_1;

    CSA_addsub csa_as(
        .x_i,
        .y_i,
        .sub_i(sub),
        .width_i,
        .ps_o(ps_1),
        .sc_o(sc_1)
    );

    prng_t ps_2, sc_2, sc_1_shift, mask;
    assign mask = {`LEN_PRNG{sub}};
    assign sc_1_shift = {sc_1[`LEN_PRNG - 2:1], 1'b0};
    assign sc_2 = sc_1_shift & !make_carry_mask(width_i) & mask;

    ///
    //Extra term
    ///

    //adder_tree

endmodule


module CSA_addsub
    import TYPES::*;
    import FUNCS:: make_carry_mask;
    (
    input   prng_t  x_i,
    input   prng_t  y_i,
    input   logic   sub_i,
    input   width_t width_i,
    output  prng_t  ps_o,
    output  prng_t  sc_o
    );

    prng_t mask, y_inv, ones;
    assign mask = {`LEN_PRNG{sub_i}};
    assign y_inv = y_i ^ mask;
    assign ones = make_carry_mask(width_i) & mask;

    CSA #(.len(`LEN_PRNG)) csa(
        .a_i(x_i),
        .b_i(y_inv),
        .c_i({ones[$bits(ones) - 1: 1], sub_i}),
        .ps_o,
        .sc_o
    );

endmodule