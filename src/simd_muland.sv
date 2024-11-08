`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2024/11/8
// Module Name: simd_muland.sv
// Tool Versions: Vivado 2024.1
//////////////////////////////////////////////////////////////////////////////////


module simd_muland
    import TYPES::*;
    import FUNCS:: make_carry_mask;
    (
    input           clk_i,
                    rst_n_i,
    input   prng_t  x_i,
    input   prng_t  y_i,
    input   mode_t  mode_i,
    input   width_t width_i,
    output  prng_t  ps_o,
    output  prng_t  sc_o
    );

    wire is_a = ~mode_i.b;
    prng_t mask_in, w_x_in, w_y_in;
    prng_t [7:0] w_acc_ps, w_acc_sc, r_acc_ps, r_acc_sc;
    prng_t [8:0] r_x_in;
    prng_split32_t[8:0] r_y_in;
    wire [31:0] mask32, mask64, mask128, mask256;
    prng_t [7:0] masks;

    assign mask32 = 32'hffffffff;
    assign mask64 = {32{width_i.is64}};
    assign mask128 = {32{width_i.is128}};
    assign mask256 = {32{width_i.is256}};
    assign masks =  {
        {mask256, mask256, mask256, mask256, mask128, mask128, mask64 , mask32},
        {mask256, mask256, mask256, mask256, mask128, mask128, mask32 , mask64},
        {mask256, mask256, mask256, mask256, mask64 , mask32 , mask128, mask128},
        {mask256, mask256, mask256, mask256, mask32 , mask64 , mask128, mask128},
        {mask128, mask128, mask64 , mask32 , mask256, mask256, mask256, mask256},
        {mask128, mask128, mask32 , mask64 , mask256, mask256, mask256, mask256},
        {mask64 , mask32 , mask128, mask128, mask256, mask256, mask256, mask256},
        {mask32 , mask64 , mask128, mask128, mask256, mask256, mask256, mask256}
    };

    parameter integer [7:0] tab_shifts [4] = {
        {0,0,0,0,0,0,0,0}, // 32
        {0, 32, 0, 32, 0, 32, 0, 32}, // 64
        {0, 32, 64, 96, 0, 32, 64, 96}, // 128
        {0, 32, 64, 96, 128, 160, 192, 224} // 256
    };

    assign mask_in = {$bits(prng_t){is_a}};
    assign x_in = x_i & (y_i | mask_in);
    assign y_in = (y_i & mask_in) | {{($bits(prng_t) - 1){1'd0}}, 1'd1 ^ is_a};
    assign w_acc_ps[0] = '0;
    assign w_acc_sc[0] = '0;

    //Pipeline stage registers.
    always_ff @(posedge clk_i) begin
        if(!rst_n_i) begin
            r_x_in <= '0;
            r_y_in <= '0;
            r_acc_ps <= '0;
            r_acc_sc <= '0;
        end
        else begin
            r_x_in <= {r_x_in[7:0], w_x_in};
            r_y_in <= {r_y_in[7:0], w_y_in};
            r_acc_ps <= w_acc_ps;
            r_acc_sc <= w_acc_sc;
        end
    end

    generate
        for(genvar i = 0; i < 8; i = i + 1) begin
            prng_t ps_o, sc_o;
            CSAMUL_256_32 u_csamul(
                .x_i(r_x_in[i]),
                .y_i(r_y_in[i][i]),
                .ps_o,
                .sc_o
            );

            CSA #(.len($bits(prng_t))) u_csa_0 (
                .a_i(),
                .b_i(psc[i-1] << 1),
                .c_i(pp),
                .ps_o(pps[i]),
                .sc_o(psc[i])
            );
        end
    endgenerate

endmodule


module CSAMUL_256_32
    import TYPES::*;
    (
    input   prng_split32_t  x_i,
    input   [31:0]  y_i,
    output  prng_t  ps_o,
    output  prng_t  sc_o
    );

    prng_t [7:0] pps, psc;

    generate
        for(genvar i = 0; i < 8; i = i + 1) begin
            prng_t pp;
            assign pp = prng_t'((x_i[i] * y_i) << i*32);

            if (i == 0) begin
                assign pps[0] = pp;
                assign psc[0] = '0;
            end
            else begin
                CSA #(.len($bits(prng_t))) u_csa (
                    .a_i(pps[i-1]),
                    .b_i(psc[i-1] << 1),
                    .c_i(pp),
                    .ps_o(pps[i]),
                    .sc_o(psc[i])
                );
            end 
        end
    endgenerate

    assign ps_o = pps[7];
    assign sc_o = psc[7];

endmodule
