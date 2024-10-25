`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: YNU
// Engineer: Junichi Sakamoto
// 
// Create Date: 2022/10/31 10:23:27
// Modified   : 2024/10/25
// Module Name: UART_CTRL
//////////////////////////////////////////////////////////////////////////////////


module UART_CTRL #(
    parameter len_din = 0,
    parameter len_dout = 0
)(
    input clk,
    input rst_n,
    input uart_rx,
    output uart_tx,
    input [len_dout - 1:0] extout_data, //288
    output reg [7:0] addr_extin,
    output reg [7:0] addr_extout,
    output reg [len_din - 1:0] extin_data,
    output extin_en,
    output swrst,
    output run
    );
    localparam  RX_BYTES_CNT = len_din / 8,
                TX_BYTES_CNT = len_dout / 8,
                WAIT_COMMAND = 5'h0,
                WAIT_ADDR = 5'h1,
                EXTIN = 5'h2,
                EXTOUT_WAIT_RAM = 5'h3,
                EXTOUT = 5'h4,
                COM_WRITE = 8'h10,
                COM_READ = 8'h20,
                COM_SWRST = 8'h30,
                COM_RUN = 8'h40;
   
   wire rx_data_en;
   wire [7:0] rx_data;
   reg [7:0] tx_data;
   reg tx_data_en;
   wire tx_busy;
   wire tx_start;

   UART_BYTE uart_byte(.clk(clk), .rst_n(rst_n), .uart_rx(uart_rx), .tx_data(tx_data), .tx_data_en(tx_data_en), .rx_data_en(rx_data_en), .uart_tx(uart_tx), .rx_data(rx_data), .tx_start(tx_start), .tx_busy(tx_busy));
    
    reg [4:0] state;
    reg [7:0] command;
    reg [1:0] shiftreg_swrst;
    reg [1:0] shiftreg_run;
    assign swrst = shiftreg_swrst[0];
    assign run = shiftreg_run[0];
    wire rx_N_busy;
    wire tx_N_busy;
    reg [RX_BYTES_CNT:0] rx_byte_cnt;
    reg [TX_BYTES_CNT - 1:0] tx_byte_cnt;
    reg [len_dout - 1:0] extout_data_buf;
    wire uart_receive;
    assign rx_N_busy = |rx_byte_cnt; 
    assign tx_N_busy = |tx_byte_cnt; 
    assign uart_receive = ~tx_N_busy & ~rx_N_busy & rx_data_en;
    assign extin_en = rx_byte_cnt[RX_BYTES_CNT];
    wire extout_en = tx_byte_cnt[TX_BYTES_CNT-1];
    
    
    always@(posedge clk) begin : STATE_MACHINE

        if(~rst_n) begin
            state <= 5'h0;
            command <= 8'h0;
            addr_extin <= 8'h0;
            addr_extout <= 8'h0;
            shiftreg_swrst <= 2'b0;
            shiftreg_run <= 2'b0;
        end
        else begin
            shiftreg_swrst <= {shiftreg_swrst[0], 1'b0};
            shiftreg_run <= {shiftreg_run[0], 1'b0};
            if(state == WAIT_COMMAND) begin
                if(rx_data_en) begin
                    if(rx_data == COM_WRITE) begin
                        command <= rx_data;
                        state <= WAIT_ADDR;
                    end
                    else if (rx_data == COM_READ) begin
                        command <= rx_data;
                        state <= WAIT_ADDR;
                    end
                    else if (rx_data == COM_SWRST) begin
                        shiftreg_swrst <= 2'b01;
                        state <= WAIT_COMMAND;
                    end
                    else if (rx_data == COM_RUN) begin
                        shiftreg_run <= 2'b01;
                        state <= WAIT_COMMAND;
                    end
                end
            end
            else if(state == WAIT_ADDR) begin
               if(rx_data_en) begin
                    if(command == COM_WRITE) begin
                        addr_extin <= rx_data;
                        state <= EXTIN;
                    end
                    else if (command == COM_READ) begin
                        addr_extout <= rx_data;
                        state <= EXTOUT_WAIT_RAM;
                    end
                end
            end
            else if(state == EXTIN) begin
                if(extin_en) state <= WAIT_COMMAND;
            end
            else if (state == EXTOUT_WAIT_RAM) begin
                state <= EXTOUT;
            end
            else if (state == EXTOUT) begin
                if(extout_en) state <= WAIT_COMMAND;
            end
        end
    end

    //EXTOUT state Nbit�?ータ送信
    always@(posedge clk) begin
        if(~rst_n) begin
            tx_byte_cnt <= '0;
            tx_data <= 8'h0;
            extout_data_buf <='0;
            tx_data_en <= 1'b0;
        end
        else begin
            if(state == EXTOUT && ~tx_N_busy) begin
                tx_byte_cnt <= {{(TX_BYTES_CNT - 1){1'b0}}, 1'b1};
                extout_data_buf <= extout_data;
            end
            else if(tx_N_busy && ~tx_busy & ~tx_start & ~tx_data_en) begin
                tx_byte_cnt <= {tx_byte_cnt[TX_BYTES_CNT - 2:0], 1'b0};
                tx_data <= extout_data_buf[len_dout - 1:len_dout - 8];
                tx_data_en <= 1'b1;
                extout_data_buf <= extout_data_buf << 8;
            end
            else begin
                tx_data_en <= 1'b0;
            end
        end
    end
        
    //EXTIN state�?Nbit�?ータ受信
    always@(posedge clk) begin
        if(~rst_n) begin
            rx_byte_cnt <= '0;
            extin_data <= '0;
        end
        else begin
            if(state == EXTIN & ~rx_N_busy) begin
                rx_byte_cnt <= {{RX_BYTES_CNT{1'b0}}, 1'b1};
            end
            else if((rx_N_busy & rx_data_en) | extin_en) begin
                rx_byte_cnt <= {rx_byte_cnt[RX_BYTES_CNT - 1:0], 1'b0};
                extin_data <= {rx_data, extin_data[len_din - 1:8]};
            end
        end
    end
    
endmodule