//---------------------------------------------------------
/*
chop 
phase	data_buf
0		0
1		1
2		0+1
3		0+1, 2
4		0+1, 2+3
5		0+1+2+3, 4
6		0+1+2+3, 4+5
7		0+1+2+3, 4+5, 6
8		0+1+2+3, 4+5, 6+7
9		0+1+2+3, 4+5+6+7, 8
10		0+1+2+3, 4+5+6+7, 8+9
11		0+1+2+3+4+5+6+7, 8+9, 10
12		0+1+2+3+4+5+6+7, 8+9, 10+11
13		0+1+2+3+4+5+6+7, 8+9+10+11, 12
14		0+1+2+3+4+5+6+7, 8+9+10+11, 12+13
15		0+1+2+3+4+5+6+7, 8+9+10+11, 12+13, 14
15		14+15 => 14+15+12+13 => 14+15+12+13+8+9+10+11 => 0~7+8~15


*/
//------------------------------------------------------
`timescale 1ns/1ps
module TS_top 
(
   input  wire clk // osc_16MHz
  ,input  wire RSTn
  
  ,input  wire       FLOCK
  ,input  wire       A2D_TS_DETOK
  ,input  wire [7:0] A2D_TS_DOUT
  ,input  wire       reg_ts_en_sel
  ,input  wire       reg_ts_chopper_clk_sel
  ,input  wire [3:0] reg_offset  
  
  ,output wire       D2A_TS_EN
  ,output reg        D2A_TS_START_EN
  ,output reg        D2A_TS_CLK
  ,output reg        D2A_TS_CHOPPER_CLK
  ,output wire [3:0] ts_out
);
parameter TDH = 1;


reg  [4:0]  counter_clk;
reg  [4:0]  counter_sta;
reg  [7:0]  data_1;
reg  [7:0]  data_2;
reg  [23:0] data_buf;
reg  [7:0]  data_buf_2;
reg  [3:0]  chop_phase;
wire [24:0] data_sum_tmp;
wire [31:0] data_sum_tmp_2;
wire [7:0]  in_1, in_2, out_m;
reg  [3:0]  clk_div;
reg  [2:0]  counter_sum;
reg         cntclk_2_div;

//------------------clk_320k
always@(posedge clk or negedge RSTn) begin
  if (!RSTn) 
    counter_clk <= #(TDH) 5'd0;
  else if (counter_clk == 5'd24)
    counter_clk <= #(TDH) 5'd0;
  else
    counter_clk <= #(TDH) counter_clk + 5'd1;
end
always@(posedge clk or negedge RSTn) begin
  if (!RSTn) 
    clk_div <= #(TDH) 4'd0;
  else
    clk_div <= #(TDH) clk_div + 5'd1;
end
/*
reg clk_320k;
always@(posedge clk or negedge RSTn) begin
  if (!RSTn) 
    clk_320k <= #(TDH) 1'd0;
  else if (counter_clk == 5'd24)
    clk_320k <= #(TDH) ~clk_320k;
  else 
    clk_320k <= #(TDH) clk_320k;
end
*/
//----------------------start en
always@(posedge clk or negedge RSTn) begin
  if (!RSTn) 
    counter_sta <= #(TDH) 5'd0;
  else if (counter_sta == 5'd20)
    counter_sta <= #(TDH) 5'd0;
  else if (counter_clk == 5'd23)
    counter_sta <= #(TDH) counter_sta + 5'd1;
  else 
    counter_sta <= #(TDH) counter_sta;
end

always@(posedge clk or negedge RSTn) begin
  if (!RSTn) 
    D2A_TS_START_EN <= #(TDH) 1'd0;
  else if (counter_sta == 5'd1)
    D2A_TS_START_EN <= #(TDH) 1'd1;
  else if (counter_sta == 5'd2)
    D2A_TS_START_EN <= #(TDH) 1'd0;
  else
    D2A_TS_START_EN <= #(TDH) D2A_TS_START_EN;
end
//-------------------ts en
assign #(TDH) D2A_TS_EN = reg_ts_en_sel ? FLOCK : 1'b1;
//---------------------chopper
always@(posedge clk or negedge RSTn) begin
  if (!RSTn) 
    D2A_TS_CHOPPER_CLK <= #(TDH) 1'd0;
  else if( counter_sta == 5'd1 && counter_clk == 5'd24 )
    D2A_TS_CHOPPER_CLK <= #(TDH) ~D2A_TS_CHOPPER_CLK;
  else
    D2A_TS_CHOPPER_CLK <= #(TDH) D2A_TS_CHOPPER_CLK;
end
//---------ts clk
always@(posedge clk or negedge RSTn) begin
  if (!RSTn) 
    D2A_TS_CLK <= #(TDH) 1'd0;
  else if (counter_sta == 5'd1 || counter_sta == 5'd2)
    D2A_TS_CLK <= #(TDH) 1'd0;
  else if (counter_clk == 5'd24)
    D2A_TS_CLK <= #(TDH) ~D2A_TS_CLK;
  else 
    D2A_TS_CLK <= #(TDH) D2A_TS_CLK;
end
//--------chop phase
always@(posedge A2D_TS_DETOK or negedge RSTn) begin
  if (!RSTn) 
    chop_phase <= #(TDH) 4'd0;
  else 
    chop_phase <= #(TDH) chop_phase + 4'd1;
end

//-----------data calculate

always@(posedge A2D_TS_DETOK or negedge RSTn) begin
  if (!RSTn) 
    data_1 <= #(TDH) 8'b00000000;
  else if (D2A_TS_CHOPPER_CLK == 1'd1)
    data_1 <= #(TDH) A2D_TS_DOUT;
  else 
    data_1 <= #(TDH) data_1;
end
always@(posedge A2D_TS_DETOK or negedge RSTn) begin
  if (!RSTn) 
    data_2 <= #(TDH) 8'b00000000;
  else if (D2A_TS_CHOPPER_CLK == 1'd0)
    data_2 <= #(TDH) A2D_TS_DOUT;
  else 
    data_2 <= #(TDH) data_2;
end

wire #(TDH) rstn_data_tmp = RSTn & ~(D2A_TS_START_EN & (chop_phase == 4'd0));
wire #(TDH) clk_data_tmp_gate = D2A_TS_CLK & ( counter_sta == 5'd19);
always@(posedge clk_data_tmp_gate or negedge rstn_data_tmp) begin
  if (!rstn_data_tmp) 
    data_buf <= #(TDH) 24'd0;
  else
    data_buf <= #(TDH) data_sum_tmp;
end

a_mean_b #(TDH) a_mean_b(.in_1(in_1),.in_2(in_2),.out_m(out_m));
assign #(TDH) data_sum_tmp = (chop_phase == 4'd0) ? data_buf :
                             (chop_phase == 4'd5 & A2D_TS_DETOK == 1'b1) ? {24'd0, out_m } :
                             (chop_phase == 4'd9 & A2D_TS_DETOK == 1'b1) ? {16'd0, data_buf[23:16], out_m } :
                             (chop_phase == 4'd11 & A2D_TS_DETOK == 1'b1) ? {16'd0, out_m, data_buf[7:0] } :					  
                             (chop_phase == 4'd13 & A2D_TS_DETOK == 1'b1) ? {16'd0, data_buf[23:16], out_m } :
                             (D2A_TS_CHOPPER_CLK == 1'b0 & A2D_TS_DETOK == 1'b1 ) ? {data_buf[23:0], out_m } ://shift
                              data_buf;
							  
assign #(TDH) in_1 = (chop_phase == 4'd5 & A2D_TS_DETOK == 1'b1) ? data_buf[7:0] :
			         (chop_phase == 4'd9 & A2D_TS_DETOK == 1'b1) ? data_buf[7:0] :
			         (chop_phase == 4'd11 & A2D_TS_DETOK == 1'b1) ? data_buf[15:8] :			  
			         (chop_phase == 4'd13 & A2D_TS_DETOK == 1'b1) ? data_buf[7:0] :
					 (chop_phase == 4'd0 & A2D_TS_DETOK == 1'b1 & counter_sum == 3'd1) ? data_1 :
					 (chop_phase == 4'd0 & A2D_TS_DETOK == 1'b1 & counter_sum == 3'd2) ? data_buf[7:0] :
					 (chop_phase == 4'd0 & A2D_TS_DETOK == 1'b1 & counter_sum == 3'd3) ? data_buf[15:8] :
                     (chop_phase == 4'd0 & A2D_TS_DETOK == 1'b1 & counter_sum == 3'd4) ? data_buf[23:16] :
                      data_1;
					  
assign #(TDH) in_2 = (chop_phase == 4'd5 & A2D_TS_DETOK == 1'b1) ? data_buf[15:8] : 
			         (chop_phase == 4'd9 & A2D_TS_DETOK == 1'b1) ? data_buf[15:8] : 
			         (chop_phase == 4'd11 & A2D_TS_DETOK == 1'b1) ? data_buf[23:16] :
			         (chop_phase == 4'd13 & A2D_TS_DETOK == 1'b1) ? data_buf[15:8] :
					 (chop_phase == 4'd0 & A2D_TS_DETOK == 1'b1 & counter_sum == 3'd1) ? data_2 :
					 (chop_phase == 4'd0 & A2D_TS_DETOK == 1'b1 & counter_sum == 3'd2) ? data_buf_2[7:0] :
					 (chop_phase == 4'd0 & A2D_TS_DETOK == 1'b1 & counter_sum == 3'd3) ? data_buf_2[7:0] :
					 (chop_phase == 4'd0 & A2D_TS_DETOK == 1'b1 & counter_sum == 3'd4) ? data_buf_2[7:0] :
			          data_2;

wire #(TDH) cnt_clk_2_gate = counter_clk[2] & ( chop_phase == 4'd0) & A2D_TS_DETOK == 1'b1;
always@(posedge cnt_clk_2_gate or negedge rstn_data_tmp) begin
  if (!rstn_data_tmp) 
    cntclk_2_div <= #(TDH) 1'd0;
  else
    cntclk_2_div <= #(TDH) ~cntclk_2_div;
end
always@(posedge cntclk_2_div or negedge RSTn) begin
  if (!RSTn) 
    data_buf_2 <= #(TDH) 8'b11111110;
  else if (counter_sum == 3'd0)
    data_buf_2 <= #(TDH) data_buf_2;
  else
    data_buf_2 <= #(TDH) out_m;
end
always@(posedge cntclk_2_div or negedge rstn_data_tmp) begin
  if (!rstn_data_tmp) 
    counter_sum <= #(TDH) 3'd0;
  else
    counter_sum <= #(TDH) counter_sum + 3'd1;
end


assign #(TDH) ts_out = data_buf_2[7:4];


endmodule
