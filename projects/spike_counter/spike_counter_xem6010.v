`timescale 1ns / 1ps
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
module spike_counter_xem6010(
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
  //  output wire  spike,
   // output wire clk_out
   );
   
    parameter NN = 8;
       
    // *** Dump all the declarations here:
    wire         ti_clk;
    wire [30:0]  ok1;
    wire [16:0]  ok2;   
    //wire [15:0]  ep001wire;
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
    assign button1 = ep00wire[2];  // testing sensitivity list
    assign button2 = ep00wire[3];
    //assign enable_sim = is_waveform_valid;
    wire    [31:0]  IEEE_1, IEEE_0;
	assign IEEE_1 = 32'h3F800000;
	assign IEEE_0 = 32'd0;
        
    // *** Triggered input from Python
    always @(posedge ep50trig[7] or posedge reset_global)
    begin
        if (reset_global)
            delay_cnt_max <= delay_cnt_max;
        else
            delay_cnt_max <= {2'b00, ep01wire};  //firing rate
    end
    
//    always @(posedge ep50trig[4] or posedge reset_global)
//    begin
//        if (reset_global)
//            gamma_dyn <= 32'h42A0_0000; // gamma_dyn reset to 80
//        else
//            gamma_dyn <= {ep02wire, ep01wire};  //firing rate
//    end    
    reg [31:0] gain;
    always @(posedge ep50trig[3] or posedge reset_global)
    begin
        if (reset_global)
            gain <= 32'd0;
        else
            gain <= {ep02wire, ep01wire};  //firing rate
    end        
    

    
      // *** Deriving clocks from on-board clk1:
    wire neuron_clk, sim_clk, spindle_clk;
    wire [NN+2:0] neuronCounter;

    gen_clk #(.NN(8)) useful_clocks
    (   .rawclk(clk1), 
        .half_cnt(delay_cnt_max), 
        .clk_out1(neuron_clk), 
        .clk_out2(sim_clk), 
        .clk_out3(spindle_clk),
        .int_neuron_cnt_out(neuronCounter) );
                
    
    // *** Generating waveform to stimulate the spindle
    wire    [31:0]  i_current_spikes;
	waveform_from_pipe gen(	
        .ti_clk(ti_clk),
        .reset(reset_global),
        .repop(reset_sim),
        .feed_data_valid(is_pipe_being_written),
        .feed_data(hex_from_py),
        .current_element(i_current_spikes),
        .test_clk(sim_clk),
        .done_feeding(is_lce_valid)
    );        

    // *** check spike count
//    wire    [31:0]  current_spike_cnt;
//    wire    clear_out;
//    spikecnt count_rawspikes
//	 (		.spike(spike), 
//			.slow_clk(slow_clk), 
//			.fast_clk(fast_clk),
//            .int_cnt_out(current_spike_cnt),
//			.reset(reset_sim),
//            .clear_out(clear_out)
//		);


    wire [31:0]  clear_out, i_MN_spk_cnt;
    spike_counter count_test
    (   .spike(spike), 
        .slow_clk(sim_clk), 
        .reset(reset_sim),
        .int_cnt_out(i_MN_spk_cnt),
        .clear_out(clear_out) );
        
                
    
    // *** Shadmehr muscle: spike_count_out => f_active_state => f_total_force
    wire    [31:0]  f_total_force, f_active_state, f_MN_spk_cnt;
    //wire    [31:0]   f_muscle_len;
    //assign f_muscle_len = IEEE_1;
    shadmehr_muscle muscle_for_test
    (   .spike_cnt(i_MN_spk_cnt*gain),
        .pos(IEEE_1),  // muscle length
        //.vel(current_vel),
        .vel(32'd0),
        .clk(sim_clk),
        .reset(reset_sim),
        .total_force_out(f_total_force),
        .current_A(f_active_state),
        .current_fp_spikes(f_MN_spk_cnt)
    );       
            

    // ** LEDs
    assign led[0] = ~reset_global;
    assign led[1] = ~reset_sim;
    assign led[2] = ~spike;
    assign led[3] = 1'b1;
    assign led[4] = 1'b1;
    assign spike  = (i_current_spikes != 32'd0);
    assign led[5] = ~sim_clk; //fast clock
    assign led[6] = ~spindle_clk; // slow clock
    //assign led[5] = ~spike;
    //assign led[6] = ~reset_sim;
    assign led[7] = 1'b1;
    //assign led[6] = ~execute; // When execute==1, led lits         
	      
          
    // *** Endpoint connections:
    assign pin0 = 1'b1;
    assign pin1 = 1'b1;
    assign pin2 = spindle_clk;
    // Instantiate the okHost and connect endpoints.
    // Host interface
    // *** Endpoint connections:
    assign ep20wire = i_MN_spk_cnt[15:0];
    assign ep21wire = i_MN_spk_cnt[31:16];
    assign ep22wire = f_total_force[15:0]; 
    assign ep23wire = f_total_force[31:16];
    assign ep24wire = f_active_state[15:0]; 
    assign ep25wire = f_active_state[31:16];
    assign ep26wire = gain[15:0];
    assign ep27wire = gain[31:16];
    //assign ep28wire = {15'b0, slow_clk_up};
    //assign ep29wire = {15'b0, slow_clk_up};
      
    okHost okHI(
        .hi_in(hi_in), .hi_out(hi_out), .hi_inout(hi_inout), .hi_aa(hi_aa), .ti_clk(ti_clk),
        .ok1(ok1), .ok2(ok2));

    wire [17*11-1:0]  ok2x;
    okWireOR # (.N(11)) wireOR (ok2, ok2x);
    okWireIn     wi00 (.ok1(ok1),                           .ep_addr(8'h00), .ep_dataout(ep00wire));
    okWireIn     wi01 (.ok1(ok1),                           .ep_addr(8'h01), .ep_dataout(ep01wire));
    okWireIn     wi02 (.ok1(ok1),                           .ep_addr(8'h02), .ep_dataout(ep02wire));
    //okWireIn     wi03 (.ok1(ok1),                           .ep_addr(8'h03), .ep_dataout(ep001wire));

    okWireOut    wo20 (.ok1(ok1), .ok2(ok2x[ 0*17 +: 17 ]), .ep_addr(8'h20), .ep_datain(ep20wire));
    okWireOut    wo21 (.ok1(ok1), .ok2(ok2x[ 1*17 +: 17 ]), .ep_addr(8'h21), .ep_datain(ep21wire));
    okWireOut    wo22 (.ok1(ok1), .ok2(ok2x[ 2*17 +: 17 ]), .ep_addr(8'h22), .ep_datain(ep22wire));
    okWireOut    wo23 (.ok1(ok1), .ok2(ok2x[ 3*17 +: 17 ]), .ep_addr(8'h23), .ep_datain(ep23wire));
    okWireOut    wo24 (.ok1(ok1), .ok2(ok2x[ 4*17 +: 17 ]), .ep_addr(8'h24), .ep_datain(ep24wire));
    okWireOut    wo25 (.ok1(ok1), .ok2(ok2x[ 5*17 +: 17 ]), .ep_addr(8'h25), .ep_datain(ep25wire));
    okWireOut    wo26 (.ok1(ok1), .ok2(ok2x[ 6*17 +: 17 ]), .ep_addr(8'h26), .ep_datain(ep26wire));
    okWireOut    wo27 (.ok1(ok1), .ok2(ok2x[ 7*17 +: 17 ]), .ep_addr(8'h27), .ep_datain(ep27wire));
    okWireOut    wo28 (.ok1(ok1), .ok2(ok2x[ 8*17 +: 17 ]), .ep_addr(8'h28), .ep_datain(ep28wire));
    okWireOut    wo29 (.ok1(ok1), .ok2(ok2x[ 9*17 +: 17 ]), .ep_addr(8'h29), .ep_datain(ep29wire));
     //ep_ready = 1 (always ready to receive)
    okBTPipeIn   ep80 (.ok1(ok1), .ok2(ok2x[ 10*17 +: 17 ]), .ep_addr(8'h80), .ep_write(is_pipe_being_written), .ep_blockstrobe(), .ep_dataout(hex_from_py), .ep_ready(1'b1));
    okBTPipeOut  epA0 (.ok1(ok1), .ok2(ok2x[ 11*17 +: 17 ]), .ep_addr(8'ha1), .ep_read(pipe_out_read),  .ep_blockstrobe(), .ep_datain(rawspikes), .ep_ready(1'b1));
    //okBTPipeOut  epA0 (.ok1(ok1), .ok2(ok2x[ 5*17 +: 17 ]), .ep_addr(8'ha0), .ep_read(pipe_out_read),  .ep_blockstrobe(), .ep_datain(response_nerf), .ep_ready(pipe_out_valid));

    okTriggerIn ep50 (.ok1(ok1),  .ep_addr(8'h50), .ep_clk(clk1), .ep_trigger(ep50trig));
endmodule

