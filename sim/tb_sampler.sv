`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2025/02/07
// Module Name: tb_sampler.sv
// Tool Versions: Vivado 2024.1
//////////////////////////////////////////////////////////////////////////////////



module tb_sampler;
    localparam integer
        CYCLE = 10,
        DELAY = 2,
        N_LOOP = 20;
                
    reg clk_i, rst_n_i, run_i;
    reg [255:0] rho_i;
    wire done_o;


    always begin
        #(CYCLE/2) clk_i <= ~clk_i;
    end

    sampleA dut(
        clk_i,
        rst_n_i,
        run_i,
        rho_i,
        done_o,
        polymat_A_o
    );

    /*-------------------------------------------
    Test
    -------------------------------------------*/
    initial begin
        clk_i <= 1;
        rst_n_i <= 1;
        #1000
        rst_n_i <= 0;
        run_i <= 0;
        rho_i <= 256'h12345;
        #100
        rst_n_i <= 1;
        #5000;
        run_i <= 1;
        #CYCLE
        run_i <= 0;
    end

endmodule
