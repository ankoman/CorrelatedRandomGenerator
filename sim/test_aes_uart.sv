`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2024/10/26
// Module Name: test_aes.sv
// Tool Versions: Vivado 2020.1
//////////////////////////////////////////////////////////////////////////////////



module test_aes_uart;
    localparam 
        CYCLE = 10,
        DELAY = 2,
        N_LOOP = 20;
                
    reg clk, rst_n, uart_rx;
    reg [23:0] cycle_cnt;

    always begin
        #(CYCLE/2) clk <= ~clk;
    end

    TOP_CRG_HW_UART dut(
        .CLK100MHZ(clk),
        .ck_rst_n(rst_n),
        .uart_txd_in(uart_rx),
        .uart_rxd_out(),
        .led()
    );

    /*-------------------------------------------
    Test
    -------------------------------------------*/
    initial begin
        clk <= 1;
        rst_n <= 1;
        #1000
        rst_n <= 0;
        uart_rx <= 1;
        #100
        rst_n <= 1;
        #1000;
        UART_RX_128(8'h10, 8'h00, 128'h2b7e151628aed2a6abf7158809cf4f3c);   // Set key
        #1000
        UART_RX(8'h40);  // Run
        #1000
        $finish;
    end

    task UART_RX;
        parameter   RATE=115200;//ボーレート[bps]
        input[7:0]  dat;//送るデータ  
        integer     i;//ループ用変数
        time        BIT_CYC;//1ビットの周期
    
        begin
            $display("UART input start : 0x%2X",dat);
            //ボーレートからbit周期[ns]を算出
            BIT_CYC=1000000000/RATE;//timescaleが1nsの前提
            //スタートビット
            uart_rx  <=1'b0;
            #BIT_CYC;
            //データ:LSBファースト
            for(i=0; i<8; i=i+1)begin
                uart_rx <= dat[i];
                #BIT_CYC;
            end
            //ストップビット
            uart_rx <= 1'b1;
            #BIT_CYC;
        end
    endtask

    task UART_RX_128;
        integer i;
        input [7:0] com;
        input [7:0] addr;
        input [127:0] dat;
        
        begin
            UART_RX(com);
            UART_RX(addr);
            for(i = 0; i < 16; i=i+1) begin
                UART_RX(dat[7:0]);
                dat = {8'd0, dat[127:8]};
                #1000;
            end
        end
    endtask

endmodule
