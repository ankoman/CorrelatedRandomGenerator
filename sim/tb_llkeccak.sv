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

    parameter STATE_SIZE = 1600;

	// Inputs
	reg Clock;
	reg Reset;
	reg [199:0][7:0] Input;
	reg [1087:0] rate;
	reg [511:0] capacity;

	// Outputs
	wire Ready;
	wire [24:0][63:0] Output;
	
	// Instantiate the Unit Under Test (UUT)
	keccak_top #(.b(STATE_SIZE), .W(64), .d(0)) uut (
		.Clock(Clock), 
		.Reset(Reset), 
		.InData(Input), 
		.FreshRand(FreshRand), 
		.Ready(Ready), 
		.OutData(Output)
	);
	
	always #10 Clock = ~Clock;

		initial begin	
		Clock = 0;
		Reset = 1;
		#500
		capacity = 512'h0;
		
		Input = {8'h60, 1072'h0, 8'h01, 512'h0};
		rate = 1188'h6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080;
		//Input = {512'h0, 8'h01, {16{64'h0}}, 48'h00, 8'h60};

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
			
	end
	
      
endmodule

