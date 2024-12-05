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
    logic run, run_d, extin_en, dvld;
    reg busy, r_party;
    key_t r_key;
    width_t r_width;
    mode_t r_mode;
    cr_cnt_t r_cnt_start, r_cnt_end, r_n_CRs;
    wire [7:0] addr_extin, addr_extout, e_o;
    logic [len_din - 1:0] extin_data;
    logic [len_dout - 1:0] a_o, b_o, c_o, tmp_for_impl;


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
            r_mode <= '0;
            r_width <= '0;
        end
        else if(extin_en) begin
            if (addr_extin === 8'h10)
                r_key <= extin_data;
            else if (addr_extin === 8'h11)
                r_mode <= extin_data[2:0];
            else if (addr_extin === 8'h12)
                r_width <= extin_data[2:0];
            else if (addr_extin === 8'h13)
                r_n_CRs <= extin_data[31:0];
        end
    end


    always @(posedge clk) begin
        if(!rst_n) begin
            r_cnt_start <= '0;
            r_cnt_end <= '0;
        end
        else if(run) begin
            // Blocking
            r_cnt_start <= r_cnt_end + 1;
            r_cnt_end <= r_cnt_end + r_n_CRs;
        end
    end

    always @(posedge clk) begin
        if(!rst_n)
            run_d <= '0;
        else
            run_d <= run;
    end
    CRG u_dut_0 (
        .clk_i(clk),
        .rst_n_i(rst_n),
        .party_i(1'b1),
        .key_i(r_key),
        .width_i(r_width),
        .mode_i(r_mode),
        .cnt_start_i(r_cnt_start),
        .cnt_end_i(r_cnt_end),
        .run_i(run_d),
        .a_o,
        .b_o,
        .c_o,
        .e_o,
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
    input [775:0] din,
    output logic [775:0] dout
);
    logic [775:0] ram [255];

    always_ff @(posedge clk) begin
        if (we)
            ram[addr] <= din;
        dout <= ram[addr];
    end
endmodule
