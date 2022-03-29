module bridge(input clk, INF.bridge_inf inf);

// ------------------
// parameter
// ------------------
parameter INPUT = 3'd0;
parameter READ = 3'd1;
parameter WRITE = 3'd2;
parameter WAIT_B = 3'd3;
parameter OUTPUT = 3'd4;

// ------------------
// logic
// ------------------
logic [2:0] current_state, next_state;

logic receive_arready, receive_awready;

logic [31:0] data;

// ------------------
// state
// ------------------
// current_state
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) current_state <= INPUT;
	else current_state <= next_state;
end

// next_state
always_comb begin
	case(current_state) 
		INPUT:
			if(inf.C_in_valid) begin
				if(inf.C_r_wb==1) next_state = READ;
				else next_state = WRITE;
			end
			else next_state = INPUT;
		READ:
			if(inf.R_VALID==1) next_state = OUTPUT;
			else next_state = READ;
		WRITE:
			if(inf.W_READY==1) next_state = WAIT_B;
			else next_state = WRITE;
		WAIT_B:
			if(inf.B_VALID) next_state = OUTPUT;
			else next_state = WAIT_B;
		OUTPUT:
			next_state = INPUT;
		default:
			next_state = INPUT;
	endcase
end

// ------------------
// access DRAM
// ------------------
// AR_VALID
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) inf.AR_VALID <= 0;
	else if(current_state==READ && receive_arready==0 && inf.AR_READY==0) inf.AR_VALID <= 1;
	else inf.AR_VALID <= 0;
end

// receive_arready
always@(posedge clk or negedge inf.rst_n) begin
  if(!inf.rst_n) receive_arready <= 0;
  else if(inf.AR_READY==1) receive_arready <= 1;
  else if(inf.R_VALID==1) receive_arready <= 0;
end

// AR_ADDR
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) inf.AR_ADDR <= 0;
	else if(inf.C_in_valid) inf.AR_ADDR <= 'h10000+inf.C_addr*4;
end

// R_READY
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) inf.R_READY <= 0;
	else inf.R_READY <= 1;
end

// AW_VALID
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) inf.AW_VALID <= 0;
	else if(current_state==WRITE && receive_awready==0 && inf.AW_READY==0) inf.AW_VALID <= 1;
	else inf.AW_VALID <= 0;
end

// receive_awready
always@(posedge clk or negedge inf.rst_n) begin
  if(!inf.rst_n) receive_awready <= 0;
  else if(inf.AW_READY==1) receive_awready <= 1;
  else if(inf.W_READY==1) receive_awready <= 0;
end

// AW_ADDR
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) inf.AW_ADDR <= 0;
	else if(inf.C_in_valid) inf.AW_ADDR <= 'h10000+inf.C_addr*4;
end

// W_VALID
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) inf.W_VALID <= 0;
	else inf.W_VALID <= 1;
end

// W_DATA
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) inf.W_DATA <= 0;
	else if(inf.C_in_valid) inf.W_DATA <= inf.C_data_w;
end

// B_READY
always@(posedge clk or negedge inf.rst_n) begin
  if(!inf.rst_n) inf.B_READY <= 0;
  else inf.B_READY <= 1;
end

// ------------------
// keep data
// ------------------
// data
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) data <= 0;
	else if(inf.R_VALID) data <= inf.R_DATA;
end

// ------------------
// output
// ------------------
// C_out_valid
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) inf.C_out_valid <= 0;
	else if(current_state==OUTPUT) inf.C_out_valid <= 1;
	else inf.C_out_valid <= 0;
end

// C_data_r
always_ff@ (posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n) inf.C_data_r <= 0;
	else if(current_state==OUTPUT) inf.C_data_r <= data;
	else inf.C_data_r <= 0;
end



endmodule