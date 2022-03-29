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

output reg[8:0] out_n;
//================================================================
//    Wire & Registers 
//================================================================

// signed/unsigned
reg signed [4:0] n0, n1, n2, n3, n4, n5;

// merge sort
reg signed [4:0] a0, a1, a2, a3, a4, a5;
reg signed [4:0] b0, b1, b2, b3;
reg signed [4:0] c0, c1, c2, c3;
reg signed [4:0] d0, d1;
reg signed [4:0] e0, e1, e2, e3;
reg signed [4:0] f0, f1, f2, f3;
reg signed [4:0] sort0, sort1, sort2, sort3, sort4, sort5;

// normalization
reg signed [4:0] avg;
reg signed [4:0] norm0, norm1, norm2, norm3, norm4, norm5;

// equation
reg signed [9:0] equ1;

//================================================================
//    DESIGN
//================================================================

// signed/unsigned
always@* begin	
	n0 = {opt[0]&in_n0[3], in_n0};
	n1 = {opt[0]&in_n1[3], in_n1};
	n2 = {opt[0]&in_n2[3], in_n2};
	n3 = {opt[0]&in_n3[3], in_n3};
	n4 = {opt[0]&in_n4[3], in_n4};
	n5 = {opt[0]&in_n5[3], in_n5};	
end

// merge sort 1st level
always@* begin
	if(n0>n1) begin
		a0 = n1;
		a1 = n0;
	end
	else begin
		a0 = n0;
		a1 = n1;
	end
	
	if(n2>n3) begin
		a2 = n3;
		a3 = n2;
	end
	else begin
		a2 = n2;
		a3 = n3;
	end
	
	if(n4>n5) begin
		a4 = n5;
		a5 = n4;
	end
	else begin
		a4 = n4;
		a5 = n5;
	end
end

// merge sort 2nd level
always@* begin
	if(a0>a2) begin
		b0 = a2;
		b1 = a0;
	end
	else begin
		b0 = a0;
		b1 = a2;
	end
	
	if(a1>a3) begin
		b2 = a3;
		b3 = a1;
	end
	else begin
		b2 = a1;
		b3 = a3;
	end
end

// merge sort 3rd level
always@* begin
	if(b0>a4) begin
		c0 = a4;
		c1 = b0;
	end
	else begin
		c0 = b0;
		c1 = a4;
	end
	
	if(b1>b2) begin
		c2 = b2;
		c3 = b1;
	end
	else begin
		c2 = b1;
		c3 = b2;
	end
end

// merge sort 4th level
always@* begin
	if(c2>a5) begin
		d0 = a5;
		d1 = c2;
	end
	else begin
		d0 = c2;
		d1 = a5;
	end
end

// merge sort 5th level
always@* begin
	if(c1>c3) begin
		e0 = c3;
		e1 = c1;
	end
	else begin
		e0 = c1;
		e1 = c3;
	end
	
	if(d1>b3) begin
		e2 = b3;
		e3 = d1;
	end
	else begin
		e2 = d1;
		e3 = b3;
	end
end

// merge sort 6th level
always@* begin
	if(e0>d0) begin
		f0 = d0;
		f1 = e0;
	end
	else begin
		f0 = e0;
		f1 = d0;
	end
	
	if(e1>e2) begin
		f2 = e2;
		f3 = e1;
	end
	else begin
		f2 = e1;
		f3 = e2;
	end
end

// sort in descending order or ascending order
always@* begin 
	if(opt[1]==1'b1) begin
		sort0 = e3;
		sort1 = f3;
		sort2 = f2;
		sort3 = f1;
		sort4 = f0;
		sort5 = c0;
	end
	else begin
		sort0 = c0;
		sort1 = f0;
		sort2 = f1;
		sort3 = f2;
		sort4 = f3;
		sort5 = e3;
	end
end

// normalization
always@* begin
	//avg = (sort0+sort5) >>> 1;
	if(opt[2]==1'b1) begin
		avg = (sort0+sort5)/2;
	end
	else begin
		avg = 0;
	end
	
	norm0 = sort0 - avg;
	norm1 = sort1 - avg;
	norm2 = sort2 - avg;
	norm3 = sort3 - avg;
	norm4 = sort4 - avg;
	norm5 = sort5 - avg;
end

// equation calculation
always@* begin
	if(equ==1'b1) begin
		equ1 = (norm3+norm3+norm3-norm0*norm4);
		if(equ1[9]==1) begin
			out_n = ~(equ1-1);
		end
		else begin
			out_n = equ1;
		end
	end
	else begin
		out_n = (norm0-norm1*norm2+norm5)/3;
	end
end

endmodule