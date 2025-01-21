`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2024/12/18
// Module Name: tb_llkeccak.sv
// Target Devices: U250
// Tool Versions: Vivado 2024.1
// This is the modified version of below implementation
//////////////////////////////////////////////////////////////////////////////////


/*
* -----------------------------------------------------------------
* AUTHOR  : Sara Zarei (sarazareei.94@gmail.com), Aein Rezaei Shahmirzadi (aein.rezaeishahmirzadi@rub.de), Amir Moradi (amir.moradi@rub.de)
* DOCUMENT: "Low-Latency Keccak at any Arbitrary Order" (TCHES 2021, Issue 4)
* -----------------------------------------------------------------
*
* Copyright (c) 2021, Sara Zarei, Aein Rezaei Shahmirzadi, Amir Moradi
*
* All rights reserved.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
* DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTERS BE LIABLE FOR ANY
* DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
* LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
* ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*
* Please see LICENSE and README for license and further instructions.
*/


module tb_llkeccak;
   localparam LEN_B = 1600;

	// Inputs
	reg Clock;
	reg Reset;
	reg [399:0] In;
	reg [199:0] FreshRand;

	// Outputs
	wire Ready;
	wire [399:0] Out;

    typedef struct packed {
        logic [255:0] d;
        logic [255:0] z;
		logic [800*8-1:0] pk;
        logic [1632*8-1:0] sk;
        logic [255:0] m;
        logic [768*8-1:0] ct;
        logic [255:0] ss;
	} tv_ml_kem_512_t;

    tv_ml_kem_512_t mem_tv [100];
	logic [4:0][4:0][LEN_B/25 - 1:0] Input, Output, Round_out, theta, pi, chi, padded_data;
	assign Round_out = uut.SlicesFromChi;
	assign theta = uut.SlicesFromCompression;
	assign pi = uut.StateFromRhoPi;
	reg  [LEN_B - 1:0] In0;
	reg  [LEN_B - 1:0] In1;
	
	// Instantiate the Unit Under Test (UUT)
	keccak_top #(.d(0), .b(LEN_B), .W(LEN_B/25)) uut (
		.Clock(Clock), 
		.Reset(Reset), 
		.InData(Input), 
		.FreshRand(FreshRand), 
		.Ready(Ready), 
		.OutData(Output)
	);
	
		initial begin	
		$readmemh("C:\\Users\\sakamoto\\Desktop\\prj\\CorrelatedRandomGenerator\\dat\\ml_kem_512.kat.little", mem_tv);
		Clock = 0;
		Reset = 1;
		#500
		
		//SHA3-256
		Input = {1600'h0};
		Input[0][0] = 64'h0000000000000006; // Input[7:0] = 4'h06;				// Lane[0][0]
		Input[1][3] = 64'h8000000000000000;	// Input[575:568] = 8'h80;			// Lane[1][3]

		#20
		Reset = 0;
		@(posedge Ready)
			#10
			if(Output == 200'he090c8c5e596d3421d2fcc695838626cbb365352811837480f) begin
					$write("------------------PASS---------------\n");
			end
			else begin
				$write("\------------------FAIL---------------\n");
				$write("%x\n", Output);
			end

		//SHA3-512	
		#400
		Reset = 1;
		Input = {1600'h0};
		padded_data = {1024'h0, 8'h80, 296'h0, 8'h06, 8'h02, reverse_endian_256(256'h7f9c2ba4e88f827d616045507605853ed73b8093f6efbc88eb1a6eacfa66ef26)};
		//padded_data = {1024'h0, 8'h80, 560'h0, 8'h06}; // empty string. This gives the corrent result.
		//padded_data = {1024'h0, 8'h80, 496'h0, 8'h06, 64'h0001020304050607}; // 64 bits input. This gives the correct result.
		//padded_data = {1024'h0, 8'h80, 432'h0, 8'h06, 64'h0001020304050607, 64'h0001020304050607}; // 128 bits input. This gives the correct result.
		//padded_data = {1024'h0, 8'h80, 304'h0, 8'h06, 256'h1001020304050607000102030405060700010203040506070001020304050607}; // 256 bits input. This gives the correct result.
		//padded_data = {1024'h0, 8'h80, 296'h0, 8'h06, 8'h02, 256'h1001020304050607000102030405060700010203040506070001020304050607}; // 226 + 8 bits input. This gives the correct result.




		Input[0][0] = padded_data[0][0]; // [63:0]
		Input[1][0] = padded_data[0][1]; // [127:64]
		Input[2][0] = padded_data[0][2]; // [191:128]
		Input[3][0] = padded_data[0][3]; // [255:192]
		Input[4][0] = padded_data[0][4]; // [319:256]

		Input[0][1] = padded_data[1][0]; 
		Input[1][1] = padded_data[1][1];
		Input[2][1] = padded_data[1][2]; 
		Input[3][1] = padded_data[1][3]; 
		Input[4][1] = padded_data[1][4];

		#20
		Reset = 0;
		@(posedge Ready)
			#10
			if(Output == 200'he090c8c5e596d3421d2fcc695838626cbb365352811837480f) begin
					$write("------------------PASS---------------\n");
			end
			else begin
				$write("\------------------FAIL---------------\n");
				$write("%x\n", Output);
			end
	
		// #400
		// Reset = 1;
		// Input = {128'hffffffffffffffffffffffffffffffff,72'h000000000000000008};
		// In0 = {7{$random}};
		// In1 = Input ^ In0;
		// #20
		// Reset = 0;
		
		// #400
		// Reset = 1;
		// Input = {128'hffffffffffffffffffffffffffffffff,72'h000000000000000006};
		// In0 = {7{$random}};
		// In1 = Input ^ In0;
		// #20
		// Reset = 0;

		// #400
		// Reset = 1;
		// Input = {128'hffffffffffffffffffffffffffffffff,72'h0123456789abcdef01};
		// In0 = {7{$random}};
		// In1 = Input ^ In0;
		// #20
		// Reset = 0;
		// @(posedge Ready)
		// 	#10
		// 	if(Output == 200'he090c8c5e596d3421d2fcc695838626cbb365352811837480f) begin
		// 			$write("------------------PASS---------------\n");
		// 	end
		// 	else begin
		// 		$write("\------------------FAIL---------------\n");
		// 		$write("%x\n", Output);
		// 	end
		
		// #400
		// Reset = 1;
		// Input = {200{1'b0}};
		// In0 = {7{$random}};
		// In1 = Input ^ In0;
		// #20
		// Reset = 0;
	
	end

	   always #10 Clock = ~Clock;
		
		always #20 FreshRand  = {7{$random}};

	function automatic logic [255:0] reverse_endian_256(input logic [255:0] data);
		logic [255:0] reversed = '0;

		for (int i = 0; i < 32; i++) begin
			reversed[i*8 +: 8] = data[(32-1-i)*8 +: 8];
    end

    return reversed;
endfunction
endmodule

