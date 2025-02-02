`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2024/11/14
// Module Name: CRG: Correlated Random Generator
// Target Devices: U250
// Tool Versions: Vivado 2024.1
//////////////////////////////////////////////////////////////////////////////////


module CRG 
    import TYPES::*;
    (
    input clk_i,
    input rst_n_i,
    input party_i,
    input key_t key_i,
    input width_t width_i,
    input mode_t mode_i,
    input cr_cnt_t cnt_start_i,
    input cr_cnt_t cnt_end_i,
    input run_i,
    output prng_t a_o, 
    output prng_t b_o, 
    output prng_t c_o,
    output [7:0] e_o,
    output dvld_o
    );

    parameter integer LATENCY = 28;

    cr_cnt_t ptxt_cnt;
    wire cnt_busy = |ptxt_cnt;
    wire cnt_reset = (ptxt_cnt == cnt_end_i) ? 1'b1 : 1'b0;
    always @(posedge clk_i) begin
        if(!rst_n_i || cnt_reset) begin
            ptxt_cnt <= '0;
        end
        else begin
            if (run_i)
                ptxt_cnt <= cnt_start_i;
            else if(cnt_busy)
                ptxt_cnt <= ptxt_cnt + $bits(ptxt_cnt)'(1);
        end
    end

    logic [LATENCY - 1:0] dvld_buf;
    always @(posedge clk_i) begin
        if(!rst_n_i)
            dvld_buf <= '0;
        else
            dvld_buf <= {dvld_buf[LATENCY - 2:0], cnt_busy};
    end
    assign dvld_o = dvld_buf[LATENCY - 1];

    prng_t [5:0] dout256;
    prng_t a0, a1, a, b0, b1, b, c0, c1, c_ps, c_sc, ex_mask;
    logic [7:0] e0, e1;
    assign ex_mask = {4{{31{!mode_i.e}}, !width_i.is64 | !mode_i.e, {31{!mode_i.e}}, 1'b1}};
    assign a0 = dout256[0];
    assign a  = dout256[1] & ex_mask;
    assign b  = dout256[2];
    assign b0 = dout256[3];
    assign c0 = dout256[4];
    assign e0 = dout256[5][7:0];
    assign e1 = {a[224], a[192], a[160], a[128], a[96], a[64], a[32], a[0]} ^ e0;

    generate
        for(genvar i = 0; i < 6; i = i + 1) begin
            PRNG256 u_prng(
                .Kin(key_i),
                .prefix(7'(i)),
                .cnt(ptxt_cnt),
                .Dout(dout256[i]),
                .Drdy(cnt_busy),
                .Dvld(),
                .CLK(clk_i),
                .RSTn(rst_n_i)
            );
        end
    endgenerate

    simd_subxor #(.EX_LATANCY(9)) u_subxor_a (
        .clk_i,
        .rst_n_i,
        .x_i(a),
        .y_i(a0),
        .ex_i(),
        .mode_i,
        .width_i,
        .z_o(a1)
    );

    simd_subxor #(.EX_LATANCY(9)) u_subxor_b (
        .clk_i,
        .rst_n_i,
        .x_i(b),
        .y_i(b0),
        .ex_i(),
        .mode_i,
        .width_i,
        .z_o(b1)
    );

    simd_muland u_muland (
        .clk_i,
        .rst_n_i,
        .x_i(a),
        .y_i(b),
        .mode_i,
        .width_i,
        .ps_o(c_ps),
        .sc_o(c_sc)
    );

    simd_subxor #(.EXTRA(1)) u_subxor_c (
        .clk_i,
        .rst_n_i,
        .x_i(c_ps),
        .y_i(r_buf_c0[8]),
        .ex_i(c_sc << 1),
        .mode_i,
        .width_i,
        .z_o(c1)
    );

    localparam integer LAT_MULSUB = 18;
    prng_t [LAT_MULSUB - 1:0] r_buf_a0, r_buf_b0, r_buf_c0;
    logic [LAT_MULSUB - 1:0][7:0] r_buf_e0, r_buf_e1;

    always @(posedge clk_i) begin
        if(!rst_n_i) begin
            r_buf_a0 <= '0;
            r_buf_b0 <= '0;
            r_buf_c0 <= '0;
            r_buf_e0 <= '0;
            r_buf_e1 <= '0;
        end
        else begin
            r_buf_a0 <= {r_buf_a0[LAT_MULSUB - 2:0], a0};
            r_buf_b0 <= {r_buf_b0[LAT_MULSUB - 2:0], b0};
            r_buf_c0 <= {r_buf_c0[LAT_MULSUB - 2:0], c0};
            r_buf_e0 <= {r_buf_e0[LAT_MULSUB - 2:0], e0};
            r_buf_e1 <= {r_buf_e1[LAT_MULSUB - 2:0], e1};
        end
    end

    assign a_o = (party_i == 1'b0) ? r_buf_a0[LAT_MULSUB - 1] : a1;
    assign b_o = (party_i == 1'b0) ? r_buf_b0[LAT_MULSUB - 1] : b1;
    assign c_o = (party_i == 1'b0) ? r_buf_c0[LAT_MULSUB - 1] : c1;
    assign e_o = (party_i == 1'b0) ? r_buf_e0[LAT_MULSUB - 1] : r_buf_e1[LAT_MULSUB - 1];

endmodule
