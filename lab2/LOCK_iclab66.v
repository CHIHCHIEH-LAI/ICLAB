module LOCK(
	clk,
	rst_n,
	//input
	in_valid,
	mode,	
	in,	
	in_p1,	
	//output
	out_valid,
	circle,
	value
);
//---------------------------------------------------------------------
//   PORT DECLARATION
//---------------------------------------------------------------------
input clk;
input rst_n;

input in_valid;
input[1:0] mode;
input[4:0] in;
input[4:0] in_p1;

output reg out_valid;
output reg[2:0]circle;
output reg[6:0]value;

//---------------------------------------------------------------------
//   PARAMETER DECLARATION
//---------------------------------------------------------------------
parameter INPUT_A    = 4'd0;
parameter INPUT_B    = 4'd1;
parameter INPUT_C    = 4'd2;
parameter INPUT_D    = 4'd3;
parameter ROTATE_BCD = 4'd4;
parameter RESTART    = 4'd5;
parameter ROTATE_A   = 4'd6;
parameter SORTING    = 4'd7;
parameter OUTPUT     = 4'd8;

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
reg [3:0] current_state, next_state;

// counter
reg [4:0] cnt;
reg [2:0] cnt_output;

// store input
reg [1:0] mode_save;
reg [4:0] p1_save;

// circle condition
wire cdn_a, cdn_b, cdn_c, cdn_d;

// circle value
reg [4:0] a0, a1, a2, a3, a4, a5, a6, a7;
reg [4:0] b0, b1, b2, b3, b4, b5, b6, b7;
reg [4:0] c0, c1, c2, c3, c4, c5, c6, c7;
reg [4:0] d0, d1, d2, d3, d4, d5, d6, d7;

// num of turns
reg [2:0] circle_a, circle_b, circle_c, circle_d;

// summation
wire [6:0] value0, value1, value2, value3, value4, value5, value6, value7;

// sorting
wire [6:0] s0_0, s0_1, s0_2, s0_3, s0_4, s0_5, s0_6, s0_7;
wire [6:0] s1_0, s1_1, s1_2, s1_3, s1_4, s1_5, s1_6, s1_7;

wire [6:0] s2_0, s2_1, s2_2, s2_3, s2_4, s2_5, s2_6, s2_7;
wire [6:0] s3_0, s3_1, s3_2, s3_3;

wire [6:0] s4_0, s4_1, s4_2, s4_3;
wire [6:0] s5_0, s5_1, s5_2, s5_3, s5_4, s5_5;

reg [6:0] tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7;

//---------------------------------------------------------------------
//   Design
//---------------------------------------------------------------------

// FSM: current state
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        current_state <= INPUT_A;
    else
        current_state <= next_state;
end

// FSM: next state
always @(*) begin
    case(current_state)
		INPUT_A:
			if(cnt==7) next_state = INPUT_B;
			else next_state = INPUT_A;
		INPUT_B:
			if(cnt==15) next_state = INPUT_C;
			else next_state = INPUT_B;
		INPUT_C:
			if(cnt==23) next_state = INPUT_D;
			else next_state = INPUT_C;
		INPUT_D:
			if(cnt==31) next_state = ROTATE_BCD;
			else next_state = INPUT_D;
		ROTATE_BCD:
			if(cdn_b&cdn_c&cdn_d) next_state = SORTING;
			else if(cnt[2:0]==7) next_state = RESTART;
			else next_state = ROTATE_BCD;
		RESTART:
			if(!circle_b&!circle_c&!circle_d) next_state = ROTATE_A;
			else next_state = RESTART;
		ROTATE_A:
			if(a1==p1_save) next_state = ROTATE_BCD;
			else next_state = ROTATE_A;
		SORTING:
			next_state = OUTPUT;
		OUTPUT:
			if(cnt_output==7) next_state = INPUT_A;
			else next_state = OUTPUT;
		default: next_state = current_state;
    endcase
end

// counter: cnt
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt <= 0;
	end
	else if(in_valid) begin
		cnt <= cnt + 1;
	end
	else if(current_state==ROTATE_BCD) begin
		cnt <= cnt + 1;
	end
	else begin 
		cnt <= 0;
	end
end

// counter: cnt_output
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_output <= 0;
	end
	else if(current_state==OUTPUT) begin
		cnt_output <= cnt_output + 1;
	end
	else begin
		cnt_output <= 0;
	end
end

// mode, in_p1
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		mode_save <= 0;
		p1_save <= 0;
	end
	else if(in_valid && cnt==0) begin
		mode_save <= mode;
		p1_save <= in_p1;
	end
end

// 1st circle
assign cdn_a = (p1_save==a0);
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		a0 <= 0;
		a1 <= 0;
		a2 <= 0;
		a3 <= 0;
		a4 <= 0;
		a5 <= 0;
		a6 <= 0;
		a7 <= 0;
	end
	else if(current_state==INPUT_A & in_valid) begin
		a0 <= a1;
		a1 <= a2;
		a2 <= a3;
		a3 <= a4;
		a4 <= a5;
		a5 <= a6;
		a6 <= a7;
		a7 <= in;
	end
	else if(current_state==INPUT_B) begin
		if(!cdn_a) begin
			a0 <= a1;
			a1 <= a2;
			a2 <= a3;
			a3 <= a4;
			a4 <= a5;
			a5 <= a6;
			a6 <= a7;
			a7 <= a0;
		end
	end
	else if(current_state==ROTATE_A) begin
		a0 <= a1;
		a1 <= a2;
		a2 <= a3;
		a3 <= a4;
		a4 <= a5;
		a5 <= a6;
		a6 <= a7;
		a7 <= a0;
	end
end

// 1st circle: num of turns 
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		circle_a <= 0;
	end
	else if(current_state==INPUT_B && !cdn_a) begin
		circle_a <= circle_a + 1;
	end
	else if(current_state==ROTATE_A) begin
		circle_a <= circle_a + 1;
	end
	else if(current_state==INPUT_A) begin
		circle_a <= 0;
	end
end

// 2nd circle
assign cdn_b = (a0==b0) & ((mode_save)?(a4==b4):1) & ((mode_save>1)?(a2==b2):1) & ((mode_save>2)?(a6==b6):1);
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		b0 <= 0;
		b1 <= 0;
		b2 <= 0;
		b3 <= 0;
		b4 <= 0;
		b5 <= 0;
		b6 <= 0;
		b7 <= 0;
	end
	else if(current_state==INPUT_B) begin
		b0 <= b1;
		b1 <= b2;
		b2 <= b3;
		b3 <= b4;
		b4 <= b5;
		b5 <= b6;
		b6 <= b7;
		b7 <= in;
	end
	else if(current_state==INPUT_C) begin
		if(!cdn_b) begin
			b0 <= b1;
			b1 <= b2;
			b2 <= b3;
			b3 <= b4;
			b4 <= b5;
			b5 <= b6;
			b6 <= b7;
			b7 <= b0;
		end
	end
	else if(current_state==RESTART) begin
		if(circle_b) begin
			b0 <= b1;
			b1 <= b2;
			b2 <= b3;
			b3 <= b4;
			b4 <= b5;
			b5 <= b6;
			b6 <= b7;
			b7 <= b0;
		end
	end
	else if(current_state==ROTATE_BCD) begin
		if(!cdn_b) begin
			b0 <= b1;
			b1 <= b2;
			b2 <= b3;
			b3 <= b4;
			b4 <= b5;
			b5 <= b6;
			b6 <= b7;
			b7 <= b0;
		end
	end
end

// 2nd circle: num of turns
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		circle_b <= 0;
	end
	else if(current_state==RESTART && circle_b) begin
		circle_b <= circle_b + 1;
	end
	else if((current_state==INPUT_C || current_state==ROTATE_BCD) && !cdn_b) begin
		circle_b <= circle_b + 1;
	end
	else if(current_state==INPUT_A) begin
		circle_b <= 0;
	end
end

// 3rd circle
assign cdn_c = (a0==c0) & ((mode_save)?(a4==c4):1) & ((mode_save>1)?(a2==c2):1) & ((mode_save>2)?(a6==c6):1);
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		c0 <= 0;
		c1 <= 0;
		c2 <= 0;
		c3 <= 0;
		c4 <= 0;
		c5 <= 0;
		c6 <= 0;
		c7 <= 0;
	end
	else if(current_state==INPUT_C) begin
		c0 <= c1;
		c1 <= c2;
		c2 <= c3;
		c3 <= c4;
		c4 <= c5;
		c5 <= c6;
		c6 <= c7;
		c7 <= in;
	end
	else if(current_state==INPUT_D) begin
		if(!cdn_c) begin
			c0 <= c1;
			c1 <= c2;
			c2 <= c3;
			c3 <= c4;
			c4 <= c5;
			c5 <= c6;
			c6 <= c7;
			c7 <= c0;
		end
	end
	else if(current_state==RESTART) begin
		if(circle_c) begin
			c0 <= c1;
			c1 <= c2;
			c2 <= c3;
			c3 <= c4;
			c4 <= c5;
			c5 <= c6;
			c6 <= c7;
			c7 <= c0;
		end
	end
	else if(current_state==ROTATE_BCD) begin
		if(!cdn_c) begin
			c0 <= c1;
			c1 <= c2;
			c2 <= c3;
			c3 <= c4;
			c4 <= c5;
			c5 <= c6;
			c6 <= c7;
			c7 <= c0;
		end
	end
end

// 3rd circle: num of turns
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		circle_c <= 0;
	end
	else if(current_state==RESTART && circle_c) begin
		circle_c <= circle_c + 1;
	end
	else if((current_state==INPUT_D || current_state==ROTATE_BCD) && !cdn_c) begin
		circle_c <= circle_c + 1;
	end
	else if(current_state==INPUT_A) begin
		circle_c <= 0;
	end
end

// 4th circle
assign cdn_d = (a0==d0) & ((mode_save)?(a4==d4):1) & ((mode_save>1)?(a2==d2):1) & ((mode_save>2)?(a6==d6):1);
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		d0 <= 0;
		d1 <= 0;
		d2 <= 0;
		d3 <= 0;
		d4 <= 0;
		d5 <= 0;
		d6 <= 0;
		d7 <= 0;
	end
	else if(current_state==INPUT_D) begin
		d0 <= d1;
		d1 <= d2;
		d2 <= d3;
		d3 <= d4;
		d4 <= d5;
		d5 <= d6;
		d6 <= d7;
		d7 <= in;
	end
	else if(current_state==RESTART) begin
		if(circle_d) begin
			d0 <= d1;
			d1 <= d2;
			d2 <= d3;
			d3 <= d4;
			d4 <= d5;
			d5 <= d6;
			d6 <= d7;
			d7 <= d0;
		end
	end
	else if(current_state==ROTATE_BCD) begin
		if(!cdn_d) begin
			d0 <= d1;
			d1 <= d2;
			d2 <= d3;
			d3 <= d4;
			d4 <= d5;
			d5 <= d6;
			d6 <= d7;
			d7 <= d0;
		end
	end
end

// 4th circle: num of turns
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		circle_d <= 0;
	end
	else if(current_state==RESTART && circle_d) begin
		circle_d <= circle_d + 1;
	end
	else if(current_state==ROTATE_BCD && !cdn_d) begin
		circle_d <= circle_d + 1;
	end
	else if(current_state==INPUT_A) begin
		circle_d <= 0;
	end
end

// summation
assign value0 = a0 + b0 + c0 + d0;
assign value1 = a1 + b1 + c1 + d1;
assign value2 = a2 + b2 + c2 + d2;
assign value3 = a3 + b3 + c3 + d3;
assign value4 = a4 + b4 + c4 + d4;
assign value5 = a5 + b5 + c5 + d5;
assign value6 = a6 + b6 + c6 + d6;
assign value7 = a7 + b7 + c7 + d7;

// sorting 0th round
assign s0_0 = (value0>value1) ? value0 : value1;
assign s0_1 = (value0>value1) ? value1 : value0;

assign s0_2 = (value2>value3) ? value2 : value3;
assign s0_3 = (value2>value3) ? value3 : value2;

assign s0_4 = (value4>value5) ? value4 : value5;
assign s0_5 = (value4>value5) ? value5 : value4;

assign s0_6 = (value6>value7) ? value6 : value7;
assign s0_7 = (value6>value7) ? value7 : value6;

// sorting 1st round
assign s1_0 = (s0_0>s0_2) ? s0_0 : s0_2;
assign s1_1 = (s0_0>s0_2) ? s0_2 : s0_0; 
 
assign s1_2 = (s0_1>s0_3) ? s0_1 : s0_3;  
assign s1_3 = (s0_1>s0_3) ? s0_3 : s0_1; 
 
assign s1_4 = (s0_4>s0_6) ? s0_4 : s0_6;  
assign s1_5 = (s0_4>s0_6) ? s0_6 : s0_4; 
 
assign s1_6 = (s0_5>s0_7) ? s0_5 : s0_7;  
assign s1_7 = (s0_5>s0_7) ? s0_7 : s0_5;

// sorting 2nd round
assign s2_0 = (tmp0>tmp4) ? tmp0 : tmp4;
assign s2_1 = (tmp0>tmp4) ? tmp4 : tmp0; 
								
assign s2_2 = (tmp1>tmp2) ? tmp1 : tmp2;  
assign s2_3 = (tmp1>tmp2) ? tmp2 : tmp1; 
								
assign s2_4 = (tmp5>tmp6) ? tmp5 : tmp6;  
assign s2_5 = (tmp5>tmp6) ? tmp6 : tmp5; 
								
assign s2_6 = (tmp3>tmp7) ? tmp3 : tmp7;  
assign s2_7 = (tmp3>tmp7) ? tmp7 : tmp3;

// sorting 3rd round
assign s3_0 = (s2_3>s2_5) ? s2_3 : s2_5;
assign s3_1 = (s2_3>s2_5) ? s2_5 : s2_3; 
									
assign s3_2 = (s2_2>s2_4) ? s2_2 : s2_4;  
assign s3_3 = (s2_2>s2_4) ? s2_4 : s2_2; 

// sorting 4th round
assign s4_0 = (tmp1>tmp2) ? tmp1 : tmp2;
assign s4_1 = (tmp1>tmp2) ? tmp2 : tmp1; 
						
assign s4_2 = (tmp5>tmp6) ? tmp5 : tmp6;  
assign s4_3 = (tmp5>tmp6) ? tmp6 : tmp5; 

// sorting 5th round
assign s5_0 = (s4_0>tmp4) ? s4_0 : tmp4;
assign s5_1 = (s4_0>tmp4) ? tmp4 : s4_0;
			
assign s5_2 = (s4_1>s4_2) ? s4_1 : s4_2;
assign s5_3 = (s4_1>s4_2) ? s4_2 : s4_1;

assign s5_4 = (tmp3>s4_3) ? tmp3 : s4_3;
assign s5_5 = (tmp3>s4_3) ? s4_3 : tmp3;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		tmp0 <= 0;
		tmp1 <= 0;
		tmp2 <= 0;
		tmp3 <= 0;
		tmp4 <= 0;
		tmp5 <= 0;
		tmp6 <= 0;
		tmp7 <= 0;
	end
	else if(current_state==SORTING)begin
		tmp0 <= s1_0;
		tmp1 <= s1_1;
		tmp2 <= s1_2;
		tmp3 <= s1_3;
		tmp4 <= s1_4;
		tmp5 <= s1_5;
		tmp6 <= s1_6;
	    tmp7 <= s1_7;
	end
	else if(current_state==OUTPUT) begin
		tmp0 <= s2_0;
		tmp1 <= s2_1;
		tmp2 <= s3_0;
		tmp3 <= s3_1;
		tmp4 <= s3_2;
		tmp5 <= s3_3;
		tmp6 <= s2_6;
	    tmp7 <= s2_7;
	end
end

// out_valid
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_valid <= 0;
	end
	else if(current_state==OUTPUT) begin
		out_valid <= 1;
	end
	else begin
		out_valid <= 0;
	end
end

// output: circle
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		circle <= 0;
	end
	else if(current_state==OUTPUT) begin
		case(cnt_output)
			3'd0:
				circle <= circle_a;
			3'd1:
				circle <= circle_b;
			3'd2:
				circle <= circle_c;
			3'd3:
				circle <= circle_d;
		endcase
	end
end

// output: value
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		value <= 0;
	end
	else if(current_state==OUTPUT) begin
		case(cnt_output)
			3'd0:
				value <= s2_0;
			3'd1:
				value <= s5_0;
			3'd2:
				value <= s5_1;
			3'd3:
				value <= s5_2;
			3'd4:
				value <= s5_3;
			3'd5:
				value <= s5_4;
			3'd6:
				value <= s5_5;
			3'd7:
				value <= tmp7;
		endcase
	end
end
endmodule