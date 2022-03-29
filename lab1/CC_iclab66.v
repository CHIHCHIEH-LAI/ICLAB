module CC(
	in_n0,
	in_n1, 
	in_n2, 
	in_n3, 
    in_n4, 
	in_n5, 
	opt,
    equ,
	out_n
);
//================================================================
//    INPUT AND OUTPUT DECLARATION                         
//================================================================
input [3:0] in_n0, in_n1, in_n2, in_n3, in_n4, in_n5;
input [2:0] opt;
input equ;

output [8:0] out_n;
//================================================================
//    Wire & Registers 
//================================================================

// signed/unsigned
wire signed [4:0] n0, n1, n2, n3, n4, n5;

// merge sort
wire signed [4:0] a0, a1, a2, a3, a4, a5;
wire signed [4:0] b0, b1, b2, b3, b4, b5;
wire signed [4:0] c0, c1, c2, c3, c4, c5;
wire signed [4:0] d0, d1, d2, d3;
wire signed [4:0] e0, e1;
wire signed [4:0] sort0, sort1, sort2, sort3, sort4, sort5;

// normalization
wire signed [4:0] avg;
wire signed [4:0] norm0, norm1, norm2, norm3, norm4, norm5;

// equation calculation
wire signed [4:0] g0, g1;
wire signed [9:0] h0;
wire signed [9:0] i0;

//================================================================
//    DESIGN
//================================================================

// signed/unsigned	
assign n0 = {opt[0]&in_n0[3], in_n0};
assign n1 = {opt[0]&in_n1[3], in_n1};
assign n2 = {opt[0]&in_n2[3], in_n2};
assign n3 = {opt[0]&in_n3[3], in_n3};
assign n4 = {opt[0]&in_n4[3], in_n4};
assign n5 = {opt[0]&in_n5[3], in_n5};

// merge sort 1st level
assign a0 = (n0>n1) ? n1 : n0;
assign a1 = (n0>n1) ? n0 : n1;

assign a2 = (n2>n3) ? n3 : n2;
assign a3 = (n2>n3) ? n2 : n3;

assign a4 = (n4>n5) ? n5 : n4;
assign a5 = (n4>n5) ? n4 : n5;

// merge sort 2nd level
assign b0 = (a0>a2) ? a2 : a0;
assign b1 = (a0>a2) ? a0 : a2;

assign b2 = (a1>a4) ? a4 : a1;
assign b3 = (a1>a4) ? a1 : a4;

assign b4 = (a3>a5) ? a5 : a3;
assign b5 = (a3>a5) ? a3 : a5;

// merge sort 3rd level
assign c0 = (b0>b2) ? b2 : b0;
assign c1 = (b0>b2) ? b0 : b2;

assign c2 = (b1>b4) ? b4 : b1;
assign c3 = (b1>b4) ? b1 : b4;

assign c4 = (b3>b5) ? b5 : b3;
assign c5 = (b3>b5) ? b3 : b5;

// merge sort 4th level
assign d0 = (c1>c2) ? c2 : c1;
assign d1 = (c1>c2) ? c1 : c2;

assign d2 = (c3>c4) ? c4 : c3;
assign d3 = (c3>c4) ? c3 : c4;

// merge sort 5th level
assign e0 = (d1>d2) ? d2 : d1;
assign e1 = (d1>d2) ? d1 : d2;

// sort in descending order or ascending order
assign sort0 = opt[1] ? c5 : c0;
assign sort1 = opt[1] ? d3 : d0;
assign sort2 = opt[1] ? e1 : e0;
assign sort3 = opt[1] ? e0 : e1;
assign sort4 = opt[1] ? d0 : d3;
assign sort5 = opt[1] ? c0 : c5;

// normalization
assign avg = opt[2] ? (sort0+sort5)/2 : 0;

assign norm0 = sort0 - avg;
assign norm1 = sort1 - avg;
assign norm2 = sort2 - avg;
assign norm3 = sort3 - avg;
assign norm4 = sort4 - avg;
assign norm5 = sort5 - avg;

// equation calculation mult section
assign g0 = equ ? norm0 : norm1;
assign g1 = equ ? norm4 : norm2;

assign h0 = g0 * g1;

// equation calculation minus section
assign i0 = equ ? norm3*3 - h0 : norm0+norm5 - h0;

// output
assign out_n = equ ? (i0[9] ? -i0 : i0) : i0/3;

endmodule