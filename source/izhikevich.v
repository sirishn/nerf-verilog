`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:08:40 06/06/2011 
// Design Name: 
// Module Name:    pipe_in_wave_2048 
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
//////////////////////////////////////////////////
//// signed mult of 2.16 format 2'comp////////////
//////////////////////////////////////////////////

module signed_mult (out, a, b);

	output 	signed	[17:0]	out;
	input 	signed	[17:0] 	a;
	input 	signed	[17:0] 	b;
	
	wire	signed	[17:0]	out;
	wire 	signed	[35:0]	mult_out;

	assign mult_out = a * b;
	assign out = {mult_out[35], mult_out[32:16]};
endmodule


module Iz_neuron_single(a, b, c, d, I1, tau, clk, reset, action_potential, recovery_potential, spike_delayed, spike);
    input [3:0] a;
    input [3:0] b;
    input signed [17:0] c;
    input signed [17:0] d;
    input signed [17:0] I1;   //a,b,c,d set cell dynamics, I1 is the input current = 100 * I
    input [3:0] tau;    	//TDS: decay time constant = 2^tau timesteps

    input wire clk;
    input wire reset;
    
    output wire [17:0] action_potential;			
    output wire [17:0] recovery_potential;			
    output wire spike_delayed;
    output wire spike;  				
    parameter DELAY = 18;  //1 to 18

	//parameter NN = 8;  // (log2(neuronCount) - 1)

	wire signed	[17:0] spike_list, u1, du1, u1reset, u1new;
	wire signed	[17:0] v1new, v1;
	reg signed [17:0] v1_mem, u1_mem, spike_list_mem, epsp_mem;
	
	wire signed	[17:0] v1xv1, v1xb;
	wire signed [17:0] u1_final, v1_final, spike_list_final;   // state variables ready to be saved
	wire signed	[17:0] p, c14;
    assign p =  18'sh0_4CCC ; // threshold of membrane potential = 0.30 x 100mv 
    assign c14 = 18'sh1_6666; // 1.4 x 100mv

	wire signed [17:0] epsp_new, epsp_final;
	wire memclk;
        
    // *** Output bundle
	always @ (posedge clk or posedge reset)
	begin
        if (reset)
		begin
            v1_mem <= 18'sh3_4CCD; // -0.70 x 100mv x 0xFFFF, Default value of v1
            u1_mem <= 18'sh3_CCCD;  // -0.20 x 100mv x 0xFFFF, default value of u1
            spike_list_mem <= 18'h0000;
            epsp_mem <= 18'sh0;
		end
        else
        begin
            v1_mem <= v1_final;
            u1_mem <= u1_final;
            spike_list_mem <= spike_list_final;
            epsp_mem <= epsp_final;
        end
	end	
    assign action_potential = spike ? p : v1_mem;
    assign recovery_potential = u1_mem;

    // === Re-capture the state variables
	assign spike_list = spike_list_mem;
    assign u1 = u1_mem;
	assign v1 = v1_mem;  //to use single-step integration
    assign spike = (v1 > p) ? 1'b1 : 1'b0;
    assign spike_delayed = reset ? 1'b0 : spike_list[DELAY-1];  //delayed output of neuron (18msec max)

        
     
    // *** Izhikevich integrations for v1:
    // Izhikevich original for v:
    // v' = 0.04*v^2 + 5*v + 140 - u + I
    // Rescaling v,u,i that v = 100*v1, u = 100*u1, I = 100*I1, therefore:
    // v1' = 4*v1^2 + 5*v1 + 140 - u1 + I1 (Minos checked the math)
    // v1 = v1 + dt*(4*v1^2 + 5*v1 + 140 - u1 + I1)
    // Assume dt = 1 ms, then:
    // v1(n+1) = v1(n) + 4*v1(n)^2 + 5*v1(n) + 1.4 - u1(n) + I1(n)
    // Minos - Terry got it right
	signed_mult v1sq(v1xv1, v1, v1);
	//assign v1new = v1 + (v1xv1<<<2) + v1+(v1<<<2) + c14 - u1 + epsp_mem; //I;  //1msec sample (no dt term)
	assign v1new = v1 + (v1xv1<<<2) + v1+(v1<<<2) + c14 - u1 + I1;  //1msec sample (no dt term)
		
    // *** Izhikevich integrations for u1:
    // Izhikevich original for u:
    // u' = a(bv - u)
    // Rescaling v,u,i that v = 100*v1, u = 100*u1, therefore:
    // u1' = a(bv1 - u1)
	// u1(n+1) = u1 + dt*a*(b*v1(n) - u1(n))
    // Assume d1 = 1 ms, then:
    // u1(n+1) = u1 + a*(b*v1(n) - u1(n))
    
	assign v1xb = v1>>>b;         //mult (v1xb, v1, b);
	assign du1 = (v1xb-u1)>>>a ;  //mult (du1, (v1xb-u1), a);
	assign u1new = u1 + du1 ; 
	assign u1reset = u1 + d ;

	// *** Nerf version of EPSP
	assign epsp_new = epsp_mem + ((-epsp_mem)>>>tau) + I1 ; //v1>>>4 originally
	assign epsp_final = reset ? 18'sh0 : epsp_new;

	// *** next state variables ready to save
    assign v1_final = spike ? c : v1new; // -0.70 x 100mv, Default value of v1
	assign u1_final = spike ? u1reset : u1new;  // -0.20 x 100mv, default value of u1
	assign spike_list_final = {spike_list[16:0], spike};
	
endmodule
