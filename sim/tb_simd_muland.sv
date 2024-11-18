`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2024/11/7
// Module Name: tb_simd_muland.sv
// Tool Versions: Vivado 2024.1
//////////////////////////////////////////////////////////////////////////////////

`define ASSERT(var, ans, res) \
    assert(res === ans) else begin \
        $display("#%d Failed %s: ans = %h, res = %h", i, var, ans, res); \
        $stop(); \
    end

module tb_simd_muland;
    import TYPES::*;
    import FUNCS::*;

    typedef struct packed {
        prng_t x;
        prng_t y;
        prng_t ans_a32_ps;
        prng_t ans_a32_sc;
        prng_t ans_a64_ps;
        prng_t ans_a64_sc;
        prng_t ans_a128_ps;
        prng_t ans_a128_sc;
        prng_t ans_a256_ps;
        prng_t ans_a256_sc;
        prng_t ans_b32_ps;
        prng_t ans_b32_sc;
        prng_t ans_b64_ps;
        prng_t ans_b64_sc;
        prng_t ans_b128_ps;
        prng_t ans_b128_sc;
        prng_t ans_b256_ps;
        prng_t ans_b256_sc;
    } tv_simd_muland_t;

    // adder_tree Parameters
    localparam integer PERIOD  = 10;
    localparam integer N_TVs   = 100000;
    localparam integer N_PIPELINE_STAGES = 9;

    // adder_tree.                                
    reg   clk_i                                = 1;
    reg   rst_n_i                              = 1;
    prng_t  x_i;
    prng_t  y_i;
    prng_t  res_a32_ps, res_a32_sc, res_a64_ps, res_a64_sc, res_a128_ps, res_a128_sc, res_a256_ps, res_a256_sc;
    prng_t  res_b32_ps, res_b32_sc, res_b64_ps, res_b64_sc, res_b128_ps, res_b128_sc, res_b256_ps, res_b256_sc;

    always begin
        #(PERIOD/2) clk_i <= ~clk_i;
    end

    simd_muland dut_a32 (
        .clk_i,
        .rst_n_i,
        .x_i,
        .y_i,
        .mode_i(3'b100),
        .width_i(3'b000),
        .ps_o(res_a32_ps),
        .sc_o(res_a32_sc)
    );

    simd_muland dut_a64 (
        .clk_i,
        .rst_n_i,
        .x_i,
        .y_i,
        .mode_i(3'b100),
        .width_i(3'b001),
        .ps_o(res_a64_ps),
        .sc_o(res_a64_sc)
    );

    simd_muland dut_a128 (
        .clk_i,
        .rst_n_i,
        .x_i,
        .y_i,
        .mode_i(3'b100),
        .width_i(3'b011),
        .ps_o(res_a128_ps),
        .sc_o(res_a128_sc)
    );

    simd_muland dut_a256 (
        .clk_i,
        .rst_n_i,
        .x_i,
        .y_i,
        .mode_i(3'b100),
        .width_i(3'b111),
        .ps_o(res_a256_ps),
        .sc_o(res_a256_sc)
    );

    simd_muland dut_b32 (
        .clk_i,
        .rst_n_i,
        .x_i,
        .y_i,
        .mode_i(3'b010),
        .width_i(3'b000),
        .ps_o(res_b32_ps),
        .sc_o(res_b32_sc)
    );

    simd_muland dut_b64 (
        .clk_i,
        .rst_n_i,
        .x_i,
        .y_i,
        .mode_i(3'b010),
        .width_i(3'b001),
        .ps_o(res_b64_ps),
        .sc_o(res_b64_sc)
    );

    simd_muland dut_b128 (
        .clk_i,
        .rst_n_i,
        .x_i,
        .y_i,
        .mode_i(3'b010),
        .width_i(3'b011),
        .ps_o(res_b128_ps),
        .sc_o(res_b128_sc)
    );

    simd_muland dut_b256 (
        .clk_i,
        .rst_n_i,
        .x_i,
        .y_i,
        .mode_i(3'b010),
        .width_i(3'b111),
        .ps_o(res_b256_ps),
        .sc_o(res_b256_sc)
    );

    // Variables
    logic [$bits(tv_simd_muland_t) - 1: 0] mem_tv [N_TVs];
    tv_simd_muland_t tv;
    tv_simd_muland_t [N_PIPELINE_STAGES - 1:0] reg_ans;

    always @(posedge clk_i)
        reg_ans <= {reg_ans[N_PIPELINE_STAGES - 2:0], tv};

    initial
    begin
        $readmemh("C:\\Users\\sakamoto\\Desktop\\CorrelatedRandomGenerator\\dat\\tv_simd_muland.txt", mem_tv);
        //$readmemh("C:/Mac/Home/Desktop/prj/CorrelatedRandomGenerator/dat/tv_simd_muland.txt", mem_tv);
        #100;
        rst_n_i <= 0;
        x_i <= '0;
        y_i <= '0;
        #100;
        rst_n_i <= 1;
        #100;
        for(integer i = 0; i < N_TVs; i = i + 1) begin
            tv = mem_tv[i];
            x_i = tv.x;
            y_i = tv.y;
            if(i >= N_PIPELINE_STAGES) begin
                // $display("#%d: ans_a32 = %h, res_a32 = %h", i, reg_ans[N_PIPELINE_STAGES - 1].ans_a32, res_a32);

                `ASSERT("a32_ps", reg_ans[N_PIPELINE_STAGES - 1].ans_a32_ps, res_a32_ps);
                `ASSERT("a32_sc", reg_ans[N_PIPELINE_STAGES - 1].ans_a32_sc, res_a32_sc);
                `ASSERT("a64_ps", reg_ans[N_PIPELINE_STAGES - 1].ans_a64_ps, res_a64_ps);
                `ASSERT("a64_sc", reg_ans[N_PIPELINE_STAGES - 1].ans_a64_sc, res_a64_sc);
                `ASSERT("a128_ps", reg_ans[N_PIPELINE_STAGES - 1].ans_a128_ps, res_a128_ps);
                `ASSERT("a128_sc", reg_ans[N_PIPELINE_STAGES - 1].ans_a128_sc, res_a128_sc);
                `ASSERT("a256_ps", reg_ans[N_PIPELINE_STAGES - 1].ans_a256_ps, res_a256_ps);
                `ASSERT("a256_sc", reg_ans[N_PIPELINE_STAGES - 1].ans_a256_sc, res_a256_sc);
            end  
            #PERIOD;
        end
        $finish;
    end

endmodule
