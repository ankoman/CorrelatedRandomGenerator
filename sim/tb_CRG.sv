`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2024/11/14
// Module Name: tb_CRG.sv
// Tool Versions: Vivado 2024.1
//////////////////////////////////////////////////////////////////////////////////

`define ASSERT(var, ans, res) \
    assert(ans === res) else begin \
        $display("#%d Failed %s: ans = %h, res = %h", i, var, ans, res); \
        $display("Type ans: %0d bits, Type res: %0d bits", $bits(ans), $bits(res)); \
        $stop(); \
    end

module tb_CRG;
    import TYPES::*;
    import FUNCS::*;

    // adder_tree Parameters
    localparam integer PERIOD  = 10;
    localparam integer N_LOOP   = 100000;
    localparam integer N_PIPELINE_STAGES = 27;

    // adder_tree.                                
    reg   clk_i                                = 1;
    reg   rst_n_i                              = 1;
    key_t key_i;
    cr_cnt_t cnt_start_i;
    cr_cnt_t cnt_end_i;
    logic run_i;
    prng_t a0_a32_o, b0_a32_o, c0_a32_o, a1_a32_o, b1_a32_o, c1_a32_o;
    prng_t a0_a64_o, b0_a64_o, c0_a64_o, a1_a64_o, b1_a64_o, c1_a64_o;
    prng_t a0_a128_o, b0_a128_o, c0_a128_o, a1_a128_o, b1_a128_o, c1_a128_o;
    prng_t a0_a256_o, b0_a256_o, c0_a256_o, a1_a256_o, b1_a256_o, c1_a256_o;
    prng_t a0_e32_o, b0_e32_o, c0_e32_o, a1_e32_o, b1_e32_o, c1_e32_o;
    prng_t a0_e64_o, b0_e64_o, c0_e64_o, a1_e64_o, b1_e64_o, c1_e64_o;
    prng_t a0_b128_o, b0_b128_o, c0_b128_o, a1_b128_o, b1_b128_o, c1_b128_o;
    logic [7:0] e0_e32_o, e1_e32_o, e0_e64_o, e1_e64_o;
    logic dvld_o;

    always begin
        #(PERIOD/2) clk_i <= ~clk_i;
    end

    CRG u_dut_a32_0 (
        .clk_i,
        .rst_n_i,
        .party_i(1'b0),
        .key_i,
        .width_i(3'b000),
        .mode_i(3'b100),
        .cnt_start_i,
        .cnt_end_i,
        .run_i,
        .a_o(a0_a32_o),
        .b_o(b0_a32_o),
        .c_o(c0_a32_o),
        .dvld_o
    );

    CRG u_dut_a32_1 (
        .clk_i,
        .rst_n_i,
        .party_i(1'b1),
        .key_i,
        .width_i(3'b000),
        .mode_i(3'b100),
        .cnt_start_i,
        .cnt_end_i,
        .run_i,
        .a_o(a1_a32_o),
        .b_o(b1_a32_o),
        .c_o(c1_a32_o),
        .dvld_o()
    );

    CRG u_dut_a64_0 (
        .clk_i,
        .rst_n_i,
        .party_i(1'b0),
        .key_i,
        .width_i(3'b001),
        .mode_i(3'b100),
        .cnt_start_i,
        .cnt_end_i,
        .run_i,
        .a_o(a0_a64_o),
        .b_o(b0_a64_o),
        .c_o(c0_a64_o),
        .dvld_o()
    );

    CRG u_dut_a64_1 (
        .clk_i,
        .rst_n_i,
        .party_i(1'b1),
        .key_i,
        .width_i(3'b001),
        .mode_i(3'b100),
        .cnt_start_i,
        .cnt_end_i,
        .run_i,
        .a_o(a1_a64_o),
        .b_o(b1_a64_o),
        .c_o(c1_a64_o),
        .dvld_o()
    );

    CRG u_dut_a128_0 (
        .clk_i,
        .rst_n_i,
        .party_i(1'b0),
        .key_i,
        .width_i(3'b011),
        .mode_i(3'b100),
        .cnt_start_i,
        .cnt_end_i,
        .run_i,
        .a_o(a0_a128_o),
        .b_o(b0_a128_o),
        .c_o(c0_a128_o),
        .dvld_o()
    );

    CRG u_dut_a128_1 (
        .clk_i,
        .rst_n_i,
        .party_i(1'b1),
        .key_i,
        .width_i(3'b011),
        .mode_i(3'b100),
        .cnt_start_i,
        .cnt_end_i,
        .run_i,
        .a_o(a1_a128_o),
        .b_o(b1_a128_o),
        .c_o(c1_a128_o),
        .dvld_o()
    );

    CRG u_dut_a256_0 (
        .clk_i,
        .rst_n_i,
        .party_i(1'b0),
        .key_i,
        .width_i(3'b111),
        .mode_i(3'b100),
        .cnt_start_i,
        .cnt_end_i,
        .run_i,
        .a_o(a0_a256_o),
        .b_o(b0_a256_o),
        .c_o(c0_a256_o),
        .dvld_o()
    );

    CRG u_dut_a256_1 (
        .clk_i,
        .rst_n_i,
        .party_i(1'b1),
        .key_i,
        .width_i(3'b111),
        .mode_i(3'b100),
        .cnt_start_i,
        .cnt_end_i,
        .run_i,
        .a_o(a1_a256_o),
        .b_o(b1_a256_o),
        .c_o(c1_a256_o),
        .dvld_o()
    );

    //Extended
    CRG u_dut_e32_0 (
        .clk_i,
        .rst_n_i,
        .party_i(1'b0),
        .key_i,
        .width_i(3'b000),
        .mode_i(3'b001),
        .cnt_start_i,
        .cnt_end_i,
        .run_i,
        .a_o(a0_e32_o),
        .b_o(b0_e32_o),
        .c_o(c0_e32_o),
        .e_o(e0_e32_o),
        .dvld_o()
    );

    CRG u_dut_e32_1 (
        .clk_i,
        .rst_n_i,
        .party_i(1'b1),
        .key_i,
        .width_i(3'b000),
        .mode_i(3'b001),
        .cnt_start_i,
        .cnt_end_i,
        .run_i,
        .a_o(a1_e32_o),
        .b_o(b1_e32_o),
        .c_o(c1_e32_o),
        .e_o(e1_e32_o),
        .dvld_o()
    );

    CRG u_dut_e64_0 (
        .clk_i,
        .rst_n_i,
        .party_i(1'b0),
        .key_i,
        .width_i(3'b001),
        .mode_i(3'b001),
        .cnt_start_i,
        .cnt_end_i,
        .run_i,
        .a_o(a0_e64_o),
        .b_o(b0_e64_o),
        .c_o(c0_e64_o),
        .e_o(e0_e64_o),
        .dvld_o()
    );

    CRG u_dut_e64_1 (
        .clk_i,
        .rst_n_i,
        .party_i(1'b1),
        .key_i,
        .width_i(3'b001),
        .mode_i(3'b001),
        .cnt_start_i,
        .cnt_end_i,
        .run_i,
        .a_o(a1_e64_o),
        .b_o(b1_e64_o),
        .c_o(c1_e64_o),
        .e_o(e1_e64_o),
        .dvld_o()
    );

    CRG u_dut_b128_0 (
        .clk_i,
        .rst_n_i,
        .party_i(1'b0),
        .key_i,
        .width_i(3'b011),
        .mode_i(3'b010),
        .cnt_start_i,
        .cnt_end_i,
        .run_i,
        .a_o(a0_b128_o),
        .b_o(b0_b128_o),
        .c_o(c0_b128_o),
        .dvld_o()
    );

    CRG u_dut_b128_1 (
        .clk_i,
        .rst_n_i,
        .party_i(1'b1),
        .key_i,
        .width_i(3'b011),
        .mode_i(3'b010),
        .cnt_start_i,
        .cnt_end_i,
        .run_i,
        .a_o(a1_b128_o),
        .b_o(b1_b128_o),
        .c_o(c1_b128_o),
        .dvld_o()
    );

    // Veriables
    prng_t res_a_a256, res_b_a256, res_c_a256;
    assign res_a_a256 = a0_a256_o + a1_a256_o;
    assign res_b_a256 = b0_a256_o + b1_a256_o;
    assign res_c_a256 = c0_a256_o + c1_a256_o;

    prng_t res_a_a32, res_b_a32, res_c_a32, ans_a32_c;
    prng_t res_a_a64, res_b_a64, res_c_a64, ans_a64_c;
    prng_t res_a_a128, res_b_a128, res_c_a128, ans_a128_c;
    prng_t res_a_b128, res_b_b128, res_c_b128, ans_b128_c;
    prng_t res_a_e32, res_b_e32, res_c_e32, ans_e32_c;
    prng_t res_a_e64, res_b_e64, res_c_e64, ans_e64_c;

    assign res_a_b128 = a0_b128_o ^ a1_b128_o;
    assign res_b_b128 = b0_b128_o ^ b1_b128_o;
    assign res_c_b128 = c0_b128_o ^ c1_b128_o;
    assign ans_b128_c = res_a_b128 & res_b_b128;

    initial
    begin
        #100;
        rst_n_i <= 0;
        key_i <= '0;
        #100;
        rst_n_i <= 1;
        //key_i <= 128'h2b7e151628aed2a6abf7158809cf4f3c;
        key_i <= 128'he3e70682c2094cac629f6fbed82c07cd;
        #PERIOD
        cnt_start_i <= 32'd3;
        cnt_end_i <= 32'h13;
        #PERIOD;
        run_i <= 1;
        #PERIOD;
        run_i <= 0;
        #270;

        for (integer i = 0; i < N_LOOP; i = i + 1) begin

            // a32
            simd_add_or_mul(32, 0, a0_a32_o, a1_a32_o, res_a_a32);
            simd_add_or_mul(32, 0, b0_a32_o, b1_a32_o, res_b_a32);
            simd_add_or_mul(32, 0, c0_a32_o, c1_a32_o, res_c_a32);
            simd_add_or_mul(32, 1, res_a_a32, res_b_a32, ans_a32_c);
            `ASSERT("a32", ans_a32_c, res_c_a32);

            // a64
            simd_add_or_mul(64, 0, a0_a64_o, a1_a64_o, res_a_a64);
            simd_add_or_mul(64, 0, b0_a64_o, b1_a64_o, res_b_a64);
            simd_add_or_mul(64, 0, c0_a64_o, c1_a64_o, res_c_a64);
            simd_add_or_mul(64, 1, res_a_a64, res_b_a64, ans_a64_c);
            `ASSERT("a64", ans_a64_c, res_c_a64);

            // a128
            simd_add_or_mul(128, 0, a0_a128_o, a1_a128_o, res_a_a128);
            simd_add_or_mul(128, 0, b0_a128_o, b1_a128_o, res_b_a128);
            simd_add_or_mul(128, 0, c0_a128_o, c1_a128_o, res_c_a128);
            simd_add_or_mul(128, 1, res_a_a128, res_b_a128, ans_a128_c);
            `ASSERT("a128", ans_a128_c, res_c_a128);

            // a256
            `ASSERT("a256", $bits(prng_t)'(res_a_a256 * res_b_a256), res_c_a256);
        
            // e32
            simd_add_or_mul(32, 0, a0_e32_o, a1_e32_o, res_a_e32);
            simd_add_or_mul(32, 0, b0_e32_o, b1_e32_o, res_b_e32);
            simd_add_or_mul(32, 0, c0_e32_o, c1_e32_o, res_c_e32);
            simd_add_or_mul(32, 1, res_a_e32, res_b_e32, ans_e32_c);
            `ASSERT("e32", ans_e32_c, res_c_e32);
            `ASSERT("e32", res_a_e32, e0_e32_o ^ e1_e32_o);

            // e64
            simd_add_or_mul(64, 0, a0_e64_o, a1_e64_o, res_a_e64);
            simd_add_or_mul(64, 0, b0_e64_o, b1_e64_o, res_b_e64);
            simd_add_or_mul(64, 0, c0_e64_o, c1_e64_o, res_c_e64);
            simd_add_or_mul(64, 1, res_a_e64, res_b_e64, ans_e64_c);
            `ASSERT("e64", ans_e64_c, res_c_e64);

            // b128
            `ASSERT("b128", ans_b128_c, res_c_b128);
            #PERIOD;
        end


        $finish;
    end

task automatic simd_add_or_mul(
    input integer LIMB,
    input integer MUL,
    input prng_t a,
    input prng_t b,
    output prng_t res
    );
    
    integer j;
    if (LIMB == 32) begin
        for (j = 0; j < 8; j = j + 1) begin
            if (MUL == 1) 
                res[j*32 +: 32] = a[j*32 +: 32] * b[j*32 +: 32];
            else
                res[j*32 +: 32] = a[j*32 +: 32] + b[j*32 +: 32];
        end
    end
    else if (LIMB == 64) begin
        for (j = 0; j < 4; j = j + 1) begin
            if (MUL == 1) 
                res[j*64 +: 64] = a[j*64 +: 64] * b[j*64 +: 64];
            else
                res[j*64 +: 64] = a[j*64 +: 64] + b[j*64 +: 64];
        end
    end
    else if (LIMB == 128) begin
        for (j = 0; j < 2; j = j + 1) begin
            if (MUL == 1) 
                res[j*128 +: 128] = a[j*128 +: 128] * b[j*128 +: 128];
            else
                res[j*128 +: 128] = a[j*128 +: 128] + b[j*128 +: 128];
        end
    end
endtask


endmodule


