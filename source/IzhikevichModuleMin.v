//neuron components for simulation

`default_nettype none

module izSimulation(spikeCount_out, dataValid, neuronCounter, neuronID, v1, v2, v3, v4, s1, s2, s3, s4, neuronClock, neuronReset, Ia_bias, M1_bias, LLR, SLR, 
							gamma_plus, gamma_minus, w1_out, w2_out, SLR_reset, LLR_reset);

parameter random_seed = 15'h0;
parameter NN = 8;  // (log2(neuronCount) - 1)
output reg [NN:0] spikeCount_out;
output wire dataValid;
output wire signed [17:0] v1, v2,v3, v4;   // cell potentials
output wire s1, s2, s3, s4 ; //the action potentials (spikes)
output wire [NN:0] neuronID;
input [NN+2:0] neuronCounter;
input neuronClock;
input neuronReset, SLR_reset, LLR_reset; //reset all values, or just the weights for SLR and LLR
input signed [17:0] Ia_bias, M1_bias;
input signed [17:0] LLR;				//long latency reflex
input signed [17:0] SLR;				//short latency reflex
input [2:0] gamma_plus, gamma_minus;  //stdp learning rates for weight increase and decrease (log divisors)
output reg signed [17:0] w1_out, w2_out;

	wire [3:0] a1, b, a2;
	wire signed [17:0] c,d ; // parameters
	//wire signed [17:0] I1 ;      // current
	//wire signed [17:0] I2 ;      // current
	wire signed [17:0] neu1In, neu2In, neu3In, neu4In ; // total input current to each cell
	//wire signed [17:0] Ia_bias18, M1_bias18;

	// the clock divider and reset
	wire neuronWriteCount;
	///reg [NN:0] neuronIndex;			//defines total number of neuron blocks as power of 2
	wire [NN:0] neuronIndex;			//defines total number of neuron blocks as power of 2
	assign neuronID = neuronIndex;  
	reg [NN:0] spikeCount;		
	///wire [NN:0] idx;				//neuron address in memory
	wire neuronWriteEnable, readClock;
	reg firstNeuron ;
	//reg [14:0] lfsr, lfsr2, lfsr3, lfsr4;
	reg [127:0] lfsr, lfsr4;
	///reg [1:0] state;
	wire [1:0] state;
	wire state1, state2, state3, state4;
	wire Ia_drive, M1_drive;
	wire Ia, MN, SC1, M1;			//post-synaptic spikes
	wire signed [17:0] Ia_w1, Ia_w2, MN_w1, MN_w2, S1_w1, S1_w2, M1_w1, M1_w2;  //learned synaptic weights
	reg signed [17+NN+1:0] av_Ia_w1, av_Ia_w2, av_MN_w1, av_MN_w2, av_S1_w1, av_S1_w2, av_M1_w1, av_M1_w2;  //learned synaptic weight sums
	
	//state machine divides clock by 4
	///initial state = 0;
	///always @ (posedge neuronClock) state <= state + 1'b1;
	assign state = neuronCounter[1:0];
	assign neuronIndex = neuronCounter[NN+2:2];
	
	assign state1 = (state == 2'h0);
	assign state2 = (state == 2'h1);
	assign state3 = (state == 2'h2);
	assign state4 = (state == 2'h3);
	 
	assign neuronWriteCount = state1;	//increment neuronID (ram address)
	assign readClock = state2;				//read RAM
	assign neuronWriteEnable = state4; //(state3 | state4);	//write RAM
	assign dataValid = firstNeuron;  //(neuronIndex ==0) & state2; //(neuronIndex == 1);   //slight delay of positive edge to allow latch set-up times
		
	//neuron address latch
	///initial neuronIndex = 0;
	/*	
	always @ (posedge neuronWriteCount)
	begin
		spikeCount <= neuronReset? {(NN+1) {1'b0}} : ((neuronIndex =={{(NN){1'b0}}, 1'b1}) ? s2 : (spikeCount + s2));  //do this one late so spikeCount_out has a chance
		av_MN_w1 <= neuronReset? {(18+NN+1) {1'b0}} : (neuronIndex == {{(NN){1'b0}}, 1'b1}) ? {{(NN+1){1'b0}}, MN_w1} : (av_MN_w1 + {{(NN+1){1'b0}}, MN_w1});
		av_MN_w2 <= neuronReset? {(18+NN+1) {1'b0}} : (neuronIndex == {{(NN){1'b0}}, 1'b1}) ? {{(NN+1){1'b0}}, MN_w2} : (av_MN_w2 + {{(NN+1){1'b0}}, MN_w2});
		///neuronIndex <= (neuronIndex + 1'b1); 
	end
	*/
	
	always @ (negedge neuronClock)
	begin
		firstNeuron <= (neuronIndex == 0);
	end
		
	always @ (negedge neuronCounter[1])  //latch on every change in neuronIndex
	begin
		spikeCount <= neuronReset? 0 : (firstNeuron ? s2 : (spikeCount + s2));  //do this one late so spikeCount_out has a chance
		av_MN_w1 <= neuronReset? 0 : (firstNeuron ? MN_w1 : (av_MN_w1 + {{(NN+1){1'b0}}, MN_w1}));
		av_MN_w2 <= neuronReset? 0 : (firstNeuron ? MN_w2 : (av_MN_w2 + {{(NN+1){1'b0}}, MN_w2}));
		spikeCount_out <= neuronReset? 0 : (firstNeuron ? spikeCount : spikeCount_out);  //change this once for each cycle
		w1_out <= neuronReset? 0 : (firstNeuron ? av_MN_w1[17+NN+1:NN+1] : w1_out);  
		w2_out <= neuronReset? 0 : (firstNeuron ? av_MN_w2[17+NN+1:NN+1] : w2_out);
	end
	/*
	always @ (negedge neuronCounter[NN+2])  //neuronIndex[NN]) //latch once per cycle of all neurons
	begin
		spikeCount_out <= spikeCount;  //save this once for each cycle
		//choose weights for output display
		w1_out <= av_MN_w1[17+NN+1:NN+1];  
		w2_out <= av_MN_w2[17+NN+1:NN+1];
	end
	*/
	//assign idx = neuronIndex;
	
	//burster "chattering" parameters
	//assign a1 = 6 ;  // 0.016  = shift right by 6  (same for regular spiking)
	//assign b =  2 ;  // 0.25  = shift right by 2
	////numbers are all divided by 100, and +/- 1 is 0xffff, +/- 2 is 0x1ffff
	//assign c =  18'sh3_8000 ; // -0.5 = dec2hex(1+bitcmp(ceil(0.5 * hex2dec('ffff')),18))
	//assign d =  18'sh0_051E ; // 0.02 = dec2hex(floor(0.02 * hex2dec('ffff')))  
	//assign a2 = 6 ; 
	
	//fast spiking parameters
	assign a1 = 3 ;  // 0.125
	assign b =  2 ;  // 0.25
	assign c =  18'sh3_599A ; // -0.65  = dec2hex(1+bitcmp(ceil(0.65 * hex2dec('ffff')),18)) = 3599A
	assign d =  18'sh0_147A ; // 0.08 = dec2hex(floor(0.08 * hex2dec('ffff'))) = 147A
	assign a2 = 3 ;   //0.125
	
	// define and connect the neurons
	Iz_neuron #(.NN(NN),.DELAY(10)) neuIa(v1,s1, a1,b,c,d, neu1In, neuronClock, neuronReset, neuronIndex, neuronWriteEnable, readClock, 4'h2, Ia);
	Iz_neuron #(.NN(NN),.DELAY(10)) neuMN(v2,s2, a2,b,c,d, neu2In, neuronClock, neuronReset, neuronIndex, neuronWriteEnable, readClock, 4'h2, MN);
	Iz_neuron #(.NN(NN),.DELAY(10)) neuS1(v3,s3, a1,b,c,d, neu3In, neuronClock, neuronReset, neuronIndex, neuronWriteEnable, readClock, 4'h2, SC1);
	Iz_neuron #(.NN(NN),.DELAY(15)) neuM1(v4,s4, a2,b,c,d, neu4In, neuronClock, neuronReset, neuronIndex, neuronWriteEnable, readClock, 4'h2, M1);
	// cross-connections  (need to include delays)
							
	//this version using probability inputs
	//             Neuron   input weight      input weight	randomInput			timeConstant
	assign Ia_drive = ({2'b00,lfsr[15:0]} < Ia_bias) ? 1'b1 : 1'b0;
	assign M1_drive = ({2'b00,lfsr4[15:0]} < M1_bias) ? 1'b1 : 1'b0;

	synapse   #(.NN(NN)) synIa(neu1In, 	Ia_drive, 18'sh01000, 	1'b0, 	18'h0, 			1'b0, 	18'h0, Ia, 
								neuronClock, neuronReset, neuronIndex, neuronWriteEnable, readClock, gamma_plus, gamma_minus, Ia_w1, Ia_w2, 
								neuronReset, neuronReset);
	synapse   #(.NN(NN)) synMN(neu2In, s1,  		SLR, 				s4, 		18'sh02000, 	1'b0, 	18'h0, MN, 
								neuronClock, neuronReset, neuronIndex, neuronWriteEnable, readClock, gamma_plus, gamma_minus, MN_w1, MN_w2, 
								SLR_reset, neuronReset);
	synapse   #(.NN(NN)) synS1(neu3In, s1,  		18'sh0_F000, 	1'b0, 	18'h0, 			1'b0, 	18'h0, SC1, 
								neuronClock, neuronReset, neuronIndex, neuronWriteEnable, readClock, gamma_plus, gamma_minus, S1_w1, S1_w2, 
								neuronReset, neuronReset);
	synapse   #(.NN(NN)) synM1(neu4In, s3,  		LLR, 				1'b0, 	18'h0, 			M1_drive, 18'sh0C000, 	M1, 
								neuronClock, neuronReset, neuronIndex, neuronWriteEnable, readClock, gamma_plus, gamma_minus, M1_w1, M1_w2, 
								LLR_reset, neuronReset);
								
	//random number generator
	initial
			begin
				lfsr <= 128'h333333333333333333333333333332ff + random_seed;
				lfsr4 <= 128'h333333333333333333333333333332ff + random_seed;
			end

	always @ (posedge readClock)
		begin
			lfsr <= neuronReset ? (128'h333333333333333333333333333332ff + random_seed) : {lfsr[126:0], (lfsr[127] ^ lfsr[125] ^ lfsr[100] ^ lfsr[98])};
			lfsr4 <= neuronReset ? (128'h333333333333333333333333333332ff + random_seed) : {lfsr4[126:0], (lfsr4[127] ^ lfsr4[125] ^ lfsr4[100] ^ lfsr4[98])};
		end

endmodule

////////////////////////////////////////
//// Synapse ///////////////////////////
////////////////////////////////////////
// Acts to create an exponentially falling current at the output 
// from a spike input and a weight which can be +/-
// up to three spike inputs are defined, each with its own weight
module synapse_v(out,s1,w1,s2,w2,s3,w3,body,clk,reset,idx, enable, read, gamma_plus, gamma_minus, stdp_w1, stdp_w2, stdp_w1_reset, stdp_w2_reset);
	parameter NN = 8;  // (log2(neuronCount) - 1)
	output wire signed [17:0] out; 				//the simulated current
	input s1,s2,s3;     			// the action potential inputs
	input signed [17:0] w1,w2,w3;   //weights
	input body;					//postsynaptic spike
	input clk, reset, enable, read, stdp_w1_reset, stdp_w2_reset;
	input [NN:0] idx;		//TDS: neuron index (memory address)
	input [2:0] gamma_plus, gamma_minus;		//TDS: decay time constant = 2^tau timesteps
	output signed [17:0] stdp_w1, stdp_w2;			//actual weights

	wire signed [17:0] r1_out, r2_out, r3_out, r4_out, r1_mem, r2_mem, r3_mem, r4_mem;
	wire [8:0] body_trace, syn1_trace, syn2_trace, syn3_trace;  //stdp decay terms
	//wire [17:0] stdp_w1, stdp_w2;			//actual weights
	wire [8:0] body_trace_out, syn1_trace_out, syn2_trace_out, syn3_trace_out;  //stdp decay terms
	wire signed [17:0] stdp_w1_out, stdp_w2_out, stdp_w1_calc, stdp_w2_calc;			//actual weights
	wire memclk;
	
	//maintain "traces" that are decaying functions of the last spike time
	//if spike comes in then reset count, otherwise multiply by 0.875 = 0.5 + 0.25 + 0.125
	assign body_trace_out = reset ? 9'sh000 : (body ? 9'sh0ff : ((body_trace >>> 1) + (body_trace >>> 2) + (body_trace >>> 3)));
	assign syn1_trace_out = reset ? 9'sh000 : (s1 ? 9'sh0ff : ((syn1_trace >>> 1) + (syn1_trace >>> 2) + (syn1_trace >>> 3)));
	assign syn2_trace_out = reset ? 9'sh000 : (s2 ? 9'sh0ff : ((syn2_trace >>> 1) + (syn2_trace >>> 2) + (syn2_trace >>> 3)));
	assign syn3_trace_out = reset ? 9'sh000 : (s3 ? 9'sh0ff : ((syn3_trace >>> 1) + (syn3_trace >>> 2) + (syn3_trace >>> 3)));	//not used
	
	//spike-timing-dependent-plasticity  (only on the first two synapses)
	//  delta_w = gamma * (synapse_trace - body_trace); 
	//  ie:  if body fires, then add if synapse_trace>0 (must have been preceding input spike).
	//			if synapse fires, then subtract if body_trace>0 (must have been preceding postsynaptic spike).
	//	  also have slow baseline decay term on weights.  Combine decay from both weights to give competition between synapses
	assign stdp_w1_calc = stdp_w1 + {9'sh000, (body ? (syn1_trace >> gamma_plus): 9'h000)} - {9'sh000, (s1 ? (body_trace >> gamma_minus) : 9'sh000) }; //- (stdp_w1 >>> 16) - (stdp_w2 >>> 16) 
	assign stdp_w2_calc = stdp_w2 + {9'sh000, (body ? (syn2_trace >> gamma_plus): 9'h000)} - {9'sh000, (s2 ? (body_trace >> gamma_minus) : 9'sh000) }; //- (stdp_w1 >>> 16) - (stdp_w2 >>> 16) 
	assign stdp_w1_out =  reset ? w1 : ((stdp_w1_calc[17]) ? stdp_w1 : stdp_w1_calc);  //reset to default input values //(reset || stdp_w1_reset)
	assign stdp_w2_out =  reset ? w2 : ((stdp_w2_calc[17]) ? stdp_w2 : stdp_w2_calc);  //make sure does not go negative //(reset || stdp_w2_reset)
	
	//save everything to RAM on each cycle
	assign r1_out = {body_trace_out, syn1_trace_out};
	assign r2_out = {syn2_trace_out, syn3_trace_out};
	assign r3_out = stdp_w1_out;
	assign r4_out = stdp_w2_out;
	
	//read from RAM on each cycle
	assign body_trace = r1_mem[17:9];
	assign syn1_trace = r1_mem[8:0];
	assign syn2_trace = r2_mem[17:9];
	assign syn3_trace = r2_mem[8:0];
	assign stdp_w1 = reset ? w1 : r3_mem;
	assign stdp_w2 = reset ? w2 : r4_mem;
	
	//use dual-ported ram so we can have 4 words
	assign memclk = ~clk;
	ram2port synapse_RAM1 (.clock(memclk), .data1(r1_out), .data2(r2_out), .address1({idx,1'b0}), .address2({idx, 1'b1}), 
						.wren(enable), .q1(r1_mem), .q2(r2_mem));
	ram2port synapse_RAM2 (.clock(memclk), .data1(r3_out), .data2(r4_out), .address1({idx,1'b0}), .address2({idx, 1'b1}), 
						.wren(enable), .q1(r3_mem), .q2(r4_mem));


	//assign out = (s1?w1:0)+(s2?w2:0)+(s3?w3:0) ; 
	assign out = (s1?stdp_w1:0);//syn1_trace_out; 
endmodule


//////////////////////////////////////////////////

//////////////////////////////////////////////////
//// Izhikevich neuron ///////////////////////////
//////////////////////////////////////////////////
// Modified to eliminate two of the multiplies
// Since a and b need not be very precise 
// and because 0.02<a<0.2 and 0.1<b<0.3
// Treat the a and b inputs as an index do determine how much to 
// shift the intermediate results
// treat the a input as value>>>a with a=1 to 7
// treat the b input as value>>>b with b=1 to 3

module Iz_neuron(out,spike_delayed,a,b,c,d,I,clk,reset,idx, enable, read, tau, spike, neuronWriteCount);
	parameter NN = 8;  // (log2(neuronCount) - 1)
	parameter DELAY = 18;  //1 to 18
	output [17:0] out; 				//the simulated membrane voltage
	output spike_delayed, spike ;     				// the action potential output
	input signed [17:0] c, d, I;   //a,b,c,d set cell dynamics, I is the input current
	input [3:0] a, b ;
	input clk, reset, enable, read;
	input [NN:0] idx;		//TDS: neuron index (memory address)
	input [3:0] tau;		//TDS: decay time constant = 2^tau timesteps
    input wire neuronWriteCount;

	wire signed	[17:0] spikes, u1;
	wire signed	[17:0] u1reset, v1new, u1new, du1, v1, u1_mem, v1_mem, spike_list_mem;
	wire signed	[17:0] v1xv1, v1xb;
	wire signed	[17:0] p, c14;
	wire signed [17:0] u1_final, v1_final, spike_list_final;   // saved cell potentials
	wire signed [17:0] epsp_new, epsp_mem, epsp_final;
	wire memclk;

	//memory for current membrane state variables
	assign memclk = ~clk;
	//ram1port v1_RAM (.clock(memclk), .data(v1_final), .address(idx), .wren(enable), .q(v1_mem));
	//ram1port u1_RAM (.clock(memclk), .data(u1_final), .address(idx), .wren(enable), .q(u1_mem));
	ram2port uv_RAM (.clock(memclk), .data1(v1_final), .data2(u1_final), .address1({idx,1'b0}), .address2({idx, 1'b1}), 
						.wren(enable), .q1(v1_mem), .q2(u1_mem));
	//ram1port axon (.clock(memclk), .data(spike_list_final), .address(idx), .wren(enable), .q(spike_list_mem));
	//ram1port epsp_RAM (.clock(memclk), .data(epsp_final), .address(idx), .wren(enable), .q(epsp_mem));
	ram2port axon_epsp_RAM (.clock(memclk), .data1(spike_list_final), .data2(epsp_final), 
									.address1({idx, 1'b0}), .address2({idx, 1'b1}), 
									.wren(enable), .q1(spike_list_mem), .q2(epsp_mem));

	assign out = v1_mem;
	assign spike = ((v1_mem > p)&&~neuronWriteCount) ? 1'b1 : 1'b0;
	assign spikes = spike_list_mem;
	assign u1 = u1_mem;
	assign v1 = out;  //to use single-step integration
	assign p =  18'sh0_4CCC ; // 0.30  = spike threshold
		
	//epsp is low-pass filtered version of input current I
	// dt = 1/16 or 2>>4 and tau=1
	// v1(n+1) = v1(n) + dt/tau*(-v1(n)+s1*w1+s2*w2+s3*w3)
	assign epsp_new = epsp_mem + ((-epsp_mem)>>>tau) + I ; //v1>>>4 originally
	assign epsp_final = reset ? 18'sh0 : epsp_new;

	//*** Main neuron calculations
	// dt = 1/16 or 2>>4, but note that base timescale is 1msec, so really dt = 0.001 / 16
	// v1(n+1) = v1(n) + dt*(4*(v1(n)^2) + 5*v1(n) +1.40 - u1(n) + I)
	// but note that what is actually coded is
	// v1(n+1) = v1(n) + (v1(n)^2) + 5/4*v1(n) +1.40/4 - u1(n)/4 + I/4)/4	
	
	assign c14 = 18'sh1_6666; // 1.4
	signed_mult v1sq(v1xv1, v1, v1);
	assign v1new = v1 + (v1xv1<<<2) + v1+(v1<<<2) + c14 - u1 + I; //I;  //1msec sample (no dt term)
		
	// u1(n+1) = u1 + dt*a*(b*v1(n) - u1(n))
	assign v1xb = v1>>>b;         //mult (v1xb, v1, b);
	assign du1 = (v1xb-u1)>>>a ;  //mult (du1, (v1xb-u1), a);
	//assign u1new = u1 + (du1>>>4) ; 
	assign u1new = u1 + du1 ; 
	assign u1reset = u1 + d ;
	
	//*** next membrane values to write to RAM
	assign v1_final = reset ? 18'sh3_4CCD : (spike ? c : v1new);
	assign u1_final = reset ? 18'sh3_CCCD : (spike ? u1reset : u1new);  //v1new instead of out?
	assign spike_list_final = reset ? 18'h0000 : {spikes[16:0], spike};
	assign spike_delayed = reset ? 1'b0 : spikes[DELAY-1];  //delayed output of neuron (18msec max)
	
endmodule
//////////////////////////////////////////////////


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

///////////////////////////////////////////////
// same, but give full 32-bit output with same normalization
// this is equivalent to a 2.34 format 2'comp
//////////////////////////////////////////////
module signed_mult32 (out, a, b);

	output 	signed	[35:0]	out;
	input 	signed	[35:0] 	a;
	input 	signed	[35:0] 	b;
	
	wire 	signed	[35:0]	mult_out, out;
	wire 	signed 	[17:0] 	tempa, tempb;

	assign tempa = a[35:18];
	assign tempb = b[35:18];
	assign mult_out = tempa * tempb;
	assign out = {mult_out[35], mult_out[32:0], 2'b00};
endmodule

//////////////////////////////////////////////////
//wrapper to make Xilinx ram look like Altera ram
//

module ram1port (
	address,
	clock,
	data,
	wren,
	q);

	parameter MM = 9;  // (log2(neuronCount) - 1)
	input	[MM:0]  address;
	input	  clock;
	input	[17:0]  data;
	input	  wren;
	output	[17:0]  q;

//  RAMB16_S18 : In order to incorporate this function into the design,
//   Verilog   : the following instance declaration needs to be placed
//  instance   : in the body of the design code.  The instance name
// declaration : (RAMB16_S18_inst) and/or the port declarations within the
//    code     : parenthesis may be changed to properly reference and
//             : connect this function to the design.  All inputs
//             : and outputs must be connected.

//  <-----Cut code below this line---->

   // RAMB16_S18: Virtex-II/II-Pro, Spartan-3/3E 1k x 16 + 2 Parity bits Single-Port RAM
   // Xilinx HDL Language Template, version 9.2.4i

	wire [15:0] DO;
	wire [1:0] DOP;
	wire [15:0] DI;
	wire [1:0] DIP;
	wire [9:0] addr;
	assign q = {DOP, DO};
	assign DI = data[15:0];
	assign DIP = data[17:16];
	assign addr = address;  //in case addr has smaller number of bits

	
   RAMB16_S18 #(
      .INIT(18'h00000),   // Value of output RAM registers at startup
      .SRVAL(18'h00000), // Output value upon SSR assertion
      .WRITE_MODE("NO_CHANGE") // WRITE_FIRST, READ_FIRST or NO_CHANGE
   ) RAMB16_S18_inst (
      .DO(DO),      // 16-bit Data Output
      .DOP(DOP),    // 2-bit parity Output
      .ADDR(addr),  // 10-bit Address Input
      .CLK(clock),    // Clock
      .DI(DI),      // 16-bit Data Input
      .DIP(DIP),    // 2-bit parity Input
      .EN(1'b1),      // RAM Enable Input
      .SSR(1'b0),    // Synchronous Set/Reset Input
      .WE(wren)       // Write Enable Input
   );

   // End of RAMB16_S18_inst instantiation

endmodule							
	
//
//same thing for dual-port ram
//
module ram2port (
	address1, address2,
	clock,
	data1, data2,
	wren,
	q1, q2);

	parameter MM = 9;  // (log2(neuronCount) - 1) memory size, not #neurons...
	input	[MM:0]  address1, address2;
	input	  clock;
	input	[17:0]  data1, data2;
	input	  wren;
	output	[17:0]  q1, q2;

//  RAMB16BWE_S18_S18 : In order to incorporate this function into the design,
//     Verilog        : the following instance declaration needs to be placed
//    instance        : in the body of the design code.  The instance name
//   declaration      : (RAMB16BWE_S18_S18_inst) and/or the port declarations within the
//      code          : parenthesis may be changed to properly reference and
//                    : connect this function to the design.  All inputs
//                    : and outputs must be connected.

//  <-----Cut code below this line---->

   // RAMB16BWE_S18_S18: 1k x 16 + 2 Parity bits Dual-Port byte-wide write RAM
   //                    Spartan-3A
   // Xilinx HDL Language Template, version 10.1
	wire [15:0] DOA, DOB;
	wire [1:0] DOPA, DOPB;
	wire [15:0] DIA, DIB;
	wire [1:0] DIPA, DIPB;
	wire [9:0] ADDRA, ADDRB;
	
	assign q1 = {DOPA, DOA};
	assign DIA = data1[15:0];
	assign DIPA = data1[17:16];
	assign ADDRA = address1;  //in case addr has smaller number of bits
	
	assign q2 = {DOPB, DOB};
	assign DIB = data2[15:0];
	assign DIPB = data2[17:16];
	assign ADDRB = address2;  //in case addr has smaller number of bits

   RAMB16_S18_S18 #(
      .INIT_A(18'h00000),  // Value of output RAM registers on Port A at startup
      .INIT_B(18'h00000),  // Value of output RAM registers on Port B at startup
      .SRVAL_A(18'h00000), // Port A output value upon SSR assertion
      .SRVAL_B(18'h00000), // Port B output value upon SSR assertion
      .WRITE_MODE_A("NO_CHANGE"), // WRITE_FIRST, READ_FIRST or NO_CHANGE
      .WRITE_MODE_B("NO_CHANGE")
)	RAMB16_S18_S18_inst (
      .DOA(DOA),      // Port A 16-bit Data Output
      .DOB(DOB),      // Port B 16-bit Data Output
      .DOPA(DOPA),    // Port A 2-bit Data Parity Output
      .DOPB(DOPB),    // Port B 2-bit Data Parity Output
      .ADDRA(ADDRA),  // Port A 10-bit Address Input
      .ADDRB(ADDRB),  // Port B 10-bit Address Input
      .CLKA(clock),    // Port A 1-bit Clock
      .CLKB(clock),    // Port B 1-bit Clock
      .DIA(DIA),      // Port A 16-bit Data Input
      .DIB(DIB),      // Port B 16-bit Data Input
      .DIPA(DIPA),    // Port A 2-bit parity Input
      .DIPB(DIPB),    // Port-B 2-bit parity Input
      .ENA(1'b1),      // Port A 1-bit RAM Enable Input
      .ENB(1'b1),      // Port B 1-bit RAM Enable Input
      .SSRA(1'b0),    // Port A 1-bit Synchronous Set/Reset Input
      .SSRB(1'b0),    // Port B 1-bit Synchronous Set/Reset Input
      .WEA(wren),      // Port A 2-bit Write Enable Input
      .WEB(wren)       // Port B 2-bit Write Enable Input
   );

   // End of RAMB16BWE_S18_S18_inst instantiation
endmodule
