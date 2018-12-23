`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Design Name: 
// Module Name:    muscle 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////


// Difference eq. description of active_state, see Shadmehr h(x) & nerf-py/muscle/gen_active_force.py
module h_diff_eq(x_i1, x_i2, y_i1, y_i2, y_i);
    input signed		 [31:0] x_i1, x_i2;
    input signed   	 [31:0] y_i1, y_i2;
    output signed  	 [31:0] y_i;

    wire signed [31:0] a0, a1, a2, b1, b2;
	 wire signed [31:0] t1, t2, t3, t4;
	 wire [31:0] t1_2, t3_4;
	 
	 assign b1 = 32'h400BD70A; //2.185 
    assign b2 = 32'hC00B4396; //-2.176 
	 assign a0 = 32'h3F800000; //1.0
    assign a1 = 32'hBFF89375; //-1.942 
    assign a2 = 32'h3F716873; //0.943 

//    assign t1 = b1 * x_i1;
//    assign t2 = b2 * x_i2;
//    assign t3 = a1 * y_i1;
//    assign t4 = a2 * y_i2;
	 mult mult1(.x(b1), .y(x_i1), .out(t1));
	 mult mult2(.x(b2), .y(x_i2), .out(t2));
	 mult mult3(.x(a1), .y(y_i1), .out(t3));
	 mult mult4(.x(a2), .y(y_i2), .out(t4));

    //assign y_i = t1 + t2 - t3 - t4;
	 add	add1(.x(t1), .y(t2), .out(t1_2));
	 add	add2(.x(t3), .y(t4), .out(t3_4));
	 sub 	sub1(.x(t1_2), .y(t3_4), .out(y_i));
	 
endmodule

// fuglevand twitch model.  
//  Z / (Z - a)^2, a= e^(-T_twitch/tau_twitch) 
module fuglevand_twitch(x_i1, x_i2, y_i1, y_i2, y_i, tau);
    input signed		 [31:0] x_i1, x_i2;
    input signed   	 [31:0] y_i1, y_i2;
    output signed  	 [31:0] y_i;

    wire signed [31:0] a0, a1, a2, b1, b2;
	 wire signed [31:0] t1, t2, t3, t4;
	 wire [31:0] t1_2, t3_4;
	 
	 input [31:0] tau;  // contraction time ~in < 100ms
	 wire signed [31:0] A_twitch, euler_e, P_unscaled, P, T_twitch;
	 wire signed [31:0] Pe, T_div_tau, neg_T_div_tau, neg_2a, A_twitch_sq, neg1, neg2, TA, PeTA, PeTA_div_tau;
	 
	 assign T_twitch = 32'h3A83126F; // 0.001
	 assign euler_e = 32'h402DF3B6; //2.718
	 assign P = 32'h3F800000; // 1 (arbitary)
	 assign neg1 = 32'hBF800000;  // -1
	 assign neg2 = 32'hC0000000; //-2
	 
	 //assign P = P_unscaled <<< 10;
	 
	 
	 div div_fuglevand1(.x(T_twitch), .y(tau), .out(T_div_tau));  //   T/tau
	 mult mult_neg(.x(neg1), .y(T_div_tau), .out(neg_T_div_tau)); //  -T/tau
	 exp exp_fuglevand(.x(neg_T_div_tau), .out(A_twitch));    //       A_twitch ~= e^(-T/tau)
	 
	 mult mult_fuglevand1(.x(P), .y(euler_e), .out(Pe));
	 mult mult_fuglevand2(.x(T_twitch), .y(A_twitch), .out(TA));
	 mult mult_fuglevand3(.x(Pe), .y(TA), .out(PeTA));  
	 
	 div  div_fuglevand2(.x(PeTA), .y(tau), .out(PeTA_div_tau));  // PeTA/ tau
	 
	 
	 mult mult_fublevanda1(.x(A_twitch), .y(neg2), .out(neg_2a));   // -2a
	 mult mult_fuglevanda2(.x(A_twitch), .y(A_twitch), .out(A_twitch_sq)); // a^2
	  
	 assign b1 = PeTA_div_tau; //
    assign b2 = 32'h0; // 0  
	 assign a0 = 32'h3F800000; //1.0
    assign a1 = neg_2a; // 
    assign a2 = A_twitch_sq; // 

//    assign t1 = b1 * x_i1;
//    assign t2 = b2 * x_i2;
//    assign t3 = a1 * y_i1;
//    assign t4 = a2 * y_i2;
	 mult mult1(.x(b1), .y(x_i1), .out(t1));
	 mult mult2(.x(b2), .y(x_i2), .out(t2));
	 mult mult3(.x(a1), .y(y_i1), .out(t3));
	 mult mult4(.x(a2), .y(y_i2), .out(t4));

	 wire signed [31:0] y_i_raw; 
    //assign y_i = t1 + t2 - t3 - t4;
	 add	add1(.x(t1), .y(t2), .out(t1_2));
	 add	add2(.x(t3), .y(t4), .out(t3_4));
	 sub 	sub1(.x(t1_2), .y(t3_4), .out(y_i));
	 //assign y_i = y_i_raw <<< 5;   // multiply by 64
	 
endmodule



module shadmehr_active_force(spikes, active_force_out, fp_spikes_out, clk, reset, tau);
	//parameter NN = 8;  // (log2(neuronCount) - 1)
	output   [31:0] fp_spikes_out;  // not used..
	output reg [31:0]	active_force_out;
	input  [31:0] spikes;
	input  clk, reset;
	input  [31:0] tau;

    reg [31:0]  spikes_i1, spikes_i2, h_i1, h_i2; 
    wire    [31:0]  spikes_i, h_i, emg_out;
    //assign  spikes_i = spikes * 32'sd1024;// 32'sd128;
	int_to_float get_fp_spike(.out(spikes_i), .in(spikes * 32'd1024));
	 
	
    //h_diff_eq gen_h(spikes_i1, spikes_i2, h_i1, h_i2, h_i);
	 fuglevand_twitch twitch(spikes_i1, spikes_i2, h_i1, h_i2, h_i, tau);
	 
	 
	 
    assign emg_out = spikes_i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            spikes_i1 <= 32'd0;
            spikes_i2 <= 32'd0;
            h_i1 <= 32'd0;
            h_i2 <= 32'd0;
			active_force_out <= 32'd0;
        end
        else begin
            spikes_i1 <= spikes_i;
            spikes_i2 <= spikes_i1;
            h_i1 <= h_i;
            h_i2 <= h_i1;
			active_force_out <= h_i;
        end
    end

endmodule


// *** Shadmehr muscle: spike_cnt => current_total_force
module shadmehr_muscle(spike_cnt, pos, vel, clk, reset, total_force_out, current_A, current_fp_spikes, tau);
    input [31:0] spike_cnt;
    input [31:0] pos, vel;
    input clk;
    input reset;
	 input [31:0] tau;
    output [31:0] total_force_out;
    output [31:0] current_A;
    output [31:0] current_fp_spikes;
    
    //wire [31:0] spike_cnt, pos, vel, total_force_out; // necessary?

    wire    [31:0]  current_h, current_fp_spikes;
    shadmehr_active_force active1
    (		.spikes(spike_cnt), 
			.active_force_out(current_h), 
			.fp_spikes_out(current_fp_spikes), 
			.clk(clk),
			.reset(reset),
			.tau(tau)
    );
        
    wire 	[31:0]	weightout, current_A;
    
    s_weight  s_func (	.x_i(pos), .weight(weightout));
    mult		multA(.x(weightout), .y(current_h), .out(current_A));
	  
		  
    wire    [31:0]  current_dT;
    shadmehr_total_force total1
    (       .A(current_A),
            .pos(pos),
            .vel(vel),
            .total_force_out(total_force_out),
            .dT_out(current_dT),
            .clk(clk),
            .reset(reset)
    );

endmodule

module s_weight(x_i, weight);
	input		[31:0]	x_i; 	// length 
	output	[31:0]	weight;		// input to shadmehr_total_force
	//input		clk, reset;
	wire		[31:0]	temp_weight1, temp_weight2;
	wire 		[31:0]	out1, out2, out3, out4, out5;
	wire 		[31:0]	w_i, weight;
	wire		[31:0]	minus4, eight, three, two, point5, one;

	assign minus4	 = 32'hC0800000; // -4
	assign eight	 = 32'h41000000; // +8
	assign three 	 = 32'h40400000;  // +3
	assign two 		 = 32'h40000000; // +2
	
	assign point5	 = 32'h3F000000; //+0.5
	assign one 		= 	32'h3F800000; //+1.0
	
//	//assign 	temp_weight1= -4.0*x**2 + 8.0*x-3.0;
		mult 	mult_a(.x(x_i), 	.y(x_i), 	.out(out1));
		mult 	mult_b(.x(minus4),.y(out1), 	.out(out2));//-4
		mult	mult_c(.x(eight), .y(x_i),		.out(out3));//8
		add	add_a( .x(out2), 	.y(out3), 	.out(out4)); //4
		sub	sub_a( .x(out4),	.y(three), 	.out(temp_weight1)); //1
	
	//	//assign 	temp_weight2 = -x**2 + 2.0*x
		mult	mult_e(.x(x_i), .y(two), .out(out5));
		sub	sub_b(.x(out5), .y(out1), .out(temp_weight2)); 
		
		assign weight=(x_i<=point5)? 32'd0: (x_i<=one)? temp_weight1: (x_i<=two)? temp_weight2: 32'd0;
		//assign weight = temp_weight1;  //for the time being.
endmodule 

    
module     shadmehr_total_force(A, pos,vel,total_force_out, dT_out, clk,reset);
    input   [31:0]  A;
    input   [31:0]  pos;
    input   [31:0]  vel;
    output  [31:0]  total_force_out, dT_out;
    input   clk, reset;

    wire    [31:0]  dT_i_F0, T_i_F0;
	reg 	[31:0] 	dT_i, T_i, T_i1;

    d_force get_dt_i
    (   .T_i(T_i),
        .x_i(pos),
        .dx_i(vel),
        .A_i(A),
        .dT_i(dT_i_F0)
    );
	 
   
    // *** Integrate dT_i => T_i

    integrator int_dT_i
    (
        .x(dT_i),
        .int_x(T_i),
        .out(T_i_F0)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            T_i <= 32'd0;
            dT_i    <= 32'd0;
        end
        else begin
            T_i <= T_i_F0;
            dT_i    <= dT_i_F0;
        end
    end
    assign  total_force_out = T_i;
    assign  dT_out = dT_i;



endmodule



module d_force (T_i, x_i, dx_i, A_i, dT_i);
    input   [31:0]  T_i;
    input   [31:0]  x_i;
    input   [31:0]  dx_i;  
    input   [31:0]  A_i;   
    output  [31:0]  dT_i;
    
    wire    [31:0]  dx_2_LLLR4, dx_2_LLL3, dx_2_LLR3, dx_2_LL2, dx_2_LR2, dx_2_L1,  dx_2_R1, dx_2_F0;
    wire    [31:0]  x0, Kse_x_Kpe_o_b, Kse, Kse_o_b_m_one_p_Kpe_o_Kse, Kpe_o_b;
 
    assign x0 = 32'h3F800000; //1.0
    assign Kse_x_Kpe_o_b = 32'h434C0000;    // Kse*Kpe/b = 204.0
    assign Kse =   32'h43080000;        // Kse = 136.0
    assign Kse_o_b_m_one_p_Kpe_o_Kse =  32'h40870A3D; //Kse/b*(1+Kpe/Kse) = 4.22
    assign Kpe_o_b = 32'h402E147B;   // Kse/b = 2.72
    
 
    //if x1 > x0:
    //dT_i = Kse / b * (Kpe * (x1 - x0) + b * rate_change_x - (1 + Kpe/Kse)*T_0 + A)   # passive + active = total
    //SIMPLFIED: exp = "204.0*(x_i-x0)+136*dx_i-4.22*T_i+2.72*A_i"
     //     x_i     ----    x0    =>    dx_2_LLLR4
    sub dx_2_LLLR4_sub( .x(x_i), .y(x0), .out(dx_2_LLLR4) );

     //     204.0     ****    dx_2_LLLR4    =>    dx_2_LLL3
    mult dx_2_LLL3_mult( .x(Kse_x_Kpe_o_b), .y(dx_2_LLLR4), .out(dx_2_LLL3) );

     //     136     ****    dx_i    =>    dx_2_LLR3
    mult dx_2_LLR3_mult( .x(Kse), .y(dx_i), .out(dx_2_LLR3) );

     //     dx_2_LLL3     ++++    dx_2_LLR3    =>    dx_2_LL2
    add dx_2_LL2_add( .x(dx_2_LLL3), .y(dx_2_LLR3), .out(dx_2_LL2) );

     //     4.22     ****    T_i    =>    dx_2_LR2
    mult dx_2_LR2_mult( .x(Kse_o_b_m_one_p_Kpe_o_Kse), .y(T_i), .out(dx_2_LR2) );

     //     dx_2_LL2     ----    dx_2_LR2    =>    dx_2_L1
    sub dx_2_L1_sub( .x(dx_2_LL2), .y(dx_2_LR2), .out(dx_2_L1) );

     //     2.72     ****    A_i    =>    dx_2_R1
    mult dx_2_R1_mult( .x(Kpe_o_b), .y(A_i), .out(dx_2_R1) );

     //     dx_2_L1     ++++    dx_2_R1    =>    dx_2_F0
    add dx_2_F0_add( .x(dx_2_L1), .y(dx_2_R1), .out(dx_2_F0) );
 
    //assign dT_i = (T_i[31]) ? 32'd0 : dx_2_F0;
    assign dT_i = dx_2_F0;
 
endmodule 


module d_force_simple (T_i, x_i, dx_i, A_i, dT_i);
    input   [31:0]  T_i;
    input   [31:0]  x_i;
    input   [31:0]  dx_i;  
    input   [31:0]  A_i;   
    output  [31:0]  dT_i;
    
    wire    [31:0]  x0, dx_2_LLLR4, dx_2_LLL3, dx_2_LLR3, dx_2_LL2, dx_2_LR2, dx_2_L1,  dx_2_R1;
    wire    [31:0]  Kse_x_Kpe_o_b, Kse, Kse_o_b_m_one_p_Kpe_o_Kse, Kpe_o_b;

    assign x0 = 32'h3F800000; //1.0
    assign Kse_x_Kpe_o_b = 32'h434C0000;    // Kse*Kpe/b = 204.0
    assign Kse =   32'h43080000;        // Kse = 136.0
    assign Kse_o_b_m_one_p_Kpe_o_Kse =  32'h40870A3D; //Kse/b*(1+Kpe/Kse) = 4.22
    assign Kpe_o_b = 32'h402E147B;   // Kse/b = 2.72
    

    //if x1 > x0:
    //dT_i = Kse / b * (Kpe * (x1 - x0) + b * rate_change_x - (1 + Kpe/Kse)*T_0 + A)   # passive + active = total
    //SIMPLFIED: exp = "204.0*(x_i-x0)+136*dx_i-4.22*T_i+2.72*A_i"
        //     x_i 	----	x0    =>    dx_2_LLLR4
    //sub dx_2_LLLR4_sub( .x(x_i), .y(x0), .out(dx_2_LLLR4) );

     //     204.0 	****	dx_2_LLLR4    =>    dx_2_LLL3
    //mult dx_2_LLL3_mult( .x(Kse_x_Kpe_o_b), .y(dx_2_LLLR4), .out(dx_2_LLL3) );

     //     136 	****	dx_i    =>    dx_2_LLR3
    //mult dx_2_LLR3_mult( .x(Kse), .y(dx_i), .out(dx_2_LLR3) );

     //     dx_2_LLL3 	++++	dx_2_LLR3    =>    dx_2_LL2
    //add dx_2_LL2_add( .x(dx_2_LLL3), .y(dx_2_LLR3), .out(dx_2_LL2) );

     //     4.22 	****	T_i    =>    dx_2_LR2
    mult dx_2_LR2_mult( .x(Kse_o_b_m_one_p_Kpe_o_Kse), .y(T_i), .out(dx_2_LR2) );

     //     dx_2_LL2 	----	dx_2_LR2    =>    dx_2_L1
    //sub dx_2_L1_sub( .x(dx_2_LL2), .y(dx_2_LR2), .out(dx_2_L1) );

     //     2.72 	****	A_i    =>    dx_2_R1
    mult dx_2_R1_mult( .x(Kpe_o_b), .y(A_i), .out(dx_2_R1) );

     //     dx_2_L1 	++++	dx_2_R1    =>    dx_2_F0
    sub dx_2_F0_sub( .x(dx_2_R1), .y(dx_2_LR2), .out(dT_i) );

        
    //else:
        //dT_i = Kse / b * (b * rate_change_x - (1 + Kpe/Kse) * T_0 + A)

endmodule

