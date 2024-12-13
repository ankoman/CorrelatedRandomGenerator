`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AIST
// Engineer: Junichi Sakamoto
// 
// Create Date: 2024/12/12
// Module Name: generic_demux
// Target Devices: U250
// Tool Versions: Vivado 2024.1
//////////////////////////////////////////////////////////////////////////////////


module generic_demux #(parameter WIDTH = 1, 
                       parameter NUMBER = 2, 
                       localparam SELECT_W = $clog2(NUMBER)) 
 (input logic [SELECT_W-1:0] sel, 
  input logic [WIDTH-1:0] mux_in,                   
  output logic [WIDTH-1:0] out [NUMBER-1:0]);
  
  assign out[sel] = mux_in;
    
endmodule  