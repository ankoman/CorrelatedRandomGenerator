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
    output  [3:0]   led
    );

    localparam integer len_din = 128;
    localparam integer len_dout = 256;

    wire clk = CLK100MHZ;
    wire rst_n = ck_rst_n;
    wire run, extin_en, dvld;
    reg busy;
    wire [7:0] addr_extin, addr_extout;
    logic [len_din - 1:0] extin_data, r_key;
    logic [len_dout - 1:0] dout256_0, dout256_1, dout256_2, tmp_for_impl;


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

    CRG u_dut_0 (
        .clk_i(clk),
        .rst_n_i(rst_n),
        .party_i(tmp_for_impl[5]),
        .key_i(r_key),
        .width_i(tmp_for_impl[2:0]),
        .mode_i(tmp_for_impl[2:0]),
        .cnt_start_i(1),
        .cnt_end_i(100),
        .run_i(run),
        .a_o(dout256_0),
        .b_o(dout256_1),
        .c_o(dout256_2),
        .dvld_o(dvld)
    );


    singleport_ram ram(
        .clk,
        .we(dvld),
        .addr(dvld ? input_cnt - 32'd10 : addr_extout),
        .din({dout256_0, dout256_1, dout256_2}),
        .dout(tmp_for_impl)
    );
endmodule

module singleport_ram (
    input clk, we,
    input [7:0] addr,
    input [767:0] din,
    output logic [767:0] dout
);
    logic [767:0] ram [255];

    always_ff @(posedge clk) begin
        if (we)
            ram[addr] <= din;
        dout <= ram[addr];
    end
endmodule
