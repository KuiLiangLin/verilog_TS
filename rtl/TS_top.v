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
  
  ,output wire        D2A_TS_EN
  ,output reg        D2A_TS_START_EN
  ,output reg        D2A_TS_CLK
  ,output reg        D2A_TS_CHOPPER_CLK
  ,output reg  [3:0] ts_out
);
parameter TDH = 1;


reg  [4:0]  counter_clk;
reg  [4:0]  counter_sta;
reg  [7:0]  data_1;
reg  [7:0]  data_2;
reg  [31:0] data_buf;
reg  [3:0]  chop_phase;
wire [31:0] data_sum_tmp;
wire [7:0]  in_1, in_2, out_m;

//------------------clk_320k
always@(posedge clk or negedge RSTn) begin
  if (!RSTn) 
    counter_clk <= #(TDH) 5'd0;
  else if (counter_clk == 5'd24)
    counter_clk <= #(TDH) 5'd0;
  else
    counter_clk <= #(TDH) counter_clk + 5'd1;
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
assign D2A_TS_EN = reg_ts_en_sel ? FLOCK : 1'b1;
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

wire rstn_data_tmp = RSTn & ~(D2A_TS_START_EN & (chop_phase == 4'd0));
wire clk_data_tmp_gate = D2A_TS_CLK & ( A2D_TS_DETOK == 1'b1);
always@(posedge clk_data_tmp_gate or negedge rstn_data_tmp) begin
  if (!rstn_data_tmp) 
    data_buf <= #(TDH) 32'd0;
//  else if (A2D_TS_DETOK == 1'b1)
//    data_buf <= #(TDH) data_sum_tmp;
  else
    data_buf <= #(TDH) data_sum_tmp;

end

a_mean_b a_mean_b(.in_1(in_1),.in_2(in_2),.out_m(out_m));
assign data_sum_tmp = (chop_phase == 4'd5 & A2D_TS_DETOK == 1'b0) ? {data_buf[31:8], out_m } :
                      (chop_phase == 4'd9 & A2D_TS_DETOK == 1'b0) ? {data_buf[31:16], data_buf[23:16], out_m } :
					  (chop_phase == 4'd11 & A2D_TS_DETOK == 1'b0) ? {data_buf[31:8], out_m } :					  
					  (chop_phase == 4'd13 & A2D_TS_DETOK == 1'b0) ? {data_buf[31:16], data_buf[15:8], out_m } :
				      (D2A_TS_CHOPPER_CLK == 1'b1 & A2D_TS_DETOK == 1'b0 ) ? {data_buf[23:0], out_m } ://shift
					  data_buf;
assign in_1 = (D2A_TS_CHOPPER_CLK == 1'b1) ? data_1 : 
              (chop_phase == 4'd5 & A2D_TS_DETOK == 1'b0) ? data_buf[7:0] :
			  (chop_phase == 4'd9 & A2D_TS_DETOK == 1'b0) ? data_buf[7:0] :
			  (chop_phase == 4'd11 & A2D_TS_DETOK == 1'b0) ? data_buf[7:0] :			  
			  (chop_phase == 4'd13 & A2D_TS_DETOK == 1'b0) ? data_buf[7:0] :
			  data_1;
assign in_2 = (D2A_TS_CHOPPER_CLK == 1'b1) ? data_2 : 
              (chop_phase == 4'd5 & A2D_TS_DETOK == 1'b0) ? data_buf[15:8] : 
			  (chop_phase == 4'd9 & A2D_TS_DETOK == 1'b0) ? data_buf[15:8] : 
			  (chop_phase == 4'd11 & A2D_TS_DETOK == 1'b0) ? data_buf[15:8] :
			  (chop_phase == 4'd13 & A2D_TS_DETOK == 1'b0) ? data_buf[15:8] :
			  data_2;



endmodule
