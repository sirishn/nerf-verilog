`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Design Name: 
// Module Name:    neuron_pool.v
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
module neuron_pool (//(f_muscle_length, f_rawfr_Ia, f_pps_coef_Ia, gain, sim_clk, neuron_clk, reset_sim, f_total_force);
    //input   [31:0]  vel,            // change of muscle length
    input   wire [31:0]  f_rawfr_Ia,     //
    input   wire [31:0]  f_pps_coef_Ia,  //
    input   wire [31:0]  half_cnt,
    input   wire rawclk,

    input   wire ti_clk,
    input   wire reset_sim,
    input   wire signed [31:0] i_gain_MN,
    input   wire [NN+2:0] neuronCounter,

    output  wire MN_spike,
    output  wire [15:0] spkid_MN,
	 // debug
	 output reg  [31:0] i_current_out,
	 output wire signed [31:0] out2,
	 output wire signed [31:0] out3,
	 output wire [31:0] out4
    );

    parameter NN = 6; // 2^(NN+1) = NUM_NEURON
    
    //Locally generate neuron_clk
    reg neuron_clk;
    reg [31:0] delay_cnt;
    always @ (posedge rawclk) begin
        if (delay_cnt < half_cnt) begin
            neuron_clk <= neuron_clk;
            delay_cnt <= delay_cnt + 1;
        end
        else begin
            neuron_clk<= ~neuron_clk;
            delay_cnt <= 0;
        end
    end

    // *** Izhikevich: f_fr_Ia => spikes
    // *** Convert float_fr to int_I1

    wire [31:0] f_fr_Ia_F0;
    
    wire [31:0] rand_out;
    rng rng_0(
            .clk1(rawclk),
            .clk2(rawclk),
            .reset(reset_sim),
            .out(rand_out)
    );    
    wire [22:0] i23_rand = {1'b0, rand_out[21:0]};
    
    wire [31:0] f_randn_F0 = {12'h3F8, rand_out[19:0]};
    wire [31:0] f_rand_Ia_F0; 
    mult get_rand_Ia( .x(f_rawfr_Ia), .y(f_randn), .out(f_rand_Ia_F0));
	mult scale_pps_Ia( .x(f_rand_Ia), .y(f_pps_coef_Ia), .out(f_fr_Ia_F0));
        
    wire Ia_spike, s_Ia;
    
    wire signed [17:0] v_Ia;   // cell potentials
      

    // *** izh-Motoneuron :: i_postsyn_I -> (MN_spike, rawspike)
    

    wire [17:0] v1, u1, s1;
    
   
	wire [1:0] state;
	assign state = neuronCounter[1:0];
    
	wire [NN:0] neuronIndex;
	assign neuronIndex = neuronCounter[NN+2:2];
	
    //wire MN_spike;


    wire signed [31:0] i_synI_Ia;
    floor float_to_int_Ia( .in(f_fr_Ia), .out(i_synI_Ia) );    

	 //reg [31:0] i_current_out;
     reg    [31:0] f_fr_Ia, f_rand_Ia, f_randn;
	 always @(posedge neuron_clk or posedge reset_sim) begin
		if (reset_sim) begin
			i_current_out <= 32'd0;
            f_fr_Ia <= 32'd0;
            f_rand_Ia <= 32'd0;
            f_randn <= 32'd0;
		end
		else begin
			//i_current_out <= i_current_F0;
			i_current_out <= i_synI_Ia;
//            f_fr_Ia <= (flag_fr_Ia[2]) ? f_fr_Ia_F0 : f_fr_Ia; 
//            f_rand_Ia <= (flag_rand_Ia[2]) ? f_rand_Ia_F0 : f_rand_Ia;      
            f_fr_Ia <= f_fr_Ia_F0; 
            f_rand_Ia <= f_rand_Ia_F0;                  
            f_randn <= f_randn_F0;
		end
	 end

	//Iz_neuron #(.NN(NN),.DELAY(10)) neuMN(v1,s1, a,b,c,d, i_current_out18 , neuron_clk, reset_sim, neuronIndex, neuronWriteEnable, readClock, tau, MN_spike, neuronWriteCount);
    wire [31:0] v;
    wire spike;
    wire [127:0] population;
    izneuron neuron_0(
                .clk(neuron_clk),
                .reset(reset_sim),
                .I_in(i_current_out),                
                .spike(MN_spike),                
                .spkid(spkid_MN)
    );    
    //reg [15:0] raw_Ia_spikes, raw_II_spikes, raw_MN_spikes;
	//always @(negedge ti_clk) raw_Ia_spikes <= {1'b0, neuronIndex[NN:2], 1'b0, Ia_spike, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
//    always @(negedge ti_clk) raw_II_spikes <= {1'b0, neuronIndex[NN:2], 1'b0, 1'b0, II_spike, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};

//
//    assign raw_MN_spikes = {1'b0, neuronIndex[NN:2], MN_spike, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
//	assign raw_Ia_spikes = {1'b0, neuronIndex[NN:2], 1'b0, Ia_spike, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
//	assign raw_II_spikes = {1'b0, neuronIndex[NN:2], 1'b0, 1'b0, II_spike, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
    
    // *** Count the spikes: rawspikes -> spike -> spike_count_out
	
    assign out2 = f_rand_Ia;
    assign out3 = f_randn;
    assign out4 = f_fr_Ia;
endmodule

