`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Creator: Eric W. Sohn (test bench[tb] written by) 

// 
// Module Name:    
// Project Name: 
// Target Devices:    ISIM test bench
// Design properties: xc6slx150-2fgg484
// Description:  ** In simulation, cross-board test is implemented in a single simulation file. ***
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module one_joint_board1_ISIM(
	 );

    parameter NN = 8;
    
    wire [15:0] hex_from_py;
     wire         ti_clk;
    reg [17:0] delay_cnt, delay_cnt_max;
    
    reg reset_global, reset_sim;

    //assign enable_sim = is_waveform_valid;
    wire    [31:0]  IEEE_1, IEEE_0;
	assign IEEE_1 = 32'h3F800000;
	assign IEEE_0 = 32'd0;

 
//    reg [31:0] f_pps_coef_Ia;
//    always @(posedge ep50trig[1] or posedge reset_global)
//    begin
//        if (reset_global)
//            f_pps_coef_Ia <= 32'h3F66_6666;
//        else
//            f_pps_coef_Ia <= {ep02wire, ep01wire};  //firing rate
//    end       
//
//    reg [31:0] tau;
//    always @(posedge ep50trig[2] or posedge reset_global)
//    begin
//        if (reset_global)
//            tau <= 32'd1; // 
//        else
//            tau <= {ep02wire, ep01wire};  
//    end       
//
//    reg [31:0] gain;
//    always @(posedge ep50trig[3] or posedge reset_global)
//    begin
//        if (reset_global)
//            gain <= 32'd0;
//        else
//            gain <= {ep02wire, ep01wire};  //firing rate
//    end        
    
//    reg [31:0] f_gamma_dyn;
//    always @(posedge ep50trig[4] or posedge reset_global)
//    begin
//        if (reset_global)
//            f_gamma_dyn <= 32'h42A0_0000; // gamma_dyn reset to 80
//        else
//            f_gamma_dyn <= {ep02wire, ep01wire};  
//    end  
    
//    reg [31:0] f_gamma_sta;
//    always @(posedge ep50trig[5] or posedge reset_global)
//    begin
//        if (reset_global)
//            f_gamma_sta <= 32'h42A0_0000; // gamma_sta reset to 80
//        else
//            f_gamma_sta <= {ep02wire, ep01wire};  
//    end  
    
//    reg signed [31:0] i_gain_mu1_MN;
//    always @(posedge ep50trig[6] or posedge reset_global)
//    begin
//        if (reset_global)
//            i_gain_mu1_MN <= 32'd1; // gamma_sta reset to 80
//        else
//            i_gain_mu1_MN <= {ep02wire, ep01wire};  
//    end
//	 
//    reg signed [31:0] i_gain_mu2_MN;
//    always @(posedge ep50trig[7] or posedge reset_global)
//    begin
//        if (reset_global)
//            i_gain_mu2_MN <= 32'd1; // gamma_sta reset to 80
//        else
//            i_gain_mu2_MN <= {ep02wire, ep01wire};  
//    end  
//
//    reg signed [31:0] i_gain_mu3_MN;
//    always @(posedge ep50trig[8] or posedge reset_global)
//    begin
//        if (reset_global)
//            i_gain_mu3_MN <= 32'd1; // gamma_sta reset to 80
//        else
//            i_gain_mu3_MN <= {ep02wire, ep01wire};  
//    end  
	 
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
//    reg [31:0] BDAMP_1, BDAMP_2, BDAMP_chain, GI, GII;
//    always @(posedge ep50trig[15] or posedge reset_global)
//    begin
//        if (reset_global)
//            BDAMP_1 <= 32'h3E71_4120; // bag 1 BDAMP reset to 0.2356
//        else
//            BDAMP_1 <= {ep02wire, ep01wire};  //firing rate
//    end
//    always @(posedge ep50trig[14] or posedge reset_global)
//    begin
//        if (reset_global)
//            BDAMP_2 <= 32'h3D14_4674; // bag 2 BDAMP reset to 0.0362
//        else
//            BDAMP_2 <= {ep02wire, ep01wire};  //firing rate
//    end    
//    always @(posedge ep50trig[13] or posedge reset_global)
//    begin
//        if (reset_global)
//            BDAMP_chain <= 32'h3C58_44D0; // chain BDAMP reset to 0.0132 
//        else
//            BDAMP_chain <= {ep02wire, ep01wire};  //firing rate
//    end
    
    parameter DATALINES = 2048;
	 
    // For test bench 
    // clk1 generation
    reg clk1;
    reg [31:0] data [DATALINES-1:0];
    //reg [31:0] data_output [5:0];
	 reg [31:0] data_input;
	 reg [31:0] data_output;
    reg [31:0] k, outfile;
	 reg reading;
     
	  // reset tb
     initial begin 
          #140 reset_global = 0; 
          #40 reset_sim = 0; 
     end
	 
	  // tb time profile
     initial
         begin 
         $readmemh("stimulus.txt", data);  // read input file once.
         $timeformat(-9, 1, " ns", 6);
		   #100;
         clk1 = 1'b0;  reset_global = 1; reset_sim = 1; k = 0; reading = 0; 
		   delay_cnt_max = 197;   // calculated from the equation in NIPS paper. (F_fpga = 200Mhz, C = 4, F_emul = 1Khz ....) 
		   #10 reset_sim = 0;
		   #10 reset_sim = 1;
		   #10 reset_sim = 0;	 // reset for one more time.   
		   reading=1;          // to control reading.       
		   outfile = $fopen ("response.txt", "w");   // output file to write.  
		   #100000; //for reading.
		  
		   #40000000;   // 4ms
			$fclose (outfile);    // CLOSE THE OUTPUT FILE			 
         $finish; // to shut down the simulation
    end

	 // writing multiple variables to file. Only write as much data points in the input file. 
	 always @(posedge sim_clk or posedge reset_sim) begin
		  if (reset_sim) begin
				data_input <= 32'd0;
		  end 
		  if (reading & (k < DATALINES)) begin
				data_input <= data[k]; 
				$fdisplay(outfile, "%x	%x   %x",  data_input, f_bicepsfr_Ia, f_total_force);
				k <= k + 1;
		  end          
	 end 
  
    // 200Mhz base clock
    always begin
        #5  clk1 = ~clk1;
    end
    
	 wire [31:0] data_output_F0;

//	 // *** Integrator test 
//    integrator integrate_data_input
//    (
//        .x(data_input),       //dT_i
//        .int_x(data_output),   //T_i
//		  .reset(reset_sim),
//        .out(data_output_F0)     //T_i_F0
//    );
//
//    always @(posedge sim_clk or posedge reset_sim) begin
//        if (reset_sim) begin
//				data_output <= 32'd0;
//        end
//        else begin
//            data_output <= data_output_F0;
//        end
//    end
        
    // *** Deriving clocks from on-board clk1:
    wire neuron_clk, sim_clk, spindle_clk;
    wire [NN+2:0] neuronCounter;
    
    gen_clk #(.NN(NN)) useful_clocks
    (   .rawclk(clk1), 
		  .reset(reset_global),
        .half_cnt(delay_cnt_max), 
        .clk_out1(neuron_clk), 
        .clk_out2(sim_clk), 
        .clk_out3(spindle_clk),
        .int_neuron_cnt_out(neuronCounter) );
                   
    wire [31:0] f_gamma_dyn, f_gamma_sta;
    assign f_gamma_dyn = 32'h42A0_0000;
    assign f_gamma_sta = 32'h42A0_0000;
    

//    //** MOTOR UNIT 1
//    wire [31:0]  f_force_mu1;  // output muscle force 
//    wire [31:0]  i_emg_mu1;
//    wire MN_spk_mu1;	
//    wire [15:0] spkid_MN_mu1;
//    motorunit mu1 (
//    .f_muscle_length(data_input),  // muscle length
//    .f_rawfr_Ia(f_bicepsfr_Ia),     //
//    .f_pps_coef_Ia(f_pps_coef_Ia),  //
//    .half_cnt(delay_cnt_max),.rawclk(clk1),  .ti_clk(ti_clk), .sim_clk(sim_clk), 
//    .neuron_clk(neuron_clk), .reset_sim(reset_sim),.neuronCounter(neuronCounter),
//    .gain(IEEE_1),           // gain 
//    .i_gain_MN(IEEE_1),     
//    .tau(IEEE_1),
//    .f_total_force(f_force_mu1),  // output muscle force 
//    .i_emg(i_emg_mu1),
//    .MN_spk(MN_spk_mu1),
//    .spkid_MN(spkid_MN_mu1)
//    );
    // *** Spindle: f_muscle_len => f_rawfr_Ia
    wire [31:0] f_bicepsfr_Ia, x_0_bic, x_1_bic, f_bicepsfr_II;
    
    spindle bic_bag1_bag2_chain
    (	.gamma_dyn(f_gamma_dyn), // 32'h42A0_0000
        .gamma_sta(f_gamma_sta),
        .lce(data_input),
        .clk(spindle_clk),
        .reset(reset_sim),
        .out0(x_0_bic),
        .out1(x_1_bic),
        .out2(f_bicepsfr_II),
        .out3(f_bicepsfr_Ia),
        .BDAMP_1(32'h3E71_4120),
        .BDAMP_2(32'h3D14_4674),
        .BDAMP_chain(32'h3C58_44D0)
		);
     
	  
	 // motorunit module decomposed. 
	 wire signed [31:0] i_current_out;
	 wire MN_spk;
	 wire [15:0] spkid_MN;
	 
    neuron_pool #(.NN(NN)) big_pool
    (   .f_rawfr_Ia(f_bicepsfr_Ia),     //
        .f_pps_coef_Ia(32'h3F66_6666), //
        .half_cnt(delay_cnt_max32),
        .rawclk(clk1),
        .ti_clk(ti_clk),
        .reset_sim(reset_sim),
        .i_gain_MN(32'd1), // not used...
        .neuronCounter(neuronCounter),
        .MN_spike(MN_spk),    // probably  neuron_ram doesn't work in ISIM. 
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

 

    wire [31:0] delay_cnt_max32;
    assign delay_cnt_max32 = {12'b0, delay_cnt_max};



 // delay by blk memory (1 bit) 
    wire [20:0] blk_size;
    assign blk_size = 21'd800000;
    
    reg [20:0] write_index, read_index;
    reg write;
    reg blk_mem_filled;
    
    wire [3:0] read_write_diff;
    assign read_write_diff = 4'd5;
    
    always @ (posedge neuron_clk or posedge reset_sim)
    begin
        if (reset_sim) begin
            write <= 0;
            write_index<=0;
            read_index <=0;
            blk_mem_filled <=0;
        end 
        else begin
            write_index <= write_index + 1;
            write <= 1;  // always write
            if (write_index == (blk_size - read_write_diff)) begin   // wrap around the blk_mem
                blk_mem_filled <= 1;             // stay filled after initial fill. 
                read_index <= read_index + 1;
            end
                
            if (write_index == blk_size) // write_index wraps around. 
                write_index <= 0;
                
            if (blk_mem_filled) begin
                read_index <= read_index + 1;
                if (read_index == blk_size)  // 
                    read_index <= 0; 
                else 
                    read_index <= read_index + 1;
            end 
        end
    end
	
	// block ram for delay (ipcore)
    wire MN_spk_delayed;
	 blk_mem_gen_v6_1 spike_ram1(
		 .clka(neuron_clk),
		 .wea(write),
		 .addra(write_index),
		 .dina(MN_spk),
		 .clkb(neuron_clk),
		 .addrb(read_index),
		 .doutb(MN_spk_delayed)
		 );
		

	// 'OR' the spike train from short & long latency loop
    wire spike_SL_combined;
    assign spike_SL_combined = MN_spk | MN_spk_delayed;
	 
	 
    wire    [31:0] i_SL_spkcnt;
    wire    dummy_slow_delayed;        
    spikecnt count_rawspikes_3
    (   .spike(spike_SL_combined), 
        .int_cnt_out(i_SL_spkcnt), 
        .fast_clk(neuron_clk), 
        .slow_clk(sim_clk), 
        .reset(reset_sim), 
        .clear_out(dummy_slow_delayed));

   // *** Shadmehr muscle: spike_count_out => f_active_state => f_total_force
	 // Big motor neuron muscle
	wire 		[31:0]  f_total_force;
	wire    [31:0]  f_force;
   wire    [31:0]  f_actstate, f_MN_spkcnt;
	
	wire 	[63:0] t_spkcnt = i_SL_spkcnt;
    shadmehr_muscle muscles
    (   .spike_cnt(t_spkcnt[31:0]),
        .pos(data_input),  // muscle length
        //.vel(current_vel),
        .vel(32'd0),
        .clk(sim_clk),
        .reset(reset_sim),
        .total_force_out(f_total_force),
        .current_A(f_actstate),
        .current_fp_spikes(f_MN_spkcnt),
		.tau(IEEE_1)
    );       




endmodule



