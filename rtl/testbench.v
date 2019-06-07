`timescale 1ns/1ps
module test_bench ();

//**************************** wire & reg**********************//
  reg clk; // osc_16MHz
  reg RSTn;
  reg FLOCK;
 

//**************************** module **********************//
initial $display("===module : TS_top");
TS_top TS_top(
   .clk(clk) // osc_16MHz
  ,.RSTn(RSTn)
  
  ,.FLOCK(FLOCK)
  ,.A2D_TS_DETOK(1'd0)
  ,.A2D_TS_DOUT(8'd0)
  ,.reg_ts_en_sel(1'd0)
  ,.reg_ts_chopper_clk_sel(1'd0)
  ,.reg_offset(4'd0)
  
  ,.D2A_TS_EN()
  ,.D2A_TS_START_EN()
  ,.D2A_TS_CLK()
  ,.D2A_TS_CHOPPER_CLK()
  ,.ts_out()
);
//**************************** clock **********************//
`define CYCLE 31.25
initial begin
	force clk = 1'b0;
    @(negedge TS_top.RSTn);
    @(posedge TS_top.RSTn);
	$display("===starting generating clk");
	forever #(`CYCLE) force TS_top.clk = ~TS_top.clk;
end

//*******************************reset******************//
initial begin
	$display("===starting initial reset");
	force TS_top.RSTn = 1'b1;
	#1_000;
	force TS_top.RSTn = 1'b0;
	#1_000;
	force TS_top.RSTn = 1'b1;
end

//**************************** initial and wavegen **********************//
initial 
begin
	$display("===starting dump waveform");
	$dumpfile("out.vcd");
	$dumpvars(0,TS_top);
end

//**************************** main **********************//

initial
begin
    @(negedge TS_top.RSTn);
    @(posedge TS_top.RSTn);
	//waiting reset


	$display("===all done");
	#1000000 $finish;
end

always begin
  @(posedge TS_top.D2A_TS_START_EN);
  force TS_top.A2D_TS_DETOK = 1'd0;
  #26562.5ns;
  force TS_top.A2D_TS_DETOK = 1'd1;
end

always begin
  @(posedge TS_top.D2A_TS_START_EN);
  force TS_top.A2D_TS_DOUT = TS_top.A2D_TS_DOUT + 8'd1;
end

//*******************************end**************************//
endmodule
