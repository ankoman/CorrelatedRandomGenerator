`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2024/10/30
// Module Name: PNG256
// Tool Versions: Vivado 2020.1
//////////////////////////////////////////////////////////////////////////////////

module PRNG256(
    input [127:0] Kin,
    input [6:0] prefix,
    input [31:0] cnt,
    output [255:0] Dout,
    input Drdy,
    output Dvld,
    input CLK,
    input RSTn
    );

    wire [127:0] aes0_out, aes1_out;
    assign Dout = {aes0_out, aes1_out};

    AES_Composite_enc_pipeline aes0(
        .Kin(Kin),
        .Din({1'b0, prefix, 88'd0, cnt}),
        .Dout(aes0_out),
        .Drdy,
        .Dvld,
        .CLK,
        .RSTn
    );

    AES_Composite_enc_pipeline aes1(
        .Kin(Kin),
        .Din({1'b1, prefix, 88'd0, cnt}),
        .Dout(aes1_out),
        .Drdy,
        .Dvld(),
        .CLK,
        .RSTn
    );
endmodule
