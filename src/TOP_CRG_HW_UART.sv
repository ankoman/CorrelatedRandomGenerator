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
    localparam len_dout = 128;

    wire clk = CLK100MHZ;
    wire rst_n = ck_rst_n;
    wire run, extin_en, dvld;
    reg busy;
    wire [7:0] addr_extin, addr_extout;
    logic [len_din - 1:0] extin_data, key0, aes_out0, aes_out1, aes_out2;

    assign led[0] = busy;

    UART_CTRL #(.len_din(len_din), .len_dout(len_dout)) uart_ctrl (
        .clk,
        .rst_n,
        .uart_rx(uart_txd_in),
        .uart_tx(uart_rxd_out),
        .extout_data(aes_out2),
        .addr_extin,
        .addr_extout,
        .extin_data,
        .extin_en,
        .run
    );

    // AES_Composite_enc aes0(
    //     .Kin(extin_data),
    //     .Din(128'd0),
    //     .Dout(aes_out0),
    //     .Krdy(extin_en),
    //     .Drdy(run),
    //     .Kvld(),
    //     .Dvld(),
    //     .EN(1'b1),
    //     .BSY(busy),
    //     .CLK(clk),
    //     .RSTn(rst_n)
    // );

    // AES_Composite_enc aes1(
    //     .Kin(extin_data+1),
    //     .Din(128'd0),
    //     .Dout(aes_out1),
    //     .Krdy(extin_en),
    //     .Drdy(run),
    //     .Kvld(),
    //     .Dvld(),
    //     .EN(1'b1),
    //     .BSY(),
    //     .CLK(clk),
    //     .RSTn(rst_n)
    // );

    logic [7:0] input_cnt;
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
            key0 <= '0;
        end
        else if(extin_en) begin
            key0 <= extin_data;
        end
    end

    AES_Composite_enc_pipeline aes2(
        .Kin(key0),
        .Din({120'd0, input_cnt}),
        .Dout(aes_out0),
        .Drdy(busy),
        .Dvld(dvld),
        .CLK(clk),
        .RSTn(rst_n)
    );

    singleport_ram ram(
        .clk,
        .we(dvld),
        .addr(dvld ? input_cnt - 8'd10 : addr_extout),
        .din(aes_out0),
        .dout(aes_out2)
    );
endmodule

module singleport_ram (
    input clk, we,
    input [7:0] addr,
    input [127:0] din,
    output logic [127:0] dout
);
    logic [127:0] ram [255:0];

    always_ff @(posedge clk) begin
        if (we)
            ram[addr] <= din;
        dout <= ram[addr];
    end
endmodule