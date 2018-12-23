`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Design Name: 
// Module Name:    motor unit.v
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


// 
module motorunit (
    input   wire [31:0]  f_muscle_length,  // muscle length
    //input   [31:0]  vel,            // change of muscle length
    input   wire [31:0]  f_rawfr_Ia,     //
    input   wire [31:0]  f_pps_coef_Ia,  //
    input   wire [31:0]  half_cnt,
    input   wire rawclk,
    input   wire ti_clk,
    input   wire sim_clk,
    input   wire neuron_clk,
    input   wire reset_sim,
    input   wire signed [31:0] i_gain_MN,
    input   wire [NN+2:0] neuronCounter,
    input   wire [31:0]  gain,           // gain 
    input   wire [31:0] tau,
    //input   wire [31:0] f_len,

    output  wire [31:0]  f_total_force,  // output muscle force 
    output  wire [31:0]  i_emg,
    output  wire MN_spk,
    output  wire [15:0] spkid_MN
    );

    parameter NN = 8; // 2^(NN+1) = NUM_NEURON


    //wire MN_spk;
    //wire [15:0] spkid_MN;
	 
	wire signed [31:0] i_current_out;
	 
    neuron_pool #(.NN(NN)) big_pool
    (   .f_rawfr_Ia(f_rawfr_Ia),     //
        .f_pps_coef_Ia(f_pps_coef_Ia), //
        .half_cnt(half_cnt),
        .rawclk(rawclk),
        .ti_clk(ti_clk),
        .reset_sim(reset_sim),
        .i_gain_MN(i_gain_MN),
        .neuronCounter(neuronCounter),
        .MN_spike(MN_spk),
        .spkid_MN(spkid_MN),
		.i_current_out(i_current_out)

    );     
    wire    [31:0] i_MN_spkcnt;
    wire    dummy_slow;        
    spikecnt count_rawspikes
    (   .spike(MN_spk), 
        .int_cnt_out(i_MN_spkcnt), 
        .fast_clk(neuron_clk), 
        .slow_clk(sim_clk), 
        .reset(reset_sim), 
        .clear_out(dummy_slow));
    
  
   // *** Shadmehr muscle: spike_count_out => f_active_state => f_total_force
	 // Big motor neuron muscle
	wire    [31:0]  f_force;
    wire    [31:0]  f_actstate, f_MN_spkcnt;
	wire 	[63:0] t_spkcnt = i_MN_spkcnt*gain;
    shadmehr_muscle muscles
    (   .spike_cnt(t_spkcnt[31:0]),
        .pos(f_muscle_length),  // muscle length
        //.vel(current_vel),
        .vel(32'd0),
        .clk(sim_clk),
        .reset(reset_sim),
        .total_force_out(f_total_force),
        .current_A(f_actstate),
        .current_fp_spikes(f_MN_spkcnt),
		.tau(tau)
    );       

    // ** EMG

    wire [17:0] si_emg;
    emg #(.NN(NN)) emg
    (   .emg_out(si_emg), 
        .i_spk_cnt(i_MN_spkcnt[NN:0]), 
        .clk(sim_clk), 
        .reset(reset_sim) ); 
    //wire [31:0] i_emg;
    assign i_emg = {{14{si_emg[17]}},si_emg[17:0]};



endmodule

