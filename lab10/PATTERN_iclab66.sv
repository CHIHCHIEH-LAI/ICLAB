
`include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype_PKG.sv"
`include "success.sv"
program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

parameter PATNUM=314;

integer i, j;
integer total_latency, lat;
integer PATCOUNT;
integer id_change, gap;
integer y;
integer s;
integer input_file, f;

integer action_random, id_random, cat_random, amnt_random;

integer dram[0:64][0:2];

initial begin
	inf.rst_n = 1'b1;
	inf.id_valid = 1'b0;
	inf.act_valid = 1'b0;
	inf.cat_valid = 1'b0;
	inf.amnt_valid = 1'b0;
	inf.D = 'bx;
	
	total_latency=0;
	
	s=0;
	reset_signal_task;
	s=1;
	
	for(i=0; i<64; i=i+1) begin
		for(j=0; j<3; j=j+1) begin
			dram[i][j] = 0;
		end
	end
	dram[64][0] = 0;
	dram[64][1] = 0;
	dram[64][2] = 'h640;
	
	input_file=$fopen("../00_TESTBED/input.txt","r");
	
	id_random = 0;
	
	for(PATCOUNT=0;PATCOUNT<PATNUM;PATCOUNT=PATCOUNT+1)begin
		
		// action_random = $urandom_range(1,5);
		f=$fscanf(input_file,"%d",action_random);
		if(action_random!=8) begin
			
			if(PATCOUNT%3==0) begin
				if(id_random==63) id_random = 0;
				else id_random = id_random + 1;
				inf.id_valid = 1'b1;
				inf.D = id_random;
				@(negedge clk);
				inf.id_valid = 1'b0;
				inf.D = 'bx;
				@(negedge clk);
			end
			
			if(action_random==1) begin
				seed_task;
			end
			else if(action_random==4) begin
				steal_task;
			end
			else if(action_random==2) begin
				reap_task;
			end
			else if(action_random==3) begin
				water_task;
			end
		end
		else begin
			action_random = 8;
			check_deposit_task;
		end
		
		repeat(2)@(negedge clk);
		
	end	
	congratulations;
end



task congratulations; begin
    $display("********************************************************************");
    $display("                        \033[0;38;5;219mCongratulations!\033[m      ");
    $display("                 \033[0;38;5;219mYou have passed all patterns!\033[m");
    $display("                 \033[0;38;5;219mTotal time: %d \033[m",$time);
    $display("********************************************************************");
    image_.success;
	repeat(2) @(negedge clk);
    $finish;
end
endtask

task reset_signal_task; begin 
	@(negedge clk); inf.rst_n=0;
	@(negedge clk); inf.rst_n=1;
	@(negedge clk);
end endtask

task check_deposit_task; begin 
	inf.act_valid = 1'b1;
	inf.D = 8;
	@(negedge clk);
	
	inf.act_valid = 1'b0;
	inf.D = 'bx;
	
	wait_OUT_VALID;
	
	y=0;
	while(inf.out_valid) begin
		y=y+1;
		@(negedge clk);
	end
	
end endtask

task seed_task; begin 
	
	inf.act_valid = 1'b1;
	inf.D = 1;
	@(negedge clk);
	inf.act_valid = 1'b0;
	inf.D = 'bx;
	
	@(negedge clk);
	
	inf.cat_valid = 1'b1;
	cat_random = 1;
	inf.D = cat_random;
	@(negedge clk);
	inf.cat_valid = 1'b0;
	inf.D = 'bx;
	
	@(negedge clk);
	
	inf.amnt_valid = 1'b1;
	amnt_random = 0;
	inf.D = amnt_random;
	@(negedge clk);
	inf.amnt_valid = 1'b0;
	inf.D = 'bx;
	
	wait_OUT_VALID;
	
	y=0;
	while(inf.out_valid) begin
		y=y+1;
		@(negedge clk);
	end
	
end endtask

task steal_task; begin
	
	inf.act_valid = 1'b1;
	inf.D = action_random;
	@(negedge clk);
	inf.act_valid = 1'b0;
	inf.D = 'bx;
	
	wait_OUT_VALID;
	
	y=0;
	while(inf.out_valid) begin
		y=y+1;
		@(negedge clk);
	end
	
end endtask

task reap_task; begin
	
	inf.act_valid = 1'b1;
	inf.D = action_random;
	@(negedge clk);
	inf.act_valid = 1'b0;
	inf.D = 'bx;
	
	wait_OUT_VALID;
	
	y=0;
	while(inf.out_valid) begin
		y=y+1;
		@(negedge clk);
	end
	
end endtask

task water_task; begin
	
	inf.act_valid = 1'b1;
	inf.D = action_random;
	@(negedge clk);
	inf.act_valid = 1'b0;
	inf.D = 'bx;
	
	@(negedge clk);
	
	inf.amnt_valid = 1'b1;
	amnt_random = $urandom_range(40,200)*10;
	inf.D = amnt_random;
	@(negedge clk);
	inf.amnt_valid = 1'b0;
	inf.D = 'bx;
	
	wait_OUT_VALID;
	
	y=0;
	while(inf.out_valid) begin
		y=y+1;
		@(negedge clk);
	end
	
end endtask

task wait_OUT_VALID; begin
	lat = -1;
	while(!inf.out_valid) begin
		lat = lat + 1;
		@(negedge clk);
	end
	total_latency = total_latency + lat + 1;
end endtask

endprogram