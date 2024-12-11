`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2024/12/12
// Module Name: tb_ML_KEM.sv
// Tool Versions: Vivado 2024.1
//////////////////////////////////////////////////////////////////////////////////



module tb_ML_KEM;
    localparam integer
        CYCLE = 10,
        DELAY = 1,
        N_LOOP = 20;

    import TYPES_KEM::*;

    reg clk_i, rst_n_i, run_i;
    kem_mode_t mode_i;

    always begin
        #(CYCLE/2) clk_i <= ~clk_i;
    end

    ML_KEM dut (
        .clk_i,
        .rst_n_i,
        .run_i,
        .mode_i
    );

    /*-------------------------------------------
    Test
    -------------------------------------------*/
    initial begin
        clk_i <= 1;
        rst_n_i <= 1;
        #DELAY;
        #100
        rst_n_i <= 0;
        run_i <= 0;
        mode_i <='0;
        #100
        rst_n_i <= 1;
        #100;
        mode_i <= 3'b100;
        run_i <= 1;
        #CYCLE;
        run_i <= 0;

        #1000; 
        $finish;
    end

endmodule
