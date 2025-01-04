
//// taken from https://github.com/hgrosz/keccak_dom


module keccak_roundconstant #(
    parameter W = 8
   ) 
   
   (input wire[4:0] RoundNrxDI,
    output reg[W-1:0] RCxDO
    );

    localparam ROUNDS = (W == 8) ? 18 : 24;

    wire[0:ROUNDS*W-1] RC;
    
    generate 
        if (W == 8) begin
            assign RC = {
                8'h01, 8'h82, 8'h8A, 8'h00, 8'h8B, 8'h01,
                8'h81, 8'h09, 8'h8A, 8'h88, 8'h09, 8'h0A,
                8'h8B, 8'h8B, 8'h89, 8'h03, 8'h02, 8'h80
            };
        end
        else if (W == 64) begin
            assign RC = {
                64'h0000000000000001, // RC[0]
                64'h0000000000008082, // RC[1]
                64'h800000000000808A, // RC[2]
                64'h8000000080008000, // RC[3]
                64'h000000000000808B, // RC[4]
                64'h0000000080000001, // RC[5]
                64'h8000000080008081, // RC[6]
                64'h8000000000008009, // RC[7]
                64'h000000000000008A, // RC[8]
                64'h0000000000000088, // RC[9]
                64'h0000000080008009, // RC[10]
                64'h000000008000000A, // RC[11]
                64'h000000008000808B, // RC[12]
                64'h800000000000008B, // RC[13]
                64'h8000000000008089, // RC[14]
                64'h8000000000008003, // RC[15]
                64'h8000000000008002, // RC[16]
                64'h8000000000000080, // RC[17]
                64'h000000000000800A, // RC[18]
                64'h800000008000000A, // RC[19]
                64'h8000000080008081, // RC[20]
                64'h8000000000008080, // RC[21]
                64'h0000000080000001, // RC[22]
                64'h8000000080008008  // RC[23]
            };
        end
    endgenerate

    always @(*) begin : SELECT_ROUND_CONSTANT
    
        RCxDO = RC[RoundNrxDI*W +: W];
		
    end


endmodule