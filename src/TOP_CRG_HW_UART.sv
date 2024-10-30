`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2024/10/24
// Module Name: TOP_CRG_HW_UART
// Target Devices: Arty-A7(-100)
// Tool Versions: Vivado 2020.1
//////////////////////////////////////////////////////////////////////////////////


module TOP_CRG_HW_UART
    import TYPES::*;
    (
    input   CLK100MHZ,
            ck_rst_n,
            uart_txd_in,
    output  uart_rxd_out,
    [3:0]   led
    );

    localparam len_din = 128;
    localparam len_dout = 256;

    wire clk = CLK100MHZ;
    wire rst_n = ck_rst_n;
    wire run, extin_en, dvld;
    reg busy;
    wire [7:0] addr_extin, addr_extout;
    logic [len_din - 1:0] extin_data, r_key;
    logic [len_dout - 1:0] dout256, tmp_for_impl;


    assign led[0] = busy;

    UART_CTRL #(.len_din(len_din), .len_dout(len_dout)) uart_ctrl (
        .clk,
        .rst_n,
        .uart_rx(uart_txd_in),
        .uart_tx(uart_rxd_out),
        .extout_data(tmp_for_impl),
        .addr_extin,
        .addr_extout,
        .extin_data,
        .extin_en,
        .run
    );

    logic [31:0] input_cnt;
    always @(posedge clk) begin
        if(!rst_n) begin
            input_cnt <= '0;
            busy <= 0;
        end
        else begin
            if(run)
                busy <= 1;
            else if (input_cnt == 8'd255)
                busy <= 0;
            if (busy)
                input_cnt <= input_cnt + 1;
        end
    end

    always @(posedge clk) begin
        if(!rst_n) begin
            r_key <= '0;
        end
        else if(extin_en) begin
            r_key <= extin_data;
        end
    end

    PRNG256 prng256_0(
        .Kin(r_key),
        .prefix(7'd0),
        .cnt(input_cnt),
        .Dout(dout256),
        .Drdy(busy),
        .Dvld(dvld),
        .CLK(clk),
        .RSTn(rst_n)
    );

    singleport_ram ram(
        .clk,
        .we(dvld),
        .addr(dvld ? input_cnt - 32'd10 : addr_extout),
        .din(dout256),
        .dout(tmp_for_impl)
    );
endmodule

module singleport_ram (
    input clk, we,
    input [7:0] addr,
    input [255:0] din,
    output logic [255:0] dout
);
    logic [255:0] ram [255:0];

    always_ff @(posedge clk) begin
        if (we)
            ram[addr] <= din;
        dout <= ram[addr];
    end
endmodule