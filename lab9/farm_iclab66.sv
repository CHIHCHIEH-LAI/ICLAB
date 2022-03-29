module farm(input clk, INF.farm_inf inf);
import usertype::*;

// ------------------
// parameter
// ------------------
parameter INPUT_ACT = 4'd0;
parameter INPUT_CAT = 4'd1;
parameter INPUT_AMNT = 4'd2;
parameter READ_DRAM = 4'd3;
parameter READ_DEPOSIT = 4'd4;
parameter CHECK_ERR = 4'd5;
parameter CALC = 4'd6;
parameter WRITE_DRAM = 4'd7;
parameter OUTPUT_ERR = 4'd8;
parameter OUTPUT = 4'd9;

// ------------------
// logic
// ------------------
logic [3:0] current_state, next_state;

logic [5:0] id_keep, id_past;
logic [3:0] action_keep;
logic [3:0] crop_keep;
logic [11:0] amnt_keep;

logic C_in_valid_high;

logic read_deposit;
logic [31:0] deposit;

logic [3:0] stage, crop_cat;
logic [11:0] water_amnt;

Error_Msg err;

logic [31:0] old_status;
logic s;
logic [31:0] last_status;

// ------------------
// state
// ------------------
// current_state
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) current_state <= INPUT_ACT;
	else current_state <= next_state;
end

// next_state
always_comb begin
	case(current_state) 
		INPUT_ACT:
			if(inf.act_valid) begin
				if(inf.D==1) next_state = INPUT_CAT;
				else if(inf.D==2) begin
					if(id_keep==id_past && s==1) next_state = CHECK_ERR;
					else if(s==1) next_state = WRITE_DRAM;
					else next_state = READ_DRAM;
				end
				else if(inf.D==3) next_state = INPUT_AMNT;
				else if(inf.D==4) begin
					if(id_keep==id_past && s==1) next_state = CHECK_ERR;
					else if(s==1) next_state = WRITE_DRAM;
					else next_state = READ_DRAM;
				end		
				else begin
					if(read_deposit==1) next_state = OUTPUT;
					else next_state = READ_DEPOSIT;
				end
			end
			else next_state = INPUT_ACT;
		INPUT_CAT: 
			if(inf.cat_valid) next_state = INPUT_AMNT;
			else next_state = INPUT_CAT;
		INPUT_AMNT:
			if(inf.amnt_valid) begin
				if(action_keep==1) begin
					if(id_keep==id_past && s==1) next_state = CHECK_ERR;
					else if(s==1) next_state = WRITE_DRAM;
					else next_state = READ_DRAM;
				end
				else begin
					if(id_keep==id_past && s==1) next_state = CHECK_ERR;
					else if(s==1) next_state = WRITE_DRAM;
					else next_state = READ_DRAM;
				end
			end
			else next_state = INPUT_AMNT;
		READ_DRAM:
			if(read_deposit==1) begin
				if(inf.C_out_valid==1) next_state = CHECK_ERR; 
				else next_state = READ_DRAM;
			end
			else next_state = READ_DEPOSIT;
		READ_DEPOSIT:
			if(inf.C_out_valid==1) begin
				if(action_keep==8) next_state = OUTPUT;
				else next_state = READ_DRAM;
			end
			else next_state = READ_DEPOSIT;
		CHECK_ERR:
			if(err==No_Err) next_state = CALC;
			else next_state = OUTPUT_ERR;
		CALC:
			next_state = OUTPUT;
		WRITE_DRAM:
			if(inf.C_out_valid==1) next_state = READ_DRAM;
			else next_state = WRITE_DRAM;
		OUTPUT_ERR:
			next_state = INPUT_ACT;
		OUTPUT:                
			next_state = INPUT_ACT;
		default:               
			next_state = INPUT_ACT;
	endcase
end

// ------------------
// keep input
// ------------------
// id_keep
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		id_keep <= 0;
	end
	else if(inf.id_valid) begin
		id_keep <= inf.D;
	end
end

// id_past
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) begin
		id_past <= 0;
	end
	else if(current_state==OUTPUT || current_state==OUTPUT_ERR) begin
		id_past <= id_keep;
	end
end

// action_keep
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) action_keep <= 0;
	else if(inf.act_valid) action_keep <= inf.D;
	else if(current_state==OUTPUT) action_keep <= 0;
end

// crop_keep
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) crop_keep <= 0;
	else if(inf.cat_valid) crop_keep <= inf.D;
	else if(current_state==CHECK_ERR && err==No_Err && action_keep!=1) crop_keep <= crop_cat;
end

// amnt_keep
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) amnt_keep <= 0;
	else if(inf.amnt_valid) amnt_keep <= inf.D;
end

// ------------------
// access DRAM
// ------------------
// C_in_valid
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) inf.C_in_valid <= 0;
	else if(current_state==READ_DRAM && C_in_valid_high==0 && read_deposit==1) inf.C_in_valid <= 1;
	else if(current_state==READ_DEPOSIT && C_in_valid_high==0) inf.C_in_valid <= 1;
	else if(current_state==WRITE_DRAM && C_in_valid_high==0) inf.C_in_valid <= 1;
	else inf.C_in_valid <= 0;
end

// C_in_valid_high
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) C_in_valid_high <= 0;
	else if(current_state==READ_DRAM && read_deposit==1 && inf.C_out_valid==0) C_in_valid_high <= 1;
	else if(current_state==READ_DEPOSIT && inf.C_out_valid==0) C_in_valid_high <= 1;
	else if(current_state==WRITE_DRAM && inf.C_out_valid==0) C_in_valid_high <= 1;
	else C_in_valid_high <= 0;
end

// C_r_wb
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) inf.C_r_wb <= 1;
	else if(current_state==WRITE_DRAM) inf.C_r_wb <= 0;
	else inf.C_r_wb <= 1;
end

// C_addr
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) inf.C_addr <= 0;
	else if(current_state==READ_DRAM) inf.C_addr <= id_keep;
	else if(current_state==READ_DEPOSIT) inf.C_addr <= 64;
	else if(current_state==WRITE_DRAM) inf.C_addr <= id_past;
	else inf.C_addr <= 0;
end

// C_data_w
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) inf.C_data_w <= 0;
	// else if(current_state==WRITE_DRAM) inf.C_data_w <= {water_amnt[7:0], 4'b0,water_amnt[11:8], stage,crop_cat, 2'b0,id_keep};
	else if(current_state==WRITE_DRAM) inf.C_data_w <= last_status;
	else inf.C_data_w <= 0;
end

// ------------------
// deposit
// ------------------
// read_deposit
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) read_deposit <= 0;
	else if(current_state==READ_DEPOSIT && inf.C_out_valid==1) read_deposit <= 1;
end

// deposit
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) deposit <= 0;
	else if(current_state==READ_DEPOSIT && inf.C_out_valid==1) deposit <= {inf.C_data_r[7:0], inf.C_data_r[15:8], inf.C_data_r[23:16], inf.C_data_r[31:24]};
	else if(current_state==CALC) begin
		if(action_keep==1) begin
			if(crop_keep==1) deposit <= deposit - 5;
			else if(crop_keep==2) deposit <= deposit - 10;
			else if(crop_keep==4) deposit <= deposit - 15;
			else if(crop_keep==8) deposit <= deposit - 20;
		end
		else if(action_keep==2) begin
			if(stage==2) begin
				if(crop_keep==1) deposit <= deposit + 10;
				else if(crop_keep==2) deposit <= deposit + 20;
				else if(crop_keep==4) deposit <= deposit + 30;
				else if(crop_keep==8) deposit <= deposit + 40;	
			end
			else if(stage==3) begin
				if(crop_keep==1) deposit <= deposit + 25;
				else if(crop_keep==2) deposit <= deposit + 50;
				else if(crop_keep==4) deposit <= deposit + 75;
				else if(crop_keep==8) deposit <= deposit + 100;	
			end
		end
	end
end

// s
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) s <= 0;
	else if(current_state==OUTPUT || current_state==OUTPUT_ERR) s <= 1;
end

// ------------------
// status
// ------------------
// stage
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) stage <= 0;
	else if(current_state==READ_DRAM && inf.C_out_valid==1) stage <= inf.C_data_r[15:12];
	else if(current_state==CALC) begin
		if(action_keep==1) begin
			if(amnt_keep>=(256*crop_keep)) stage <= 3;
			else if(amnt_keep>=(128*crop_keep)) stage <= 2;
			else stage <= 1;
		end
		else if(action_keep==3) begin
			if((water_amnt+amnt_keep)>=(256*crop_cat)) stage <= 3;
			else if((water_amnt+amnt_keep)>=(128*crop_cat)) stage <= 2;
			else stage <= 1;
		end
		else if(action_keep==2 || action_keep==4) stage <= 0;
	end
end

// crop_cat
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) crop_cat <= 0;
	else if(current_state==READ_DRAM && inf.C_out_valid==1) crop_cat <= inf.C_data_r[11:8];
	else if(current_state==CALC) begin
		if(action_keep==1) crop_cat <= crop_keep;
		else if(action_keep==2 || action_keep==4) crop_cat <= 0;
	end
end

// water_amnt
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) water_amnt <= 0;
	else if(current_state==READ_DRAM && inf.C_out_valid==1) water_amnt <= {inf.C_data_r[23:16], inf.C_data_r[31:24]};	
	else if(current_state==CALC) begin
		if(action_keep==1 || action_keep==3) water_amnt <= water_amnt + amnt_keep;
		else if(action_keep==2 || action_keep==4) water_amnt <= 0;
	end
end

// old_status
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) old_status <= 0;
	else if(current_state==READ_DRAM && inf.C_out_valid==1) old_status <= {inf.C_data_r[7:0], inf.C_data_r[15:8], inf.C_data_r[23:16], inf.C_data_r[31:24]};	
	else if(current_state==OUTPUT) old_status <= {2'b0,id_keep, stage,crop_cat, 4'b0,water_amnt};
end

// last_status
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) last_status <= 0;	
	else if(inf.out_valid==1) last_status <= inf.out_status;
end

// err
always_comb begin
	if(action_keep==1 && crop_cat!=0) err = Not_Empty;
	else if((action_keep==3||action_keep==2||action_keep==4) && crop_cat==0) err = Is_Empty;
	else if(action_keep==3 && water_amnt>=256*crop_cat) err = Has_Grown;
	else if((action_keep==2||action_keep==4) && stage<2) err = Not_Grown;
	else err = No_Err;
end

// ------------------
// output
// ------------------
// out_valid
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) inf.out_valid <= 0;
	else if(current_state==OUTPUT_ERR) inf.out_valid <= 1;
	else if(current_state==OUTPUT) inf.out_valid <= 1;
	else inf.out_valid <= 0;
end

// err_msg
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) inf.err_msg <= No_Err;
	else if(current_state==OUTPUT_ERR) inf.err_msg <= err;
	else inf.err_msg <= No_Err;
end

// complete
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) inf.complete <= 0;
	else if(current_state==OUTPUT_ERR) inf.complete <= 0;
	else if(current_state==OUTPUT) inf.complete <= 1;
	else inf.complete <= 0;
end

// out_status
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) inf.out_status <= 0;
	else if(current_state==OUTPUT) begin
		if(action_keep==2 || action_keep==4) inf.out_status <= old_status;
		else if(action_keep==8) inf.out_status <= 0;
		else inf.out_status <= {2'b0,id_keep, stage,crop_cat, 4'b0,water_amnt};
	end
	else inf.out_status <= 0;
end

// out_deposit
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) inf.out_deposit <= 0;
	else if(current_state==OUTPUT && action_keep==8) inf.out_deposit <= deposit;
	else inf.out_deposit <= 0;
end

endmodule