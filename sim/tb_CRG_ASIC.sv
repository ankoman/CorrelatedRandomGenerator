`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2024/12/6
// Module Name: tb_CRG_ASIC.sv
// Tool Versions: Vivado 2024.1
//////////////////////////////////////////////////////////////////////////////////



module tb_CRG_ASIC;
    localparam integer
        CYCLE_10 = 280,
        CYCLE_70 = 40,
        CYCLE_140 = 20,
        DELAY = 1,
        N_LOOP = 20;
                
    reg clk_10m_i, clk_70m_i, clk_140m_i, rst_n_i;
    wire [111:0] data;
    reg [111:0] din;
    reg drdy;

    assign data = (drdy) ? din : 'z;

    always begin
        #(CYCLE_10/2) clk_10m_i <= ~clk_10m_i;
    end

    always begin
        #(CYCLE_70/2) clk_70m_i <= ~clk_70m_i;
    end

    always begin
        #(CYCLE_140/2) clk_140m_i <= ~clk_140m_i;
    end

    TOP_CRG_HW_ASIC dut(
        .clk_10m_i,
        .clk_70m_i,
        .rst_n_i,
        .din_rdy_i(drdy),
        .dout_vld_o(),
        .dinout(data)
    );

    /*-------------------------------------------
    Test
    -------------------------------------------*/
    initial begin
        clk_10m_i <= 1;
        clk_70m_i <= 1;
        clk_140m_i <= 1;
        rst_n_i <= 1;
        #DELAY;
        #1000
        drdy <= '0;
        din <= '0;
        rst_n_i <= 0;
        #1000
        rst_n_i <= 1;
        #1000;
        drdy <= 1;
        din <= 112'he3e70682c2094cac629f6fbed82c;
        #CYCLE_140;
        #CYCLE_140;
        din <= {16'h07cd, 3'b001, 3'b100, 32'd2, 32'd12, 1'b1, 25'd0};
        #CYCLE_140;
        #CYCLE_140;
        drdy <= 0;

        #400;

        $finish;
    end

endmodule
