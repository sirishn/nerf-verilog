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
module limb_xem6010(
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
    wire        is_pipe_being_written, is_hex_valid;

    wire [31:0] current_lce;
    wire [15:0] hex_from_py;

    wire [31:0] Ia_fr, x_0, x_1, II_fr;
    
    
    wire pipe_out_read;
    // *** Target interface bus:
    assign i2c_sda = 1'bz;
    assign i2c_scl = 1'bz;
    assign hi_muxsel = 1'b0;

    // *** Triggered input from Python
    reg [31:0] delay_cnt_max;
    always @(posedge ep50trig[7] or posedge reset_global)
    begin
        if (reset_global)
            delay_cnt_max <= delay_cnt_max;
        else
            delay_cnt_max <= {ep02wire, ep01wire};  //firing rate
    end    
    
    reg [31:0] gamma_dyn;
    always @(posedge ep50trig[4] or posedge reset_global)
    begin
        if (reset_global)
            gamma_dyn <= 32'h4220_0000; // gamma_dyn reset to 80
        else
            gamma_dyn <= {ep02wire, ep01wire};  //firing rate
    end 
	 
    reg [31:0] gamma_sta;
    always @(posedge ep50trig[5] or posedge reset_global)
    begin
        if (reset_global)
            gamma_sta <= 32'h4220_0000; // gamma_sta reset to 80
        else
            gamma_sta <= {ep02wire, ep01wire};  //firing rate
    end
	 
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
    always @(posedge ep50trig[12] or posedge reset_global)
    begin
        if (reset_global)
            GI <= 32'h469C4000; // GI reset to 20000
        else
            GI <= {ep02wire, ep01wire};  //firing rate
    end    
    always @(posedge ep50trig[11] or posedge reset_global)
    begin
        if (reset_global)
            GII <= 32'h45E2_9000; // GII reset to 7250
        else
            GII <= {ep02wire, ep01wire};  //firing rate
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
    wire    [31:0] f_ext_trq;
	waveform_from_pipe gen(	
        .ti_clk(ti_clk),
        .reset(reset_global),
        .repop(reset_sim),
        .feed_data_valid(is_pipe_being_written),
        .feed_data(hex_from_py),
        .current_element(f_ext_trq),
        .test_clk(sim_clk),
        .done_feeding(is_hex_valid)
    );        

    
    // *** Limb dynamics
    wire    [31:0]  f_trq_elbow, f_pos_elbow, f_vel_elbow, f_acc_elbow;
    limb elbow( .trq1(32'd0), 
                .trq2(32'd0), 
                .ext_trq(f_ext_trq), 
                .pos_default(32'd0), 
                .vel_default(32'd0), 
                .reset(reset_sim), 
                .clk(sim_clk), 
                .trq_out(f_trq_elbow), 
                .pos_out(f_pos_elbow), 
                .vel_out(f_vel_elbow), 
                .acc_out(f_acc_elbow) );
    
    
    // ** LEDs 0 = ON    
    assign led[4:2] = 3'b111;
    assign led[0] = ~spindle_clk;
    assign led[1] = 1'b1;
    assign led[5] = ~neuron_clk;
    assign led[6] = ~sim_clk;
    assign led[7] = ~reset_global;
    
      
    // *** Buttons, physical on XEM3010, software on XEM3050 & XEM6010
    assign reset_global = ep00wire[0];
    assign reset_sim = ep00wire[1];
    
    // *** Endpoint connections:
    assign pin0 = sim_clk;
    assign pin1 = 0;//Ia_spike;
    assign pin2 = 0;//II_spike;
    
//    assign ep20wire = Ia_fr[15:0];
//    assign ep21wire = Ia_fr[31:16];
    assign ep22wire = f_ext_trq[15:0];
    assign ep23wire = f_ext_trq[31:16];
//    assign ep24wire = v1[15:0];
//    assign ep25wire = {16'b0, v1[17:16]};
    assign ep26wire = f_acc_elbow[15:0];
    assign ep27wire = f_acc_elbow[31:16];
    assign ep28wire = f_vel_elbow[15:0];
    assign ep29wire = f_vel_elbow[31:16];
    assign ep30wire = f_pos_elbow[15:0];
    assign ep31wire = f_pos_elbow[31:16];
      
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
    okBTPipeIn   ep80 (.ok1(ok1), .ok2(ok2x[ 10*17 +: 17 ]), .ep_addr(8'h80), .ep_write(is_pipe_being_written), .ep_blockstrobe(), .ep_dataout(hex_from_py), .ep_ready(1'b1));

    okBTPipeOut  epA0 (.ok1(ok1), .ok2(ok2x[ 11*17 +: 17 ]), .ep_addr(8'ha1), .ep_read(pipe_out_read),  .ep_blockstrobe(), .ep_datain(rawspikes), .ep_ready(1'b1));

    okTriggerIn ep50 (.ok1(ok1),  .ep_addr(8'h50), .ep_clk(clk1), .ep_trigger(ep50trig));
endmodule

