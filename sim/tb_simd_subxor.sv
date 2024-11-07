`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2024/11/7
// Module Name: tb_simd_subxor.sv
// Tool Versions: Vivado 2020.1
//////////////////////////////////////////////////////////////////////////////////

`define ASSERT(var, ans, res) \
    assert(res === ans) else begin \
        $display("#%d Failed %s: ans = %h, res = %h", i, var, ans, res); \
        $stop(); \
    end

module tb_simd_subxor;
    import TYPES::*;
    import FUNCS::*;

    typedef struct packed {
        prng_t x;
        prng_t y;
        prng_t ex;
        prng_t ans_a32;
        prng_t ans_a32_ex;
        prng_t ans_a64;
        prng_t ans_a64_ex;
        prng_t ans_a128;
        prng_t ans_a128_ex;
        prng_t ans_a256;
        prng_t ans_a256_ex;
        prng_t ans_b32;
        prng_t ans_b32_ex;
        prng_t ans_b64;
        prng_t ans_b64_ex;
        prng_t ans_b128;
        prng_t ans_b128_ex;
        prng_t ans_b256;
        prng_t ans_b256_ex;
    } tv_simd_subxor_t;

    // adder_tree Parameters
    localparam integer PERIOD  = 10;
    localparam integer N_TVs   = 100000;
    localparam integer N_PIPELINE_STAGES = 9;

    // adder_tree.                                
    reg   clk_i                                = 1;
    reg   rst_n_i                              = 1;
    prng_t  x_i;
    prng_t  y_i;
    prng_t  ex_i;
    mode_t  mode_i;
    width_t width_i;
    prng_t  z_o;
    prng_t res_a32, res_a64, res_a128, res_a256, res_a32_ex, res_a64_ex, res_a128_ex, res_a256_ex;
    prng_t res_b32, res_b64, res_b128, res_b256, res_b32_ex, res_b64_ex, res_b128_ex, res_b256_ex;

    always begin
        #(PERIOD/2) clk_i <= ~clk_i;
    end

    simd_subxor dut_a32 (
        .clk_i,
        .rst_n_i,
        .x_i,
        .y_i,
        .ex_i,
        .mode_i(3'b100),
        .width_i(3'b000),
        .z_o(res_a32)
    );

    simd_subxor #(1) dut_a32_ex (
        .clk_i,
        .rst_n_i,
        .x_i,
        .y_i,
        .ex_i,
        .mode_i(3'b100),
        .width_i(3'b000),
        .z_o(res_a32_ex)
    );

    simd_subxor dut_a64 (
        .clk_i,
        .rst_n_i,
        .x_i,
        .y_i,
        .ex_i,
        .mode_i(3'b100),
        .width_i(3'b001),
        .z_o(res_a64)
    );

    simd_subxor #(1) dut_a64_ex (
        .clk_i,
        .rst_n_i,
        .x_i,
        .y_i,
        .ex_i,
        .mode_i(3'b100),
        .width_i(3'b001),
        .z_o(res_a64_ex)
    );

    simd_subxor dut_a128 (
        .clk_i,
        .rst_n_i,
        .x_i,
        .y_i,
        .ex_i,
        .mode_i(3'b100),
        .width_i(3'b011),
        .z_o(res_a128)
    );

    simd_subxor #(1) dut_a128_ex (
        .clk_i,
        .rst_n_i,
        .x_i,
        .y_i,
        .ex_i,
        .mode_i(3'b100),
        .width_i(3'b011),
        .z_o(res_a128_ex)
    );

    simd_subxor dut_a256 (
        .clk_i,
        .rst_n_i,
        .x_i,
        .y_i,
        .ex_i,
        .mode_i(3'b100),
        .width_i(3'b111),
        .z_o(res_a256)
    );

    simd_subxor #(1) dut_a256_ex (
        .clk_i,
        .rst_n_i,
        .x_i,
        .y_i,
        .ex_i,
        .mode_i(3'b100),
        .width_i(3'b111),
        .z_o(res_a256_ex)
    );
    
    simd_subxor dut_b32 (
        .clk_i,
        .rst_n_i,
        .x_i,
        .y_i,
        .ex_i,
        .mode_i(3'b010),
        .width_i(3'b000),
        .z_o(res_b32)
    );

    simd_subxor #(1) dut_b32_ex (
        .clk_i,
        .rst_n_i,
        .x_i,
        .y_i,
        .ex_i,
        .mode_i(3'b010),
        .width_i(3'b000),
        .z_o(res_b32_ex)
    );

    simd_subxor dut_b64 (
        .clk_i,
        .rst_n_i,
        .x_i,
        .y_i,
        .ex_i,
        .mode_i(3'b010),
        .width_i(3'b001),
        .z_o(res_b64)
    );

    simd_subxor #(1) dut_b64_ex (
        .clk_i,
        .rst_n_i,
        .x_i,
        .y_i,
        .ex_i,
        .mode_i(3'b010),
        .width_i(3'b001),
        .z_o(res_b64_ex)
    );

    simd_subxor dut_b128 (
        .clk_i,
        .rst_n_i,
        .x_i,
        .y_i,
        .ex_i,
        .mode_i(3'b010),
        .width_i(3'b011),
        .z_o(res_b128)
    );

    simd_subxor #(1) dut_b128_ex (
        .clk_i,
        .rst_n_i,
        .x_i,
        .y_i,
        .ex_i,
        .mode_i(3'b010),
        .width_i(3'b011),
        .z_o(res_b128_ex)
    );

    simd_subxor dut_b256 (
        .clk_i,
        .rst_n_i,
        .x_i,
        .y_i,
        .ex_i,
        .mode_i(3'b010),
        .width_i(3'b111),
        .z_o(res_b256)
    );

    simd_subxor #(1) dut_b256_ex (
        .clk_i,
        .rst_n_i,
        .x_i,
        .y_i,
        .ex_i,
        .mode_i(3'b010),
        .width_i(3'b111),
        .z_o(res_b256_ex)
    );

    // Variables
    logic [$bits(tv_simd_subxor_t) - 1: 0] mem_tv [N_TVs];
    tv_simd_subxor_t tv;
    tv_simd_subxor_t [N_PIPELINE_STAGES - 1:0] reg_ans;

    always @(posedge clk_i)
        reg_ans <= {reg_ans[N_PIPELINE_STAGES - 2:0], tv};

    initial
    begin
        $readmemh("C:\\Users\\sakamoto\\Desktop\\prj\\CorrelatedRandomGenerator\\dat\\tv_simd_subxor.txt", mem_tv);
        #100;
        rst_n_i <= 0;
        x_i <= '0;
        y_i <= '0;
        ex_i <= '0;
        #100;
        rst_n_i <= 1;
        #100;
        for(integer i = 0; i < N_TVs; i = i + 1) begin
            tv = mem_tv[i];
            x_i = tv.x;
            y_i = tv.y;
            ex_i = tv.ex;
            if(i >= N_PIPELINE_STAGES) begin
                // $display("#%d: ans_a32 = %h, res_a32 = %h", i, reg_ans[N_PIPELINE_STAGES - 1].ans_a32, res_a32);

                `ASSERT("a32", reg_ans[N_PIPELINE_STAGES - 1].ans_a32, res_a32);
                `ASSERT("a32_ex", reg_ans[N_PIPELINE_STAGES - 1].ans_a32_ex, res_a32_ex);
                `ASSERT("a64", reg_ans[N_PIPELINE_STAGES - 1].ans_a64, res_a64);
                `ASSERT("a64_ex", reg_ans[N_PIPELINE_STAGES - 1].ans_a64_ex, res_a64_ex);
                `ASSERT("a128", reg_ans[N_PIPELINE_STAGES - 1].ans_a128, res_a128);
                `ASSERT("a128_ex", reg_ans[N_PIPELINE_STAGES - 1].ans_a128_ex, res_a128_ex);
                `ASSERT("a256", reg_ans[N_PIPELINE_STAGES - 1].ans_a256, res_a256);
                `ASSERT("a256_ex", reg_ans[N_PIPELINE_STAGES - 1].ans_a256_ex, res_a256_ex);

                `ASSERT("b32", reg_ans[N_PIPELINE_STAGES - 1].ans_b32, res_b32);
                `ASSERT("b32_ex", reg_ans[N_PIPELINE_STAGES - 1].ans_b32_ex, res_b32_ex);
                `ASSERT("b64", reg_ans[N_PIPELINE_STAGES - 1].ans_b64, res_b64);
                `ASSERT("b64_ex", reg_ans[N_PIPELINE_STAGES - 1].ans_b64_ex, res_b64_ex);
                `ASSERT("b128", reg_ans[N_PIPELINE_STAGES - 1].ans_b128, res_b128);
                `ASSERT("b128_ex", reg_ans[N_PIPELINE_STAGES - 1].ans_b128_ex, res_b128_ex);
                `ASSERT("b256", reg_ans[N_PIPELINE_STAGES - 1].ans_b256, res_b256);
                `ASSERT("b256_ex", reg_ans[N_PIPELINE_STAGES - 1].ans_b256_ex, res_b256_ex);
            end  
            #PERIOD;
        end
        $finish;
    end

endmodule
