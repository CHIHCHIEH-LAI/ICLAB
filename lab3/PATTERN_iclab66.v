//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2020 ICLAB FALL Course
//   Lab03       : Testbench and Pattern
//   Author      : Chih-Chieh Lai
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//   Release version : v1.0
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`ifdef RTL
	`timescale 1ns/10ps
	`include "SD.v"
    `define CYCLE_TIME 7.0
`endif

`ifdef GATE
	`timescale 1ns/1ps
	`include "SD_SYN.v"
    `define CYCLE_TIME 7.0
`endif


module PATTERN(
    // Output signals
	clk,
    rst_n,
	in_valid,
	in,
    // Input signals
    out_valid,
    out
);

//================================================================ 
//   INPUT AND OUTPUT DECLARATION
//================================================================
output reg clk, rst_n, in_valid;
output reg [3:0] in;
input out_valid;
input [3:0] out;

//================================================================
// parameters & integer
//================================================================
real	CYCLE = `CYCLE_TIME;
integer PATNUM=1;
integer seed = 333;
integer i,j,k,l,y;
integer gold;
integer gap;
integer lat,total_latency;
integer patcount;
integer input_file,output_file;

//================================================================
// clock
//================================================================
always	#(CYCLE/2.0) clk = ~clk;
initial	clk = 0;

always @(negedge clk) begin
	if(out_valid===1'b0) begin
		if(out !== 4'b0) begin
			$display ("SPEC 4 FAIL!");
			repeat(9) @(negedge clk);
			$finish;
		end
	end
end

//================================================================
// initial
//================================================================
initial begin
    rst_n = 1;    
    in_valid = 1'b0; 
	in = 4'bx;
	
	force clk = 0;
	
	total_latency = 0; 
	reset_signal_task;

	input_file=$fopen("../00_TESTBED/input.txt","r");
  	output_file=$fopen("../00_TESTBED/output.txt","r");
	
	for(patcount=0; patcount<PATNUM; patcount=patcount+1) begin		
		input_task;
		wait_OUT_VALID;
		check_ans;
		$display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32m Latency: %3d\033[m",
				patcount ,lat);
	end

	YOU_PASS_task;
	$finish;
end

//================================================================
// task
//================================================================
task reset_signal_task; begin 
    #(0.5);   rst_n=0;
	
	#(2.0);
	if((out_valid !== 1'b0)||(out !== 4'b0)) begin
		$display ("SPEC 3 FAIL!");
		$finish;
	end
	
	#(10);   rst_n=1;
	#(3);   release clk;
end endtask

task input_task; begin
	gap = $urandom_range(2,4);
	repeat(gap) @(negedge clk);
	
	in_valid = 1;
	for(j=0; j<81; j=j+1) begin
	
		if(out_valid !== 1'b0) begin
			$display ("SPEC 7 FAIL!");
			repeat(9) @(negedge clk);
			$finish;
		end
		
		k=$fscanf(input_file,"%d",in);
		@(negedge clk);	
	end   
	in_valid = 0;
	in = 'dx;
end endtask

task wait_OUT_VALID; begin
  lat = -1;
  while(out_valid !==1'b1) begin
	lat = lat + 1;
	
	if(lat >= 300) begin
		$display ("SPEC 6 FAIL!");
		repeat(2)@(negedge clk);
		$finish;
	end
	@(negedge clk);
  end
  
  total_latency = total_latency + lat;
end endtask

task check_ans; begin
	y=0;
	while(out_valid) begin
		if(y>=9) begin
			$display ("SPEC 5 FAIL!");
			repeat(9) @(negedge clk);
			$finish;
		end		
		l=$fscanf(output_file,"%d",gold);
		if(out!==gold) begin
			$display ("SPEC 8 FAIL!");
			repeat(9) @(negedge clk);
			$finish;
		end
		@(negedge clk);	
		y=y+1;
	end		
	
	if(y!=9) begin
		$display ("SPEC 5 FAIL!");
		repeat(9) @(negedge clk);
		$finish;
	end		
end endtask

task YOU_PASS_task;begin

	$display ("----------------------------------------------------------------------------------------------------------------------");
	$display ("                                                  Congratulations!                						            ");
	$display ("                                           You have passed all patterns!          						            ");
	$display ("                                           Your execution cycles = %5d cycles   						            ", total_latency);
	$display ("                                           Your clock period = %.1f ns        					                ", CYCLE);
	$display ("                                           Your total latency = %.1f ns         						            ", total_latency*CYCLE);
	$display ("----------------------------------------------------------------------------------------------------------------------");
	$finish;	
end endtask

endmodule