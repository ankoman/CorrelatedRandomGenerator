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

    #(parameter integer EXTRA = 0)
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

    prng_t sc_2, mask, sum_o, sc_3, ps_2, r_ps, r_sc, carry_mask;
    assign carry_mask = ~make_carry_mask(width_i);
    assign mask = {$bits(prng_t){sub}};
    assign sc_2 = (sc_1 << 1) & carry_mask & mask;

    generate
        if (EXTRA == 1) begin : g_Extra_CSA
            prng_t sc_ex;
            CSA #(.len($bits(prng_t))) u_csa_extra (
                .a_i(ps_1),
                .b_i(sc_2),
                .c_i(ex_i),
                .ps_o(ps_2),
                .sc_o(sc_ex)
            );
            assign sc_3 = (sc_ex << 1) & carry_mask;
        end
        else begin
            assign ps_2 = ps_1;
            assign sc_3 = sc_2;
        end
    endgenerate

    //
    always_ff @(posedge clk_i) begin
        if(!rst_n_i) begin
            r_ps <= '0;
            r_sc <= '0;
        end
        else begin
            r_ps <= ps_2;
            r_sc <= sc_3;
        end
    end

    adder_tree u_add_tree(
        .clk_i,
        .rst_n_i,
        .ps_32_i(r_ps),
        .sc_32_i(r_sc),
        .width_i,
        .sum_o
    );

    assign z_o = sum_o;

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
    assign mask = {$bits(prng_t){sub_i}};
    assign y_inv = y_i ^ mask;
    assign ones = make_carry_mask(width_i) & mask;

    CSA #(.len($bits(prng_t))) u_csa (
        .a_i(x_i),
        .b_i(y_inv),
        .c_i({ones[$bits(ones) - 1: 1], sub_i}),
        .ps_o,
        .sc_o
    );

endmodule
