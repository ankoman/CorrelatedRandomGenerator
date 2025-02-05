`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2024/02/05
// Module Name: SampleA
// Target Devices: U250
// Tool Versions: Vivado 2024.1
//////////////////////////////////////////////////////////////////////////////////


module SampleA
     import TYPES_KEM::*;
    (
        input clk_i,
        input rst_n_i,
        input run_i,
        output done_o,
        output polymat_t polymat_A_o;
    );

    logic [ML_KEM_K*ML_KEM_K-1:0] sreg_kk;
    wire sample_run, sample_rdy, sample_done, busy;
    assign busy = |sreg_kk;
    assign sample_run = run_i || (sample_done && busy)
    assign sample_done = rising og sample_rdy
    assign done_o = sreg_kk[$bits(sreg_kk)-1] && sample_done;

    always_ff(@posedge clk_i) begin
        if(!rst_n_i) begin
            sreg_kk <= '0;
        end
        else if(xof_run) begin
            sreg_kk <= {sreg_kk[$bits(sreg_kk)-2:1], run_i};
        end
    end

endmodule

module SampleNTT
     import TYPES_KEM::*;
    (
        input clk_i,
        input rst_n_i,
        input run_i,
        output done_o,
        output polymat_t polymat_A_o;
    );

    logic [ML_KEM_K*ML_KEM_K-1:0] sreg_kk;
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


	keccak_xof #(.d(0), .b(1600), .W(64)) uut (
		.Clock(clk_i), 
		.Reset((!rst_n_i) | xof_run), 
		.InData(Input), 
		.FreshRand(), 
		.Ready(xof_rdy), 
		.OutData(Output)
	);

endmodule
