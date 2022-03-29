//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright OASIS LAB @NCTU ED317A
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2020 Fall
//   Midterm Proejct            : EDH  
//   Author                     : Tzu-Yun Huang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : EDH.v
//   Module Name : EDH
//   Release version : V1.0 (Release Date: 2020-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module EDH(
		    clk,
		  rst_n,
		     op,
	   in_valid,
         pic_no,
          se_no,
           busy,

     arid_m_inf,
   araddr_m_inf,
    arlen_m_inf,
   arsize_m_inf,
  arburst_m_inf,
  arvalid_m_inf,
  arready_m_inf,

      rid_m_inf,
    rdata_m_inf,
    rresp_m_inf,
    rlast_m_inf,
   rvalid_m_inf,
   rready_m_inf,

     awid_m_inf,
   awaddr_m_inf,
   awsize_m_inf,
  awburst_m_inf,
    awlen_m_inf,
  awvalid_m_inf,
  awready_m_inf,
                
    wdata_m_inf,
    wlast_m_inf,
   wvalid_m_inf,
   wready_m_inf,

      bid_m_inf,
    bresp_m_inf,
   bvalid_m_inf,
   bready_m_inf 
);
parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32;    // DO NOT modify
input  wire     clk,
	          rst_n, in_valid;
input [3:0]   pic_no;
input [1:0]   op;
input [5:0]   se_no;

output reg   busy;

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
       your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
	   therefore I declared output of AXI as wire  
*/

// axi write addr channel 
// src master
output reg [ID_WIDTH-1:0]      awid_m_inf; // 'b0
output reg [ADDR_WIDTH-1:0]  awaddr_m_inf;
output reg [2:0]             awsize_m_inf; // 3'b100
output reg [1:0]            awburst_m_inf; // 2'b01
output reg [7:0]              awlen_m_inf;
output reg                  awvalid_m_inf;
// src slave
input  wire                  awready_m_inf;
// -------------------------

// axi write data channel 
// src master
output reg [DATA_WIDTH-1:0]   wdata_m_inf;
output reg                    wlast_m_inf;
output reg                   wvalid_m_inf;
// src slave
input  wire                   wready_m_inf;

// axi write resp channel 
// src slave
input  wire  [ID_WIDTH-1:0]      bid_m_inf; // 'b0
input  wire  [1:0]             bresp_m_inf;	// 2'b00
input  wire                   bvalid_m_inf;
// src master 
output reg                   bready_m_inf;
// ------------------------

// axi read addr channel 
// src master
output reg [ID_WIDTH-1:0]      arid_m_inf; // 'b0
output reg [ADDR_WIDTH-1:0]  araddr_m_inf;
output reg [7:0]              arlen_m_inf;
output reg [2:0]             arsize_m_inf; // 3'b100
output reg [1:0]            arburst_m_inf; // 2'b01
output reg                  arvalid_m_inf;
// src slave
input  wire                  arready_m_inf;
// ------------------------

// axi read data channel 
// slave
input  wire [ID_WIDTH-1:0]       rid_m_inf; // 'b0
input  wire [DATA_WIDTH-1:0]   rdata_m_inf;
input  wire [1:0]              rresp_m_inf; // 2'b00
input  wire                    rlast_m_inf;
input  wire                   rvalid_m_inf;
// master
output reg                   rready_m_inf;

// -----------------------------------------------
// parameter
parameter INPUT = 4'd0;
parameter READ_SE = 4'd1;
parameter HIST = 4'd2;
parameter EROSION = 4'd3;
parameter DILATION = 4'd4;
parameter WRITE = 4'd5;
parameter OUTPUT = 4'd6;
parameter DIVIDE = 4'd7;
parameter DENO = 4'd8;

reg [3:0] current_state, next_state;

// input_keep
reg [3:0] pic_no_keep;
reg [5:0] se_no_keep;
reg [1:0] op_keep;

reg receive_arready;

reg [7:0] SE[0:3][0:3];

reg [6:0] cnt_r;
reg [5:0] cnt_c;
reg [7:0] PIC[0:3][0:63];

reg [7:0] cmp_a[0:15][0:3][0:3], cmp_b[0:15][0:7], cmp_c[0:15][0:3], cmp_d[0:15][0:1], cmp_e[0:15];

reg [127:0] data;

// SRAM
reg W;
reg [7:0] A;
reg [127:0] D;
wire [127:0] Q;

reg receive_awready;
reg [8:0] cnt_write;

reg [12:0] CDF[0:255];
reg [7:0] h[0:255];

integer i, j;
genvar k;

// current_state
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) current_state <= INPUT;
	else current_state <= next_state;
end

// next_state
always@ (*) begin
	case(current_state)
		INPUT: 
			if(op_keep<2) next_state = READ_SE;
			else if(op_keep==2) next_state = HIST;
			else next_state = INPUT;
		READ_SE:
			if(rlast_m_inf==1) begin
				if(op_keep==0) next_state = EROSION;
				else next_state = DILATION;
			end
			else next_state = READ_SE;
		HIST: 
			if(cnt_r==63 && cnt_c==48) next_state = DENO;
			else next_state = HIST;
		EROSION: 
			if(cnt_r==67 && cnt_c==48) next_state = WRITE;
			else next_state = EROSION;
		DILATION: 
			if(cnt_r==67 && cnt_c==48) next_state = WRITE;
			else next_state = DILATION;
		WRITE:
			if(cnt_write==255) next_state = OUTPUT;
			else next_state = WRITE;
		DENO: next_state = DIVIDE;
		DIVIDE:
			if(cnt_write==255) next_state = WRITE;
			else next_state = DIVIDE;
		default: 
			next_state = INPUT;			
	endcase
end

// pic_no_keep, se_no_keep, op_keep;
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		pic_no_keep <= 0;
		se_no_keep <= 0;
		op_keep <= 3;
	end
	else if(in_valid) begin
		pic_no_keep <= pic_no;
		se_no_keep <= se_no;
		op_keep <= op;
	end
	else if(current_state==OUTPUT) begin
		pic_no_keep <= 0;
		se_no_keep <= 0;
		op_keep <= 3;
	end
end

// ------------------------
// read address channel
// arid_m_inf
always@(posedge clk or negedge rst_n) begin
  if(!rst_n) arid_m_inf <= 0;
  else arid_m_inf <= 0;
end
// araddr_m_inf
always@(posedge clk or negedge rst_n) begin
  if(!rst_n) araddr_m_inf <= 0;
  else if(current_state==READ_SE) araddr_m_inf <= 32'h0002_0000 + (se_no_keep<<4);
  else araddr_m_inf <= 32'h0001_0000 + (pic_no_keep<<12);
end
// arlen_m_inf
always@(posedge clk or negedge rst_n) begin
  if(!rst_n) arlen_m_inf <= 0;
  else if(current_state==READ_SE) arlen_m_inf <= 0;
  else arlen_m_inf <= 255;
end
// arsize_m_inf
always@(posedge clk or negedge rst_n) begin
  if(!rst_n) arsize_m_inf <= 3'b100;
  else arsize_m_inf <= 3'b100;
end
// arburst_m_inf
always@(posedge clk or negedge rst_n) begin
  if(!rst_n) arburst_m_inf <= 2'b01;
  else arburst_m_inf <= 2'b01;
end
// arvalid_m_inf
always@(posedge clk or negedge rst_n) begin
  if(!rst_n) arvalid_m_inf <= 0;
  else if(current_state==READ_SE && receive_arready==0 && arready_m_inf==0) arvalid_m_inf <= 1;
  else if((current_state==EROSION||current_state==DILATION) && receive_arready==0 && arready_m_inf==0 && cnt_r<1) arvalid_m_inf <= 1;
  else if(current_state==HIST && receive_arready==0 && arready_m_inf==0) arvalid_m_inf <= 1;
  else arvalid_m_inf <= 0;
end
// ------------------------
// read data channel
// rready_m_inf
always@(posedge clk or negedge rst_n) begin
  if(!rst_n) rready_m_inf <= 0;
  else rready_m_inf <= 1;
end

// receive_arready
always@(posedge clk or negedge rst_n) begin
  if(!rst_n) receive_arready <= 0;
  else if(arready_m_inf==1) receive_arready <= 1;
  else if(rlast_m_inf==1) receive_arready <= 0;
end

// ------------------------
// write address channel
// awid_m_inf
always@(posedge clk or negedge rst_n) begin
  if(!rst_n) awid_m_inf <= 0;
  else awid_m_inf <= 0;
end
// awaddr_m_inf
always@(posedge clk or negedge rst_n) begin
  if(!rst_n) awaddr_m_inf <= 0;
  else awaddr_m_inf <= 32'h0001_0000 + (pic_no_keep<<12);
end
// awlen_m_inf
always@(posedge clk or negedge rst_n) begin
  if(!rst_n) awlen_m_inf <= 255;
  else awlen_m_inf <= 255;
end
// awsize_m_inf
always@(posedge clk or negedge rst_n) begin
  if(!rst_n) awsize_m_inf <= 3'b100;
  else awsize_m_inf <= 3'b100;
end
// awburst_m_inf
always@(posedge clk or negedge rst_n) begin
  if(!rst_n) awburst_m_inf <= 2'b01;
  else awburst_m_inf <= 2'b01;
end
// awvalid_m_inf
always@(posedge clk or negedge rst_n) begin
  if(!rst_n) awvalid_m_inf <= 0;
  else if(current_state == WRITE && awready_m_inf==0 && receive_awready==0) awvalid_m_inf <= 1;
  else awvalid_m_inf <= 0;
end
// ------------------------
// write data channel
// wdata_m_inf
always@(*) begin
  if(op_keep==2) wdata_m_inf = {h[Q[127:120]], h[Q[119:112]], h[Q[111:104]], h[Q[103:96]], h[Q[95:88]], h[Q[87:80]], h[Q[79:72]], h[Q[71:64]], h[Q[63:56]], h[Q[55:48]], h[Q[47:40]], h[Q[39:32]], h[Q[31:24]], h[Q[23:16]], h[Q[15:8]], h[Q[7:0]]};
  else wdata_m_inf = Q;
end
// wvalid_m_inf
always@(posedge clk or negedge rst_n) begin
  if(!rst_n) wvalid_m_inf <= 0;
  else if(current_state==WRITE) wvalid_m_inf <= 1;
  else wvalid_m_inf <= 0;
end
// wlast_m_inf
always@(posedge clk or negedge rst_n) begin
  if(!rst_n) wlast_m_inf <= 0;
  else if(cnt_write==254) wlast_m_inf <= 1;
  else wlast_m_inf <= 0;
end
// ------------------------
// write resp channel
always@(posedge clk or negedge rst_n) begin
  if(!rst_n) bready_m_inf <= 0;
  else bready_m_inf <= 1;
end

// receive_awready
always@(posedge clk or negedge rst_n) begin
  if(!rst_n) receive_awready <= 0;
  else if(awready_m_inf==1) receive_awready <= 1;
  else if(wlast_m_inf==1) receive_awready <= 0;
end

// SE
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0; i<4; i=i+1) begin
			for(j=0; j<4; j=j+1) begin
				SE[i][j] <= 0;
			end
		end
	end
	else if(current_state==READ_SE && op_keep==0) begin
		if(rvalid_m_inf) begin 
			for(i=0; i<4; i=i+1) begin
				for(j=0; j<4; j=j+1) begin
					SE[i][j] <= rdata_m_inf>>(32*i+8*j);
				end
			end
		end
	end
	else if(current_state==READ_SE && op_keep==1) begin
		if(rvalid_m_inf) begin 
			for(i=0; i<4; i=i+1) begin
				for(j=0; j<4; j=j+1) begin
					SE[i][j] <= rdata_m_inf>>(32*(3-i)+8*(3-j));
				end
			end
		end
	end
end

// cnt_r
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) cnt_r <= 0;
	else if(current_state==EROSION || current_state==DILATION) begin
		if(cnt_c==48 && (rvalid_m_inf==1||cnt_r>63)) cnt_r <= cnt_r + 1;
	end
	else if(current_state==HIST) begin
		if(cnt_c==48 && rvalid_m_inf==1) cnt_r <= cnt_r + 1;
	end
	else if(current_state==OUTPUT) cnt_r <= 0;
end

// cnt_c
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) cnt_c <= 0;
	else if(current_state==EROSION || current_state==DILATION) begin
		if(rvalid_m_inf==1 || cnt_r>63) cnt_c <= cnt_c + 16;
	end
	else if(current_state==HIST) begin
		if(rvalid_m_inf==1) cnt_c <= cnt_c + 16;
	end
	else if(current_state==OUTPUT) cnt_c <= 0;
end

// PIC
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0; i<4; i=i+1) begin
			for(j=0; j<64; j=j+1) begin
				PIC[i][j] <= 0;
			end
		end
	end
	else if((current_state==EROSION || current_state==DILATION) && (rvalid_m_inf==1 || cnt_r>63)) begin
		if(cnt_r<4) begin 
			for(j=0; j<16; j=j+1) begin
				PIC[cnt_r][cnt_c+j] <= rdata_m_inf>>(8*j);
			end
		end
		else begin
			for(j=0; j<16; j=j+1) begin
				PIC[3][cnt_c+j] <= rdata_m_inf>>(8*j);
			end
			for(i=0;i<3; i=i+1) begin
				for(j=0; j<16; j=j+1) begin
					PIC[i][cnt_c+j] <= PIC[i+1][cnt_c+j];
				end
			end
		end
	end
end

// cmp_a
generate
for(k=0; k<256; k=k+1) begin
always@ (*) begin
	for(i=0; i<4; i=i+1) begin
		for(j=0; j<4; j=j+1) begin
			if(current_state==EROSION) begin
				if((cnt_r-4+i)>63 || (cnt_c+j+k)>63) cmp_a[k][i][j] = 0;
				else begin
					if((PIC[i][cnt_c+j+k]<SE[i][j])) cmp_a[k][i][j] = 0;
					else cmp_a[k][i][j] = PIC[i][cnt_c+j+k] - SE[i][j];
				end
			end
			else begin
				if((cnt_r-4+i)>63 || (cnt_c+j+k)>63) cmp_a[k][i][j] = SE[i][j];
				else begin
					if(({1'b0, PIC[i][cnt_c+j+k]}+{1'b0, SE[i][j]})>255) cmp_a[k][i][j] = 255;
					else cmp_a[k][i][j] = PIC[i][cnt_c+j+k] + SE[i][j];
				end
			end
		end
	end
end
end
endgenerate

// cmp_b
generate
for(k=0; k<256; k=k+1) begin
always@ (*) begin
	if(current_state==EROSION) begin
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
for(k=0; k<256; k=k+1) begin
always@ (*) begin
	if(current_state==EROSION) begin
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
for(k=0; k<256; k=k+1) begin
always@ (*) begin
	if(current_state==EROSION) begin
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
for(k=0; k<256; k=k+1) begin
always@ (*) begin
	if(current_state==EROSION) begin
		cmp_e[k] = (cmp_d[k][0] < cmp_d[k][1]) ? cmp_d[k][0] : cmp_d[k][1];
	end
	else begin
		cmp_e[k] = (cmp_d[k][0] > cmp_d[k][1]) ? cmp_d[k][0] : cmp_d[k][1];
	end
end
end
endgenerate

// data
always@ (*) begin
	data = {cmp_e[15], cmp_e[14], cmp_e[13], cmp_e[12], cmp_e[11], cmp_e[10], cmp_e[9], cmp_e[8], cmp_e[7], cmp_e[6], cmp_e[5], cmp_e[4], cmp_e[3], cmp_e[2], cmp_e[1], cmp_e[0]};
end

// CDF
generate
for(k=0; k<256; k=k+1) begin
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		CDF[k] <= 0;
	end
	else if(current_state==HIST && rvalid_m_inf==1) begin
		CDF[k] <= CDF[k] + (rdata_m_inf[7:0]<=k)+(rdata_m_inf[15:8]<=k)+(rdata_m_inf[23:16]<=k)+(rdata_m_inf[31:24]<=k)+(rdata_m_inf[39:32]<=k)+(rdata_m_inf[47:40]<=k)+(rdata_m_inf[55:48]<=k)+(rdata_m_inf[63:56]<=k)+(rdata_m_inf[71:64]<=k)+(rdata_m_inf[79:72]<=k)+(rdata_m_inf[87:80]<=k)+(rdata_m_inf[95:88]<=k)+(rdata_m_inf[103:96]<=k)+(rdata_m_inf[111:104]<=k)+(rdata_m_inf[119:112]<=k)+(rdata_m_inf[127:120]<=k);
	end
	else if(current_state==INPUT) begin
		CDF[k] <= 0;
	end
end
end
endgenerate

wire [12:0] cdf_min;
assign cdf_min = (CDF[0]==0)+(CDF[1]==0)+(CDF[2]==0)+(CDF[3]==0)+(CDF[4]==0)+(CDF[5]==0)+(CDF[6]==0)+(CDF[7]==0)+(CDF[8]==0)+(CDF[9]==0)+(CDF[10]==0)+(CDF[11]==0)+(CDF[12]==0)+(CDF[13]==0)+(CDF[14]==0)+(CDF[15]==0)+(CDF[16]==0)+(CDF[17]==0)+(CDF[18]==0)+(CDF[19]==0)+(CDF[20]==0)+(CDF[21]==0)+(CDF[22]==0)+(CDF[23]==0)+(CDF[24]==0)+(CDF[25]==0)+(CDF[26]==0)+(CDF[27]==0)+(CDF[28]==0)+(CDF[29]==0)+(CDF[30]==0)+(CDF[31]==0)+(CDF[32]==0)+(CDF[33]==0)+(CDF[34]==0)+(CDF[35]==0)+(CDF[36]==0)+(CDF[37]==0)+(CDF[38]==0)+(CDF[39]==0)+(CDF[40]==0)+(CDF[41]==0)+(CDF[42]==0)+(CDF[43]==0)+(CDF[44]==0)+(CDF[45]==0)+(CDF[46]==0)+(CDF[47]==0)+(CDF[48]==0)+(CDF[49]==0)+(CDF[50]==0)+(CDF[51]==0)+(CDF[52]==0)+(CDF[53]==0)+(CDF[54]==0)+(CDF[55]==0)+(CDF[56]==0)+(CDF[57]==0)+(CDF[58]==0)+(CDF[59]==0)+(CDF[60]==0)+(CDF[61]==0)+(CDF[62]==0)+(CDF[63]==0)+(CDF[64]==0)+(CDF[65]==0)+(CDF[66]==0)+(CDF[67]==0)+(CDF[68]==0)+(CDF[69]==0)+(CDF[70]==0)+(CDF[71]==0)+(CDF[72]==0)+(CDF[73]==0)+(CDF[74]==0)+(CDF[75]==0)+(CDF[76]==0)+(CDF[77]==0)+(CDF[78]==0)+(CDF[79]==0)+(CDF[80]==0)+(CDF[81]==0)+(CDF[82]==0)+(CDF[83]==0)+(CDF[84]==0)+(CDF[85]==0)+(CDF[86]==0)+(CDF[87]==0)+(CDF[88]==0)+(CDF[89]==0)+(CDF[90]==0)+(CDF[91]==0)+(CDF[92]==0)+(CDF[93]==0)+(CDF[94]==0)+(CDF[95]==0)+(CDF[96]==0)+(CDF[97]==0)+(CDF[98]==0)+(CDF[99]==0)+(CDF[100]==0)+(CDF[101]==0)+(CDF[102]==0)+(CDF[103]==0)+(CDF[104]==0)+(CDF[105]==0)+(CDF[106]==0)+(CDF[107]==0)+(CDF[108]==0)+(CDF[109]==0)+(CDF[110]==0)+(CDF[111]==0)+(CDF[112]==0)+(CDF[113]==0)+(CDF[114]==0)+(CDF[115]==0)+(CDF[116]==0)+(CDF[117]==0)+(CDF[118]==0)+(CDF[119]==0)+(CDF[120]==0)+(CDF[121]==0)+(CDF[122]==0)+(CDF[123]==0)+(CDF[124]==0)+(CDF[125]==0)+(CDF[126]==0)+(CDF[127]==0)+(CDF[128]==0)+(CDF[129]==0)+(CDF[130]==0)+(CDF[131]==0)+(CDF[132]==0)+(CDF[133]==0)+(CDF[134]==0)+(CDF[135]==0)+(CDF[136]==0)+(CDF[137]==0)+(CDF[138]==0)+(CDF[139]==0)+(CDF[140]==0)+(CDF[141]==0)+(CDF[142]==0)+(CDF[143]==0)+(CDF[144]==0)+(CDF[145]==0)+(CDF[146]==0)+(CDF[147]==0)+(CDF[148]==0)+(CDF[149]==0)+(CDF[150]==0)+(CDF[151]==0)+(CDF[152]==0)+(CDF[153]==0)+(CDF[154]==0)+(CDF[155]==0)+(CDF[156]==0)+(CDF[157]==0)+(CDF[158]==0)+(CDF[159]==0)+(CDF[160]==0)+(CDF[161]==0)+(CDF[162]==0)+(CDF[163]==0)+(CDF[164]==0)+(CDF[165]==0)+(CDF[166]==0)+(CDF[167]==0)+(CDF[168]==0)+(CDF[169]==0)+(CDF[170]==0)+(CDF[171]==0)+(CDF[172]==0)+(CDF[173]==0)+(CDF[174]==0)+(CDF[175]==0)+(CDF[176]==0)+(CDF[177]==0)+(CDF[178]==0)+(CDF[179]==0)+(CDF[180]==0)+(CDF[181]==0)+(CDF[182]==0)+(CDF[183]==0)+(CDF[184]==0)+(CDF[185]==0)+(CDF[186]==0)+(CDF[187]==0)+(CDF[188]==0)+(CDF[189]==0)+(CDF[190]==0)+(CDF[191]==0)+(CDF[192]==0)+(CDF[193]==0)+(CDF[194]==0)+(CDF[195]==0)+(CDF[196]==0)+(CDF[197]==0)+(CDF[198]==0)+(CDF[199]==0)+(CDF[200]==0)+(CDF[201]==0)+(CDF[202]==0)+(CDF[203]==0)+(CDF[204]==0)+(CDF[205]==0)+(CDF[206]==0)+(CDF[207]==0)+(CDF[208]==0)+(CDF[209]==0)+(CDF[210]==0)+(CDF[211]==0)+(CDF[212]==0)+(CDF[213]==0)+(CDF[214]==0)+(CDF[215]==0)+(CDF[216]==0)+(CDF[217]==0)+(CDF[218]==0)+(CDF[219]==0)+(CDF[220]==0)+(CDF[221]==0)+(CDF[222]==0)+(CDF[223]==0)+(CDF[224]==0)+(CDF[225]==0)+(CDF[226]==0)+(CDF[227]==0)+(CDF[228]==0)+(CDF[229]==0)+(CDF[230]==0)+(CDF[231]==0)+(CDF[232]==0)+(CDF[233]==0)+(CDF[234]==0)+(CDF[235]==0)+(CDF[236]==0)+(CDF[237]==0)+(CDF[238]==0)+(CDF[239]==0)+(CDF[240]==0)+(CDF[241]==0)+(CDF[242]==0)+(CDF[243]==0)+(CDF[244]==0)+(CDF[245]==0)+(CDF[246]==0)+(CDF[247]==0)+(CDF[248]==0)+(CDF[249]==0)+(CDF[250]==0)+(CDF[251]==0)+(CDF[252]==0)+(CDF[253]==0)+(CDF[254]==0)+(CDF[255]==0);

reg [12:0] deno, nume[0:255];
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) deno <= 0;
	else if(current_state==DENO) deno <= (4096-CDF[cdf_min]);
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0; i<256; i=i+1) begin
			nume[i] <= 0;
		end
	end
	else if(current_state==DENO) begin
		for(i=0; i<256; i=i+1) begin
			nume[i] <= (CDF[i]-CDF[cdf_min]);
		end
	end
end

// h
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0; i<256; i=i+1) begin
			h[i] <= 0;
		end
	end
	else if(current_state==DIVIDE) begin
		h[cnt_write] <= nume[cnt_write]*255/deno;
	end
end

// ------------------------
// SRAM
RA1SH sram1(.Q(Q),.CLK(clk),.CEN(1'b0),.WEN(W),.A(A),.D(D),.OEN(1'b0));
// SRAM W
always @(*) begin
	if((current_state==EROSION || current_state==DILATION) && (rvalid_m_inf==1||cnt_r>63) && cnt_r>3) W = 0;
	else if(current_state==HIST && rvalid_m_inf==1) W = 0;
	else W = 1;
end
// SRAM A
always @(*) begin
	if(current_state==EROSION || current_state==DILATION) A = (cnt_r-4)*4 + cnt_c/16;
	else if(current_state==HIST) A = cnt_r*4 + cnt_c/16;
	else if(current_state==WRITE) A = cnt_write+wready_m_inf;
	else A = 0;
end
// SRAM D
always @(*) begin
	if(current_state==EROSION || current_state==DILATION) D = data;
	else if(current_state==HIST) D = rdata_m_inf;
	else D = 0;
end

// cnt_write
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) cnt_write <= 0;
	else if(current_state==WRITE && wready_m_inf==1) cnt_write <= cnt_write + 1;
	else if(current_state==DIVIDE) cnt_write <= cnt_write + 1;
	else if(current_state==INPUT) cnt_write <= 0;
end

// busy
always@ (posedge clk or negedge rst_n) begin
	if(!rst_n) busy <= 0;
	else if(current_state==OUTPUT) busy <= 0;
	else if(next_state==READ_SE || next_state==HIST) busy <= 1;
end


endmodule