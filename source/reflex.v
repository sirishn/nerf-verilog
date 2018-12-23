//high level simulation of the reflex loop, including muscle and spindle simulation
//
`default_nettype none

module reflexloop(emg1, torque1, spikes1, pos1_in, vel1_in, 
						emg2, torque2, spikes2, pos2_in, vel2_in, 
						torque1_2,
						Ia_bias1, M1_bias1, LLR1, SLR1, gamma1, gammaD1, 
						Ia_bias2, M1_bias2, LLR2, SLR2, gamma2, gammaD2,
						dataValid, neuronReset, nClock, rawspikes, g_plus, g_minus, 
						w1a_out, w2a_out, w1b_out, w2b_out,
						pos1_out, vel1_out, pos2_out, vel2_out, acc_out, ext_torque, SLR_reset, LLR_reset, dynamics_error);
						
	parameter NN = 8;  // (log2(neuronCount) - 1)
	input neuronReset, nClock, SLR_reset, LLR_reset;
	input signed [17:0] M1_bias1, Ia_bias1, LLR1, gamma1, gammaD1, M1_bias2, Ia_bias2, LLR2, gamma2, gammaD2;
	input signed [17:0] SLR1, SLR2;
	input signed [17:0] pos1_in, vel1_in, pos2_in, vel2_in;
//	output signed [17:0] pos1_out, vel1_out, pos2_out, vel2_out;
	output [31:0] pos1_out, vel1_out, pos2_out, vel2_out, acc_out;
	
//	output signed [17:0] emg1, torque1, emg2, torque2;
	output [17:0] emg1, emg2;

//	output reg [31:0] torque1, torque2;
	output [31:0] torque1, torque2;
	output [31:0] torque1_2;
	
	output [NN:0] spikes1, spikes2;
	output dataValid;
	output reg signed [17:0] rawspikes;
	input [2:0] g_plus, g_minus;
	output signed [17:0] w1a_out, w2a_out, w1b_out, w2b_out;
//	input signed [17:0] ext_torque;
	input [31:0] ext_torque;
	
	output [1:0] dynamics_error;
//	wire [1:0] dynamics_error;
	
	
	wire [NN:0] neuronID1, neuronID2;
	wire signed [17:0] v1a, v2a, v3a, v4a;
	wire signed [17:0] v1b, v2b, v3b, v4b;
	wire signed [17:0] Ia1, Ia2;
	wire s1a, s2a, s3a, s4a;
	wire s1b, s2b, s3b, s4b;
//	wire signed [17:0] pos1, vel1, pos2, vel2;
	wire [31:0] pos1, vel1, pos2, vel2;
	
//	wire signed [17:0] pos1_calc, pos2_calc, vel1_calc, vel2_calc;
	wire [31:0] pos1_calc, pos2_calc, vel1_calc, vel2_calc;
	
	wire blockClock, muscleClock1, muscleClock2, plantClock;
	reg [NN+2:0] neuronCounter;
	wire spikeValid1, spikeValid2, muscleValid1, muscleValid2, plantValid;

initial neuronCounter = 0;
always @ (posedge nClock) neuronCounter <= neuronCounter + 1'b1;
assign blockClock  = (neuronID2 == {(NN+1){1'b0}})? 1'b1 : 1'b0;  // rising edge on every new block of 1024 neuron groups, delayed just to be safe
assign dataValid = blockClock;
assign muscleClock1 = spikeValid1; //~neuronCounter[NN+2];  //rising edge 1 clock cycle after spikes are latched
assign muscleClock2 = spikeValid2; //~neuronCounter[NN+2];  //rising edge 1 clock cycle after spikes are latched

//assign plantClock = muscleValid1 & muscleValid2;
assign plantClock = muscleClock1 & muscleClock2;

//each izSimulation runs a full cycle of 1024 blocks and returns the total #spikes over the cycle
izSimulation #(.random_seed(15'h1000), .NN(NN)) izSim1(spikes1, spikeValid1, neuronCounter, neuronID1, v1a, v2a, v3a, v4a, s1a, s2a, s3a, s4a, 
						nClock, neuronReset, Ia1, M1_bias1, LLR1, SLR1, g_plus, g_minus, w1a_out, w2a_out, SLR_reset, LLR_reset);
izSimulation #(.random_seed(15'h1100), .NN(NN)) izSim2(spikes2, spikeValid2, neuronCounter, neuronID2, v1b, v2b, v3b, v4b, s1b, s2b, s3b, s4b, 
						nClock, neuronReset, Ia2, M1_bias2, LLR2, SLR2, g_plus, g_minus, w1b_out, w2b_out, SLR_reset, LLR_reset);
						
//send out the individual spikes at the full neuronclock rate
always @(negedge neuronID1[0]) rawspikes <= {1'b0, neuronID1[NN:2], s1a, s2a, s3a, s4a, s1b, s2b, s3b, s4b};

//muscles spindles and plant dynamics update their outputs once per full block of 1024 neuron groups
///muscle #(.NN(NN)) biceps(emg1, torque1, spikes1, pos1, vel1, blockClock, neuronReset);
///muscle #(.NN(NN)) triceps(emg2, torque2, spikes2, pos2, vel2, blockClock, neuronReset);

//muscle #(.NN(NN)) biceps(emg1, torque1, spikes1, pos1, vel1, muscleClock1, muscleValid1, nClock, neuronReset);
//muscle #(.NN(NN)) triceps(emg2, torque2, spikes2, pos2, vel2, muscleClock2, muscleValid2, nClock, neuronReset);

fp_muscle #(.NN(NN)) biceps(emg1, torque1, spikes1, pos1, vel1, muscleClock1, muscleValid1, nClock, neuronReset);
fp_muscle #(.NN(NN)) triceps(emg2, torque2, spikes2, pos2, vel2, muscleClock2, muscleValid2, nClock, neuronReset);

/*
wire [31:0] torque2_out;
wire [1:0] mult1_error;
fp_mult mult1 (torque2_out, mult1_error, ext_torque, 32'h40000000);
always @ (posedge spikeValid1) torque1<=ext_torque;
always @ (posedge spikeValid2) torque2<=torque2_out;
*/

//spindle Ia_biceps(Ia1, pos1, vel1, gamma1, gammaD1, Ia_bias1);
//spindle Ia_triceps(Ia2, pos2, vel2, gamma2, gammaD2, Ia_bias2);

wire [31:0] pos_default, vel_default;
assign pos_default = 0;
assign vel_default = 0;


fpu_plant Dynamics(pos1_calc, pos2_calc, vel1_calc, vel2_calc, acc_out, torque1_2, torque1, torque2, ext_torque, 
	 neuronReset, plantClock, nClock, pos_default, vel_default, plantValid, dynamics_error );	
	 
//fpu_plant Dynamics(pos1_calc, pos2_calc, vel1_calc, vel2_calc, torque1, torque2, ext_torque, 
//	 neuronReset, plantClock, nClock, pos_default, vel_default, plantValid, dynamics_error );	
	 
//plant #(.NN(NN)) Dynamics(pos1_calc, pos2_calc, vel1_calc, vel2_calc,
//				torque1, torque2, ext_torque, 
//				pos1_in, vel1_in, neuronReset, plantClock, nClock, plantValid); //blockClock);  //pos1,vel1 is biceps, which correlates + with elbow angle
				
//change the following 4 lines to switch between external and internal dynamics models	
//assign pos1 = pos1_in;  //pos1_calc for the internal model, pos1_in for the external model
//assign pos2 = pos2_in;
//assign vel1 = vel1_in;
//assign vel2 = vel2_in;

assign pos1 = pos1_calc;  //pos1_calc for the internal model, pos1_in for the external model
assign pos2 = pos2_calc;	//note that calc model reverses the directions
assign vel1 = vel1_calc;
assign vel2 = vel2_calc;

//sends this back out so can compare  (swapped numbering)
assign pos1_out = pos1_calc;
assign pos2_out = pos2_calc;
assign vel1_out = vel1_calc;
assign vel2_out = vel2_calc;

endmodule

///////////////////////////////
//very simple spindle model
//   takes incoming Ia_bias (usually zero) and adds bias based on p, v, and gamma
//   p, v are relative to muscle.  positive for stretch. p=0 at rest length
//   p = 7fff and v= 7fff are max length and max velocity for muscle
//
module spindle(Ia_bias_out, pos, vel, gammaS, gammaD, Ia_bias);
	output signed [17:0] Ia_bias_out;
	input signed [17:0] pos, vel;
	input signed [17:0] gammaS, gammaD, Ia_bias;
	
	wire signed [17:0] p1, v1;  //r1
	wire signed [17:0] mult_out1, mult_out2;
	
	assign p1 = (pos>(18'sh0)) ? pos : 18'sh00000;  //threshold really should be tunable
	assign v1 = (vel>(18'sh0)) ? vel : 18'sh00000;
	signed_mult spindle_mult1(mult_out1, gammaS, (p1>>>5));
	signed_mult spindle_mult2(mult_out2, gammaD, (v1>>>3));
	
	assign Ia_bias_out = Ia_bias + mult_out1 + mult_out2;  //watch out for overflow!
endmodule

///////////////////////////////////
//very simple muscle and emg model
//  models active-state, but needs to have position and velocity inputs
//  works at 1msec resolution
//  outputs are latched on positive edge of clk
//
module muscle(emg_out, torque_out, spikes, pos, vel, inputValid, outputValid, clk, reset);
	parameter NN = 8;  // (log2(neuronCount) - 1)
	output signed  [17:0] emg_out, torque_out;
	input  [NN:0] spikes;
	input signed [17:0] pos, vel;  //in direction of extension of the muscle
	input  inputValid, clk, reset;
	output reg outputValid;
	
	reg signed [35:0] emg_hp, emg_lp;
	reg signed [35:0] activestate_lp; //first-order filters
	wire signed [35:0] pos_long, vel_long;
	//wire signed [17:0] as_lp;
	wire [35:0] stimulus, spikes_long;
	wire signed [35:0] emg_long;
	reg signed [35:0] torque;
	
	//reg [35:0] last_stimulus;
	assign spikes_long = {{(35-NN) {1'b0}}, spikes};
	assign pos_long = {pos, 18'h00000};
	assign vel_long = {vel, 18'h00000}; 
	assign stimulus = (spikes_long <<< 7);  //{{(29-NN) {1'b0}}, spikes, 7'h00};
	//assign emg_out = spikes_long[24:7]; //emg_long[24:7];
	assign emg_long = emg_lp - emg_hp;
	assign emg_out = emg_long[17:0]; //[24:7]; //spikes_long[8:0];
	//assign emg_out[17:9] = 9'h00;
	assign torque_out = (torque[35]) ? 18'sh00000: torque[35:18];  //muscles cannot push
	//assign as_lp = activestate_lp[35:18];
	
	// hill model from Shadmehr and Wise supplementary materials
	// dT/dt = (Kse/b) ( Kpe(x-x0) + bdx/dt - (1+Kpe/Kse)T + A)
	//  frog leg:  Kse = 136 g/cm, Kpe = 75 g/cm, b = 50 g.s/cm
	//  so approx:  dT = dt * (256p + 128v -4T + 2A + A)
	//       where p = x-x0 in cm, v in cm/sec  dt in sec (=1/1024)  T and A in kg
	
	always @(posedge inputValid)
	begin
		activestate_lp <= reset ? 36'h000000000 : (activestate_lp - (activestate_lp >>> 7) + (stimulus<<<11));  //0.02 at 500msec  (twitch duration)
		emg_hp <= reset ? 36'h0 : (emg_hp + (stimulus >>> 4) - (emg_hp >>> 4)); //TDS 8-17-08 + ((-last_stimulus) >>>4); //0.04 at 25 msec  (40hz hp)
		emg_lp <= reset ? 36'h0 : (emg_lp - (emg_lp >>> 2) + (stimulus >>> 2)); 			//stimulus;  // (1khz lp)  
		///emg_long <= emg_lp - emg_hp;
		
		//last_stimulus <= reset ? 36'h0 : stimulus;
		////torque <= reset ? 18'h0 : torque + (({pos, 10'h00} >>>9) + ({vel, 10'h00} >>>10)) + ((-torque)>>>8) + (stimulus>>>8) + (stimulus>>>9);
		////torque <= reset ? 18'h0 : torque + ((pos >>>8) + (vel >>>9)) + ((-torque)>>>8) + (stimulus>>>7) + (stimulus>>>8);
		//torque <= reset ? 18'h0 : torque + ((pos >>>9) + (vel >>>10)) + ((-torque)>>>4) + (stimulus>>>5) + (stimulus>>>6);  //should use activestate_lp
		//torque <= reset ? 18'h00000 : (torque + ((pos >>>9) + (vel >>>10)) + ((-torque)>>>4) + {5'b0, activestate_lp[35:23]} + {6'b0, activestate_lp[35:24]}); //(as_lp>>>5) + (as_lp>>>6));  
		torque <= reset ? 36'h0 : (torque - (torque >>> 8) + (activestate_lp >>> 5) + (activestate_lp >>> 6));  //+ (pos_long >>>4) + (vel_long >>>5) 
	end
	
	//set data valid one clock cycle after the latch
	always @(posedge clk) outputValid <= inputValid;  //waits one clock cycle after inputValid
endmodule
