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
module emg_xem6010(
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
    wire button1 = ep00wire[2];  // testing sensitivity list
    wire button2 = ep00wire[3];
    //assign enable_sim = is_waveform_valid;
    wire    [31:0]  IEEE_1, IEEE_0;
	assign IEEE_1 = 32'h3F800000;
	assign IEEE_0 = 32'd0;
        
    // *** Triggered input from Python

        
    reg [31:0] i_gain_MN;
    always @(posedge ep50trig[6] or posedge reset_global)
    begin
        if (reset_global)
            i_gain_MN <= 32'd1; // gamma_sta reset to 80
        else
            i_gain_MN <= {ep02wire, ep01wire};  
    end    
       
    always @(posedge ep50trig[7] or posedge reset_global)
    begin
        if (reset_global)
            delay_cnt_max <= delay_cnt_max;
        else
            delay_cnt_max <= {2'b00, ep01wire};  //firing rate
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
    wire    [31:0] f_rawfr_Ia;
    waveform_from_pipe gen(	
        .ti_clk(ti_clk),
        .reset(reset_global),
        .repop(reset_sim),
        .feed_data_valid(is_pipe_being_written),
        .feed_data(hex_from_py),
        .current_element(f_rawfr_Ia),
        .test_clk(sim_clk),
        .done_feeding(is_lce_valid)
    );    

    wire MN_spike;
    neuron_pool #(.NN(NN)) pool_bic
    (   .f_rawfr_Ia(f_rawfr_Ia),     //
        .f_pps_coef_Ia(32'h3F66_6666), //
        .half_cnt(delay_cnt_max),
        .rawclk(clk1),
        .ti_clk(ti_clk),
        .reset_sim(reset_sim),
        .i_gain_MN(i_gain_MN),
        .neuronCounter(neuronCounter),
        .MN_spike(MN_spike)
    );   

    // *** spike counter 
    wire    [31:0] i_MN_spk_cnt;
    wire    clear_out;
//    spike_counter count_rawspikes
//    (   .spike(MN_spike), 
//        .slow_clk(sim_clk), 
//        .reset(reset_sim),
//        .int_cnt_out(i_MN_spk_cnt),
//        .clear_out(clear_out) );
  
   spikecnt count_rawspikes
   (    .spike(MN_spike), 
        .int_cnt_out(i_MN_spk_cnt), 
        .fast_clk(neuron_clk), 
        .slow_clk(sim_clk), 
        .reset(reset_sim), 
        .clear_out(clear_out));        
    
    // *** EMG
    wire [31:0] si_emg; // short integer, 18-bit
    emg #(.NN(NN)) muscle_emg
    (   .emg_out(si_emg), 
        .i_spk_cnt(i_MN_spk_cnt[NN : 0]), 
        .clk(sim_clk), 
        .reset(reset_sim) );
            

    // ** LEDs
    assign led[0] = ~reset_global;
    assign led[1] = ~reset_sim;
    assign led[2] = ~clk1;
    assign led[3] = ~0;
    assign led[4] = ~MN_spike;
    assign led[5] = ~sim_clk; //fast clock
    assign led[6] = ~spindle_clk; // slow clock
    //assign led[5] = ~spike;
    //assign led[5] = ~button1_response;
    //assign led[6] = ~button2_response;
    //assign led[6] = ~reset_sim;
    assign led[7] = 1'b1;
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

    wire [17*11-1:0]  ok2x;
    okWireOR # (.N(11)) wireOR (ok2, ok2x);
    okWireIn     wi00 (.ok1(ok1),                           .ep_addr(8'h00), .ep_dataout(ep00wire));
    okWireIn     wi01 (.ok1(ok1),                           .ep_addr(8'h01), .ep_dataout(ep01wire));
    okWireIn     wi02 (.ok1(ok1),                           .ep_addr(8'h02), .ep_dataout(ep02wire));
    //okWireIn     wi03 (.ok1(ok1),                           .ep_addr(8'h03), .ep_dataout(ep001wire));

    okWireOut    wo20 (.ep_datain(si_emg[15:0]), .ok1(ok1), .ok2(ok2x[  0*17 +: 17 ]), .ep_addr(8'h20) );
    okWireOut    wo21 (.ep_datain({{14{si_emg[17]}},si_emg[17:16]}), .ok1(ok1), .ok2(ok2x[  1*17 +: 17 ]), .ep_addr(8'h21) );
    okWireOut    wo22 (.ep_datain(f_rawfr_Ia[15:0]), .ok1(ok1), .ok2(ok2x[  2*17 +: 17 ]), .ep_addr(8'h22) );
    okWireOut    wo23 (.ep_datain(f_rawfr_Ia[31:16]), .ok1(ok1), .ok2(ok2x[  3*17 +: 17 ]), .ep_addr(8'h23) );
    okWireOut    wo24 (.ep_datain(i_MN_spk_cnt[15:0]), .ok1(ok1), .ok2(ok2x[  4*17 +: 17 ]), .ep_addr(8'h24) );
    okWireOut    wo25 (.ep_datain(i_MN_spk_cnt[31:16]), .ok1(ok1), .ok2(ok2x[  5*17 +: 17 ]), .ep_addr(8'h25) );

     //ep_ready = 1 (always ready to receive)
    okBTPipeIn   ep80 (.ok1(ok1), .ok2(ok2x[ 10*17 +: 17 ]), .ep_addr(8'h80), .ep_write(is_pipe_being_written), .ep_blockstrobe(), .ep_dataout(hex_from_py), .ep_ready(1'b1));
    //okBTPipeOut  epA0 (.ok1(ok1), .ok2(ok2x[ 11*17 +: 17 ]), .ep_addr(8'ha1), .ep_read(pipe_out_read),  .ep_blockstrobe(), .ep_datain(rawspikes), .ep_ready(1'b1));
    //okBTPipeOut  epA0 (.ok1(ok1), .ok2(ok2x[ 5*17 +: 17 ]), .ep_addr(8'ha0), .ep_read(pipe_out_read),  .ep_blockstrobe(), .ep_datain(response_nerf), .ep_ready(pipe_out_valid));

    okTriggerIn ep50 (.ok1(ok1),  .ep_addr(8'h50), .ep_clk(clk1), .ep_trigger(ep50trig));
endmodule

