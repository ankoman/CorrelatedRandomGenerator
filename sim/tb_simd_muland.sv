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
    localparam integer N_PIPELINE_STAGES = 8;

    // adder_tree.                                
    reg   clk_i                                = 1;
    reg   rst_n_i                              = 1;
    prng_t  x_i;
    prng_t  y_i;
    prng_t  ps_o, sc_o;

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
        .ps_o,
        .sc_o
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
        #100;
        rst_n_i <= 1;
        #100;
        for(integer i = 0; i < N_TVs; i = i + 1) begin
            tv = mem_tv[i];
            x_i = tv.x;
            y_i = tv.y;
            if(i >= N_PIPELINE_STAGES) begin
                // $display("#%d: ans_a32 = %h, res_a32 = %h", i, reg_ans[N_PIPELINE_STAGES - 1].ans_a32, res_a32);

                //`ASSERT("a32", reg_ans[N_PIPELINE_STAGES - 1].ans_a32, res_a32);

            end  
            #PERIOD;
        end
        $finish;
    end

endmodule
