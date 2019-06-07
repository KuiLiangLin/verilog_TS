`timescale 1ns/1ps
module a_mean_b 
(
   input  wire [7:0] in_1
  ,input  wire [7:0] in_2
  ,output wire [7:0] out_m
);
assign out_m = {1'b0, in_1[7:1]} + {1'b0, in_2[7:1]};

endmodule
