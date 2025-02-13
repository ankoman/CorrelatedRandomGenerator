`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2024/02/05
// Module Name: sampleA
// Target Devices: U250
// Tool Versions: Vivado 2024.1
//////////////////////////////////////////////////////////////////////////////////


module sampleA
     import TYPES_KEM::*;
    (
        input clk_i,
        input rst_n_i,
        input run_i,
        input [255:0] rho_i,
        output done_o,
        output polymat_t polymat_A_o
    );
    localparam CNT_WIDTH = $clog2(ML_KEM_K*ML_KEM_K);
    localparam K_WIDTH = $clog2(ML_KEM_K);


    logic [CNT_WIDTH:0] cnt_kk;
    logic sample_poly_run, sample_poly_done, sample_poly_done_d, busy, count;
    logic [K_WIDTH - 1:0] index_i, index_j, latch_i, latch_j;
    poly_t poly_o;

    assign busy = |cnt_kk[1:0];
    assign count = run_i || (sample_poly_done_d && busy);
    assign done_o = cnt_kk[CNT_WIDTH] && sample_poly_done; // ML-KEM-512 specific definition
    assign index_i = cnt_kk[1]; // ML-KEM-512 specific definition
    assign index_j = cnt_kk[0]; // ML-KEM-512 specific definition

    always_ff @(posedge clk_i) begin
        if(!rst_n_i || done_o) begin
            cnt_kk <= '0;
            latch_i <= '0;
            latch_j <= '0;
        end
        else if(count) begin
            cnt_kk <= cnt_kk + 1'b1;
            latch_i <= index_i;
            latch_j <= index_j;
        end
    end

    always_ff @(posedge clk_i) begin
        sample_poly_run <= count;
        sample_poly_done_d <= sample_poly_done;
    end

    sampleNTT u0(
        .clk_i,
        .rst_n_i,
        .run_i(sample_poly_run),
        .rho_i,
        .index_i_i(8'(latch_i)),
        .index_j_i(8'(latch_j)),
        .done_o(sample_poly_done),
        .poly_o
    );

    always_ff @(posedge clk_i) begin
        if(!rst_n_i)
            polymat_A_o <= '0;
        else if (sample_poly_done)
            polymat_A_o[latch_i][latch_j] <= poly_o;
    end

endmodule

module sampleNTT
     import TYPES_KEM::*;
    (
        input clk_i,
        input rst_n_i,
        input run_i,
        input [255:0] rho_i,
        input [7:0] index_i_i,
        input [7:0] index_j_i,
        output logic done_o,
        output poly_t poly_o
    );

    keccak_1600_t xof_in, xof_out, xof_out_conv;
    logic [4:0][63:0] xof_msg;
    assign xof_out_conv = keccak_1600_conv(xof_out);
    assign xof_msg = {40'd0, 8'h1f, index_i_i, index_j_i, rho_i};

    assign xof_in[0][0] = xof_msg[0]; // [63:0]
    assign xof_in[1][0] = xof_msg[1]; // [127:64]
    assign xof_in[2][0] = xof_msg[2]; // [191:128]
    assign xof_in[3][0] = xof_msg[3]; // [255:192]
    assign xof_in[4][0] = xof_msg[4]; // [319:256]
	assign xof_in[0][4] = 64'h8000000000000000;
    generate
        for(genvar i = 1; i < 5; i = i + 1) begin
            for (genvar j = 0; j < 5; j = j + 1) begin
                if((i == 4) && (j == 0)) begin
                    // Do nothing
                end
                else
                    assign xof_in[j][i] = 64'h0;
            end
        end
    endgenerate

    logic xof_rdy, xof_rdy_prev;
    logic [6:0] cnt_112;
    logic [8:0] cnt_sampled_coeff;
    logic [7:0] cnt_squeezed;
    logic [1343:0] xof_rate;
    wire xof_run = run_i | sample_end;

    always_ff @(posedge clk_i) begin
        xof_rdy_prev <= xof_rdy;
    end
    wire sample_start = ({xof_rdy_prev, xof_rdy} == 2'b01) ? 1'b1 : 1'b0; // Rising edge. Same time as squeeze done.
    wire sample_end = (cnt_112 == 7'd112) ? 1'b1 : 1'b0;
    wire sample112_busy = |cnt_112;
    wire sample_coeff_busy = |cnt_sampled_coeff;
    wire [ML_KEM_LEN_Q - 1:0] coeff = xof_rate[ML_KEM_LEN_Q - 1:0];
    wire is_reject = (coeff > (ML_KEM_Q - 1)) ? 1'b1 : 1'b0;
    wire sel_xor_in = |cnt_squeezed;
    assign done_o = cnt_sampled_coeff[8];

    always_ff @(posedge clk_i) begin
        if(!rst_n_i | done_o) begin
            cnt_squeezed <= '0;
        end
        else if(sample_start) begin
            cnt_squeezed <= cnt_squeezed + 1'b1;    // If overflowing, then should abort
        end
    end

    always_ff @(posedge clk_i) begin
        if(!rst_n_i || sample_end || done_o) begin
            cnt_112 <= '0;
        end
        else if(sample_start | sample112_busy) begin
            cnt_112 <= cnt_112 + 1'b1;
        end
    end

    always_ff @(posedge clk_i) begin
        if(!rst_n_i || done_o) begin
            poly_o <= '0;
            cnt_sampled_coeff <= '0;
        end
        else if(sample112_busy && !is_reject) begin
            poly_o <= {coeff, poly_o[255:1]};
            cnt_sampled_coeff <= cnt_sampled_coeff + 1'b1;
        end
    end

    always_ff @(posedge clk_i) begin
        if(!rst_n_i) begin
            xof_rate <= '0;
        end
        else if(sample_start) begin
            xof_rate <= xof_out_conv[1343:0];
        end
        else if(sample112_busy) begin
            xof_rate <= {12'd0, xof_rate[1343:12]};
        end
    end

	keccak_top #(.d(0), .b(1600), .W(64)) xof (
		.Clock(clk_i), 
		.Reset(xof_run), 
		.InData(sel_xor_in ? xof_out : xof_in), 
		.FreshRand(), 
		.Ready(xof_rdy), 
		.OutData(xof_out)
	);

    function automatic keccak_1600_t keccak_1600_conv(input keccak_1600_t din);
        for (int i = 0; i < 5; i++) begin
            keccak_1600_conv[0][i] = din[i][0]; // [63:0]
            keccak_1600_conv[1][i] = din[i][1]; // [127:64]
            keccak_1600_conv[2][i] = din[i][2]; // [191:128]
            keccak_1600_conv[3][i] = din[i][3]; // [255:192]
            keccak_1600_conv[4][i] = din[i][4]; // [319:256]
        end
    endfunction
endmodule
