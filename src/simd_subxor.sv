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


module simd_subxor #(
    parameter integer EXTRA = 0,
    )
    import TYPES::*;
    import FUNCS:: make_carry_mask;
    (
    input           clk_i,
                    rst_n_i,
    input   prng_t  x_i,
    input   prng_t  y_i,
    input   prng_t  ex_i,
    input   mode_t  mode_i,
    input   width_t width_i,
    output  prng_t  z_o
    );

    wire sub = ~mode_i.b;
    prng_t ps_1, sc_1;

    CSA_addsub u_csa_as (
        .x_i,
        .y_i,
        .sub_i(sub),
        .width_i,
        .ps_o(ps_1),
        .sc_o(sc_1)
    );

    prng_t sc_2, sc_1_shift, mask, sum_o, sc_3, ps_2;
    assign mask = {`LEN_PRNG{sub}};
    assign sc_1_shift = {sc_1[`LEN_PRNG - 2:1], 1'b0};
    assign sc_2 = sc_1_shift & !make_carry_mask(width_i) & mask;

    generate
        if (EXTRA == 1) begin
            CSA #(.len(`LEN_PRNG)) u_csa_extra (
                .a_i(ps_1),
                .b_i(sc_2),
                .c_i(ex_i),
                .ps_o(ps_2),
                .sc_o(sc_3)
            );
        end
        else begin
            assign ps_2 = ps_1;
            assign sc_3 = sc_2;
        end
    endgenerate

    adder_tree u_add_tree(
        .clk_i,
        .rst_n_i,
        .ps_32_i(ps_2),
        .sc_32_i(sc_3),
        .width_i,
        .sum_o
    );

    assign z_0 = sum_o;

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

    CSA #(.len(`LEN_PRNG)) u_csa (
        .a_i(x_i),
        .b_i(y_inv),
        .c_i({ones[$bits(ones) - 1: 1], sub_i}),
        .ps_o,
        .sc_o
    );

endmodule
