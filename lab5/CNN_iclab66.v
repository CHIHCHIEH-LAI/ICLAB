module CNN(
	//io
	clk,
	rst_n,
	in_valid,
	setup_en,
	in_data,
	action,
	size,
	out_valid,
	out_data
);
//-----------------------------------------------------------------------------------------------------------------
//   PORT DECLARATION                                                  
//-----------------------------------------------------------------------------------------------------------------
input			clk;
input			rst_n;
input			in_valid;
input			setup_en;
input	[31:0]	in_data;
input	[1:0]	action;
input	[1:0]	size;

output	reg 	out_valid;
output	reg[31:0]out_data;

//---------------------------------------------------------------------
//   PARAMETER DECLARATION
//---------------------------------------------------------------------
parameter IDLE   = 3'd0;
parameter SETUP  = 3'd1;
parameter CONV   = 3'd2;
parameter POOL   = 3'd3;
parameter FULL   = 3'd4;
parameter OUTPUT = 3'd5;

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
// state
reg [2:0] current_state, next_state;

// cnt
reg [8:0] cnt_main, cnt_out;
reg [3:0] cnt_minor;

// SRAM
wire signed [31:0] out_data0, out_data1;
reg write0, write1;
reg [7:0] address0, address1;
reg signed [31:0] in_data0, in_data1;

reg [1:0] action_1;
reg relu_keep;

reg [1:0] size_keep;
wire [4:0] matrix_size;
wire [8:0] matrix_size_square;

reg signed [67:0] tmp;

reg zero_keep;
reg signed [31:0] tmp_conv[0:8];
wire up_0, do_0, le_0, ri_0;
wire zero;
reg signed [31:0] tmp_mult;

reg signed [31:0] tmp_cmp;

reg signed [31:0] in_data_keep;

integer i;
//---------------------------------------------------------------------
//   Design
//---------------------------------------------------------------------

// FSM: current state
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

// FSM: next state
always @(*) begin
    case(current_state)
		IDLE:
			if(setup_en) next_state = SETUP;
			else if(in_valid) begin
				if(action_1==0) next_state = CONV;
				else if(action_1==1) next_state = OUTPUT;
				else if(action_1==2) next_state = POOL;
				else next_state = FULL;
			end
			else next_state = IDLE;
		SETUP: 
			if(cnt_main==matrix_size_square-1) next_state = OUTPUT;
			else next_state = SETUP;
		CONV:
			if(cnt_main==matrix_size_square) next_state = OUTPUT;
			else next_state = CONV;
		POOL:
			if(cnt_main==matrix_size_square) next_state = OUTPUT;
			else next_state = POOL;
		FULL:
			if(cnt_main==matrix_size_square) next_state = OUTPUT;
			else next_state = FULL;
		OUTPUT:
			if(cnt_out==matrix_size_square) next_state = IDLE;
			else next_state = OUTPUT;
		default: next_state = current_state;
    endcase
end

// cnt_main
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) cnt_main <= 0;
	else if(setup_en | current_state==SETUP) cnt_main <= cnt_main + 1;
	else if(!in_valid & current_state==CONV & cnt_minor==8) cnt_main <= cnt_main + 1;
	else if(current_state==POOL & cnt_minor==3) cnt_main <= cnt_main + 1;
	else if(current_state==FULL & cnt_minor==matrix_size_square-1) cnt_main <= cnt_main + 1;
	else if(current_state==IDLE) cnt_main <= 0;
end

// cnt_minor
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) cnt_minor <= 0;
	else if(current_state==CONV) begin
		if(cnt_minor==8) cnt_minor <= 0;
		else cnt_minor <= cnt_minor + 1;
	end
	else if(current_state==POOL) begin
		if(cnt_minor==3) cnt_minor <= 0;
		else cnt_minor <= cnt_minor + 1;
	end
	else if(in_valid | current_state==FULL) begin
		if(cnt_minor==matrix_size_square-1) cnt_minor <= 0;
		else cnt_minor <= cnt_minor + 1;
	end
	else if(current_state==IDLE) cnt_minor <= 0;
end

// cnt_out
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) cnt_out <= 0;
	else if(current_state==OUTPUT) cnt_out <= cnt_out + 1;
	else if(current_state==IDLE) cnt_out <= 0;
end

// SRAM declaration
RA1SH SRAM0(.Q(out_data0),.CLK(clk),.CEN(1'b0),.WEN(write0),.A(address0),.D(in_data0),.OEN(1'b0));
RA1SH SRAM1(.Q(out_data1),.CLK(clk),.CEN(1'b0),.WEN(write1),.A(address1),.D(in_data1),.OEN(1'b0));

// action_1
always @(*) begin
	if(in_valid & current_state==IDLE) action_1 = action;
	else action_1 = 0;
end

// relu_keep
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) relu_keep <= 0;
	else if(in_valid) if(action_1==1) relu_keep <= 1;
	else if(current_state==IDLE) relu_keep <= 0;
end

// size_keep
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) size_keep <= 0;
	else if(setup_en) begin
		case(size)
			2'b00:   size_keep <= 3;
			2'b01:   size_keep <= 2;
			2'b10:   size_keep <= 1;
			default: size_keep <= 0;
		endcase
	end
	else if(action_1==2) size_keep <= size_keep - 1;
end

// matrix_size
assign matrix_size = 2**(size_keep+1);

// matrix_size_square
assign matrix_size_square = 4**(size_keep+1);

// SRAM write0
always @(*) begin
	if(cnt_out>0 & cnt_out<matrix_size_square+1) write0 = 0;
	else write0 = 1;
end

// SRAM address0
always @(*) begin
	if(current_state==CONV) begin
		if(zero) address0 = 0;
		else address0 = cnt_main + (cnt_minor%3-1) + (cnt_minor/3-1)*matrix_size;
	end
	else if(current_state==POOL) address0 = (cnt_main%matrix_size)*2 + (cnt_main/matrix_size)*4*matrix_size + cnt_minor[0] + cnt_minor[1]*2*matrix_size;
	else if(current_state==FULL) address0 = cnt_minor;
	else if(current_state==OUTPUT) address0 = cnt_out==0 ? 0 : cnt_out-1;
	else address0 = cnt_out==0 ? 0 : cnt_out-1;
end

// SRAM in_data0
always @(*) begin
	if(current_state==OUTPUT) begin
		if(relu_keep) in_data0 = (out_data1<0) ? 0 : out_data1;
		else in_data0 = out_data1;
	end
	else in_data0 = 0;
end

// SRAM write1
always @(*) begin
	if(setup_en | current_state==SETUP) write1 = 0;
	else if(!in_valid & current_state==CONV & cnt_main!=0 & cnt_minor==0) write1 = 0;
	else if(current_state==POOL & cnt_main!=0 & cnt_minor==0) write1 = 0;
	else if(current_state==FULL & cnt_main!=0 & cnt_minor==0) write1 = 0;
	else write1 = 1;
end

// SRAM address1
always @(*) begin
	if(setup_en | current_state==SETUP) address1 = cnt_main;
	else if(current_state==CONV & cnt_main!=0) address1 = cnt_main-1;
	else if(current_state==POOL & cnt_main!=0) address1 = cnt_main-1;
	else if(current_state==FULL & cnt_main!=0) address1 = cnt_main-1;
	else if(current_state==OUTPUT) address1 = cnt_out;
	else address1 = 0;
end

// SRAM in_data1
always @(*) begin
	if(setup_en | current_state==SETUP) in_data1 = in_data;
	else if(current_state==CONV) in_data1 = tmp + tmp_conv[8]*tmp_mult;
	else if(current_state==POOL) in_data1 = (tmp_cmp<out_data0) ? out_data0 : tmp_cmp;
	else if(current_state==FULL) in_data1 = tmp + in_data_keep*out_data0;
	else in_data1 = 0;
end

// tmp_conv
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0; i<9; i=i+1) begin
			tmp_conv[i] <= 0;
		end
	end
	else if(in_valid & (action_1==0 | current_state==CONV)) begin
		tmp_conv[8] <= in_data;
		for(i=0; i<8; i=i+1) begin
			tmp_conv[i] <= tmp_conv[i+1];
		end
	end
	else if(current_state==IDLE) begin
		for(i=0; i<9; i=i+1) begin
			tmp_conv[i] <= 0;
		end
	end
end

// up_0, do_0, le_0, ri_0
assign up_0 = ((cnt_main/matrix_size==0) & cnt_minor<3); 
assign do_0 = ((cnt_main/matrix_size==(matrix_size-1)) & cnt_minor>5); 
assign le_0 = ((cnt_main%matrix_size==0) & (cnt_minor==0 | cnt_minor==3 | cnt_minor==6)); 
assign ri_0 = ((cnt_main%matrix_size==(matrix_size-1)) & (cnt_minor==2 | cnt_minor==5 | cnt_minor==8)); 
// zero
assign zero = (up_0 | do_0 | le_0 | ri_0);

// zero_keep
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) zero_keep <= 0;
	else zero_keep <= zero;
end

// tmp_mult
always @(*) begin
	if(current_state==CONV) begin
		if(zero_keep) tmp_mult = 0;
		else tmp_mult = out_data0;
	end
	else tmp_mult = 0;
end

// in_data_keep
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) in_data_keep <= 0;
	else if(action_1==3 | (in_valid & current_state==FULL)) in_data_keep <= in_data;
end

// tmp
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) tmp <= 0;
	else if(!in_valid & current_state==CONV) begin
		if(cnt_minor==0) tmp <= 0;
		else if(!zero_keep) tmp <= tmp + tmp_conv[cnt_minor-1]*tmp_mult;
	end
	else if(current_state==FULL) begin
		if(cnt_minor==1) tmp <= in_data_keep*out_data0;
		else tmp <= tmp + in_data_keep*out_data0;
	end
	else if(current_state==IDLE) tmp <= 0;
end

// tmp_cmp
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) tmp_cmp <= 0;
	else if(current_state==POOL) begin
		if(cnt_minor==1) tmp_cmp <= out_data0;
		else if(tmp_cmp<out_data0) tmp_cmp <= out_data0;
	end
	else if(current_state==IDLE) tmp_cmp <= 0;
end

// out_valid
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) out_valid <= 0;
	else if(current_state==OUTPUT & cnt_out!=0) out_valid <= 1;
	else out_valid <= 0;
end

// out_data
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) out_data <= 0;
	else if(current_state==OUTPUT & cnt_out!=0) begin
		if(relu_keep) out_data <= (out_data1<0) ? 0 : out_data1;
		else out_data <= out_data1;
	end
	else if(current_state==IDLE) out_data <= 0;
end

endmodule
