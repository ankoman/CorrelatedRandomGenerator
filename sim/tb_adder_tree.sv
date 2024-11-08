`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2024/11/6
// Module Name: tb_adder_tree.sv
// Tool Versions: Vivado 2020.1
//////////////////////////////////////////////////////////////////////////////////

module tb_adder_tree;
    import TYPES::*;
    import FUNCS::*;

    typedef struct packed {
        prng_t ps;
        prng_t sc;
        prng_t ans_32;
        prng_t ans_64;
        prng_t ans_128;
        prng_t ans_256;
    } tv_adder_tree_t;

    // adder_tree Parameters
    localparam integer PERIOD  = 10;
    localparam integer N_TVs   = 100000;
    localparam integer N_PIPELINE_STAGES = 8;

    // adder_tree Inputs
    reg   clk_i                                = 1;
    reg   rst_n_i                              = 1;
    reg   [7:0][31:0]  ps_32_i;
    reg   [7:0][31:0]  sc_32_i;
    prng_t res_32, res_64, res_128, res_256;

    always begin
        #(PERIOD/2) clk_i <= ~clk_i;
    end

    adder_tree dut_32 (
        .clk_i,
        .rst_n_i,
        .ps_32_i,
        .sc_32_i,
        .width_i(3'd0),
        .sum_o(res_32)
    );

    adder_tree dut_64 (
        .clk_i,
        .rst_n_i,
        .ps_32_i,
        .sc_32_i,
        .width_i(3'd1),
        .sum_o(res_64)
    );

    adder_tree dut_128 (
        .clk_i,
        .rst_n_i,
        .ps_32_i,
        .sc_32_i,
        .width_i(3'd3),
        .sum_o(res_128)
    );

    adder_tree dut_256 (
        .clk_i,
        .rst_n_i,
        .ps_32_i,
        .sc_32_i,
        .width_i(3'd7),
        .sum_o(res_256)
    );

    // Variables
    logic [`LEN_PRNG*6 - 1: 0] mem_tv [N_TVs];
    tv_adder_tree_t tv;
    tv_adder_tree_t [N_PIPELINE_STAGES - 1:0] reg_ans;

    always @(posedge clk_i)
        reg_ans <= {reg_ans[N_PIPELINE_STAGES - 2:0], tv};

    initial
    begin
        //$readmemh("C:\\Users\\sakamoto\\Desktop\\prj\\CorrelatedRandomGenerator\\dat\\tv_adder_tree.txt", mem_tv);
        $readmemh("C:\\Users\\seedtyps\\Desktop\\CorrelatedRandomGenerator\\dat\\tv_adder_tree.txt", mem_tv);
        #100;
        rst_n_i <= 0;
        ps_32_i <= '0;
        sc_32_i <= '0;
        #100;
        rst_n_i <= 1;
        #100;
        for(integer i = 0; i < N_TVs; i = i + 1) begin
            tv = mem_tv[i];
            ps_32_i = tv.ps;
            sc_32_i = tv.sc;
            if(i >= N_PIPELINE_STAGES) begin
                // $display("#%d: ans_32 = %h, res_32 = %h", i, reg_ans[N_PIPELINE_STAGES - 1].ans_32, res_32);
                if(res_32 !== reg_ans[N_PIPELINE_STAGES - 1].ans_32) begin
                    $display("#%d Failed: ans_32 = %h, res_32 = %h", i, reg_ans[N_PIPELINE_STAGES - 1].ans_32, res_32);
                    $stop();
                end
                if(res_64 !== reg_ans[N_PIPELINE_STAGES - 1].ans_64) begin
                    $display("#%d Failed: ans_64 = %h, res_64 = %h", i, reg_ans[N_PIPELINE_STAGES - 1].ans_64, res_64);
                    $stop();
                end
                if(res_128 !== reg_ans[N_PIPELINE_STAGES - 1].ans_128) begin
                    $display("#%d Failed: ans_128 = %h, res_128 = %h", i, reg_ans[N_PIPELINE_STAGES - 1].ans_128, res_128);
                    $stop();
                end
                if(res_256 !== reg_ans[N_PIPELINE_STAGES - 1].ans_256) begin
                    $display("#%d Failed: ans_256 = %h, res_256 = %h", i, reg_ans[N_PIPELINE_STAGES - 1].ans_256, res_256);
                    $stop();
                end
            end  
            #PERIOD;
        end
        $finish;
    end

endmodule
