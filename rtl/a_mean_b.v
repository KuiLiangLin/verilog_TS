`timescale 1ns/1ps
module a_mean_b 
(
   input  wire [7:0] in_1
  ,input  wire [7:0] in_2
  ,output wire [7:0] out_m
);
wire [8:0] sum_tmp;

assign sum_tmp = {1'b0, in_1} + {1'b0, in_2};
assign out_m = sum_tmp[8:1];

endmodule
