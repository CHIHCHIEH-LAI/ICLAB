//synopsys translate_off
`include "DW_sincos.v" 
//synopsys translate_on

// evince /RAID2/EDA/synopsys/synthesis/cur/dw/doc/dwbb_overview.pdf &

module DH(
	// Input signals
	clk,
	rst_n,
	IN_VALID_1,
	IN_VALID_2,
	ALPHA_I,
	A_I,
	D_I,
	THETA_JOINT_1,
	THETA_JOINT_2,
	THETA_JOINT_3,
	THETA_JOINT_4,
	// Output signals
	OUT_VALID,
	OUT_X,
	OUT_Y,
	OUT_Z
);

//-----------------------------------------------------------------------------------------------------------------
//   PORT DECLARATION                                                  
//-----------------------------------------------------------------------------------------------------------------
input            clk, rst_n, IN_VALID_1, IN_VALID_2;
input [5:0]		 ALPHA_I;
input [2:0]      A_I, D_I;
input [5:0]      THETA_JOINT_1, THETA_JOINT_2, THETA_JOINT_3, THETA_JOINT_4;
output reg		 OUT_VALID;
output reg [10:0] OUT_X, OUT_Y, OUT_Z;

//---------------------------------------------------------------------
//   Design
//---------------------------------------------------------------------
integer i;


// IN_VALID_1
//---------------------------------------------------------------------
reg signed [5:0] ALPHA[1:3];
reg signed [3:0] A[0:3];
reg signed [3:0] D[0:3];

// ALPHA
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=1; i<4; i=i+1) begin
			ALPHA[i] <= 0;
		end
	end
	else if(IN_VALID_1) begin
		ALPHA[3] <= ALPHA_I;
		for(i=2; i<4; i=i+1) begin
			ALPHA[i-1] <= ALPHA[i];
		end
	end
end

// A
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0; i<4; i=i+1) begin
			A[i] <= 0;
		end
	end
	else if(IN_VALID_1) begin
		A[3] <= {1'b0, A_I};
		for(i=1; i<4; i=i+1) begin
			A[i-1] <= A[i];
		end
	end
end

// D
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0; i<4; i=i+1) begin
			D[i] <= 0;
		end
	end
	else if(IN_VALID_1) begin
		D[3] <= {1'b0, D_I};
		for(i=1; i<4; i=i+1) begin
			D[i-1] <= D[i];
		end
	end
end


// pipeline 0
//---------------------------------------------------------------------
reg in_valid0;
reg signed [5:0] THETA0[0:3];

// in_valid0
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		in_valid0 <= 0;
	end
	else begin
		in_valid0 <= IN_VALID_2;
	end
end

// THETA0
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0; i<4; i=i+1) begin
			THETA0[i] <= 0;
		end
	end
	else if(IN_VALID_2) begin
		THETA0[0] <= THETA_JOINT_1;
		THETA0[1] <= THETA_JOINT_2;
		THETA0[2] <= THETA_JOINT_3;
		THETA0[3] <= THETA_JOINT_4;
	end
end

wire signed [10:0] COS_T0_0, SIN_T0_0;
wire signed [10:0] COS_T1_0, SIN_T1_0;
wire signed [10:0] COS_ALPHA1_0, SIN_ALPHA1_0;
wire signed [10:0] SIN_T1pALPHA1_0, SIN_T1mALPHA1_0, COS_T1pALPHA1_0, COS_T1mALPHA1_0;
wire signed [10:0] SIN_T0pT1_0, SIN_T0mT1_0, COS_T0pT1_0, COS_T0mT1_0;
wire signed [10:0] COS_T0pALPHA1_0, COS_T0mALPHA1_0;

DW_sincos #(6,11,1,1) COST0(.A(THETA0[0]),.SIN_COS(1'b1),.WAVE(COS_T0_0));
DW_sincos #(6,11,1,1) SINT0(.A(THETA0[0]),.SIN_COS(1'b0),.WAVE(SIN_T0_0));
			  
DW_sincos #(6,11,1,1) COST1(.A(THETA0[1]),.SIN_COS(1'b1),.WAVE(COS_T1_0));
DW_sincos #(6,11,1,1) SINT1(.A(THETA0[1]),.SIN_COS(1'b0),.WAVE(SIN_T1_0));
			  
DW_sincos #(6,11,1,1) COSALPHA1(.A(ALPHA[1]),.SIN_COS(1'b1),.WAVE(COS_ALPHA1_0));
DW_sincos #(6,11,1,1) SINALPHA1(.A(ALPHA[1]),.SIN_COS(1'b0),.WAVE(SIN_ALPHA1_0));

DW_sincos #(6,11,1,1) SINT1pALPHA1(.A(THETA0[1]+ALPHA[1]),.SIN_COS(1'b0),.WAVE(SIN_T1pALPHA1_0));
DW_sincos #(6,11,1,1) SINT1mALPHA1(.A(THETA0[1]-ALPHA[1]),.SIN_COS(1'b0),.WAVE(SIN_T1mALPHA1_0));

DW_sincos #(6,11,1,1) COST1pALPHA1(.A(THETA0[1]+ALPHA[1]),.SIN_COS(1'b1),.WAVE(COS_T1pALPHA1_0));
DW_sincos #(6,11,1,1) COST1mALPHA1(.A(THETA0[1]-ALPHA[1]),.SIN_COS(1'b1),.WAVE(COS_T1mALPHA1_0));

DW_sincos #(6,11,1,1) SINT0pT1(.A(THETA0[0]+THETA0[1]),.SIN_COS(1'b0),.WAVE(SIN_T0pT1_0));
DW_sincos #(6,11,1,1) SINT0mT1(.A(THETA0[0]-THETA0[1]),.SIN_COS(1'b0),.WAVE(SIN_T0mT1_0));
										 
DW_sincos #(6,11,1,1) COST0pT1(.A(THETA0[0]+THETA0[1]),.SIN_COS(1'b1),.WAVE(COS_T0pT1_0));
DW_sincos #(6,11,1,1) COST0mT1(.A(THETA0[0]-THETA0[1]),.SIN_COS(1'b1),.WAVE(COS_T0mT1_0));

DW_sincos #(6,11,1,1) COST0pALPHA1(.A(THETA0[0]+ALPHA[1]),.SIN_COS(1'b1),.WAVE(COS_T0pALPHA1_0));
DW_sincos #(6,11,1,1) COST0mALPHA1(.A(THETA0[0]-ALPHA[1]),.SIN_COS(1'b1),.WAVE(COS_T0mALPHA1_0));


// pipeline 1
//---------------------------------------------------------------------
reg in_valid1;
reg signed [5:0] THETA1 [2:3];
reg signed [10:0] COS_T0_1, SIN_T0_1;
reg signed [10:0] COS_T1_1, SIN_T1_1;
reg signed [10:0] COS_ALPHA1_1, SIN_ALPHA1_1;
reg signed [10:0] SIN_T1pALPHA1_1, SIN_T1mALPHA1_1, COS_T1pALPHA1_1, COS_T1mALPHA1_1;
reg signed [10:0] SIN_T0pT1_1, SIN_T0mT1_1, COS_T0pT1_1, COS_T0mT1_1;
reg signed [10:0] COS_T0pALPHA1_1, COS_T0mALPHA1_1;

// in_valid1
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		in_valid1 <= 0;
	end
	else begin
		in_valid1 <= in_valid0;
	end
end

// THETA1
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		THETA1[2] <= 0;
		THETA1[3] <= 0;
	end
	else if(in_valid0) begin
		THETA1[2] <= THETA0[2];
		THETA1[3] <= THETA0[3];
	end
end

// COS and SIN T0/T1/ALPHA1
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		COS_T0_1 <= 0;
		SIN_T0_1 <= 0;
		COS_T1_1 <= 0;
		SIN_T1_1 <= 0;
		COS_ALPHA1_1 <= 0;
		SIN_ALPHA1_1 <= 0;
		SIN_T1pALPHA1_1 <= 0;
		SIN_T1mALPHA1_1 <= 0;
		COS_T1pALPHA1_1 <= 0;
		COS_T1mALPHA1_1 <= 0;
		SIN_T0pT1_1 <= 0;
		SIN_T0mT1_1 <= 0;
		COS_T0pT1_1 <= 0;
		COS_T0mT1_1 <= 0;
		COS_T0pALPHA1_1 <= 0;
		COS_T0mALPHA1_1 <= 0;
	end
	else if(in_valid0) begin
		COS_T0_1 <= COS_T0_0;
		SIN_T0_1 <= SIN_T0_0;
		COS_T1_1 <= COS_T1_0;
		SIN_T1_1 <= SIN_T1_0;
		COS_ALPHA1_1 <= COS_ALPHA1_0;
		SIN_ALPHA1_1 <= SIN_ALPHA1_0;
		SIN_T1pALPHA1_1 <= SIN_T1pALPHA1_0;
		SIN_T1mALPHA1_1 <= SIN_T1mALPHA1_0;
		COS_T1pALPHA1_1 <= COS_T1pALPHA1_0;
        COS_T1mALPHA1_1 <= COS_T1mALPHA1_0;
		SIN_T0pT1_1 <= SIN_T0pT1_0;
		SIN_T0mT1_1 <= SIN_T0mT1_0;
		COS_T0pT1_1 <= COS_T0pT1_0;
		COS_T0mT1_1 <= COS_T0mT1_0;
		COS_T0pALPHA1_1 <= COS_T0pALPHA1_0;
		COS_T0mALPHA1_1 <= COS_T0mALPHA1_0;	
	end
end

wire signed [10:0] COS_T2_1, SIN_T2_1;
wire signed [10:0] COS_ALPHA2_1, SIN_ALPHA2_1;
wire signed [10:0] SIN_T2pALPHA2_1, SIN_T2mALPHA2_1, COS_T2pALPHA2_1, COS_T2mALPHA2_1;
wire signed [23:0] result1_1 [0:2];

DW_sincos #(6,11,1,1) COST2(.A(THETA1[2]),.SIN_COS(1'b1),.WAVE(COS_T2_1));
DW_sincos #(6,11,1,1) SINT2(.A(THETA1[2]),.SIN_COS(1'b0),.WAVE(SIN_T2_1));
			   
DW_sincos #(6,11,1,1) COSALPHA2(.A(ALPHA[2]),.SIN_COS(1'b1),.WAVE(COS_ALPHA2_1));
DW_sincos #(6,11,1,1) SINALPHA2(.A(ALPHA[2]),.SIN_COS(1'b0),.WAVE(SIN_ALPHA2_1));

DW_sincos #(6,11,1,1) SINT2pALPHA2(.A(THETA1[2]+ALPHA[2]),.SIN_COS(1'b0),.WAVE(SIN_T2pALPHA2_1));
DW_sincos #(6,11,1,1) SINT2mALPHA2(.A(THETA1[2]-ALPHA[2]),.SIN_COS(1'b0),.WAVE(SIN_T2mALPHA2_1));
																							 
DW_sincos #(6,11,1,1) COST2pALPHA2(.A(THETA1[2]+ALPHA[2]),.SIN_COS(1'b1),.WAVE(COS_T2pALPHA2_1));
DW_sincos #(6,11,1,1) COST2mALPHA2(.A(THETA1[2]-ALPHA[2]),.SIN_COS(1'b1),.WAVE(COS_T2mALPHA2_1));

// assign result1_1[0] = ((A[0]*COS_T0_1*COS_T1_1)) - ((A[0]*SIN_T0_1*SIN_T1_1*COS_ALPHA1_1)>>>9) + ((D[0]*SIN_T1_1*SIN_ALPHA1_1)) + ((A[1]*COS_T1_1)<<<9);
// assign result1_1[1] = ((A[0]*COS_T0_1*SIN_T1_1)) + ((A[0]*SIN_T0_1*COS_T1_1*COS_ALPHA1_1)>>>9) - ((D[0]*COS_T1_1*SIN_ALPHA1_1)) + ((A[1]*SIN_T1_1)<<<9);
// assign result1_1[2] =                                  ((A[0]*SIN_T0_1*SIN_ALPHA1_1))           + ((D[0]*COS_ALPHA1_1)<<<9)              +  (D[1]<<<18);

assign result1_1[0] = ((A[0]*((COS_T0pT1_1+COS_T0mT1_1)/2))) - ((A[0]*SIN_T0_1*((SIN_T1pALPHA1_1+SIN_T1mALPHA1_1)/2))>>>9) + ((D[0]*((-COS_T1pALPHA1_1+COS_T1mALPHA1_1)/2))) + ((A[1]*COS_T1_1));
assign result1_1[1] = ((A[0]*((SIN_T0pT1_1-SIN_T0mT1_1)/2))) + ((A[0]*SIN_T0_1*((COS_T1pALPHA1_1+COS_T1mALPHA1_1)/2))>>>9) - ((D[0]*(( SIN_T1pALPHA1_1-SIN_T1mALPHA1_1)/2))) + ((A[1]*SIN_T1_1));
assign result1_1[2] =                                          ((A[0]*((-COS_T0pALPHA1_1+COS_T0mALPHA1_1)/2)))             + ((D[0]*COS_ALPHA1_1))                           +  (D[1]<<<9);


// pipeline 2
//---------------------------------------------------------------------
reg in_valid2;
reg signed [5:0] THETA2;
reg signed [10:0] COS_T2_2, SIN_T2_2;
reg signed [10:0] COS_ALPHA2_2, SIN_ALPHA2_2;
reg signed [10:0] SIN_T2pALPHA2_2, SIN_T2mALPHA2_2, COS_T2pALPHA2_2, COS_T2mALPHA2_2;
reg signed [14:0] result1_2 [0:2];

// in_valid2
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		in_valid2 <= 0;
	end
	else begin
		in_valid2 <= in_valid1;
	end
end

// THETA2
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		THETA2 <= 0;
	end
	else if(in_valid1) begin
		THETA2 <= THETA1[3];
	end
end

// COS and SIN T2/ALPHA2
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		COS_T2_2 <= 0;
		SIN_T2_2 <= 0;
		COS_ALPHA2_2 <= 0;
		SIN_ALPHA2_2 <= 0;
		SIN_T2pALPHA2_2 <= 0;
		SIN_T2mALPHA2_2 <= 0;
		COS_T2pALPHA2_2 <= 0;
		COS_T2mALPHA2_2 <= 0;
	end
	else if(in_valid1) begin
		COS_T2_2 <= COS_T2_1;
		SIN_T2_2 <= SIN_T2_1;
		COS_ALPHA2_2 <= COS_ALPHA2_1;
		SIN_ALPHA2_2 <= SIN_ALPHA2_1;
		SIN_T2pALPHA2_2 <= SIN_T2pALPHA2_1;
		SIN_T2mALPHA2_2 <= SIN_T2mALPHA2_1;
		COS_T2pALPHA2_2 <= COS_T2pALPHA2_1;
		COS_T2mALPHA2_2 <= COS_T2mALPHA2_1;
	end
end

// result1_2
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0; i<3; i=i+1) begin
			result1_2[i] <= 0;
		end
	end
	else if(in_valid1) begin
		result1_2[0] <= result1_1[0];
		result1_2[1] <= result1_1[1];
		result1_2[2] <= result1_1[2];
	end
end

wire signed [10:0] COS_T3_2, SIN_T3_2;
wire signed [10:0] COS_ALPHA3_2, SIN_ALPHA3_2;
wire signed [10:0] SIN_T3pALPHA3_2, SIN_T3mALPHA3_2, COS_T3pALPHA3_2, COS_T3mALPHA3_2;
wire signed [23:0] result2_2 [0:2];

DW_sincos #(6,11,1,1) COST3(.A(THETA2),.SIN_COS(1'b1),.WAVE(COS_T3_2));
DW_sincos #(6,11,1,1) SINT3(.A(THETA2),.SIN_COS(1'b0),.WAVE(SIN_T3_2));
			  
DW_sincos #(6,11,1,1) COSALPHA3(.A(ALPHA[3]),.SIN_COS(1'b1),.WAVE(COS_ALPHA3_2));
DW_sincos #(6,11,1,1) SINALPHA3(.A(ALPHA[3]),.SIN_COS(1'b0),.WAVE(SIN_ALPHA3_2));

DW_sincos #(6,11,1,1) SINT3pALPHA3(.A(THETA2+ALPHA[3]),.SIN_COS(1'b0),.WAVE(SIN_T3pALPHA3_2));
DW_sincos #(6,11,1,1) SINT3mALPHA3(.A(THETA2-ALPHA[3]),.SIN_COS(1'b0),.WAVE(SIN_T3mALPHA3_2));
																						
DW_sincos #(6,11,1,1) COST3pALPHA3(.A(THETA2+ALPHA[3]),.SIN_COS(1'b1),.WAVE(COS_T3pALPHA3_2));
DW_sincos #(6,11,1,1) COST3mALPHA3(.A(THETA2-ALPHA[3]),.SIN_COS(1'b1),.WAVE(COS_T3mALPHA3_2));

// assign result2_2[0] = ((result1_2[0]*COS_T2_2)>>>9) - ((result1_2[1]*SIN_T2_2*COS_ALPHA2_2)>>>18) + ((result1_2[2]*SIN_T2_2*SIN_ALPHA2_2)>>>18) + ((A[2]*COS_T2_2)<<<9);
// assign result2_2[1] = ((result1_2[0]*SIN_T2_2)>>>9) + ((result1_2[1]*COS_T2_2*COS_ALPHA2_2)>>>18) - ((result1_2[2]*COS_T2_2*SIN_ALPHA2_2)>>>18) + ((A[2]*SIN_T2_2)<<<9);
// assign result2_2[2] =                                 ((result1_2[1]*SIN_ALPHA2_2)>>>9)           + ((result1_2[2]*COS_ALPHA2_2)>>>9)           +  (D[2]<<<18)      ;

assign result2_2[0] = ((result1_2[0]*COS_T2_2)>>>9) - ((result1_2[1]*((SIN_T2pALPHA2_2+SIN_T2mALPHA2_2)/2))>>>9) + ((result1_2[2]*((-COS_T2pALPHA2_2+COS_T2mALPHA2_2)/2))>>>9) + ((A[2]*COS_T2_2));
assign result2_2[1] = ((result1_2[0]*SIN_T2_2)>>>9) + ((result1_2[1]*((COS_T2pALPHA2_2+COS_T2mALPHA2_2)/2))>>>9) - ((result1_2[2]*(( SIN_T2pALPHA2_2-SIN_T2mALPHA2_2)/2))>>>9) + ((A[2]*SIN_T2_2));
assign result2_2[2] =                                 ((result1_2[1]*SIN_ALPHA2_2)>>>9)                          + ((result1_2[2]*COS_ALPHA2_2)>>>9)                           +  (D[2]<<<9)      ;


// pipeline 3 
//---------------------------------------------------------------------
reg in_valid3;
reg signed [10:0] COS_T3_3, SIN_T3_3;
reg signed [10:0] COS_ALPHA3_3, SIN_ALPHA3_3;
reg signed [10:0] SIN_T3pALPHA3_3, SIN_T3mALPHA3_3, COS_T3pALPHA3_3, COS_T3mALPHA3_3;
reg signed [14:0] result2_3 [0:2];

// in_valid3
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		in_valid3 <= 0;
	end
	else begin
		in_valid3 <= in_valid2;
	end
end

// COS and SIN T3/ALPHA3
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		COS_T3_3 <= 0;
		SIN_T3_3 <= 0;
		COS_ALPHA3_3 <= 0;
		SIN_ALPHA3_3 <= 0;
		SIN_T3pALPHA3_3 <= 0;
		SIN_T3mALPHA3_3 <= 0;
		COS_T3pALPHA3_3 <= 0;
		COS_T3mALPHA3_3 <= 0;
	end
	else if(in_valid2) begin
		COS_T3_3 <= COS_T3_2;
		SIN_T3_3 <= SIN_T3_2;
		COS_ALPHA3_3 <= COS_ALPHA3_2;
		SIN_ALPHA3_3 <= SIN_ALPHA3_2;
		SIN_T3pALPHA3_3 <= SIN_T3pALPHA3_2;
		SIN_T3mALPHA3_3 <= SIN_T3mALPHA3_2;
		COS_T3pALPHA3_3 <= COS_T3pALPHA3_2;
		COS_T3mALPHA3_3 <= COS_T3mALPHA3_2;
	end
end

// result2_3
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0; i<3; i=i+1) begin
			result2_3[i] <= 0;
		end
	end
	else if(in_valid2) begin
		result2_3[0] <= result2_2[0];
		result2_3[1] <= result2_2[1];
		result2_3[2] <= result2_2[2];
	end
end

wire signed [23:0] result3_3 [0:2];

assign result3_3[0] = ((result2_3[0]*COS_T3_3)>>>9) - ((result2_3[1]*((SIN_T3pALPHA3_3+SIN_T3mALPHA3_3)/2))>>>9) + ((result2_3[2]*((-COS_T3pALPHA3_3+COS_T3mALPHA3_3)/2))>>>9) + ((A[3]*COS_T3_3));
assign result3_3[1] = ((result2_3[0]*SIN_T3_3)>>>9) + ((result2_3[1]*((COS_T3pALPHA3_3+COS_T3mALPHA3_3)/2))>>>9) - ((result2_3[2]*(( SIN_T3pALPHA3_3-SIN_T3mALPHA3_3)/2))>>>9) + ((A[3]*SIN_T3_3));
assign result3_3[2] =                                 ((result2_3[1]*SIN_ALPHA3_3)>>>9)                          + ((result2_3[2]*COS_ALPHA3_3)>>>9)                           +  (D[3]<<<9);


// output
//---------------------------------------------------------------------

// OUT_VALID
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		OUT_VALID <= 0;
	end
	else begin
		OUT_VALID <= in_valid3;
	end
end

// OUT_X, OUT_Y, OUT_Z
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		OUT_X <= 0;
		OUT_Y <= 0;
		OUT_Z <= 0;
	end
	else if(in_valid3) begin
		OUT_X <= result3_3[0]>>>4;
		OUT_Y <= result3_3[1]>>>4;
		OUT_Z <= result3_3[2]>>>4;
	end
	else begin
		OUT_X <= 0;
		OUT_Y <= 0;
		OUT_Z <= 0;
	end
end

endmodule