`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2024/11/6
// Module Name: adder_tree
// Target Devices: U250
// Tool Versions: Vivado 2020.1
//////////////////////////////////////////////////////////////////////////////////


module adder_tree
    import TYPES::*;
    (
    input           clk_i,
                    rst_n_i,
    input   [7:0][31:0]  ps_32_i,
    input   [7:0][31:0]  sc_32_i,
    // input   mode_t  mode_i,
    input   width_t width_i,
    output  prng_t  sum_o
    );

    wire [6:0] tab_carrychain =     {width_i.is64, width_i.is128, width_i.is64, width_i.is256,
                                     width_i.is64, width_i.is128, width_i.is64};
    u32_w_c_t [7:0][7:0] w_cy_sum, r_cy_sum;
    u32_w_c_t [7:0] tmp_u32_w_c_t;

    generate
        for(genvar i = 0; i < 8; i = i + 1) begin
            for(genvar j = 0; j < 8; j = j + 1) begin : gen_1st_adders
                if (i == 0)
                    assign w_cy_sum[0][j] = ps_32_i[j] + sc_32_i[j];
                else begin : gen_2to8th_adders
                    if(i == j) begin
                        assign tmp_u32_w_c_t[i]
                                = r_cy_sum[i - 1][j].val + (r_cy_sum[i - 1][j - 1].carry & tab_carrychain[i - 1]);
                        assign w_cy_sum[i][j].val = tmp_u32_w_c_t[i].val;
                        assign w_cy_sum[i][j].carry = tmp_u32_w_c_t[i].carry | r_cy_sum[i - 1][j].carry;
                    end
                    else begin
                        assign w_cy_sum[i][j] = r_cy_sum[i - 1][j];
                    end
                end
            end
        end
    endgenerate

    always_ff @(posedge clk_i) begin
        if(!rst_n_i) begin
            r_cy_sum <= '0;
        end
        else begin
            r_cy_sum <= w_cy_sum;
        end
    end

    assign sum_o = f_u32_w_c_t_to_256(r_cy_sum[7]);

    function automatic prng_t f_u32_w_c_t_to_256;
        input u32_w_c_t [7:0] array32;

        f_u32_w_c_t_to_256 = 0;
        for(integer i = 0; i < 8; i = i + 1) begin
            f_u32_w_c_t_to_256 = f_u32_w_c_t_to_256 | (array32[i].val << (32*i));
        end
    endfunction

endmodule
