`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2024/02/14
// Module Name: sampleCBD
// Target Devices: U250
// Tool Versions: Vivado 2024.1
//////////////////////////////////////////////////////////////////////////////////


// Sample polynomials 2k times from CBD
module sampleCBD_2k
     import TYPES_KEM::*;
    (
        input clk_i,
        input rst_n_i,
        input run_i,
        input [255:0] seed_i,
        input eta_i,    // 0: eta1, 1: eta2
        output logic done_o,
        output poly_t [2*ML_KEM_K-1:0] polyvec_o
    );
    localparam CNT_WIDTH = $clog2(ML_KEM_K*2);
    localparam K_WIDTH = $clog2(ML_KEM_K);

    logic [CNT_WIDTH:0] cnt_2k;
    logic sample_cbd_run, sample_cbd_done, busy;
    poly_t poly_o;

    assign busy = |cnt_2k[1:0];
    assign sample_cbd_run = run_i || (sample_cbd_done && busy);
    always_ff @(posedge clk_i) begin
        done_o <= cnt_2k[CNT_WIDTH] && sample_cbd_done;
    end

    always_ff @(posedge clk_i) begin
        if(!rst_n_i || done_o) begin
            cnt_2k <= '0;
        end
        else if(sample_cbd_run) begin
            cnt_2k <= cnt_2k + 1'b1;
        end
    end

    sampleCBD u0(
        .clk_i,
        .rst_n_i,
        .run_i(sample_cbd_run),
        .seed_i,
        .N_i(8'(cnt_2k)),
        .done_o(sample_cbd_done),
        .poly_o
    );

    always_ff @(posedge clk_i) begin
        if(!rst_n_i)
            polyvec_o <= '0;
        else if (sample_cbd_done)
            polyvec_o <= {poly_o, polyvec_o[2*ML_KEM_K-1:1]};
    end

endmodule

module sampleCBD
    import TYPES_KEM::*;
    import FUNCS::keccak_1600_conv;
    (
        input clk_i,
        input rst_n_i,
        input run_i,
        input [255:0] seed_i,
        input [7:0] N_i,
        input eta_i,    // 0: eta1, 1: eta2
        output logic done_o,
        output poly_t poly_o
    );

    logic prf_rdy, prf_rdy_prev, prf_done, prf_run;
    always_ff @(posedge clk_i) begin
        prf_rdy_prev <= prf_rdy;
    end
    assign prf_run = run_i || (prf_done & !sreg_squeeze[1]);
    assign prf_done = !prf_rdy_prev & prf_rdy; // Rising edge. 
    // always_ff @(posedge clk_i) begin
    //     done_o <= prf_done & sreg_squeeze[1];
    // end
    assign done_o = prf_done & sreg_squeeze[1];

    logic [1:0] sreg_squeeze;

    always @(posedge clk_i) begin
        if(!rst_n_i) begin
            sreg_squeeze <= '0;
        end
        else if (prf_done || run_i) begin
            sreg_squeeze <= {sreg_squeeze[0], run_i};
        end
    end

    keccak_1600_t prf_in;
    logic [1599:0] prf_out_1600, prf_out_conv;
    logic [4:0][63:0] prf_msg;
    logic [1087:0] prf_rate;
    assign prf_out_conv = keccak_1600_conv(prf_out_1600);
    assign prf_msg = {48'd0, 8'h1f, N_i, seed_i};

    assign prf_in[0][0] = prf_msg[0]; // [63:0]
    assign prf_in[1][0] = prf_msg[1]; // [127:64]
    assign prf_in[2][0] = prf_msg[2]; // [191:128]
    assign prf_in[3][0] = prf_msg[3]; // [255:192]
    assign prf_in[4][0] = prf_msg[4]; // [319:256]
	assign prf_in[1][3] = 64'h8000000000000000;
    generate
        for(genvar i = 1; i < 5; i = i + 1) begin
            for (genvar j = 0; j < 5; j = j + 1) begin
                if((i == 3) && (j == 1)) begin
                    // Do nothing
                end
                else
                    assign prf_in[j][i] = 64'h0;
            end
        end
    endgenerate

    //shake256
	keccak_top #(.d(0), .b(1600), .W(64)) prf (
		.Clock(clk_i), 
		.Reset(prf_run), 
		.InData(sreg_squeeze[0] ? prf_out_1600 : prf_in), 
		.FreshRand(), 
		.Ready(prf_rdy), 
		.OutData(prf_out_1600)
	);

    // Output
    logic [180:0][2:0] cbd_coeffs_1st;  // Register for 181 cbd coefficients from the first squeeze
    logic [1:0] rem_of_1st_squeeze;     // Remainder bits of the 1st squeeze

    generate
        for(genvar i = 0; i < 256; i = i + 1) begin
            wire [2:0] cbd_tmp;
            if(i < 181)
                assign cbd_tmp = cbd_coeffs_1st[i];
            else if(i == 181)
                assign cbd_tmp = table_cbd3({prf_out_conv[3:0], rem_of_1st_squeeze});
            else
                assign cbd_tmp = table_cbd3(prf_out_conv[(i-182)*6 + 4 +: 6]);
            assign poly_o[i] = 12'(signed'(cbd_tmp)) + (12'd3329 & {12{cbd_tmp[2]}});
        end
    endgenerate

    always_ff @(posedge clk_i) begin
        if(prf_done) begin
                cbd_coeffs_1st <= apply_cbd3table_1st(prf_out_conv[1085:0]);
                rem_of_1st_squeeze <= prf_out_conv[1087:1086];
        end
    end

    function automatic logic [180:0][2:0] apply_cbd3table_1st(input logic [1085:0] val);
        for(int i = 0; i < 181; i++) begin
            apply_cbd3table_1st[i] = table_cbd3(val[6*i +: 6]);
        end
    endfunction

    function automatic logic [2:0] table_cbd3(input logic [5:0] val);
        case(val)
            6'b000000: table_cbd3 = 3'b000;
            6'b000001: table_cbd3 = 3'b001;
            6'b000010: table_cbd3 = 3'b001;
            6'b000011: table_cbd3 = 3'b010;
            6'b000100: table_cbd3 = 3'b001;
            6'b000101: table_cbd3 = 3'b010;
            6'b000110: table_cbd3 = 3'b010;
            6'b000111: table_cbd3 = 3'b011;
            6'b001000: table_cbd3 = 3'b111;
            6'b001001: table_cbd3 = 3'b000;
            6'b001010: table_cbd3 = 3'b000;
            6'b001011: table_cbd3 = 3'b001;
            6'b001100: table_cbd3 = 3'b000;
            6'b001101: table_cbd3 = 3'b001;
            6'b001110: table_cbd3 = 3'b001;
            6'b001111: table_cbd3 = 3'b010;
            6'b010000: table_cbd3 = 3'b111;
            6'b010001: table_cbd3 = 3'b000;
            6'b010010: table_cbd3 = 3'b000;
            6'b010011: table_cbd3 = 3'b001;
            6'b010100: table_cbd3 = 3'b000;
            6'b010101: table_cbd3 = 3'b001;
            6'b010110: table_cbd3 = 3'b001;
            6'b010111: table_cbd3 = 3'b010;
            6'b011000: table_cbd3 = 3'b110;
            6'b011001: table_cbd3 = 3'b111;
            6'b011010: table_cbd3 = 3'b111;
            6'b011011: table_cbd3 = 3'b000;
            6'b011100: table_cbd3 = 3'b111;
            6'b011101: table_cbd3 = 3'b000;
            6'b011110: table_cbd3 = 3'b000;
            6'b011111: table_cbd3 = 3'b001;
            6'b100000: table_cbd3 = 3'b111;
            6'b100001: table_cbd3 = 3'b000;
            6'b100010: table_cbd3 = 3'b000;
            6'b100011: table_cbd3 = 3'b001;
            6'b100100: table_cbd3 = 3'b000;
            6'b100101: table_cbd3 = 3'b001;
            6'b100110: table_cbd3 = 3'b001;
            6'b100111: table_cbd3 = 3'b010;
            6'b101000: table_cbd3 = 3'b110;
            6'b101001: table_cbd3 = 3'b111;
            6'b101010: table_cbd3 = 3'b111;
            6'b101011: table_cbd3 = 3'b000;
            6'b101100: table_cbd3 = 3'b111;
            6'b101101: table_cbd3 = 3'b000;
            6'b101110: table_cbd3 = 3'b000;
            6'b101111: table_cbd3 = 3'b001;
            6'b110000: table_cbd3 = 3'b110;
            6'b110001: table_cbd3 = 3'b111;
            6'b110010: table_cbd3 = 3'b111;
            6'b110011: table_cbd3 = 3'b000;
            6'b110100: table_cbd3 = 3'b111;
            6'b110101: table_cbd3 = 3'b000;
            6'b110110: table_cbd3 = 3'b000;
            6'b110111: table_cbd3 = 3'b001;
            6'b111000: table_cbd3 = 3'b101;
            6'b111001: table_cbd3 = 3'b110;
            6'b111010: table_cbd3 = 3'b110;
            6'b111011: table_cbd3 = 3'b111;
            6'b111100: table_cbd3 = 3'b110;
            6'b111101: table_cbd3 = 3'b111;
            6'b111110: table_cbd3 = 3'b111;
            6'b111111: table_cbd3 = 3'b000;
        endcase
    endfunction
endmodule
