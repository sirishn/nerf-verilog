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
module gen_clk_xem6010(
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
//
//    wire [31:0] current_lce;
//    wire [15:0] lce_from_py;
//
//    wire [31:0] Ia_fr, x_0, x_1, II_fr;
//    
//    reg [17:0] delay_cnt, delay_cnt_max;
//    reg [31:0] gamma_dyn;
//    
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
    //assign enable_sim = is_lce_valid;
        
    // ** LEDs
    assign led[4:2] = 3'b111;
    assign led[0] = ~spindle_clk;
    assign led[1] = 1'b1;
    assign led[5] = ~neuron_clk;
    assign led[6] = ~sim_clk;
    assign led[7] = ~reset_global;
    //assign led[6] = ~execute; // When execute==1, led lits


    // *** Triggered input from Python
    reg [31:0] delay_cnt_max;
    always @(posedge ep50trig[7] or posedge reset_global)
    begin
        if (reset_global)
            delay_cnt_max <= delay_cnt_max;
        else
            delay_cnt_max <= {ep02wire, ep01wire};  //firing rate
    end
    
//    always @(posedge ep50trig[4] or posedge reset_global)
//    begin
//        if (reset_global)
//            gamma_dyn <= 32'h42A0_0000; // gamma_dyn reset to 80
//        else
//            gamma_dyn <= {ep02wire, ep01wire};  //firing rate
//    end    

    
    // *** Deriving clocks from on-board clk1:
    wire neuron_clk, sim_clk, spindle_clk;
    wire [31:0] neuronCounter;
    gen_clk #(.NN(8)) useful_clocks
    (   .rawclk(clk1), 
        .half_cnt(delay_cnt_max), 
        .clk_out1(neuron_clk), 
        .clk_out2(sim_clk), 
        .clk_out3(spindle_clk),
        .int_neuron_cnt_out(neuronCounter) );

    
    // *** Generating waveform to stimulate the spindle
//    waveform_from_lut get_muscle_lce
//    (   .clk(test_clk),
//        .reset(reset_global),
//        .value(current_lce)
//    );
//
//	waveform_from_pipe gen(	
//        .ti_clk(ti_clk),
//        .reset(reset_global),
//        .repop(reset_sim),
//        .feed_data_valid(is_pipe_being_written),
//        .feed_data(lce_from_py),
//        .current_element(current_lce),
//        .test_clk(sim_clk),
//        .done_feeding(is_lce_valid)
//    );        

    // *** Spindle: current_lce => Ia_fr
//    spindle bag1_bag2_chain(	.gamma_dyn(gamma_dyn), // 32'h42A0_0000
//                        .gamma_sta(gamma_dyn),
//					.lce(current_lce),
//					.clk(spindle_clk),
//					.reset(reset_sim),
//					.out0(x_0),
//                    .out1(x_1),
//                    .out2(II_fr),
//                    .out3(Ia_fr),
//                    .BDAMP_1(BDAMP_1),
//                    .BDAMP_2(BDAMP_2),
//                    .BDAMP_chain(BDAMP_chain),
//                    .GI(GI),
//                    .GII(GII)
//		);

    // *** Izhikevich: Ia_fr => spikes
        // *** Convert float_fr to int_I1
	/*
    wire [31:0] float_I1;
    wire [17:0] int_I1;

	mult pps_to_I( .x(Ia_fr), .y(32'h438C_E666), .out(float_I1));
	floor float_to_int( .in(float_I1), .out(int_I1) );
    */
//    spindle_neuron Ia_neuron(	.pps(Ia_fr),
//								.clk(sim_clk),
//                                .reset(reset_sim),
//								.spike(Ia_spike)
//    );
//   spindle_neuron II_neuron(	.pps(II_fr),
//								.clk(sim_clk),
//                                .reset(reset_sim),
//								.spike(II_spike)
//    );
    // *** Create 1 Izh-neuron
    
//	wire [3:0] a, b, tau;
//	wire [17:0] c, d, v1, u1, s1;
//	assign a = 3 ;  // bits for shifting, a = 0.125
//	assign b =  2 ;  // bits for shifting, b = 0.25
//	assign c =  18'sh3_599A ; // -0.65  = dec2hex(1+bitcmp(ceil(0.65 * hex2dec('ffff')),18)) = 3599A
//	assign d =  18'sh0_147A ; // 0.08 = dec2hex(floor(0.08 * hex2dec('ffff'))) = 147A
//	assign tau = 4'h2;
	
    
//	wire [1:0] state;
//	assign state = neuronCounter[1:0];
//	assign neuronIndex = neuronCounter[NN+2:2];
//	
//	wire state1, state2, state3, state4;
//	assign state1 = (state == 2'h0);
//	assign state2 = (state == 2'h1);
//	assign state3 = (state == 2'h2);
//	assign state4 = (state == 2'h3);
//	
//	wire neuronWriteCount, readClock, neuronWriteEnable, dataValid;
//	
//	assign neuronWriteCount = state1;	//increment neuronID (ram address)
//	assign readClock = state2;				//read RAM
//	assign neuronWriteEnable = state4; //(state3 | state4);	//write RAM
//	assign dataValid = firstNeuron;  //(neuronIndex ==0) & state2; //(neuronIndex == 1);   //slight delay of positive edge to allow latch set-up times
		
	//Iz_neuron #(.NN(NN),.DELAY(10)) neuIa(v1,s1, a,b,c,d, int_I1[17:0], test_clk, reset_sim, neuronIndex, neuronWriteEnable, readClock, tau, spike);
//	always @(negedge neuronIndex[0]) rawspikes <= {1'b0, neuronIndex[NN:2], spike, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
    // Instantiate the okHost and connect endpoints.
    // Host interface
    
    
    // *** Endpoint connections:
    assign pin0 = neuron_clk;
    assign pin1 = sim_clk;
    assign pin2 = spindle_clk;
//    assign ep20wire = Ia_fr[15:0];
//    assign ep21wire = Ia_fr[31:16];
//  
//    assign ep22wire = current_lce[15:0];
//    assign ep23wire = current_lce[31:16];
//    assign ep24wire = v1[15:0];
//    assign ep25wire = {16'b0, v1[17:16]};
//    assign ep26wire = x_1[15:0];
//    assign ep27wire = x_1[31:16];
//    assign ep28wire = spike_count_out[15:0];
//    assign ep29wire = spike_count_out[31:16];
//    assign ep30wire = II_fr[15:0];
//    assign ep31wire = II_fr[31:16];
      
    okHost okHI(
        .hi_in(hi_in), .hi_out(hi_out), .hi_inout(hi_inout), .hi_aa(hi_aa), .ti_clk(ti_clk),
        .ok1(ok1), .ok2(ok2));

    wire [17*14-1:0]  ok2x;
    okWireOR # (.N(14)) wireOR (ok2, ok2x);
    okWireIn     wi00 (.ok1(ok1),                           .ep_addr(8'h00), .ep_dataout(ep00wire));
    okWireIn     wi01 (.ok1(ok1),                           .ep_addr(8'h01), .ep_dataout(ep01wire));
    okWireIn     wi02 (.ok1(ok1),                           .ep_addr(8'h02), .ep_dataout(ep02wire));

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
    okWireOut    wo30 (.ok1(ok1), .ok2(ok2x[ 12*17 +: 17 ]), .ep_addr(8'h30), .ep_datain(ep30wire));
    okWireOut    wo31 (.ok1(ok1), .ok2(ok2x[ 13*17 +: 17 ]), .ep_addr(8'h31), .ep_datain(ep31wire));
        
     //ep_ready = 1 (always ready to receive)
    okBTPipeIn   ep80 (.ok1(ok1), .ok2(ok2x[ 10*17 +: 17 ]), .ep_addr(8'h80), .ep_write(is_pipe_being_written), .ep_blockstrobe(), .ep_dataout(lce_from_py), .ep_ready(1'b1));

    okBTPipeOut  epA0 (.ok1(ok1), .ok2(ok2x[ 11*17 +: 17 ]), .ep_addr(8'ha1), .ep_read(pipe_out_read),  .ep_blockstrobe(), .ep_datain(rawspikes), .ep_ready(1'b1));

    okTriggerIn ep50 (.ok1(ok1),  .ep_addr(8'h50), .ep_clk(clk1), .ep_trigger(ep50trig));
endmodule

