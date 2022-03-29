module SD(
    //Input Port
    clk,
    rst_n,
	in_valid,
	in,

    //Output Port
    out_valid,
    out
    );

//-----------------------------------------------------------------------------------------------------------------
//   PORT DECLARATION                                                  
//-----------------------------------------------------------------------------------------------------------------
input            clk, rst_n, in_valid;
input [3:0]		 in;
output reg		 out_valid;
output reg [3:0] out;

//---------------------------------------------------------------------
//   PARAMETER DECLARATION
//---------------------------------------------------------------------
parameter INPUT  = 2'd0;
parameter SOLVE  = 2'd1;
parameter BACK   = 2'd2;
parameter OUTPUT = 2'd3;

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
// state
reg [1:0] current_state, next_state;

// counter
reg [3:0] cnt_input_x, cnt_input_y;
reg [3:0] cnt_blank;
reg [3:0] cnt_output;

reg [3:0] blank_x[0:8], blank_y[0:8];

reg [8:0] row_check[0:8], col_check[0:8], squ_check[0:2][0:2];
wire [8:0] check;

reg [3:0] current;

wire [8:0] cdn;

reg back_tracking;

reg [3:0] value[0:8];

integer x, y, z;
//---------------------------------------------------------------------
//   Design
//---------------------------------------------------------------------

// FSM: current state
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        current_state <= INPUT;
    else
        current_state <= next_state;
end

// FSM: next state
always @(*) begin
    case(current_state)
		INPUT:
			if(cnt_input_x==8 & cnt_input_y==8) next_state = SOLVE;
			else next_state = INPUT;
		SOLVE:
			if(value[8]) next_state = OUTPUT;
			else if(back_tracking) next_state = BACK;
			else next_state = SOLVE;
		BACK:
			next_state = SOLVE;
		OUTPUT:
			if(cnt_output==8) next_state = INPUT;
			else next_state = OUTPUT;
		default: next_state = current_state;
    endcase
end

// cnt_input_x
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_input_x <= 0;
	end
	else if(in_valid) begin
		if(cnt_input_x==8) begin
			cnt_input_x <= 0;
		end
		else begin
			cnt_input_x <= cnt_input_x + 1;
		end
	end
	else if(out_valid) begin
		cnt_input_x <= 0;
	end
end

// cnt_input_y
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_input_y <= 0;
	end
	else if(in_valid) begin
		if(cnt_input_x==8) begin
			cnt_input_y <= cnt_input_y + 1;
		end
	end
	else if(out_valid) begin
		cnt_input_y <= 0;
	end
end

// cnt_blank
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_blank <= 0;
	end
	else if(in_valid & in==0) begin
		cnt_blank <= cnt_blank + 1;
	end
	else if(out_valid) begin
		cnt_blank <= 0;
	end
end

// blank_x
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(x=0; x<9; x=x+1) begin
			blank_x[x] <= 0;
		end
	end
	else if(in_valid & in==0) begin
		blank_x[8] <= cnt_input_x;
		for(x=0; x<8; x=x+1) begin
			blank_x[x] <= blank_x[x+1];
		end	
	end
end

// blank_y
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(y=0; y<9; y=y+1) begin
			blank_y[y] <= 0;
		end
	end
	else if(in_valid & in==0) begin
		blank_y[8] <= cnt_input_y;
		for(y=0; y<8; y=y+1) begin
			blank_y[y] <= blank_y[y+1];
		end
	end
end

// row_check
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(y=0; y<9; y=y+1) begin
			row_check[y] <= 0;
		end
	end
	else if(in_valid) begin
		case(in)
			4'd1: row_check[cnt_input_y][0] <= 1;
			4'd2: row_check[cnt_input_y][1] <= 1;
			4'd3: row_check[cnt_input_y][2] <= 1;
			4'd4: row_check[cnt_input_y][3] <= 1;
			4'd5: row_check[cnt_input_y][4] <= 1;
			4'd6: row_check[cnt_input_y][5] <= 1;
			4'd7: row_check[cnt_input_y][6] <= 1;
			4'd8: row_check[cnt_input_y][7] <= 1;
			4'd9: row_check[cnt_input_y][8] <= 1;
		endcase
	end
	else if(current_state==SOLVE) begin
		if     (cdn[0]) row_check[blank_y[current]][0] <= 1;
		else if(cdn[1]) row_check[blank_y[current]][1] <= 1;
		else if(cdn[2]) row_check[blank_y[current]][2] <= 1;
		else if(cdn[3]) row_check[blank_y[current]][3] <= 1;
		else if(cdn[4]) row_check[blank_y[current]][4] <= 1;
		else if(cdn[5]) row_check[blank_y[current]][5] <= 1;
		else if(cdn[6]) row_check[blank_y[current]][6] <= 1;
		else if(cdn[7]) row_check[blank_y[current]][7] <= 1;
		else if(cdn[8]) row_check[blank_y[current]][8] <= 1;
	end
	else if(current_state==BACK) begin
		row_check[blank_y[current]][value[current]-1] <= 0;
	end
	else if(out_valid) begin
		for(y=0; y<9; y=y+1) begin
			row_check[y] <= 0;
		end
	end
end

// col_check
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(x=0; x<9; x=x+1) begin
			col_check[x] <= 0;
		end
	end
	else if(in_valid) begin
		case(in)
			4'd1: col_check[cnt_input_x][0] <= 1;
			4'd2: col_check[cnt_input_x][1] <= 1;
			4'd3: col_check[cnt_input_x][2] <= 1;
			4'd4: col_check[cnt_input_x][3] <= 1;
			4'd5: col_check[cnt_input_x][4] <= 1;
			4'd6: col_check[cnt_input_x][5] <= 1;
			4'd7: col_check[cnt_input_x][6] <= 1;
			4'd8: col_check[cnt_input_x][7] <= 1;
			4'd9: col_check[cnt_input_x][8] <= 1;
		endcase
	end
	else if(current_state==SOLVE) begin
		if     (cdn[0]) col_check[blank_x[current]][0] <= 1;
		else if(cdn[1]) col_check[blank_x[current]][1] <= 1;
		else if(cdn[2]) col_check[blank_x[current]][2] <= 1;
		else if(cdn[3]) col_check[blank_x[current]][3] <= 1;
		else if(cdn[4]) col_check[blank_x[current]][4] <= 1;
		else if(cdn[5]) col_check[blank_x[current]][5] <= 1;
		else if(cdn[6]) col_check[blank_x[current]][6] <= 1;
		else if(cdn[7]) col_check[blank_x[current]][7] <= 1;
		else if(cdn[8]) col_check[blank_x[current]][8] <= 1;
	end
	else if(current_state==BACK) begin
		col_check[blank_x[current]][value[current]-1] <= 0;
	end
	else if(out_valid) begin
		for(x=0; x<9; x=x+1) begin
			col_check[x] <= 0;
		end
	end
end

wire [3:0] squ_x, squ_y;
assign squ_x = ( (current_state==INPUT | current>=9) ? cnt_input_x : blank_x[current] )/3;
assign squ_y = ( (current_state==INPUT | current>=9) ? cnt_input_y : blank_y[current] )/3;

// squ_check
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(y=0;y<3; y=y+1) begin
			for(x=0; x<3; x=x+1) begin
				squ_check[y][x] <= 0;
			end
		end
	end
	else if(in_valid) begin
		case(in)
			4'd1: squ_check[squ_y][squ_x][0] <= 1;
			4'd2: squ_check[squ_y][squ_x][1] <= 1;
			4'd3: squ_check[squ_y][squ_x][2] <= 1;
			4'd4: squ_check[squ_y][squ_x][3] <= 1;
			4'd5: squ_check[squ_y][squ_x][4] <= 1;
			4'd6: squ_check[squ_y][squ_x][5] <= 1;
			4'd7: squ_check[squ_y][squ_x][6] <= 1;
			4'd8: squ_check[squ_y][squ_x][7] <= 1;
			4'd9: squ_check[squ_y][squ_x][8] <= 1;
		endcase
	end
	else if(current_state==SOLVE) begin
		if     (cdn[0]) squ_check[squ_y][squ_x][0] <= 1;
		else if(cdn[1]) squ_check[squ_y][squ_x][1] <= 1;
		else if(cdn[2]) squ_check[squ_y][squ_x][2] <= 1;
		else if(cdn[3]) squ_check[squ_y][squ_x][3] <= 1;
		else if(cdn[4]) squ_check[squ_y][squ_x][4] <= 1;
		else if(cdn[5]) squ_check[squ_y][squ_x][5] <= 1;
		else if(cdn[6]) squ_check[squ_y][squ_x][6] <= 1;
		else if(cdn[7]) squ_check[squ_y][squ_x][7] <= 1;
		else if(cdn[8]) squ_check[squ_y][squ_x][8] <= 1;
	end
	else if(current_state==BACK) begin
		squ_check[squ_y][squ_x][value[current]-1] <= 0;
end
	else if(out_valid) begin
		for(y=0;y<3; y=y+1) begin
			for(x=0; x<3; x=x+1) begin
				squ_check[y][x] <= 0;
			end
		end
	end
end

// check
assign check = (current<9) ? row_check[blank_y[current]] | col_check[blank_x[current]] | squ_check[squ_y][squ_x] : 0;

// current
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) current <= 0;
	else if(current_state==SOLVE & !back_tracking) current <= current + 1;
	else if(current_state==SOLVE & current!=0) current <= current - 1;
	else if(in_valid) current <= 0;
end

assign cdn[0] = (current<9) ? (check[0]==0 & value[current]==0) : 0;
assign cdn[1] = (current<9) ? (check[1]==0 & value[current]<2)  : 0;
assign cdn[2] = (current<9) ? (check[2]==0 & value[current]<3)  : 0;
assign cdn[3] = (current<9) ? (check[3]==0 & value[current]<4)  : 0;
assign cdn[4] = (current<9) ? (check[4]==0 & value[current]<5)  : 0;
assign cdn[5] = (current<9) ? (check[5]==0 & value[current]<6)  : 0;
assign cdn[6] = (current<9) ? (check[6]==0 & value[current]<7)  : 0;
assign cdn[7] = (current<9) ? (check[7]==0 & value[current]<8)  : 0;
assign cdn[8] = (current<9) ? (check[8]==0 & value[current]<9)  : 0;

// value
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(z=0; z<9; z=z+1) begin
			value[z] <= 0;
		end
	end
	else if(current_state==SOLVE) begin
		if     (cdn[0])	value[current] <= 1;
		else if(cdn[1]) value[current] <= 2;
		else if(cdn[2]) value[current] <= 3;
		else if(cdn[3]) value[current] <= 4;
		else if(cdn[4]) value[current] <= 5;
		else if(cdn[5]) value[current] <= 6;
		else if(cdn[6]) value[current] <= 7;
		else if(cdn[7]) value[current] <= 8;
		else if(cdn[8]) value[current] <= 9;
		else            value[current] <= 0;
	end
	else if(in_valid) begin
		for(z=0; z<9; z=z+1) begin
			value[z] <= 0;
		end
	end
end

// back_tracking
always @(*) begin
	if     (cdn[0]) back_tracking = 0;
	else if(cdn[1]) back_tracking = 0;
	else if(cdn[2]) back_tracking = 0;
	else if(cdn[3]) back_tracking = 0;
	else if(cdn[4]) back_tracking = 0;
	else if(cdn[5]) back_tracking = 0;
	else if(cdn[6]) back_tracking = 0;
	else if(cdn[7]) back_tracking = 0;
	else if(cdn[8]) back_tracking = 0;
	else            back_tracking = 1;
end

wire cdn_output;
assign cdn_output = (current_state==SOLVE&current==9) | current_state==OUTPUT;

// cnt_output
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_output <= 0;
	end
	else if(cdn_output) begin
		cnt_output <= cnt_output + 1;
	end
	else if(in_valid) begin
		cnt_output <= 0;
	end
end

// out_valid
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_valid <= 0;
	end
	else if(cdn_output) begin
		out_valid <= 1;
	end
	else begin
		out_valid <= 0;
	end
end

// out
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out <= 0;
	end
	else if(cdn_output) begin
		case(cnt_output)
			4'd0: out <= value[0];
			4'd1: out <= value[1];
			4'd2: out <= value[2];
			4'd3: out <= value[3];
			4'd4: out <= value[4];
			4'd5: out <= value[5];
			4'd6: out <= value[6];
			4'd7: out <= value[7];
			4'd8: out <= value[8];
		endcase
	end
	else begin
		out <= 0;
	end
end

endmodule