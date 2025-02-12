`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2025/02/07
// Module Name: tb_sampler.sv
// Tool Versions: Vivado 2024.1
//////////////////////////////////////////////////////////////////////////////////



module tb_sampler;
    localparam integer
        CYCLE = 10,
        DELAY = 2,
        N_LOOP = 20;
                
    reg clk_i, rst_n_i, run_i;
    reg [255:0] rho_i;
    wire done_o;


    always begin
        #(CYCLE/2) clk_i <= ~clk_i;
    end

    sampleA dut(
        clk_i,
        rst_n_i,
        run_i,
        rho_i,
        done_o,
        polymat_A_o
    );

    /*-------------------------------------------
    Test
    -------------------------------------------*/
    initial begin
        clk_i <= 1;
        rst_n_i <= 1;
        #1000
        rst_n_i <= 0;
        run_i <= 0;
        rho_i <= reverse_endian_256(256'hcd03078d0c74faf81a1de464203713aef34ef4e369e8564f48497aaf9d47a9b3);
        #100
        rst_n_i <= 1;
        #5000;
        run_i <= 1;
        #CYCLE
        run_i <= 0;
    end

	function automatic logic [255:0] reverse_endian_256(input logic [255:0] data);
		logic [255:0] reversed = '0;

		for (int i = 0; i < 32; i++) begin
			reversed[i*8 +: 8] = data[(32-1-i)*8 +: 8];
    	end
    	return reversed;
	endfunction


endmodule
