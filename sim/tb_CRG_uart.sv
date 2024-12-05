`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2024/12/4
// Module Name: tb_CRG_uart.sv
// Tool Versions: Vivado 2024.1
//////////////////////////////////////////////////////////////////////////////////



module tb_CRG_uart;
    localparam integer
        CYCLE = 10,
        DELAY = 2,
        N_LOOP = 20;
                
    reg clk, rst_n, uart_rx;

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
        UART_RX_128(8'h10, 8'h10, 128'he3e70682c2094cac629f6fbed82c07cd);   // Set key
        #1000
        UART_RX_128(8'h10, 8'h11, 128'd4);   // Set mode
        #1000
        UART_RX_128(8'h10, 8'h12, 128'd1);   // Set width
        #1000
        UART_RX_128(8'h10, 8'h13, 128'd2);   // Set n_CRs
        #1000
        UART_RX(8'h40);  // Run
        #1000
        UART_RX_128(8'h10, 8'h13, 128'd3);   // Set n_CRs
        #1000
        UART_RX(8'h40);  // Run
        #1000
        $finish;
    end

    task automatic UART_RX;
        parameter   integer RATE=115200;//ボーレート[bps]
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

    task automatic UART_RX_128;
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
