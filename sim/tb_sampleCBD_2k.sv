`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2025/02/14
// Module Name: tb_sampleCBD_2k.sv
// Tool Versions: Vivado 2024.1
//////////////////////////////////////////////////////////////////////////////////



module tb_sampleCBD_2k;
    import FUNCS::*;
    localparam integer
        CYCLE = 10,
        DELAY = 2,
        N_LOOP = 20;
                
    reg clk_i, rst_n_i, run_i, eta_i;
    reg [255:0] seed_i;
    wire done_o;


    always begin
        #(CYCLE/2) clk_i <= ~clk_i;
    end

   sampleCBD_2k dut(
        .clk_i,
        .rst_n_i,
        .run_i,
        .seed_i,
        .eta_i,    // 0: eta1, 1: eta2
        .done_o,
        .polyvec_o()
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
        eta_i <= 0;
        seed_i <= reverse_endian_256(256'h98536d1af787a4ad136710605af5e97aa81aa5aef3642964521b9cbf5e576885);
        #100
        rst_n_i <= 1;
        #5000;
        repeat (5) @(posedge clk_i);  // 5クロック後にrun_iを1にする
        run_i <= 1;
        repeat (1) @(posedge clk_i);  // 1クロック後にrun_iを0にする
        run_i <= 0;

        wait(done_o == 1);

        #1000
        seed_i <= reverse_endian_256(256'h7efb9e40c3bf0ff0432986ae4bc1a242ce9921aa9e22448819585dea308eb039);
        repeat (5) @(posedge clk_i);  // 5クロック後にrun_iを1にする
        run_i <= 1;
        repeat (1) @(posedge clk_i);  // 1クロック後にrun_iを0にする
        run_i <= 0;
    end


endmodule

/*
For seed = 0x98536d1af787a4ad136710605af5e97aa81aa5aef3642964521b9cbf5e576885

prf output N=0
7de5064d31be349d3573e7ebef8936c01b45c997b418710056507e29ecf764195be8305490f81a8758a26f5d91cbbc2ad02e6faa2ac36d54aabeed2d4c9ee8fa7fd36ee9d9f44ed4b450d5d9ccffe88e7280e1248ec14e628124ecb5df84d7b7d90ddba9b2ec73537df347d0afb71979c6ec57f2bfce9d1463049a12aa01d037c75cfaa740235138bb48722635685942adda5e974c237e8ae2bbcb6da18b93494e1946f6d871d0bb74a9572058bb08f2b672221eaa023e4aded7627fe858e7aa

prf output N=1
f93a775b87c8694973ac6cefbbba9b4f854ea336ec776d8ee8081d2ff1334cd8ce0b5d098f6aca6fdb051e8c89453453a3a6b89aa49b571ab21ad2c18880bde491c9911f520829ce4021499aa5f2edeb63ee3f013fcc5ee69db7fe1c076cc5072ba6abc0d1e74bd709a03b7c31dcc7566677d5fb254717e35f26d897f47423b1b42ca3796a839f8dffe0064cffda04314e5813d98804df6272a6ee62e01a947b9f4db20010a352b00932917778a6ad0b4b4bc4b11dcf8268d00386630f110ef4

*/