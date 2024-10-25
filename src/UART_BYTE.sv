`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: YNU
// Engineer: Junichi Sakamoto
// 
// Create Date: 2022/10/31 10:23:27
// Design Name: 
// Module Name: UART_BYTE
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


//import PARAM_UART::*;

parameter   UART_CLK_FREQ = 100000000,
            UART_BAUD_RATE = 115200;

module UART_BYTE(
    input clk,
          rst_n,
          uart_rx,
          tx_data_en,
    [7:0] tx_data,
    output tx_start,
           reg rx_data_en,
           reg uart_tx,
           reg [7:0] rx_data,
           reg tx_busy
    );
   
    localparam  BIT_WIDTH = UART_CLK_FREQ / UART_BAUD_RATE,
                N_BIT_WIDTH = 15,//$clog2(BIT_WIDTH);
                BIT_WIDTH_DIV2 = BIT_WIDTH/2;

    //Internal Variables 
    //RX
    reg[2:0] falling; //エッジ検出微分FF
    reg rx_busy;
    reg[N_BIT_WIDTH - 1:0] rx_cnt; //1ビットカウント
    reg[9:0] rx_sp_ff; //シリパラFF
    reg[4:0] rx_bit_cnt;

    wire rx_start;
    wire rx_stop;
    wire rx_latch;
    //TX
    reg[2:0] rising; //エッジ検出微分FF
    
    reg[N_BIT_WIDTH - 1:0] tx_cnt; //1ビットカウント
    reg[4:0] tx_bit_cnt;

    reg[10:0] tx_frame;
    wire tx_stop;
    
    //開始パルス：tx_data_enの立上がり∧非ビジー
    assign tx_start = (rising[1:0] == 2'b01) & (tx_busy == 1'b0) ? 1'b1 : 1'b0;

    //終了パルス：11bit目のサンプルタイミング
    assign tx_stop = (tx_bit_cnt == 5'd10) & (tx_cnt == BIT_WIDTH) ? 1'b1 : 1'b0;
        
            
    //エッジ検出微分FF
    always@(posedge clk) begin
        if(~rst_n)
            rising <= 3'b111;
        else
            rising <= {rising[1:0], tx_data_en};
    end
    
    //送信中ビジーフラグ
    always@(posedge clk) begin
        if(~rst_n) begin
            tx_busy <= 1'b0;
        end
        else if(tx_start) begin
            tx_busy <= 1'b1;
        end
        else if(tx_stop) begin
            tx_busy <= 1'b0;
        end
        else 
            tx_busy <= tx_busy;
    end
        
    //1ビットカウント
    always@(posedge clk) begin
        if(~rst_n)
            tx_cnt <= 15'd0;
        else if(tx_cnt == BIT_WIDTH)
            tx_cnt <= 15'd0;
        else if(tx_busy)
            tx_cnt <= tx_cnt + 1;
        else
            tx_cnt <= 15'd0;
    end
    
    
    //ビット数カウンタ
    always@(posedge clk) begin
        if(~rst_n) begin
            tx_bit_cnt <= 5'd0;
            tx_frame <= 11'h7ff;
        end
        else if(tx_start) begin
            tx_frame <= {2'b11, tx_data, 1'b0};
            tx_bit_cnt <= 5'd0; //開始時ゼロクリア
       end
        else if(tx_cnt == BIT_WIDTH) begin
            tx_bit_cnt <= tx_bit_cnt + 1; //データゲット毎にインクリメント
            tx_frame <= tx_frame >> 1;
        end
    end

     //送信
    always@(posedge clk) begin
        if(~rst_n)
            uart_tx <= 1'b1;
        else if(tx_busy)
            uart_tx <= tx_frame[0:0];
        else 
            uart_tx <= 1'b1;
    end
    
    
    //開始パルス：立下り∧非ビジー
    assign rx_start = (falling[2:1] == 2'b10) & (rx_busy == 1'b0) ? 1'b1 : 1'b0;

    //終了パルス：10bit目のサンプルタイミング
    assign rx_stop = (rx_bit_cnt == 5'd9) & (rx_latch == 1'b1) ? 1'b1 : 1'b0;

    //データラッチトリガ
    assign rx_latch = (rx_busy == 1'b1) & (rx_cnt == (BIT_WIDTH_DIV2[14:0])) ? 1'b1 : 1'b0;
    
    //エッジ検出微分FF
    always@(posedge clk) begin
        if(~rst_n)
            falling <= 3'b111;
        else
            falling <= {falling[1:0], uart_rx};
    end
        
    //受信中ビジーフラグ
    always@(posedge clk) begin
        if(~rst_n)
            rx_busy <= 1'b0;
        else if(rx_start)
            rx_busy <= 1'b1;
        else if(rx_stop)
            rx_busy <= 1'b0;
        else 
            rx_busy <= rx_busy;
    end
        
    //1ビットカウント
    always@(posedge clk) begin
        if(~rst_n)
            rx_cnt <= 15'd0;
        else if(rx_cnt == BIT_WIDTH)
            rx_cnt <= 15'd0;
        else if(rx_busy)
            rx_cnt <= rx_cnt + 1;
        else
            rx_cnt <= 15'd0;
    end
    
    //シリパラFF
    always@(posedge clk) begin
        if(~rst_n)
            rx_sp_ff <= 10'h3FF;
        else if(rx_latch)
            rx_sp_ff <= {uart_rx, rx_sp_ff[8:1]};//LSBファーストを受信
    end
    
    //ビット数カウンタ
    always@(posedge clk) begin
        if(~rst_n)
            rx_bit_cnt <= 5'd0;
        else if(rx_start)
           rx_bit_cnt <= 5'd0; //開始時ゼロクリア
        else if(rx_latch)
            rx_bit_cnt <= rx_bit_cnt + 1; //データゲット毎にインクリメント
    end
        
    always@(posedge clk) begin
        if(~rst_n) begin
            rx_data <= 8'd0;
            rx_data_en <= 1'b0;
        end
        else if(rx_stop) begin
            rx_data <= rx_sp_ff[8:1];
            rx_data_en <= 1'b1;
        end
        else begin
            rx_data <= rx_data;
            rx_data_en <= 1'b0;
        end
    end
    
endmodule