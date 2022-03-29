`include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype_PKG.sv"


program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;
parameter PATNUM=10000;

integer i, j;
integer total_latency, lat;
integer PATCOUNT;
integer id_change, gap;
integer y;
integer s;

integer action_random, id_random, cat_random, amnt_random;

integer dram[0:64][0:2];

initial begin
	forever@(negedge clk) begin
		if(inf.out_valid === 1'b0 && s==1) begin
			if(inf.out_status !== 32'b0 || inf.out_deposit !== 32'b0) begin
				output_not_zero_task;
			end
		end
	end
end

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
	
	@(negedge clk);
	@(negedge clk);
	
	for(PATCOUNT=0;PATCOUNT<PATNUM;PATCOUNT=PATCOUNT+1)begin
		
		if(PATCOUNT%16==1) begin
			action_random = 8;
			$display("check deposit");
			check_deposit_task;
		end
		else begin
			id_change = $urandom_range(1,5);
			if(id_change==1 || PATCOUNT==0) begin
				inf.id_valid = 1'b1;
				id_random = $urandom_range(0,63);
				inf.D = id_random;
				@(negedge clk);
				inf.id_valid = 1'b0;
				inf.D = 'bx;

				gap = $urandom_range(1,3);
				repeat(gap)@(negedge clk);
			end
			
			action_random = $urandom_range(1,10);
			if(action_random==1) begin
				$display("seed");
				seed_task;
			end
			else if(action_random==4) begin
				$display("steal");
				steal_task;
			end
			else if(action_random==2) begin
				$display("reap");
				reap_task;
			end
			else begin
				action_random = 3;
				$display("water");
				water_task;
			end
		end
		gap = $urandom_range(2,10);
		repeat(gap)@(negedge clk);
		
	end	
	YOU_PASS_task;
	$finish;

end

task reset_signal_task; begin 
	@(negedge clk); inf.rst_n=0;
	@(negedge clk);
  
	if(inf.out_valid !== 1'b0 || inf.err_msg !== 4'b0 || inf.complete !== 1'b0 || inf.out_status !== 32'b0 || inf.out_deposit !== 32'b0) begin
		fail;
		$display("************************************************************");
		$display("*         signal should be 0 after initial RESET           *");
		$display("************************************************************");
		$finish;
	end

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
		if(inf.err_msg !== 4'b0 || inf.complete !== 1'b1 || inf.out_status !== 32'b0) begin
			other_output_not0_task;
		end
		if(inf.out_deposit!==dram[64][2]) begin
			fail;
			$display("************************************************************");
			$display("*                    deposit is wrong                      *");
			$display("************************************************************");
			repeat(10) @(negedge clk);
			$finish;
		end
		@(negedge clk);
	end
	
	if(y>1) begin
		output_not_1_cycle_task;
	end
	
	$display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %3d\033[m",PATCOUNT ,lat);
	
end endtask

task seed_task; begin 
	
	inf.act_valid = 1'b1;
	inf.D = 1;
	@(negedge clk);
	inf.act_valid = 1'b0;
	inf.D = 'bx;
	
	gap = $urandom_range(1,3);
	repeat(gap)@(negedge clk);
	
	inf.cat_valid = 1'b1;
	cat_random = 2**$urandom_range(0,3);
	inf.D = cat_random;
	@(negedge clk);
	inf.cat_valid = 1'b0;
	inf.D = 'bx;
	
	gap = $urandom_range(1,3);
	repeat(gap)@(negedge clk);
	
	inf.amnt_valid = 1'b1;
	amnt_random = $urandom_range(0,2048);
	inf.D = amnt_random;
	@(negedge clk);
	inf.amnt_valid = 1'b0;
	inf.D = 'bx;
	
	wait_OUT_VALID;
	
	y=0;
	while(inf.out_valid) begin
		y=y+1;
		if(y>1) begin
			output_not_1_cycle_task;
		end
		if(dram[id_random][0]!=0) begin
			if(inf.out_status !== 32'b0 || inf.out_deposit !== 32'b0) begin
				other_output_not0_task;
			end
			if(inf.complete!==1'b0) begin
				fail;
				$display("************************************************************");
				$display("*         complete should be 0 when there is an error      *");
				$display("************************************************************");
				repeat(10) @(negedge clk);
				$finish;
			end
			if(inf.err_msg!==4'b0010) begin
				wrong_err_task;
			end
		end
		else begin
			if(inf.err_msg !== 4'b0 || inf.complete !== 1'b1 || inf.out_deposit !== 32'b0) begin
				other_output_not0_task;
			end
			
			if(cat_random==1) dram[64][2] = dram[64][2] - 5;
			else if(cat_random==2) dram[64][2] = dram[64][2] - 10;
			else if(cat_random==4) dram[64][2] = dram[64][2] - 15;
			else if(cat_random==8) dram[64][2] = dram[64][2] - 20;
			dram[id_random][1] = cat_random;
			dram[id_random][2] = dram[id_random][2]+amnt_random;
			if(dram[id_random][2]>=256*cat_random) dram[id_random][0] = 3;
			else if(dram[id_random][2]>=128*cat_random) dram[id_random][0] = 2;
			else dram[id_random][0] = 1;
			
			if(inf.out_status[31:24]!=id_random || inf.out_status[23:20]!=dram[id_random][0] || inf.out_status[19:16]!=dram[id_random][1] || inf.out_status[15:0]!=dram[id_random][2]) begin
				fail;
				$display("************************************************************");
				$display("*                    status is wrong                       *");
				$display("************************************************************");
				repeat(10) @(negedge clk);
				$finish;
			end
		end
		@(negedge clk);
	end
	
	if(y==0) begin
		output_not_1_cycle_task;
	end
	
	$display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %3d\033[m",PATCOUNT ,lat);
	
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
		if(y>1) begin
			output_not_1_cycle_task;
		end
		if(dram[id_random][0]==0 || dram[id_random][0]==1) begin
			if(inf.out_status !== 32'b0 || inf.out_deposit !== 32'b0) begin
				other_output_not0_task;
			end
			if(inf.complete!==1'b0) begin
				fail;
				$display("************************************************************");
				$display("*         complete should be 0 when there is an error      *");
				$display("************************************************************");
				repeat(10) @(negedge clk);
				$finish;
			end
			if(inf.err_msg!==4'b0001 && dram[id_random][0]==0) begin
				wrong_err_task;
			end
			if(inf.err_msg!==4'b0100 && dram[id_random][0]==1) begin
				wrong_err_task;
			end
		end
		else begin
			if(inf.err_msg !== 4'b0 || inf.complete !== 1'b1 || inf.out_deposit !== 32'b0) begin
				other_output_not0_task;
			end
			if(inf.out_status[31:24]!=id_random || inf.out_status[23:20]!=dram[id_random][0] || inf.out_status[19:16]!=dram[id_random][1] || inf.out_status[15:0]!=dram[id_random][2]) begin
				fail;
				$display("************************************************************");
				$display("*                    status is wrong                       *");
				$display("************************************************************");
				repeat(10) @(negedge clk);
				$finish;
			end
			dram[id_random][0] = 0;
			dram[id_random][1] = 0;
			dram[id_random][2] = 0;	
		end
		@(negedge clk);
	end
	
	if(y==0) begin
		output_not_1_cycle_task;
	end
	
	$display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %3d\033[m",PATCOUNT ,lat);
	
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
		if(y>1) begin
			output_not_1_cycle_task;
		end
		if(dram[id_random][0]==0 || dram[id_random][0]==1) begin
			if(inf.out_status !== 32'b0 || inf.out_deposit !== 32'b0) begin
				other_output_not0_task;
			end
			if(inf.complete!==1'b0) begin
				fail;
				$display("************************************************************");
				$display("*         complete should be 0 when there is an error      *");
				$display("************************************************************");
				repeat(10) @(negedge clk);
				$finish;
			end
			if(inf.err_msg!==4'b0001 && dram[id_random][0]==0) begin
				wrong_err_task;
			end
			if(inf.err_msg!==4'b0100 && dram[id_random][0]==1) begin
				wrong_err_task;
			end
		end
		else begin
			if(inf.err_msg !== 4'b0 || inf.complete !== 1'b1 || inf.out_deposit !== 32'b0) begin
				other_output_not0_task;
			end
			if(inf.out_status[31:24]!=id_random || inf.out_status[23:20]!=dram[id_random][0] || inf.out_status[19:16]!=dram[id_random][1] || inf.out_status[15:0]!=dram[id_random][2]) begin
				fail;
				$display("************************************************************");
				$display("*                    status is wrong                       *");
				$display("************************************************************");
				repeat(10) @(negedge clk);
				$finish;
			end	
			if(dram[id_random][0]==2) begin
				if(dram[id_random][1]==1) dram[64][2] = dram[64][2] + 10;
				else if(dram[id_random][1]==2) dram[64][2] = dram[64][2] + 20;
				else if(dram[id_random][1]==4) dram[64][2] = dram[64][2] + 30;
				else if(dram[id_random][1]==8) dram[64][2] = dram[64][2] + 40;
			end
			else if(dram[id_random][0]==3) begin
				if(dram[id_random][1]==1) dram[64][2] = dram[64][2] + 25;
				else if(dram[id_random][1]==2) dram[64][2] = dram[64][2] + 50;
				else if(dram[id_random][1]==4) dram[64][2] = dram[64][2] + 75;
				else if(dram[id_random][1]==8) dram[64][2] = dram[64][2] + 100;
			end
			dram[id_random][0] = 0;
			dram[id_random][1] = 0;
			dram[id_random][2] = 0;	
		end
		@(negedge clk);
	end
	
	if(y==0) begin
		output_not_1_cycle_task;
	end
	
	$display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %3d\033[m",PATCOUNT ,lat);
	
end endtask

task water_task; begin
	
	inf.act_valid = 1'b1;
	inf.D = action_random;
	@(negedge clk);
	inf.act_valid = 1'b0;
	inf.D = 'bx;
	
	gap = $urandom_range(1,3);
	repeat(gap)@(negedge clk);
	
	inf.amnt_valid = 1'b1;
	amnt_random = $urandom_range(0,2048 - dram[id_random][2]);
	inf.D = amnt_random;
	@(negedge clk);
	inf.amnt_valid = 1'b0;
	inf.D = 'bx;
	
	wait_OUT_VALID;
	
	y=0;
	while(inf.out_valid) begin
		y=y+1;
		if(y>1) begin
			output_not_1_cycle_task;
		end
		if(dram[id_random][0]==0 || (dram[id_random][2]>=(256*dram[id_random][1]) && (dram[id_random][1]!=0))) begin
			if(inf.out_status !== 32'b0 || inf.out_deposit !== 32'b0) begin
				other_output_not0_task;
			end
			if(inf.complete!==1'b0) begin
				fail;
				$display("************************************************************");
				$display("*         complete should be 0 when there is an error      *");
				$display("************************************************************");
				repeat(10) @(negedge clk);
				$finish;
			end
			if(inf.err_msg!==4'b0001 && dram[id_random][0]==0) begin
				wrong_err_task;
			end
			else if(inf.err_msg!==4'b0011 && (dram[id_random][2]>=(256*dram[id_random][1]) && (dram[id_random][1]!=0))) begin
				wrong_err_task;
			end
		end
		else begin
			if(inf.err_msg !== 4'b0 || inf.complete !== 1'b1 || inf.out_deposit !== 32'b0) begin
				other_output_not0_task;
			end
			dram[id_random][2] = dram[id_random][2] + amnt_random;	
			if(dram[id_random][2]>=256*dram[id_random][1]) dram[id_random][0] = 3;
			else if(dram[id_random][2]>=128*dram[id_random][1]) dram[id_random][0] = 2;
			else dram[id_random][0] = 1;
			if(inf.out_status[31:24]!=id_random || inf.out_status[23:20]!=dram[id_random][0] || inf.out_status[19:16]!=dram[id_random][1] || inf.out_status[15:0]!=dram[id_random][2]) begin
				$display("id: %d, %d", inf.out_status[31:24], id_random);
				$display("stage: %d, %d", inf.out_status[23:20], dram[id_random][0]);
				$display("crop cat: %d, %d", inf.out_status[19:16], dram[id_random][1]);
				$display("amnt: %d, %d", inf.out_status[15:0], dram[id_random][2]);
				fail;
				$display("************************************************************");
				$display("*                    status is wrong                       *");
				$display("************************************************************");
				repeat(10) @(negedge clk);
				$finish;
			end
		end
		@(negedge clk);
	end
	
	if(y==0) begin
		output_not_1_cycle_task;
	end
	
	$display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %3d\033[m",PATCOUNT ,lat);
	
end endtask

task wait_OUT_VALID; begin
	lat = -1;
	while(!inf.out_valid) begin
		lat = lat + 1;
		if(lat == 1200) begin
			fail;
			$display("************************************************************");
			$display("*        The execution latency are over  1200  cycles      *");
			$display("************************************************************");
			$finish;
		end
		@(negedge clk);
	end
	total_latency = total_latency + lat + 1;
end endtask

task output_not_1_cycle_task; begin
	fail;
	$display("************************************************************");
	$display("*                 output doesn't last  1 cycle             *");
	$display("************************************************************");
	repeat(10) @(negedge clk);
	$finish;
end endtask

task other_output_not0_task; begin
	fail;
	$display("************************************************************");
	$display("*                other signals should be 0                 *");
	$display("************************************************************");
	repeat(10) @(negedge clk);
	$finish;
end endtask

task wrong_err_task; begin
	fail;
	$display("************************************************************");
	$display("*                     err_msg is wrong                     *");
	$display("************************************************************");
	repeat(10) @(negedge clk);
	$finish;
end endtask

task output_not_zero_task; begin
	fail;
	$display("************************************************************");
	$display("*           output not zero when outvalid is 0             *");
	$display("************************************************************");
	repeat(10) @(negedge clk);
	$finish;
end endtask

task YOU_PASS_task;begin

$display ("---------------------------------------------------------------------------------------------------------------------");
$display ("                                                  Congratulations!                						            ");
$display ("                                           You have passed all patterns!          						            ");
$display ("                                           Your execution cycles = %5d cycles   						                ", total_latency);
$display ("---------------------------------------------------------------------------------------------------------------------");
$finish;	

end endtask

task fail;begin
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
$display("Oo::::ooOOO8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
$display(" ..::..       .:o88@@@@@@@@@@@8OOoo:::..::oooOO8@@@@@@@@@@@@");
$display("@@@@@@@@@@@@Oo..                   ..:.:..      .:O8@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@88888888888@@@@@@@@@@@@@@@@@8.    :O@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8.   :8@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8.   :");
$display("@@@@@@8@@@@@@@@8o::o8@@@@@8ooO88@@@@@@@@@@@@@@@@@@@@@@@@8:. ");
$display("@@O      :@@@O   ..  :O@@@:       :@@@@OoO8@@@@@@@@@@@@@@@@O");
$display("@:  .@@88@@@8:  o@@o  :@@@. 0@@@.  O@@@      .O8@@@@@@@@@@@@");
$display("@O.      :8@8:  o@@O. .@@8  000o  .8@@O  O8O:  .@@o .O@@@@@@");
$display("@@@@@@@:  .o8:  o@@o. .@@O  ::  .O@@@O.  o0o.  :@@O. :8@8::8");
$display("@@@OO@@8.  o@8   ''  .O@@o  O@:  :O@@:  ::   .8@@@O. .:   .8");
$display("@@O      .8@@@@Oo::oO@@@@O  8@8:  :@8  :@O. :O@@@@8:   .o@@@");
$display("@@@@@8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@o:8@8:  :@@@@:  .O@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@OoO@@@O  :8@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@88@@@@@@@@@@@@@@@@@@@8::@@@@@88@");
$display("@@@@@@@@@@@@@@@@@@@88OOoo::....:O88@@@@@@@@@@@@@@@@@@@@8o .8");
$display(" ..:o8888888OO::.      ....:o:..     oO@@@@@@@@@@@@@@@@8O..@");
$display("o::.          ..:OO@@@@@@@@@@@@@@@@O:  .o@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8O   .8@@@@@@@@@@@@@@@@");
end
endtask
endprogram

	
	
	
	
