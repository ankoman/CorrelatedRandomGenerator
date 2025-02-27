`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2025/02/27
// Module Name: tb_NTT_wrapper.sv
// Tool Versions: Vivado 2020.1
//////////////////////////////////////////////////////////////////////////////////

module tb_NTT_wrapper;
    import TYPES_KEM::*;
    // Parameters
    parameter CLK_PERIOD = 10;

    // Signals
    logic clk_i, rst_n_i, run_i, done_o;
    poly_t poly_a_i, poly_b_i, poly_c_o;
    ntt_mode_t mode_i;

    reg [11:0] dina [0:255];
    reg [11:0] dinb [0:255];
    reg [11:0] doua	[0:255];
    reg [11:0] doub	[0:255];

    // DUT instance
    NTT_wrapper dut(
        .clk_i,
        .rst_n_i,
        .run_i,
        .poly_a_i(poly_t'(dina)),
        .poly_b_i(poly_t'(dinb)),
        .mode_i,
        .poly_c_o,
        .done_o
    );

    // Clock generation
    initial begin
        clk_i = 0;
        forever #(CLK_PERIOD/2) clk_i = ~clk_i;
    end

    initial begin
        rst_n_i = 0;
        // Test data for NTT
        //C:\Users\sakamoto\Desktop\prj\CorrelatedRandomGenerator\src_others\kyber-polmul-hw-master
        $readmemh("C:/Users/sakamoto/Desktop/prj/CorrelatedRandomGenerator/src_others/kyber-polmul-hw-master/pe1/test_pe1/KYBER_DIN0.txt" , dina);
        $readmemh("C:/Users/sakamoto/Desktop/prj/CorrelatedRandomGenerator/src_others/kyber-polmul-hw-master/pe1/test_pe1/KYBER_DIN1.txt" , dinb);
        $readmemh("C:/Users/sakamoto/Desktop/prj/CorrelatedRandomGenerator/src_others/kyber-polmul-hw-master/pe1/test_pe1/KYBER_DIN0_MFNTT.txt" , doua);
        $readmemh("C:/Users/sakamoto/Desktop/prj/CorrelatedRandomGenerator/src_others/kyber-polmul-hw-master/pe1/test_pe1/KYBER_DIN1_MFNTT.txt" , doua);
        #20;
        rst_n_i = 1;
        #CLK_PERIOD;

        //NTT
        mode_i = NTT_a;
        run_i = 1;
        #CLK_PERIOD;
        run_i = 0;
        wait(done_o == 1);
        #CLK_PERIOD;

        //PWM
        mode_i = PWM_ab;
        run_i = 1;
        #CLK_PERIOD;
        run_i = 0;
        wait(done_o == 1);
        #CLK_PERIOD;
    end

    // Monitor
    initial begin
        //$monitor("Time: %0t, clk: %b, rst_n_i: %b", $time, clk, rst_n);
    end

endmodule