//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//
//   File Name   : CHECKER.sv
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
//`include "Usertype_PKG.sv"

module Checker(input clk, INF.CHECKER inf);
import usertype::*;

covergroup Spec1 @(posedge clk && inf.amnt_valid);
	coverpoint inf.D.d_amnt{
		bins s0={[0:500]};
		bins s1={[501:1000]};
		bins s2={[1001:1500]};
		bins s3={[1501:2000]};
		option.at_least=10;
	}
endgroup

//declare other cover group
covergroup Spec2 @(posedge clk && inf.id_valid);
	coverpoint inf.D.d_id[0]{
		option.auto_bin_max=64;
		option.at_least=1;
	}
endgroup

covergroup Spec3 @(posedge clk && inf.act_valid);
	coverpoint inf.D.d_act[0]{
		bins s0  = (Seed=>Seed);
		bins s1  = (Seed=>Water);
		bins s2  = (Seed=>Reap);
		bins s3  = (Seed=>Steal);
		bins s4  = (Seed=>Check_dep);
		bins s5  = (Water=>Seed);
		bins s6  = (Water=>Water);
		bins s7  = (Water=>Reap);
		bins s8  = (Water=>Steal);
		bins s9  = (Water=>Check_dep);
		bins s10 = (Reap=>Seed);
		bins s11 = (Reap=>Water);
		bins s12 = (Reap=>Reap);
		bins s13 = (Reap=>Steal);
		bins s14 = (Reap=>Check_dep);
		bins s15 = (Steal=>Seed);
		bins s16 = (Steal=>Water);
		bins s17 = (Steal=>Reap);
		bins s18 = (Steal=>Steal);
		bins s19 = (Steal=>Check_dep);
		bins s20 = (Check_dep=>Seed);
		bins s21 = (Check_dep=>Water);
		bins s22 = (Check_dep=>Reap);
		bins s23 = (Check_dep=>Steal);
		bins s24 = (Check_dep=>Check_dep);
		option.at_least=10;
	}	
endgroup

covergroup Spec4 @(negedge clk && inf.out_valid);
	coverpoint inf.err_msg{
		bins s0={(Is_Empty )};
		bins s1={(Not_Empty)};
		bins s2={(Has_Grown)};
		bins s3={(Not_Grown)};	
		option.at_least=10;
	}
endgroup	


//declare the cover group 
Spec1 cov_inst_1 = new();
Spec2 cov_inst_2 = new();
Spec3 cov_inst_3 = new();
Spec4 cov_inst_4 = new();


//************************************ below assertion is to check your pattern ***************************************** 
//                                          Please finish and hand in it
// This is an example assertion given by TA, please write other assertions at the below
/*
 assert_interval : assert property ( @(posedge clk)  inf.out_valid |=> inf.id_valid == 0 [*2])
 else
 begin
 	$display("Assertion X is violated");
 	$fatal; 
 end
 */

//write other assertions
always@(negedge inf.rst_n)begin
	#1; assert_1 : assert (inf.out_valid==0&&inf.err_msg==0&&inf.complete==0&&inf.out_deposit==0&&inf.out_status==0)
	else
	begin
		$display("Assertion 1 is violated");
		$fatal; 
	end
	
end
	
assert2 : assert property(@(posedge clk) inf.complete==1 |->inf.err_msg==0)
	else begin
		$display("Assertion 2 is violated");
		$fatal; 
	end
	
Action action;
always@(posedge clk) begin
	if(inf.act_valid) action <= inf.D.d_act[0];
end
assert3 : assert property(@(posedge clk) (inf.out_valid==1&&action==Check_dep) |->inf.out_status==0)
	else begin
		$display("Assertion 3 is violated");
		$fatal; 
	end
	
assert4 : assert property(@(posedge clk) (inf.out_valid==1&&action!=Check_dep) |->inf.out_deposit==0)
	else begin
		$display("Assertion 4 is violated");
		$fatal; 
	end
	
assert5 : assert property(@(posedge clk) inf.out_valid==1 |=>inf.out_valid==0 )
	else begin
		$display("Assertion 5 is violated");
		$fatal; 
	end	
	
assert6 : assert property(@(posedge clk) inf.id_valid==1 |=>inf.act_valid==0 )
	else begin
		$display("Assertion 6 is violated");
		$fatal; 
	end	
	
assert7 : assert property(@(posedge clk) (action==Seed&&inf.cat_valid==1) |=>inf.amnt_valid==0 )
	else begin
		$display("Assertion 7 is violated");
		$fatal; 
	end	
	
assert8_1 : assert property(@(posedge clk) inf.id_valid==1 |->(inf.act_valid==0&&inf.cat_valid==0&&inf.amnt_valid==0))
	else begin
		$display("Assertion 8 is violated");
		$fatal; 
	end	
assert8_2 : assert property(@(posedge clk) inf.act_valid==1 |->(inf.id_valid==0&&inf.cat_valid==0&&inf.amnt_valid==0))
	else begin
		$display("Assertion 8 is violated");
		$fatal; 
	end	
assert8_3 : assert property(@(posedge clk) inf.cat_valid==1 |->(inf.id_valid==0&&inf.act_valid==0&&inf.amnt_valid==0))
	else begin
		$display("Assertion 8 is violated");
		$fatal; 
	end	
assert8_4 : assert property(@(posedge clk) inf.amnt_valid==1 |->(inf.id_valid==0&&inf.act_valid==0&&inf.cat_valid==0))
	else begin
		$display("Assertion 8 is violated");
		$fatal; 
	end	


endmodule