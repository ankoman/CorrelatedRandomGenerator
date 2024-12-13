`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2024/12/06
// Module Name: TOP_CRG_HW_ASIC
// Target Devices: 
// Tool Versions: Vivado 2024.1
//////////////////////////////////////////////////////////////////////////////////

localparam integer LEN_INOUT = 112;

module TOP_CRG_HW_ASIC
    import TYPES::*;
    (
    input   clk_10m_i,
    input   clk_70m_i,
    input   rst_n_i,
    input   din_rdy_i,
    output  dout_vld_o,
    inout[LEN_INOUT - 1:0] dinout
    );

    logic din_rdy_prev, first_input, second_input, run_start, run;
    logic [6:0] sreg_run;
    always_ff @(posedge clk_70m_i) begin
        din_rdy_prev <= din_rdy_i;
        sreg_run <= {sreg_run[5:0], run_start};
    end
    assign first_input = ({din_rdy_prev, din_rdy_i} == 2'b01) ? 1'b1 : 1'b0;
    assign second_input = ({din_rdy_prev, din_rdy_i} == 2'b11) ? 1'b1 : 1'b0;
    assign run_start = ({din_rdy_prev, din_rdy_i} == 2'b10) ? 1'b1 : 1'b0;
    assign run = |sreg_run;

    reg r_party;
    key_t r_key;
    width_t r_width;
    mode_t r_mode;
    cr_cnt_t r_cnt_start, r_cnt_end;
    prng_t a_o, b_o, c_o;
    logic [7:0] e_o;

    always @(posedge clk_70m_i) begin
        if (!rst_n_i) begin
            r_key <= '0;
            r_party <= '0;
            r_width <= '0;
            r_mode <= '0;
            r_cnt_start <= '0;
            r_cnt_end <= '0;
        end
        else if (first_input) begin
            r_key[127:16] <= dinout;
        end
        else if (second_input) begin
            {r_key[15:0], r_width, r_mode, r_cnt_start, r_cnt_end, r_party} <= dinout[111:25];
        end
    end

    CRG u_crg (
        .clk_i(clk_10m_i),
        .rst_n_i(rst_n_i),
        .party_i(r_party),
        .key_i(r_key),
        .width_i(r_width),
        .mode_i(r_mode),
        .cnt_start_i(r_cnt_start),
        .cnt_end_i(r_cnt_end),
        .run_i(run),
        .a_o,
        .b_o,
        .c_o,
        .e_o,
        .dvld_o(dout_vld_o)
    );

    logic [6:0][LEN_INOUT - 1:0] dout_buf;

    always @(posedge clk_10m_i) begin
        if (!rst_n_i) begin
            dout_buf <= '0;
        end
        else begin
            if (dout_vld_o) begin
                dout_buf <= {a_o, b_o, c_o, e_o, 8'd0};
            end
        end
    end

    logic [2:0] cnt_index;

    always @(posedge clk_70m_i) begin
        if (!rst_n_i) begin
            cnt_index <= '0;
        end
        else if (dout_vld_o) begin
            if (cnt_index == 3'd6)
                cnt_index <= '0;
            else
                cnt_index <= cnt_index + 1'b1;

        end
    end

    assign dinout = din_rdy_i ?  'z : dout_buf[cnt_index];

endmodule
