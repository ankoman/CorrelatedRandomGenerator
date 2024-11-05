`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2024/10/24
// Module Name: CSA
// Target Devices: U250
// Tool Versions: Vivado 2020.1
//////////////////////////////////////////////////////////////////////////////////

module CSA #(
    parameter len = 0
    )(
    input [len-1:0] a_i, b_i, c_i,
    output [len-1:0] ps_o, sc_o
    );

    assign ps_o = a_i ^ b_i ^ c_i;
    assign sc_o = (a_i&b_i) | (a_i&c_i) | (b_i&c_i);

endmodule