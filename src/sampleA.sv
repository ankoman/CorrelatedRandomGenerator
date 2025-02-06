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
        input [31:0] rho_i,
        output done_o,
        output polymat_t polymat_A_o
    );
    localparame CNT_WIDTH = $clog(ML_KEM_K*ML_KEM_K);
    localparame K_WIDTH = $clog(ML_KEM_K);


    logic [CNT_WIDTH:0] cnt_kk;
    wire sample_run, sample_rdy, sample_done, busy;
    logic [K_WIDTH - 1:0] index_i, index_j;

    assign busy = |cnt_kk;
    assign sample_run = run_i || (sample_done && busy)
    assign sample_done = rising og sample_rdy
    assign done_o = cnt_kk[CNT_WIDTH] && sample_done; // ML-KEM-512 specific definition
    assign index_i = cnt_kk[0]; // ML-KEM-512 specific definition
    assign index_j = cnt_kk[1]; // ML-KEM-512 specific definition

    always_ff(@posedge clk_i) begin
        if(!rst_n_i || done_o) begin
            cnt_kk <= '0;
        end
        else if(sample_run) begin
            cnt_kk <= cnt_kk + 1'b1;
        end
    end

    sampleNTT u0(
        .clk_i,
        .rst_n_i,
        .run_i(sample_run),
        .rho_i,
        .index_i_i(index_i),
        .index_j_i(index_j),
        .done_o(sample_rdy),
        .poly_o()
    );

    always_ff @(posedge clk_i) begin
        if(!rst_n_i)
            polymat_A_o <= '0;
        else if (sample_done)
            polymat_A_o[index_j][index_i] <= poly_o;
    end

endmodule

module sampleNTT
     import TYPES_KEM::*;
    (
        input clk_i,
        input rst_n_i,
        input run_i,
        input [31:0] rho_i,
        input [7:0] index_i_i,
        input [7:0] index_j_i,
        output done_o,
        output poly_t poly_o
    );

    logic [ML_KEM_K*ML_KEM_K-1:0] sreg_kk;
    keccak_1600_t xof_in;

    wire xof_run, xof_rdy, xof_done, busy;
    assign busy = |sreg_kk;
    assign xof_run = run_i || (xof_done && busy)
    assign xof_done = rising og xof_rdy
    assign done_o = sreg_kk[$bits(sreg_kk)-1] && xof_done;

    always_ff(@posedge clk_i) begin
        if(!rst_n_i) begin
            sreg_kk <= '0;
        end
        else if(xof_run) begin
            sreg_kk <= {sreg_kk[$bits(sreg_kk)-2:1], run_i};
        end
    end

	keccak_top #(.d(0), .b(1600), .W(64)) xof (
		.Clock(clk_i), 
		.Reset((!rst_n_i) | xof_run), 
		.InData(xof_in), 
		.FreshRand(), 
		.Ready(xof_rdy), 
		.OutData(Output)
	);

endmodule
