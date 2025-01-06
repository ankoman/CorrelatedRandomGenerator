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


	wire [24:0][LEN_B/25 - 1:0] Output, Round_out, In_lane, theta, pi, chi;
	assign Round_out = uut.SlicesFromChi;
	assign theta = uut.SlicesFromCompression;
	assign pi = uut.StateFromRhoPi;
	assign In_lane = Input;
	reg  [LEN_B - 1:0] Input;
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
		Clock = 0;
		Reset = 1;
		#500
		
		//Input = {128'hffffffffffffffffffffffffffffffff,72'h0123456789abcdef01};
		Input = {1600'h0};
		Input[3:0] = 4'b0110;
		Input[575] = 1'b1;

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

      
endmodule

