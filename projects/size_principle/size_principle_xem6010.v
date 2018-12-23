`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Creator: C. Minos Niu
// 
// Module Name:    
// Project Name: 
// Target Devices: XEM6010 - OpalKelly
// Design properties: xc6slx150-2fgg484
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module size_principle_xem6010(
	input  wire [7:0]  hi_in,
	output wire [1:0]  hi_out,
	inout  wire [15:0] hi_inout,
	inout  wire        hi_aa,

	output wire        i2c_sda,
	output wire        i2c_scl,
	output wire        hi_muxsel,
	input  wire        clk1,
	input  wire        clk2,
	
	output wire [7:0]  led,
    output wire pin0,
    output wire pin1,
    output wire pin2
   );
   
    parameter NN = 8;
		
    // *** Dump all the declarations here:
    wire         ti_clk;
    wire [30:0]  ok1;
    wire [16:0]  ok2;   
    wire [15:0]  ep00wire, ep01wire, ep02wire, ep50trig, ep20wire, ep21wire, ep22wire, ep23wire;
    wire [15:0]  ep24wire, ep25wire, ep26wire, ep27wire, ep28wire, ep29wire, ep30wire, ep31wire;
    wire reset_global, reset_sim;
    wire        is_pipe_being_written, is_lce_valid;
    
    wire [15:0] hex_from_py;
    
    reg [17:0] delay_cnt, delay_cnt_max;
    
    reg [15:0] rawspikes;
    wire pipe_out_read;
 
    // *** Target interface bus:
    assign i2c_sda = 1'bz;
    assign i2c_scl = 1'bz;
    assign hi_muxsel = 1'b0;

  // *** Buttons, physical on XEM3010, software on XEM3050 & XEM6010
    // *** Reset & Enable signals
    assign reset_global = ep00wire[0];
    assign reset_sim = ep00wire[1];

    //assign enable_sim = is_waveform_valid;
    wire    [31:0]  IEEE_1, IEEE_0;
	assign IEEE_1 = 32'h3F800000;
	assign IEEE_0 = 32'd0;

    // *** Triggered input from Python
    always @(posedge ep50trig[0] or posedge reset_global)
    begin
        if (reset_global)
            delay_cnt_max <= delay_cnt_max;
        else
            delay_cnt_max <= {2'b00, ep01wire};  //firing rate
    end
    
    
    reg [31:0] f_pps_coef_Ia;
    always @(posedge ep50trig[1] or posedge reset_global)
    begin
        if (reset_global)
            f_pps_coef_Ia <= 32'h3F66_6666;
        else
            f_pps_coef_Ia <= {ep02wire, ep01wire};  //firing rate
    end       
//    
//    reg [31:0] f_pps_coef_II;
//    always @(posedge ep50trig[2] or posedge reset_global)
//    begin
//        if (reset_global)
//            f_pps_coef_II <= 32'h3F66_6666;
//        else
//            f_pps_coef_II <= {ep02wire, ep01wire};  //firing rate
//    end           
//    



    reg [31:0] tau;
    always @(posedge ep50trig[2] or posedge reset_global)
    begin
        if (reset_global)
            tau <= 32'd1; // gamma_sta reset to 80
        else
            tau <= {ep02wire, ep01wire};  
    end      
//    

    reg [31:0] gain;
    always @(posedge ep50trig[3] or posedge reset_global)
    begin
        if (reset_global)
            gain <= 32'd0;
        else
            gain <= {ep02wire, ep01wire};  //firing rate
    end        
    
    reg [31:0] f_gamma_dyn;
    always @(posedge ep50trig[4] or posedge reset_global)
    begin
        if (reset_global)
            f_gamma_dyn <= 32'h42A0_0000; // gamma_dyn reset to 80
        else
            f_gamma_dyn <= {ep02wire, ep01wire};  
    end  
    
    reg [31:0] f_gamma_sta;
    always @(posedge ep50trig[5] or posedge reset_global)
    begin
        if (reset_global)
            f_gamma_sta <= 32'h42A0_0000; // gamma_sta reset to 80
        else
            f_gamma_sta <= {ep02wire, ep01wire};  
    end  
    
    reg signed [31:0] i_gain_mu1_MN;
    always @(posedge ep50trig[6] or posedge reset_global)
    begin
        if (reset_global)
            i_gain_mu1_MN <= 32'd1; // gamma_sta reset to 80
        else
            i_gain_mu1_MN <= {ep02wire, ep01wire};  
    end
	 
    reg signed [31:0] i_gain_mu2_MN;
    always @(posedge ep50trig[7] or posedge reset_global)
    begin
        if (reset_global)
            i_gain_mu2_MN <= 32'd1; // gamma_sta reset to 80
        else
            i_gain_mu2_MN <= {ep02wire, ep01wire};  
    end  

    reg signed [31:0] i_gain_mu3_MN;
    always @(posedge ep50trig[8] or posedge reset_global)
    begin
        if (reset_global)
            i_gain_mu3_MN <= 32'd1; // gamma_sta reset to 80
        else
            i_gain_mu3_MN <= {ep02wire, ep01wire};  
    end  
	 
//    
//    reg [31:0] delay_cnt_max;
//    always @(posedge ep50trig[7] or posedge reset_global)
//    begin
//        if (reset_global)
//            delay_cnt_max <= delay_cnt_max;
//        else
//            delay_cnt_max <= {ep02wire, ep01wire};  //firing rate
//    end        
//    
    reg [31:0] BDAMP_1, BDAMP_2, BDAMP_chain, GI, GII;
    always @(posedge ep50trig[15] or posedge reset_global)
    begin
        if (reset_global)
            BDAMP_1 <= 32'h3E71_4120; // bag 1 BDAMP reset to 0.2356
        else
            BDAMP_1 <= {ep02wire, ep01wire};  //firing rate
    end
    always @(posedge ep50trig[14] or posedge reset_global)
    begin
        if (reset_global)
            BDAMP_2 <= 32'h3D14_4674; // bag 2 BDAMP reset to 0.0362
        else
            BDAMP_2 <= {ep02wire, ep01wire};  //firing rate
    end    
    always @(posedge ep50trig[13] or posedge reset_global)
    begin
        if (reset_global)
            BDAMP_chain <= 32'h3C58_44D0; // chain BDAMP reset to 0.0132 
        else
            BDAMP_chain <= {ep02wire, ep01wire};  //firing rate
    end
    
    // *** Deriving clocks from on-board clk1:
    wire neuron_clk, sim_clk, spindle_clk;
    wire [NN+2:0] neuronCounter;

    gen_clk #(.NN(NN)) useful_clocks
    (   .rawclk(clk1), 
        .half_cnt(delay_cnt_max), 
        .clk_out1(neuron_clk), 
        .clk_out2(sim_clk), 
        .clk_out3(spindle_clk),
        .int_neuron_cnt_out(neuronCounter) );
                
    
    // *** Generating waveform to stimulate the spindle
    wire    [31:0] f_pos_elbow;
    waveform_from_pipe_bram_2s    generator(
                                .reset(reset_sim),
                                .pipe_clk(ti_clk),
                                .pipe_in_write(is_pipe_being_written),
                                .pipe_in_data(hex_from_py),
                                .pop_clk(sim_clk),
                                .wave(f_bicepsfr_Ia)
    );  


//    waveform_from_pipe_2k gen(	
//        .ti_clk(ti_clk),
//        .reset(reset_global),
//        .repop(reset_sim),
//        .feed_data_valid(is_pipe_being_written),
//        .feed_data(hex_from_py),
//        .current_element(f_bicepsfr_Ia),
//        .test_clk(sim_clk),
//        .done_feeding(is_lce_valid)
//    );      




    // *** Spindle: f_muscle_len => f_rawfr_Ia
    // Get biceps muscle length from joint angle
    wire    [31:0]  f_len, IEEE_1p57, IEEE_2p77;
    assign IEEE_1p57 = 32'h3FC8F5C3; 
    assign IEEE_2p77 = 32'h403147AE;    
//    sub get_bic_len(.x(IEEE_2p77), .y(f_pos_elbow), .out(f_len_bic));  
	 assign f_len = IEEE_1;
    
    wire [31:0] f_bicepsfr_Ia, x_0_bic, x_1_bic, f_bicepsfr_II;
//    spindle bic_bag1_bag2_chain
//    (	.gamma_dyn(f_gamma_dyn), // 32'h42A0_0000
//        .gamma_sta(f_gamma_sta),
//        .lce(f_len),
//        .clk(spindle_clk),
//        .reset(reset_sim),
//        .out0(x_0_bic),
//        .out1(x_1_bic),
//        .out2(f_bicepsfr_II),
//        .out3(f_bicepsfr_Ia),
//        .BDAMP_1(BDAMP_1),
//        .BDAMP_2(BDAMP_2),
//        .BDAMP_chain(BDAMP_chain)
//		);
    


    //** MOTOR UNIT 1
    wire [31:0]  f_force_mu1;  // output muscle force 
    wire [31:0]  i_emg_mu1;
    wire MN_spk_mu1;	
    wire [15:0] spkid_MN_mu1;
    motorunit mu1 (
    .f_muscle_length(f_len),  // muscle length
    .f_rawfr_Ia(f_bicepsfr_Ia),     //
    .f_pps_coef_Ia(f_pps_coef_Ia),  //
    .half_cnt(delay_cnt_max),.rawclk(clk1),  .ti_clk(ti_clk), .sim_clk(sim_clk), 
    .neuron_clk(neuron_clk), .reset_sim(reset_sim),.neuronCounter(neuronCounter),
    .gain(gain),           // gain 
    .i_gain_MN(i_gain_mu1_MN),
    .tau(tau),
    .f_total_force(f_force_mu1),  // output muscle force 
    .i_emg(i_emg_mu1),
    .MN_spk(MN_spk_mu1),
    .spkid_MN(spkid_MN_mu1)
    );

        //** MOTOR UNIT 2
    wire [31:0]  f_force_mu2;  // output muscle force 
    wire [31:0]  i_emg_mu2;
    wire MN_spk_mu2;	
    wire [15:0] spkid_MN_mu2;
    motorunit mu2 (
    .f_muscle_length(f_len),  // muscle length
    .f_rawfr_Ia(f_bicepsfr_Ia),     //
    .f_pps_coef_Ia(f_pps_coef_Ia),  //
    .half_cnt(delay_cnt_max),.rawclk(clk1),  .ti_clk(ti_clk), .sim_clk(sim_clk), 
    .neuron_clk(neuron_clk), .reset_sim(reset_sim),.neuronCounter(neuronCounter),
    .gain(gain), .tau(tau),     
    .i_gain_MN(i_gain_mu1_MN+2),
    .f_total_force(f_force_mu2),  // output muscle force 
    .i_emg(i_emg_mu2),
    .MN_spk(MN_spk_mu2),
    .spkid_MN(spkid_MN_mu2)
    );
    
      //** MOTOR UNIT 3
    wire [31:0]  f_force_mu3;  // output muscle force 
    wire [31:0]  i_emg_mu3;
    wire MN_spk_mu3;	
    wire [15:0] spkid_MN_mu3;
    motorunit mu3 (
    .f_muscle_length(f_len),  // muscle length
    .f_rawfr_Ia(f_bicepsfr_Ia),     //
    .f_pps_coef_Ia(f_pps_coef_Ia),  //
    .half_cnt(delay_cnt_max),.rawclk(clk1),  .ti_clk(ti_clk), .sim_clk(sim_clk), 
    .neuron_clk(neuron_clk), .reset_sim(reset_sim),.neuronCounter(neuronCounter),
    .gain(gain),           // gain 
    .i_gain_MN(i_gain_mu1_MN+4),
    .tau(tau),
    .f_total_force(f_force_mu3),  // output muscle force 
    .i_emg(i_emg_mu3),
    .MN_spk(MN_spk_mu3),
    .spkid_MN(spkid_MN_mu3)
    );

      //** MOTOR UNIT 4
    wire [31:0]  f_force_mu4;  // output muscle force 
    wire [31:0]  i_emg_mu4;
    wire MN_spk_mu4;	
    wire [15:0] spkid_MN_mu4;
    motorunit mu4 (
    .f_muscle_length(f_len),  // muscle length
    .f_rawfr_Ia(f_bicepsfr_Ia),     //
    .f_pps_coef_Ia(f_pps_coef_Ia),  //
    .half_cnt(delay_cnt_max),.rawclk(clk1),  .ti_clk(ti_clk), .sim_clk(sim_clk), 
    .neuron_clk(neuron_clk), .reset_sim(reset_sim),.neuronCounter(neuronCounter),
    .gain(gain), .tau(tau),         // gain 
    .i_gain_MN(i_gain_mu1_MN+6),
    .f_total_force(f_force_mu4),  // output muscle force 
    .i_emg(i_emg_mu4),
    .MN_spk(MN_spk_mu4),
    .spkid_MN(spkid_MN_mu4)
    );

      //** MOTOR UNIT 5
    wire [31:0]  f_force_mu5;  // output muscle force 
    wire [31:0]  i_emg_mu5;
    wire MN_spk_mu5;	
    wire [15:0] spkid_MN_mu5;
    motorunit mu5 (
    .f_muscle_length(f_len),  // muscle length
    .f_rawfr_Ia(f_bicepsfr_Ia),     //
    .f_pps_coef_Ia(f_pps_coef_Ia),  //
    .half_cnt(delay_cnt_max),.rawclk(clk1),  .ti_clk(ti_clk), .sim_clk(sim_clk), 
    .neuron_clk(neuron_clk), .reset_sim(reset_sim),.neuronCounter(neuronCounter),
    .gain(gain), .tau(tau),        // gain 
    .i_gain_MN(i_gain_mu1_MN+8),
    .f_total_force(f_force_mu5),  // output muscle force 
    .i_emg(i_emg_mu5),
    .MN_spk(MN_spk_mu5),
    .spkid_MN(spkid_MN_mu5)
    );




		  
//    // *** Biceps: Medium MN pools
//    wire MN_spk_med_mu;
//    wire [15:0] spkid_MN_med_mu;
//	 
//	 wire signed [31:0] i_current_med_mu_out;
//	 
//    neuron_pool #(.NN(NN)) med_pool
//    (   .f_rawfr_Ia(f_bicepsfr_Ia),     //
//        .f_pps_coef_Ia(f_pps_coef_Ia), //
//        .half_cnt(delay_cnt_max),
//        .rawclk(clk1),
//        .ti_clk(ti_clk),
//        .reset_sim(reset_sim),
//        .i_gain_MN(i_gain_med_MN),
//        .neuronCounter(neuronCounter),
//        .MN_spike(MN_spk_med_mu),
//        .spkid_MN(spkid_MN_med_mu),
//		  .i_current_out(i_current_med_mu_out)
//	 );  
//	 wire    [31:0] i_MN_spkcnt_med_mu;
//    wire    dummy_slow_med;        
//    spikecnt count_rawspikes_med_mu
//    (    .spike(MN_spk_med_mu), 
//        .int_cnt_out(i_MN_spkcnt_med_mu), 
//        .fast_clk(neuron_clk), 
//        .slow_clk(sim_clk), 
//        .reset(reset_sim), 
//        .clear_out(dummy_slow_med));
//
//    // *** Biceps: Small MN pools
//    wire MN_spk_small_mu;
//    wire [15:0] spkid_MN_small_mu;
//	 
//	 wire signed [31:0] i_current_small_mu_out;
//	 
//    neuron_pool #(.NN(NN)) small_pool
//    (   .f_rawfr_Ia(f_bicepsfr_Ia),     //
//        .f_pps_coef_Ia(f_pps_coef_Ia), //
//        .half_cnt(delay_cnt_max),
//        .rawclk(clk1),
//        .ti_clk(ti_clk),
//        .reset_sim(reset_sim),
//        .i_gain_MN(i_gain_small_MN),
//        .neuronCounter(neuronCounter),
//        .MN_spike(MN_spk_small_mu),
//        .spkid_MN(spkid_MN_small_mu),
//		  .i_current_out(i_current_small_mu_out)
//	 );  
//	 wire    [31:0] i_MN_spkcnt_small_mu;
//    wire    dummy_slow_small;        
//    spikecnt count_rawspikes_small_mu
//    (    .spike(MN_spk_small_mu), 
//        .int_cnt_out(i_MN_spkcnt_small_mu), 
//        .fast_clk(neuron_clk), 
//        .slow_clk(sim_clk), 
//        .reset(reset_sim), 
//        .clear_out(dummy_slow_small));
//		  
//		  
                 wire [31:0] i_MN_spkcnt_combined;
//  	assign i_MN_spkcnt_combined = i_MN_spkcnt_big_mu + i_MN_spkcnt_med_mu + i_MN_spkcnt_small_mu; 
// 
// 
// 
// 
// 
// 
// 
// 
// 
//	 // Medium motor neuron muscle
//	 wire    [31:0]  f_force_bic_med_mu;
//    wire    [31:0]  f_actstate_bic_med_mu, f_MN_spkcnt_bic_med_mu; 
//	 wire 	[63:0] t_spkcnt_med_mu = i_MN_spkcnt_med_mu*gain;
//    shadmehr_muscle biceps_med_mu
//    (   .spike_cnt(t_spkcnt_med_mu[31:0]),
//        .pos(f_len),  // muscle length
//        //.vel(current_vel),
//        .vel(32'd0),
//        .clk(sim_clk),
//        .reset(reset_sim),
//        .total_force_out(f_force_bic_med_mu),
//        .current_A(f_actstate_bic_med_mu),
//        .current_fp_spikes(f_MN_spkcnt_bic_med_mu),
//		  .tau(tau)
//    );       
//	 // Small motor neuron muscle
//	 wire    [31:0]  f_force_bic_small_mu;
//    wire    [31:0]  f_actstate_bic_small_mu, f_MN_spkcnt_bic_small_mu; 
//	 wire 	[63:0] t_spkcnt_small_mu = i_MN_spkcnt_small_mu*gain;
//    shadmehr_muscle biceps_small_mu
//    (   .spike_cnt(t_spkcnt_small_mu[31:0]),
//        .pos(f_len),  // muscle length
//        //.vel(current_vel),
//        .vel(32'd0),
//        .clk(sim_clk),
//        .reset(reset_sim),
//        .total_force_out(f_force_bic_small_mu),
//        .current_A(f_actstate_bic_small_mu),
//        .current_fp_spikes(f_MN_spkcnt_bic_small_mu),
//		  .tau(tau)
//    );       
//    
////	 //*** Combined muscle Force. 
//    wire    [31:0]  f_force_bic_combined_mu;
////    wire    [31:0]  f_actstate_bic_combined_mu, f_MN_spkcnt_bic_combined_mu; 
////	 wire 	[63:0] t_spkcnt_combined_mu = i_MN_spkcnt_combined*gain;
////    shadmehr_muscle biceps_combined_mu
////    (   .spike_cnt(t_spkcnt_combined_mu[31:0]),
////        .pos(f_len),  // muscle length
////        //.vel(current_vel),
////        .vel(32'd0),
////        .clk(sim_clk),
////        .reset(reset_sim),
////        .total_force_out(f_force_bic_combined_mu),
////        .current_A(f_actstate_bic_combined_mu),
////        .current_fp_spikes(f_MN_spkcnt_bic_combined_mu),
////		  .tau(tau)
////    );       
//	 wire signed [31:0] f_force_bic_bigmed_mu;
//	 add add_bm(.x(f_force_bic_big_mu), .y(f_force_bic_med_mu), .out(f_force_bic_bigmed_mu));
//	 add add_bms(.x(f_force_bic_bigmed_mu), .y(f_force_bic_small_mu), .out(f_force_bic_combined_mu));
//	 
//    // *** EMG
//   
//    wire [17:0] si_emg_med;
//    emg #(.NN(NN)) emg_med
//    (   .emg_out(si_emg_med), 
//        .i_spk_cnt(i_MN_spkcnt_med_mu[NN:0]), 
//        .clk(sim_clk), 
//        .reset(reset_sim) ); 
//    wire [31:0] i_emg_med;
//    assign i_emg_med = {{14{si_emg_med[17]}},si_emg_med[17:0]};
//	 
//    wire [17:0] si_emg_small;
//    emg #(.NN(NN)) emg_small
//    (   .emg_out(si_emg_small), 
//        .i_spk_cnt(i_MN_spkcnt_small_mu[NN:0]), 
//        .clk(sim_clk), 
//        .reset(reset_sim) );     
//    wire [31:0] i_emg_small;
//    assign i_emg_small = {{14{si_emg_small[17]}},si_emg_small[17:0]};
    
 // ** LEDs
    assign led[0] = ~reset_global;
    assign led[1] = ~reset_sim;
    assign led[2] = ~clk1;
    assign led[3] = ~MN_spk_mu1;
    assign led[4] = ~MN_spk_mu3;
    assign led[5] = ~MN_spk_mu5;
    assign led[6] = ~spindle_clk; // slow clock
    //assign led[5] = ~spike;
    //assign led[5] = ~button1_response;
    //assign led[6] = ~button2_response;
    //assign led[6] = ~reset_sim;
    assign led[7] = ~sim_clk; //fast clock
    //assign led[6] = ~execute; // When execute==1, led lits      
    // *** Buttons, physical on XEM3010, software on XEM3050 & XEM6010
    assign reset_global = ep00wire[0];
    assign reset_sim = ep00wire[1];
    
    // *** Endpoint connections:
    assign pin0 = clk1;   
    assign pin1 = sim_clk;
    assign pin2 = spindle_clk;
    


  // Instantiate the okHost and connect endpoints.
    // Host interface
    // *** Endpoint connections:
  
    okHost okHI(
        .hi_in(hi_in), .hi_out(hi_out), .hi_inout(hi_inout), .hi_aa(hi_aa), .ti_clk(ti_clk),
        .ok1(ok1), .ok2(ok2));
        
    parameter NUM_OK_IO = 32;
    wire [NUM_OK_IO*17 - 1: 0]  ok2x;    
    okWireOR # (.N(NUM_OK_IO)) wireOR (ok2, ok2x);
    
    okWireIn     wi00 (.ok1(ok1),                           .ep_addr(8'h00), .ep_dataout(ep00wire));
    okWireIn     wi01 (.ok1(ok1),                           .ep_addr(8'h01), .ep_dataout(ep01wire));
    okWireIn     wi02 (.ok1(ok1),                           .ep_addr(8'h02), .ep_dataout(ep02wire));
    //okWireIn     wi03 (.ok1(ok1),                           .ep_addr(8'h03), .ep_dataout(ep001wire));

    okWireOut    wo20 (.ep_datain(f_bicepsfr_Ia[15:0]), .ok1(ok1), .ok2(ok2x[  0*17 +: 17 ]), .ep_addr(8'h20) );
    okWireOut    wo21 (.ep_datain(f_bicepsfr_Ia[31:16]), .ok1(ok1), .ok2(ok2x[  1*17 +: 17 ]), .ep_addr(8'h21) );
    okWireOut    wo22 (.ep_datain(i_MN_spkcnt_combined[15:0]), .ok1(ok1), .ok2(ok2x[  2*17 +: 17 ]), .ep_addr(8'h22) );
    okWireOut    wo23 (.ep_datain(i_MN_spkcnt_combined[31:16]), .ok1(ok1), .ok2(ok2x[  3*17 +: 17 ]), .ep_addr(8'h23) );
    okWireOut    wo24 (.ep_datain(i_emg_mu1[15:0]), .ok1(ok1), .ok2(ok2x[  4*17 +: 17 ]), .ep_addr(8'h24) );
    okWireOut    wo25 (.ep_datain(i_emg_mu1[31:16]), .ok1(ok1), .ok2(ok2x[  5*17 +: 17 ]), .ep_addr(8'h25) );
    okWireOut    wo26 (.ep_datain(i_emg_mu2[15:0]), .ok1(ok1), .ok2(ok2x[  6*17 +: 17 ]), .ep_addr(8'h26) );
    okWireOut    wo27 (.ep_datain(i_emg_mu2[31:16]), .ok1(ok1), .ok2(ok2x[  7*17 +: 17 ]), .ep_addr(8'h27) );
    okWireOut    wo28 (.ep_datain(i_emg_mu3[15:0]),  .ok1(ok1), .ok2(ok2x[ 8*17 +: 17 ]), .ep_addr(8'h28) );
    okWireOut    wo29 (.ep_datain(i_emg_mu3[31:16]), .ok1(ok1), .ok2(ok2x[ 9*17 +: 17 ]), .ep_addr(8'h29) );
    okWireOut    wo30 (.ep_datain(i_emg_mu4[15:0]),  .ok1(ok1), .ok2(ok2x[ 10*17 +: 17 ]), .ep_addr(8'h30) );
    okWireOut    wo31 (.ep_datain(i_emg_mu4[31:16]), .ok1(ok1), .ok2(ok2x[ 11*17 +: 17 ]), .ep_addr(8'h31) );
    okWireOut    wo32 (.ep_datain(i_emg_mu5[15:0]),  .ok1(ok1), .ok2(ok2x[ 12*17 +: 17 ]), .ep_addr(8'h32) );
    okWireOut    wo33 (.ep_datain(i_emg_mu5[31:16]), .ok1(ok1), .ok2(ok2x[ 13*17 +: 17 ]), .ep_addr(8'h33) );    
    okWireOut    wo34 (.ep_datain(i_emg_mu1[15:0]),  .ok1(ok1), .ok2(ok2x[ 14*17 +: 17 ]), .ep_addr(8'h34) );
    okWireOut    wo35 (.ep_datain(i_emg_mu1[31:16]), .ok1(ok1), .ok2(ok2x[ 15*17 +: 17 ]), .ep_addr(8'h35) );
    okWireOut    wo36 (.ep_datain(i_emg_mu2[15:0]),  .ok1(ok1), .ok2(ok2x[ 16*17 +: 17 ]), .ep_addr(8'h36) );
    okWireOut    wo37 (.ep_datain(i_emg_mu2[31:16]), .ok1(ok1), .ok2(ok2x[ 17*17 +: 17 ]), .ep_addr(8'h37) );
    okWireOut    wo38 (.ep_datain(i_emg_mu3[15:0]),  .ok1(ok1), .ok2(ok2x[ 18*17 +: 17 ]), .ep_addr(8'h38) );
    okWireOut    wo39 (.ep_datain(i_emg_mu3[31:16]), .ok1(ok1), .ok2(ok2x[ 19*17 +: 17 ]), .ep_addr(8'h39) );
    okWireOut    wo40 (.ep_datain(i_emg_mu4[15:0]),  .ok1(ok1), .ok2(ok2x[ 20*17 +: 17 ]), .ep_addr(8'h40) );
    okWireOut    wo41 (.ep_datain(i_emg_mu4[31:16]), .ok1(ok1), .ok2(ok2x[ 21*17 +: 17 ]), .ep_addr(8'h41) );
    okWireOut    wo42 (.ep_datain(i_emg_mu5[15:0]),  .ok1(ok1), .ok2(ok2x[ 22*17 +: 17 ]), .ep_addr(8'h42) );
    okWireOut    wo43 (.ep_datain(i_emg_mu5[31:16]), .ok1(ok1), .ok2(ok2x[ 23*17 +: 17 ]), .ep_addr(8'h43) );
    //ep_ready = 1 (always ready to receive)
    okBTPipeIn   ep80 (.ok1(ok1), .ok2(ok2x[ 26*17 +: 17 ]), .ep_addr(8'h80), .ep_write(is_pipe_being_written), .ep_blockstrobe(), .ep_dataout(hex_from_py), .ep_ready(1'b1));
    //okBTPipeOut  epA0 (.ok1(ok1), .ok2(ok2x[ 5*17 +: 17 ]), .ep_addr(8'ha0), .ep_read(pipe_out_read),  .ep_blockstrobe(), .ep_datain(response_nerf), .ep_ready(pipe_out_valid));
    okBTPipeOut  epA0 (.ok1(ok1), .ok2(ok2x[ 27*17 +: 17 ]), .ep_addr(8'ha0), .ep_read(pipe_out_read),  .ep_blockstrobe(), .ep_datain(spkid_MN_mu1), .ep_ready(1'b1));
    okBTPipeOut  epA1 (.ok1(ok1), .ok2(ok2x[ 28*17 +: 17 ]), .ep_addr(8'ha1), .ep_read(pipe_out_read),  .ep_blockstrobe(), .ep_datain(spkid_MN_mu2), .ep_ready(1'b1));
    okBTPipeOut  epA2 (.ok1(ok1), .ok2(ok2x[ 29*17 +: 17 ]), .ep_addr(8'ha2), .ep_read(pipe_out_read),  .ep_blockstrobe(), .ep_datain(spkid_MN_mu3), .ep_ready(1'b1));
    okBTPipeOut  epA3 (.ok1(ok1), .ok2(ok2x[ 30*17 +: 17 ]), .ep_addr(8'ha3), .ep_read(pipe_out_read),  .ep_blockstrobe(), .ep_datain(spkid_MN_mu4), .ep_ready(1'b1));
    okBTPipeOut  epA4 (.ok1(ok1), .ok2(ok2x[ 31*17 +: 17 ]), .ep_addr(8'ha4), .ep_read(pipe_out_read),  .ep_blockstrobe(), .ep_datain(spkid_MN_mu5), .ep_ready(1'b1));

    okTriggerIn ep50 (.ok1(ok1),  .ep_addr(8'h50), .ep_clk(clk1), .ep_trigger(ep50trig));
endmodule



