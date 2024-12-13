`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2024/12/12
// Module Name: TRNG_256
// Target Devices: U250
// Tool Versions: Vivado 2024.1
//////////////////////////////////////////////////////////////////////////////////


module TRNG_256
    (
        input clk_i,
        input rst_n_i,
        input run_i,
        output dvld_o,
        output [255:0] dout_o
    );

    logic [31:0] cnt_trng;
    always @(posedge clk_i) begin
        if(!rst_n_i)
            cnt_trng <='0;
        else
            cnt_trng <= cnt_trng + 1;
    end

    PRNG256 #(.PIPELINE(0)) u_trng (
        .Kin(128'he3e70682c2094cac629f6fbed82c07cd),
        .prefix(7'h55),
        .cnt(cnt_trng),
        .Dout(dout_o),
        .Drdy(run_i),
        .Dvld(dvld_o),
        .CLK(clk_i),
        .RSTn(rst_n_i)
    );

endmodule