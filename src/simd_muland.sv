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
    assign mask64 = {32{width_i.is64}} | {32{mode_i.b}};
    assign mask128 = {32{width_i.is128}} | {32{mode_i.b}};
    assign mask256 = {32{width_i.is256}} | {32{mode_i.b}};
    assign masks =  {
        {mask32 , mask64 , mask128, mask128, mask256, mask256, mask256, mask256},
        {mask64 , mask32 , mask128, mask128, mask256, mask256, mask256, mask256},
        {mask128, mask128, mask32 , mask64, mask256, mask256, mask256, mask256},
        {mask128, mask128, mask64 , mask32, mask256, mask256, mask256, mask256},
        {mask256, mask256, mask256, mask256, mask32, mask64, mask128, mask128},
        {mask256, mask256, mask256, mask256, mask64, mask32, mask128, mask128},
        {mask256, mask256, mask256, mask256, mask128, mask128, mask32, mask64},
        {mask256, mask256, mask256, mask256, mask128, mask128, mask64, mask32}
    };

    assign mask_in = {$bits(prng_t){is_a}};
    assign w_x_in = x_i & (y_i | mask_in);
    assign w_y_in = (y_i & mask_in) | {{($bits(prng_t) - 1){1'd0}}, 1'd1 ^ is_a};
    //assign w_acc_ps[0] = '0;
    //assign w_acc_sc[0] = '0;

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

    prng_t [7:0] ps_mul, sc_mul, ps_shift, sc_shift, tmp_ps, tmp_sc;
    prng_t carry_mask;
    assign carry_mask = ~make_carry_mask(width_i);
    generate
        for(genvar i = 0; i < 8; i = i + 1) begin
            CSAMUL_256_32 u_csamul(
                .x_i(r_x_in[i] & masks[i]),
                .y_i(r_y_in[i][i]),
                .ps_o(ps_mul[i]),
                .sc_o(sc_mul[i])
            );

            if (i == 0) begin      
                CSA #(.len($bits(prng_t))) u_csa_0 (
                    .a_i(prng_t'(0)),
                    .b_i(ps_shift[i] & masks[i]),
                    .c_i((sc_shift[i] << 1) & masks[i]),
                    .ps_o(tmp_ps[i]),
                    .sc_o(tmp_sc[i])
                );
                CSA #(.len($bits(prng_t))) u_csa_1 (
                    .a_i(tmp_ps[i]),
                    .b_i((tmp_sc[i] << 1) & carry_mask),
                    .c_i(prng_t'(0)),
                    .ps_o(w_acc_ps[i]),
                    .sc_o(w_acc_sc[i])
                );
            end
            else begin
                CSA #(.len($bits(prng_t))) u_csa_0 (
                    .a_i(r_acc_ps[i - 1]),
                    .b_i(ps_shift[i] & masks[i]),
                    .c_i((sc_shift[i] << 1) & masks[i]),
                    .ps_o(tmp_ps[i]),
                    .sc_o(tmp_sc[i])
                );
                CSA #(.len($bits(prng_t))) u_csa_1 (
                    .a_i(tmp_ps[i]),
                    .b_i((tmp_sc[i] << 1) & carry_mask),
                    .c_i((r_acc_sc[i - 1] << 1) & carry_mask),
                    .ps_o(w_acc_ps[i]),
                    .sc_o(w_acc_sc[i])
                );
            end
        end
    endgenerate

    assign ps_shift[0] = ps_mul[0];
    assign ps_shift[1] = (width_i == 3'b000) ? ps_mul[1] : ps_mul[1] << 32;
    assign ps_shift[2] = (width_i.is128) ? ps_mul[2] << 64 : ps_mul[2];
    assign ps_shift[3] = (width_i == 3'b000) ? ps_mul[3] : (width_i.is128) ? ps_mul[3] << 96 : ps_mul[3] << 32;
    assign ps_shift[4] = (width_i.is256) ? ps_mul[4] << 128 : ps_mul[4];
    assign ps_shift[5] = (width_i == 3'b000) ? ps_mul[5] : (width_i.is256) ? ps_mul[5] << 160 : ps_mul[5] << 32;
    assign ps_shift[6] = (width_i.is256) ? ps_mul[6] << 192 : (~width_i.is128) ? ps_mul[6] : ps_mul[6] << 64;
    assign ps_shift[7] = (width_i.is256) ? ps_mul[7] << 224 : (width_i == 3'b000) ? ps_mul[7] : 
                        (width_i == 3'b001) ? ps_mul[7] << 32 : ps_mul[7] << 96;

    assign sc_shift[0] = sc_mul[0];
    assign sc_shift[1] = (width_i == 3'b000) ? sc_mul[1] : sc_mul[1] << 32;
    assign sc_shift[2] = (width_i.is128) ? sc_mul[2] << 64 : sc_mul[2];
    assign sc_shift[3] = (width_i == 3'b000) ? sc_mul[3] : (width_i.is128) ? sc_mul[3] << 96 : sc_mul[3] << 32;
    assign sc_shift[4] = (width_i.is256) ? sc_mul[4] << 128 : sc_mul[4];
    assign sc_shift[5] = (width_i == 3'b000) ? sc_mul[5] : (width_i.is256) ? sc_mul[5] << 160 : sc_mul[5] << 32;
    assign sc_shift[6] = (width_i.is256) ? sc_mul[6] << 192 : (~width_i.is128) ? sc_mul[6] : sc_mul[6] << 64;
    assign sc_shift[7] = (width_i.is256) ? sc_mul[7] << 224 : (width_i == 3'b000) ? sc_mul[7] : 
                        (width_i == 3'b001) ? sc_mul[7] << 32 : sc_mul[7] << 96;

    assign ps_o = r_acc_ps[7];
    prng_t last_mask;
    assign last_mask = {1'b1, carry_mask[$bits(prng_t) - 1:1]};
    assign sc_o = r_acc_sc[7] & last_mask;
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
