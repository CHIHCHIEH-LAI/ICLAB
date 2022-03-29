module MH(
	// input signals
	clk,
	rst_n,
	in_valid,
	op_valid,
	pic_data,
	se_data,
	op,
	// output signals
	out_valid,
	out_data
);

input   clk, rst_n, in_valid, op_valid;
input  [31:0] pic_data;
input  [7:0] se_data;
input  [2:0] op;
output reg  out_valid;
output reg [31:0] out_data;

integer i, j;
genvar k;

// parameter
parameter INPUT = 3'd0;
parameter EROSION_IN = 3'd1;
parameter DILATION_IN = 3'd2;
parameter OUTPUT = 3'd3;
parameter OUTPUT_EROSION = 3'd4;
parameter OUTPUT_DILATION = 3'd5;
parameter HISTOGRAM_DIV = 3'd6;

reg [2:0] current_state, next_state;

reg [5:0] cnt_in_r, cnt_in_c;
reg [7:0] cnt_out;

reg [2:0] op_keep;

// pic, se
reg [7:0] pic[0:3][0:31], tmp_pic[0:3][0:31], tmp_pic_80[0:3];
reg [7:0] se[0:3][0:3];

// EROSION & DILATION compare
reg [7:0] cmp_a[0:3][0:3][0:3], cmp_b[0:3][0:7], cmp_c[0:3][0:3], cmp_d[0:3][0:1], cmp_e[0:3];
reg [7:0] cmp_a_2[0:3][0:3][0:3], cmp_b_2[0:3][0:7], cmp_c_2[0:3][0:3], cmp_d_2[0:3][0:1], cmp_e_2[0:3];

// histogram
reg [10:0] CDF[0:255];
wire [8:0] cdf_min;
reg [10:0] deno;

// SRAM
reg W;
reg [7:0] A;
reg [31:0] D;
wire [31:0] Q;

// ------------------------
// FSM

// current_state
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) current_state <= INPUT;
	else current_state <= next_state;
end

// next_state
always @(*) begin
	case(current_state)
		INPUT: 
			if(cnt_in_r==3 && cnt_in_c==28) begin
				if(op_keep==0 || op_keep==4) next_state = EROSION_IN;
				else if(op_keep==1 || op_keep==5) next_state = DILATION_IN;
				else next_state = INPUT;
			end
			else if(cnt_in_r==31 && cnt_in_c==28) next_state = HISTOGRAM_DIV;
			else next_state = INPUT;
		EROSION_IN:
			if(cnt_in_r==31 && cnt_in_c==28) begin
				if(op_keep==0) next_state = OUTPUT;
				else next_state = OUTPUT_DILATION;
			end
			else next_state = EROSION_IN;
		DILATION_IN:
			if(cnt_in_r==31 && cnt_in_c==28) begin
				if(op_keep==1) next_state = OUTPUT;
				else next_state = OUTPUT_EROSION;
			end
			else next_state = DILATION_IN;
		HISTOGRAM_DIV: next_state = OUTPUT;
		OUTPUT: 
			if(cnt_out==255) next_state = INPUT;
			else next_state = OUTPUT;
		OUTPUT_EROSION: 
			if(cnt_out==255) next_state = INPUT;
			else next_state = OUTPUT_EROSION;
		OUTPUT_DILATION: 
			if(cnt_out==255) next_state = INPUT;
			else next_state = OUTPUT_DILATION;
		default: next_state = INPUT;
	endcase
end

// ------------------------
// INPUT

// cnt_in_r
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) cnt_in_r <= 0;
	else if(op_keep<2 && cnt_in_r==35 && cnt_in_c==28) cnt_in_r <= 0;
	else if(op_keep>3 && cnt_in_r==31 && cnt_in_c==28) cnt_in_r <= 0;
	else if(in_valid || current_state==EROSION_IN || current_state==DILATION_IN || current_state==OUTPUT || current_state==OUTPUT_EROSION || current_state==OUTPUT_DILATION) begin
		if(cnt_in_c==28) cnt_in_r <= cnt_in_r + 1;
		else cnt_in_r <= cnt_in_r;
	end
	else cnt_in_r <= 0;
end

// cnt_in_c
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) cnt_in_c <= 0;
	else if(in_valid || current_state==EROSION_IN || current_state==DILATION_IN || current_state==OUTPUT || current_state==OUTPUT_EROSION || current_state==OUTPUT_DILATION) begin
		if(cnt_in_c==28) cnt_in_c <= 0;
		else cnt_in_c <= cnt_in_c + 4;
	end
	else cnt_in_c <= 0;
end

// op_keep
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) op_keep <= 0;
	else if(op_valid) op_keep <= op;
	else op_keep <= op_keep;
end

// se
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0;i<4;i=i+1) begin
			for(j=0;j<4;j=j+1) begin
				se[i][j] <= 0;
			end
		end
	end
	else if(in_valid && cnt_in_r<2) begin
		se[3][3] <= se_data;
		for(i=0;i<4;i=i+1) begin
			for(j=0;j<3;j=j+1) begin
				se[i][j] <= se[i][j+1];
			end
		end
		for(i=0;i<3;i=i+1) begin
			se[i][3] <= se[i+1][0];
		end
	end
end

wire [7:0] pic_in[0:3];
assign pic_in[0] = (in_valid || current_state==EROSION_IN || current_state==DILATION_IN || current_state==OUTPUT) ? pic_data[7:0]   : cmp_e[0];
assign pic_in[1] = (in_valid || current_state==EROSION_IN || current_state==DILATION_IN || current_state==OUTPUT) ? pic_data[15:8]  : cmp_e[1];
assign pic_in[2] = (in_valid || current_state==EROSION_IN || current_state==DILATION_IN || current_state==OUTPUT) ? pic_data[23:16] : cmp_e[2];
assign pic_in[3] = (in_valid || current_state==EROSION_IN || current_state==DILATION_IN || current_state==OUTPUT) ? pic_data[31:24] : cmp_e[3];

// pic
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0;i<4;i=i+1) begin
			for(j=0;j<32;j=j+1) begin
				pic[i][j] <= 0;
			end
		end
	end
	else if(in_valid || current_state==EROSION_IN || current_state==DILATION_IN || current_state==OUTPUT || (cnt_in_r<4 && (current_state==OUTPUT_EROSION || current_state==OUTPUT_DILATION))) begin
		pic[3][cnt_in_c]   <= pic_in[0];
		pic[3][cnt_in_c+1] <= pic_in[1];
		pic[3][cnt_in_c+2] <= pic_in[2];
		pic[3][cnt_in_c+3] <= pic_in[3];
		for(i=0; i<3; i=i+1) begin
			for(j=0; j<4; j=j+1) begin
				pic[i][cnt_in_c+j] <= pic[i+1][cnt_in_c+j];
			end
		end
	end
end

wire [7:0] tmp_pic_in[0:3];
assign tmp_pic_in[0] = (cnt_out==0) ? tmp_pic_80[0] : (cnt_in_r>23) ? pic[cnt_in_r-24][cnt_in_c]   : Q[7:0]  ;
assign tmp_pic_in[1] = (cnt_out==0) ? tmp_pic_80[1] : (cnt_in_r>23) ? pic[cnt_in_r-24][cnt_in_c+1] : Q[15:8] ;
assign tmp_pic_in[2] = (cnt_out==0) ? tmp_pic_80[2] : (cnt_in_r>23) ? pic[cnt_in_r-24][cnt_in_c+2] : Q[23:16];
assign tmp_pic_in[3] = (cnt_out==0) ? tmp_pic_80[3] : (cnt_in_r>23) ? pic[cnt_in_r-24][cnt_in_c+3] : Q[31:24];

// tmp_pic
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0;i<4;i=i+1) begin
			for(j=0;j<32;j=j+1) begin
				tmp_pic[i][j] <= 0;
			end
		end
	end
	else if(cnt_in_r==4&&cnt_in_c==0 && op_keep<2 && (current_state==EROSION_IN || current_state==DILATION_IN)) begin
		tmp_pic[0][0] <= cmp_e[0];
		tmp_pic[0][1] <= cmp_e[1];
		tmp_pic[0][2] <= cmp_e[2];
		tmp_pic[0][3] <= cmp_e[3];
	end
	else if(cnt_in_r>31 && op_keep<2 && current_state==OUTPUT) begin
		tmp_pic[cnt_in_r-32][cnt_in_c] <= cmp_e[0];
		tmp_pic[cnt_in_r-32][cnt_in_c+1] <= cmp_e[1];
		tmp_pic[cnt_in_r-32][cnt_in_c+2] <= cmp_e[2];
		tmp_pic[cnt_in_r-32][cnt_in_c+3] <= cmp_e[3];
	end
	else if(cnt_in_r<8 && op_keep>3 && (current_state==EROSION_IN || current_state==DILATION_IN)) begin
		tmp_pic[cnt_in_r-4][cnt_in_c] <= cmp_e[0];
		tmp_pic[cnt_in_r-4][cnt_in_c+1] <= cmp_e[1];
		tmp_pic[cnt_in_r-4][cnt_in_c+2] <= cmp_e[2];
		tmp_pic[cnt_in_r-4][cnt_in_c+3] <= cmp_e[3];
	end
	else if(current_state==OUTPUT_EROSION || current_state==OUTPUT_DILATION) begin
		tmp_pic[3][cnt_in_c]   <= tmp_pic_in[0];  
		tmp_pic[3][cnt_in_c+1] <= tmp_pic_in[1];
		tmp_pic[3][cnt_in_c+2] <= tmp_pic_in[2];
		tmp_pic[3][cnt_in_c+3] <= tmp_pic_in[3];
		for(i=0; i<3; i=i+1) begin
			for(j=0; j<4; j=j+1) begin
				tmp_pic[i][cnt_in_c+j] <= tmp_pic[i+1][cnt_in_c+j];
			end
		end
	end
end

// tmp_pic_80
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0; i<4; i=i+1) begin
			tmp_pic_80[i] <= 0;
		end
	end
	else if(cnt_in_r==8&&cnt_in_c==0&&(current_state==EROSION_IN || current_state==DILATION_IN)) begin
		tmp_pic_80[0] <= cmp_e[0];
		tmp_pic_80[1] <= cmp_e[1];
		tmp_pic_80[2] <= cmp_e[2];
		tmp_pic_80[3] <= cmp_e[3];
	end
end

// ------------------------
// EROSION, DILATION compare

wire [5:0] cmp_a_in;
assign cmp_a_in = (current_state==EROSION_IN || op_keep<2 || current_state==DILATION_IN) ? cnt_in_r-4 : cnt_in_r+28;
// cmp_a
generate
for(k=0; k<4; k=k+1) begin
always@ (*) begin
	for(i=0; i<4; i=i+1) begin
		for(j=0; j<4; j=j+1) begin
			if(current_state==EROSION_IN || op_keep==0 || current_state==OUTPUT_DILATION) begin
				if((cmp_a_in+i)>31 || (cnt_in_c+j+k)>31) cmp_a[k][i][j] = 0;
				else begin
					if((pic[i][cnt_in_c+j+k]<se[i][j])) cmp_a[k][i][j] = 0;
					else cmp_a[k][i][j] = pic[i][cnt_in_c+j+k] - se[i][j];
				end
			end
			else begin
				if((cmp_a_in+i)>31 || (cnt_in_c+j+k)>31) cmp_a[k][i][j] = se[3-i][3-j];
				else begin
					if((pic[i][cnt_in_c+j+k]+se[3-i][3-j])>255) cmp_a[k][i][j] = 255;
					else cmp_a[k][i][j] = pic[i][cnt_in_c+j+k] + se[3-i][3-j];
				end
			end
		end
	end
end
end
endgenerate

// cmp_b
generate
for(k=0; k<4; k=k+1) begin
always@ (*) begin
	if(current_state==EROSION_IN || op_keep==0 || current_state==OUTPUT_DILATION) begin
		for(i=0; i<4; i=i+1) begin
			cmp_b[k][2*i] = (cmp_a[k][i][0] < cmp_a[k][i][1]) ? cmp_a[k][i][0] : cmp_a[k][i][1];
			cmp_b[k][2*i+1] = (cmp_a[k][i][2] < cmp_a[k][i][3]) ? cmp_a[k][i][2] : cmp_a[k][i][3];
		end
	end
	else begin
		for(i=0; i<4; i=i+1) begin
			cmp_b[k][2*i] = (cmp_a[k][i][0] > cmp_a[k][i][1]) ? cmp_a[k][i][0] : cmp_a[k][i][1];
			cmp_b[k][2*i+1] = (cmp_a[k][i][2] > cmp_a[k][i][3]) ? cmp_a[k][i][2] : cmp_a[k][i][3];
		end
	end
end
end
endgenerate

// cmp_c
generate
for(k=0; k<4; k=k+1) begin
always@ (*) begin
	if(current_state==EROSION_IN || op_keep==0 || current_state==OUTPUT_DILATION) begin
		for(i=0; i<4; i=i+1) begin
			cmp_c[k][i] = (cmp_b[k][2*i] < cmp_b[k][2*i+1]) ? cmp_b[k][2*i] : cmp_b[k][2*i+1];
		end
	end
	else begin
		for(i=0; i<4; i=i+1) begin
			cmp_c[k][i] = (cmp_b[k][2*i] > cmp_b[k][2*i+1]) ? cmp_b[k][2*i] : cmp_b[k][2*i+1];
		end
	end
end
end
endgenerate

// cmp_d
generate
for(k=0; k<4; k=k+1) begin
always@ (*) begin
	if(current_state==EROSION_IN || op_keep==0 || current_state==OUTPUT_DILATION) begin
		for(i=0; i<2; i=i+1) begin
			cmp_d[k][i] = (cmp_c[k][2*i] < cmp_c[k][2*i+1]) ? cmp_c[k][2*i] : cmp_c[k][2*i+1];
		end
	end
	else begin
		for(i=0; i<2; i=i+1) begin
			cmp_d[k][i] = (cmp_c[k][2*i] > cmp_c[k][2*i+1]) ? cmp_c[k][2*i] : cmp_c[k][2*i+1];
		end
	end
end
end
endgenerate

// cmp_e
generate
for(k=0; k<4; k=k+1) begin
always@ (*) begin
	if(current_state==EROSION_IN || op_keep==0 || current_state==OUTPUT_DILATION) begin
		cmp_e[k] = (cmp_d[k][0] < cmp_d[k][1]) ? cmp_d[k][0] : cmp_d[k][1];
	end
	else begin
		cmp_e[k] = (cmp_d[k][0] > cmp_d[k][1]) ? cmp_d[k][0] : cmp_d[k][1];
	end
end
end
endgenerate

// EROSION, DILATION compare_2
// cmp_a_2
generate
for(k=0; k<4; k=k+1) begin
always@ (*) begin
	for(i=0; i<4; i=i+1) begin
		for(j=0; j<4; j=j+1) begin
			if(current_state==OUTPUT_EROSION) begin
				if((cnt_in_r+i)>31 || (cnt_in_c+j+k)>31) cmp_a_2[k][i][j] = 0;
				else begin
					if((tmp_pic[i][cnt_in_c+j+k]<se[i][j])) cmp_a_2[k][i][j] = 0;
					else cmp_a_2[k][i][j] = tmp_pic[i][cnt_in_c+j+k] - se[i][j];
				end
			end
			else begin
				if((cnt_in_r+i)>31 || (cnt_in_c+j+k)>31) cmp_a_2[k][i][j] = se[3-i][3-j];
				else begin
					if((tmp_pic[i][cnt_in_c+j+k]+se[3-i][3-j])>255) cmp_a_2[k][i][j] = 255;
					else cmp_a_2[k][i][j] = tmp_pic[i][cnt_in_c+j+k] + se[3-i][3-j];
				end
			end	
		end
	end
end
end
endgenerate

// cmp_b_2
generate
for(k=0; k<4; k=k+1) begin
always@ (*) begin
	if(current_state==OUTPUT_EROSION) begin
		for(i=0; i<4; i=i+1) begin
			cmp_b_2[k][2*i] = (cmp_a_2[k][i][0] < cmp_a_2[k][i][1]) ? cmp_a_2[k][i][0] : cmp_a_2[k][i][1];
			cmp_b_2[k][2*i+1] = (cmp_a_2[k][i][2] < cmp_a_2[k][i][3]) ? cmp_a_2[k][i][2] : cmp_a_2[k][i][3];
		end
	end
	else begin
		for(i=0; i<4; i=i+1) begin
			cmp_b_2[k][2*i] = (cmp_a_2[k][i][0] > cmp_a_2[k][i][1]) ? cmp_a_2[k][i][0] : cmp_a_2[k][i][1];
			cmp_b_2[k][2*i+1] = (cmp_a_2[k][i][2] > cmp_a_2[k][i][3]) ? cmp_a_2[k][i][2] : cmp_a_2[k][i][3];
		end
	end
end
end
endgenerate

// cmp_c_2
generate
for(k=0; k<4; k=k+1) begin
always@ (*) begin
	if(current_state==OUTPUT_EROSION) begin
		for(i=0; i<4; i=i+1) begin
			cmp_c_2[k][i] = (cmp_b_2[k][2*i] < cmp_b_2[k][2*i+1]) ? cmp_b_2[k][2*i] : cmp_b_2[k][2*i+1];
		end
	end
	else begin
		for(i=0; i<4; i=i+1) begin
			cmp_c_2[k][i] = (cmp_b_2[k][2*i] > cmp_b_2[k][2*i+1]) ? cmp_b_2[k][2*i] : cmp_b_2[k][2*i+1];
		end
	end
end
end
endgenerate

// cmp_d_2
generate
for(k=0; k<4; k=k+1) begin
always@ (*) begin
	if(current_state==OUTPUT_EROSION) begin
		for(i=0; i<2; i=i+1) begin
			cmp_d_2[k][i] = (cmp_c_2[k][2*i] < cmp_c_2[k][2*i+1]) ? cmp_c_2[k][2*i] : cmp_c_2[k][2*i+1];
		end
	end
	else begin
		for(i=0; i<2; i=i+1) begin
			cmp_d_2[k][i] = (cmp_c_2[k][2*i] > cmp_c_2[k][2*i+1]) ? cmp_c_2[k][2*i] : cmp_c_2[k][2*i+1];
		end
	end
end
end
endgenerate

// cmp_e_2
generate
for(k=0; k<4; k=k+1) begin
always@ (*) begin
	if(current_state==OUTPUT_EROSION) begin
		cmp_e_2[k] = (cmp_d_2[k][0] < cmp_d_2[k][1]) ? cmp_d_2[k][0] : cmp_d_2[k][1];
	end
	else begin
		cmp_e_2[k] = (cmp_d_2[k][0] > cmp_d_2[k][1]) ? cmp_d_2[k][0] : cmp_d_2[k][1];
	end
end
end
endgenerate

// ------------------------
// HISTOGRAM

// CDF, deno
generate
for(k=0; k<256; k=k+1) begin
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) CDF[k] <= 0;
	else if(in_valid) begin
		CDF[k] <= CDF[k] + (pic_data[7:0]<=k)+(pic_data[15:8]<=k)+(pic_data[23:16]<=k)+(pic_data[31:24]<=k);
	end
	else if(current_state==HISTOGRAM_DIV) begin
		CDF[k] <= CDF[k]-CDF[cdf_min];
	end
	else if(current_state==INPUT) begin
		CDF[k] <= 0;
	end
end
end
endgenerate

// cdf_min
assign cdf_min = (CDF[0]==0)+(CDF[1]==0)+(CDF[2]==0)+(CDF[3]==0)+(CDF[4]==0)+(CDF[5]==0)+(CDF[6]==0)+(CDF[7]==0)+(CDF[8]==0)+(CDF[9]==0)+(CDF[10]==0)+(CDF[11]==0)+(CDF[12]==0)+(CDF[13]==0)+(CDF[14]==0)+(CDF[15]==0)+(CDF[16]==0)+(CDF[17]==0)+(CDF[18]==0)+(CDF[19]==0)+(CDF[20]==0)+(CDF[21]==0)+(CDF[22]==0)+(CDF[23]==0)+(CDF[24]==0)+(CDF[25]==0)+(CDF[26]==0)+(CDF[27]==0)+(CDF[28]==0)+(CDF[29]==0)+(CDF[30]==0)+(CDF[31]==0)+(CDF[32]==0)+(CDF[33]==0)+(CDF[34]==0)+(CDF[35]==0)+(CDF[36]==0)+(CDF[37]==0)+(CDF[38]==0)+(CDF[39]==0)+(CDF[40]==0)+(CDF[41]==0)+(CDF[42]==0)+(CDF[43]==0)+(CDF[44]==0)+(CDF[45]==0)+(CDF[46]==0)+(CDF[47]==0)+(CDF[48]==0)+(CDF[49]==0)+(CDF[50]==0)+(CDF[51]==0)+(CDF[52]==0)+(CDF[53]==0)+(CDF[54]==0)+(CDF[55]==0)+(CDF[56]==0)+(CDF[57]==0)+(CDF[58]==0)+(CDF[59]==0)+(CDF[60]==0)+(CDF[61]==0)+(CDF[62]==0)+(CDF[63]==0)+(CDF[64]==0)+(CDF[65]==0)+(CDF[66]==0)+(CDF[67]==0)+(CDF[68]==0)+(CDF[69]==0)+(CDF[70]==0)+(CDF[71]==0)+(CDF[72]==0)+(CDF[73]==0)+(CDF[74]==0)+(CDF[75]==0)+(CDF[76]==0)+(CDF[77]==0)+(CDF[78]==0)+(CDF[79]==0)+(CDF[80]==0)+(CDF[81]==0)+(CDF[82]==0)+(CDF[83]==0)+(CDF[84]==0)+(CDF[85]==0)+(CDF[86]==0)+(CDF[87]==0)+(CDF[88]==0)+(CDF[89]==0)+(CDF[90]==0)+(CDF[91]==0)+(CDF[92]==0)+(CDF[93]==0)+(CDF[94]==0)+(CDF[95]==0)+(CDF[96]==0)+(CDF[97]==0)+(CDF[98]==0)+(CDF[99]==0)+(CDF[100]==0)+(CDF[101]==0)+(CDF[102]==0)+(CDF[103]==0)+(CDF[104]==0)+(CDF[105]==0)+(CDF[106]==0)+(CDF[107]==0)+(CDF[108]==0)+(CDF[109]==0)+(CDF[110]==0)+(CDF[111]==0)+(CDF[112]==0)+(CDF[113]==0)+(CDF[114]==0)+(CDF[115]==0)+(CDF[116]==0)+(CDF[117]==0)+(CDF[118]==0)+(CDF[119]==0)+(CDF[120]==0)+(CDF[121]==0)+(CDF[122]==0)+(CDF[123]==0)+(CDF[124]==0)+(CDF[125]==0)+(CDF[126]==0)+(CDF[127]==0)+(CDF[128]==0)+(CDF[129]==0)+(CDF[130]==0)+(CDF[131]==0)+(CDF[132]==0)+(CDF[133]==0)+(CDF[134]==0)+(CDF[135]==0)+(CDF[136]==0)+(CDF[137]==0)+(CDF[138]==0)+(CDF[139]==0)+(CDF[140]==0)+(CDF[141]==0)+(CDF[142]==0)+(CDF[143]==0)+(CDF[144]==0)+(CDF[145]==0)+(CDF[146]==0)+(CDF[147]==0)+(CDF[148]==0)+(CDF[149]==0)+(CDF[150]==0)+(CDF[151]==0)+(CDF[152]==0)+(CDF[153]==0)+(CDF[154]==0)+(CDF[155]==0)+(CDF[156]==0)+(CDF[157]==0)+(CDF[158]==0)+(CDF[159]==0)+(CDF[160]==0)+(CDF[161]==0)+(CDF[162]==0)+(CDF[163]==0)+(CDF[164]==0)+(CDF[165]==0)+(CDF[166]==0)+(CDF[167]==0)+(CDF[168]==0)+(CDF[169]==0)+(CDF[170]==0)+(CDF[171]==0)+(CDF[172]==0)+(CDF[173]==0)+(CDF[174]==0)+(CDF[175]==0)+(CDF[176]==0)+(CDF[177]==0)+(CDF[178]==0)+(CDF[179]==0)+(CDF[180]==0)+(CDF[181]==0)+(CDF[182]==0)+(CDF[183]==0)+(CDF[184]==0)+(CDF[185]==0)+(CDF[186]==0)+(CDF[187]==0)+(CDF[188]==0)+(CDF[189]==0)+(CDF[190]==0)+(CDF[191]==0)+(CDF[192]==0)+(CDF[193]==0)+(CDF[194]==0)+(CDF[195]==0)+(CDF[196]==0)+(CDF[197]==0)+(CDF[198]==0)+(CDF[199]==0)+(CDF[200]==0)+(CDF[201]==0)+(CDF[202]==0)+(CDF[203]==0)+(CDF[204]==0)+(CDF[205]==0)+(CDF[206]==0)+(CDF[207]==0)+(CDF[208]==0)+(CDF[209]==0)+(CDF[210]==0)+(CDF[211]==0)+(CDF[212]==0)+(CDF[213]==0)+(CDF[214]==0)+(CDF[215]==0)+(CDF[216]==0)+(CDF[217]==0)+(CDF[218]==0)+(CDF[219]==0)+(CDF[220]==0)+(CDF[221]==0)+(CDF[222]==0)+(CDF[223]==0)+(CDF[224]==0)+(CDF[225]==0)+(CDF[226]==0)+(CDF[227]==0)+(CDF[228]==0)+(CDF[229]==0)+(CDF[230]==0)+(CDF[231]==0)+(CDF[232]==0)+(CDF[233]==0)+(CDF[234]==0)+(CDF[235]==0)+(CDF[236]==0)+(CDF[237]==0)+(CDF[238]==0)+(CDF[239]==0)+(CDF[240]==0)+(CDF[241]==0)+(CDF[242]==0)+(CDF[243]==0)+(CDF[244]==0)+(CDF[245]==0)+(CDF[246]==0)+(CDF[247]==0)+(CDF[248]==0)+(CDF[249]==0)+(CDF[250]==0)+(CDF[251]==0)+(CDF[252]==0)+(CDF[253]==0)+(CDF[254]==0)+(CDF[255]==0);

// deno
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) deno <= 0;
	else if(current_state==HISTOGRAM_DIV) begin
		deno <= 1024-CDF[cdf_min];
	end
end

// ------------------------
// SRAM
RA1SH SRAM1(.Q(Q),.CLK(clk),.CEN(1'b0),.WEN(W),.A(A),.D(D),.OEN(1'b0));

// SRAM W
always @(*) begin
	if(in_valid) W = 0;
	else if(current_state==EROSION_IN || current_state==DILATION_IN) W = 0;
	else W = 1;
end
// SRAM A
always @(*) begin
	if(current_state==INPUT && in_valid) A = cnt_in_r*8 + cnt_in_c/4;
	else if(current_state==EROSION_IN || current_state==DILATION_IN) A = cnt_in_r*8 -32 + cnt_in_c/4;
	else if(current_state==OUTPUT_EROSION || current_state==OUTPUT_DILATION) A = cnt_out+33;
	else if(current_state==OUTPUT) A = cnt_out+1;
	else A = 0;
end
// SRAM D
always @(*) begin
	if(current_state==INPUT && in_valid) D = pic_data;
	else if(current_state==EROSION_IN || current_state==DILATION_IN) D = {cmp_e[3], cmp_e[2], cmp_e[1], cmp_e[0]};
	else D = 0;
end

// ------------------------
// OUTPUT

// cnt_out
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) cnt_out <= 0;
	else if(current_state==OUTPUT || current_state==OUTPUT_EROSION || current_state==OUTPUT_DILATION) cnt_out <= cnt_out + 1;
	else cnt_out <= 0;
end

// out_valid
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) out_valid <= 0;
	else if(current_state==OUTPUT) out_valid <= 1;
	else if(current_state==OUTPUT_EROSION || current_state==OUTPUT_DILATION) out_valid <= 1;
	else out_valid <= 0;
end

wire [7:0] data[0:3];
assign data[0] = (CDF[Q[7:0]]  *255)/deno;
assign data[1] = (CDF[Q[15:8]] *255)/deno;
assign data[2] = (CDF[Q[23:16]]*255)/deno;
assign data[3] = (CDF[Q[31:24]]*255)/deno;

// out_data
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) out_data <= 0;
	else if(current_state==OUTPUT) begin
		if(op_keep==2) begin
			out_data <= {data[3], data[2], data[1], data[0]};
		end
		else if(op_keep==0 || op_keep==1) begin
			if(cnt_out==0) out_data <= {tmp_pic[0][3], tmp_pic[0][2], tmp_pic[0][1], tmp_pic[0][0]};
			else if(cnt_out>223) out_data <= {tmp_pic[cnt_in_r-24][cnt_in_c+3], tmp_pic[cnt_in_r-24][cnt_in_c+2], tmp_pic[cnt_in_r-24][cnt_in_c+1], tmp_pic[cnt_in_r-24][cnt_in_c]};
			else out_data <= Q;
		end
	end
	else if(current_state==OUTPUT_EROSION || current_state==OUTPUT_DILATION) begin
		out_data <= {cmp_e_2[3], cmp_e_2[2], cmp_e_2[1], cmp_e_2[0]};
	end
	else out_data <= 0;
end

endmodule


