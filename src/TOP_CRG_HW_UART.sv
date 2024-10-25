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


module TOP_CRG_HW_UART(
    input   CLK100MHZ,
            ck_rst_n,
            uart_txd_in,
    output  uart_rxd_out,
    [3:0]   led
    );

    localparam len_din = 128;
    localparam len_dout = 768;

    wire clk = CLK100MHZ;
    wire rst_n = ck_rst_n;
    wire run, extin_en, busy;
    wire [7:0] addr_extin, addr_extout;
    logic [len_din - 1:0] extin_data, aes_out0, aes_out1, aes_out2;

    assign led[0] = busy;

    UART_CTRL #(.len_din(len_din), .len_dout(len_dout)) uart_ctrl (
        .clk,
        .rst_n,
        .uart_rx(uart_txd_in),
        .uart_tx(uart_rxd_out),
        .extout_data({aes_out0, 128'd0, aes_out1, 128'd0, aes_out2, 128'd0}),
        .addr_extin,
        .addr_extout,
        .extin_data,
        .extin_en,
        .run
    );

    AES_Composite_enc aes0(
        .Kin(extin_data),
        .Din(128'd0),
        .Dout(aes_out0),
        .Krdy(extin_en),
        .Drdy(run),
        .Kvld(),
        .Dvld(),
        .EN(1'b1),
        .BSY(busy),
        .CLK(clk),
        .RSTn(rst_n)
    );

    AES_Composite_enc aes1(
        .Kin(extin_data+1),
        .Din(128'd0),
        .Dout(aes_out1),
        .Krdy(extin_en),
        .Drdy(run),
        .Kvld(),
        .Dvld(),
        .EN(1'b1),
        .BSY(),
        .CLK(clk),
        .RSTn(rst_n)
    );

    AES_Composite_enc aes2(
        .Kin(extin_data+2),
        .Din(128'd0),
        .Dout(aes_out2),
        .Krdy(extin_en),
        .Drdy(run),
        .Kvld(),
        .Dvld(),
        .EN(1'b1),
        .BSY(),
        .CLK(clk),
        .RSTn(rst_n)
    );
endmodule