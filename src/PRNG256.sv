`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2024/10/30
// Module Name: PNG256
// Tool Versions: Vivado 2020.1
//////////////////////////////////////////////////////////////////////////////////

module PRNG256
    import TYPES::*;
    #(
        parameter integer PIPELINE = 1)
    (
    input [127:0] Kin,
    input [6:0] prefix,
    input cr_cnt_t cnt,
    output [255:0] Dout,
    input Drdy,
    output Dvld,
    input CLK,
    input RSTn
    );

    wire [127:0] aes0_out, aes1_out;
    assign Dout = {aes0_out, aes1_out};
    wire [128 - $bits(cr_cnt_t) - 8 - 1:0] padding = '0;

    generate
        if (PIPELINE == 1) begin
            AES_Composite_enc_pipeline aes0_pl(
                .Kin(Kin),
                .Din({1'b0, prefix, padding, cnt}),
                .Dout(aes0_out),
                .Drdy,
                .Dvld,
                .CLK,
                .RSTn
            );

            AES_Composite_enc_pipeline aes1_pl(
                .Kin(Kin),
                .Din({1'b1, prefix, padding, cnt}),
                .Dout(aes1_out),
                .Drdy,
                .Dvld(),
                .CLK,
                .RSTn
            );
        end
        else begin
            logic Krdy;
            always @(posedge CLK) begin
                if(!RSTn)
                    Krdy <= '0;
                else
                    Krdy <= Drdy;
            end

            AES_Composite_enc aes0(
                .Kin(Kin),
                .Din({1'b0, prefix, padding, cnt}),
                .Dout(aes0_out),
                .Drdy,
                .Dvld,
                .CLK,
                .RSTn,
                .Krdy,
                .Kvld(),
                .EN(1'b1),
                .BSY()
            );

            AES_Composite_enc aes1(
                .Kin(Kin),
                .Din({1'b1, prefix, padding, cnt}),
                .Dout(aes1_out),
                .Drdy,
                .Dvld(),
                .CLK,
                .RSTn,
                .Krdy,
                .Kvld(),
                .EN(1'b1),
                .BSY()
            );
        end
    endgenerate
endmodule
