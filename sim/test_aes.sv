`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2024/10/26
// Module Name: test_aes.sv
// Tool Versions: Vivado 2020.1
//////////////////////////////////////////////////////////////////////////////////



module test_aes;
    localparam 
        CYCLE = 10,
        DELAY = 2,
        N_LOOP = 20;
                
    reg clk, rst_n, run, run_d;
    reg [23:0] cycle_cnt;
    reg [127:0] key, din;
    wire [127:0] aes_out0;

    always begin
        #(CYCLE/2) clk <= ~clk;
    end

    // always @(posedge clk)begin
    //     if(run)
    //         cycle_cnt <= '0;
    //     else if(busy)
    //         cycle_cnt <= cycle_cnt + 1'b1;
    // end

    AES_Composite_enc aes0(
        .Kin(key),
        .Din(din),
        .Dout(aes_out0),
        .Krdy(run),
        .Drdy(run_d),
        .Kvld(),
        .Dvld(),
        .EN(1'b1),
        .BSY(),
        .CLK(clk),
        .RSTn(rst_n)
    );

    /*-------------------------------------------
    Test
    -------------------------------------------*/
    initial begin
        clk <= 1;
        rst_n <= 1;
        #1000
        run <= 0;
        rst_n <= 0;
        key <= '0;
        din <= '0;
        #100
        rst_n <= 1;
        #1000;
        key <= 128'd123;
        din <= 128'd0;
        run <= 1'b1;
        #CYCLE
        run <= 1'b0;
        run_d <= 1'b1;
        #CYCLE
        run_d <= 1'b0;
    end

endmodule
