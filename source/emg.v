`timescale 1ns / 1ps

module emg(emg_out, i_spk_cnt, clk, reset);
	parameter NN = 8;  // (log2(neuronCount) - 1)
	output wire signed  [17:0] emg_out;
	input wire [NN:0] i_spk_cnt;
	input wire  clk, reset;
	
	reg signed [35:0] emg_hp, emg_lp;
	wire [35:0] stimulus, emg_stimulus;
	reg [35:0]	spikes_long;
	wire signed [35:0] emg_long;

	assign emg_stimulus = (spikes_long <<< 8);  //{{(29-NN) {1'b0}}, spikes, 7'h00};
	//assign emg_stimulus = (spikes_long);  //{{(29-NN) {1'b0}}, spikes, 7'h00};
	assign stimulus = spikes_long;

	assign emg_long = emg_lp - emg_hp;
	assign emg_out = emg_long[17:0]; 
	
	always @(posedge clk or posedge reset)
	begin
		spikes_long <= reset? 0:	{{(35-NN) {1'b0}}, i_spk_cnt};
		emg_hp <= reset ? 36'h0 : (emg_hp + (emg_stimulus >>> 4) - (emg_hp >>> 4)); //TDS 8-17-08 + ((-last_stimulus) >>>4); //0.04 at 25 msec  (40hz hp)
		emg_lp <= reset ? 36'h0 : (emg_lp - (emg_lp >>> 2) + (emg_stimulus >>> 2)); 			//stimulus;  // (1khz lp)  
	end

endmodule
