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
    assert(res === ans) else begin \
        $display("#%d Failed %s: ans = %h, res = %h", i, var, ans, res); \
        $stop(); \
    end

module tb_CRG;
    import TYPES::*;
    import FUNCS::*;

    // adder_tree Parameters
    localparam integer PERIOD  = 10;
    localparam integer N_TVs   = 100000;
    localparam integer N_PIPELINE_STAGES = 27;

    // adder_tree.                                
    reg   clk_i                                = 1;
    reg   rst_n_i                              = 1;
    key_t key_i;
    cr_cnt_t cnt_start_i;
    cr_cnt_t cnt_end_i;
    logic run_i;
    prng_t a_o, b_o, c_o;
    logic dvld_o;

    always begin
        #(PERIOD/2) clk_i <= ~clk_i;
    end

    CRG u_dut_0 (
        .clk_i,
        .rst_n_i,
        .party_i(1'b0),
        .key_i,
        .width_i(3'b111),
        .mode_i(3'b100),
        .cnt_start_i,
        .cnt_end_i,
        .run_i,
        .a_o,
        .b_o,
        .c_o,
        .dvld_o
    );


    // // Variables
    // logic [$bits(tv_simd_muland_t) - 1: 0] mem_tv [N_TVs];
    // tv_simd_muland_t tv;
    // tv_simd_muland_t [N_PIPELINE_STAGES - 1:0] reg_ans;

    // always @(posedge clk_i)
    //     reg_ans <= {reg_ans[N_PIPELINE_STAGES - 2:0], tv};

    initial
    begin
        #100;
        rst_n_i <= 0;
        #100;
        rst_n_i <= 1;
        key_i <= 128'h2b7e151628aed2a6abf7158809cf4f3c;
        cnt_start_i <= 32'd1;
        cnt_end_i <= 32'd11;
        #PERIOD;
        run_i <= 1;
        #PERIOD
        run_i <= 0;

        #400

        $finish;
    end

endmodule
