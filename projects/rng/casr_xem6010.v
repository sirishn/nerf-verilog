`timescale 1ns / 1ps

module rng_xem6010(
	input  wire [7:0]  hi_in,
	output wire [1:0]  hi_out,
	inout  wire [15:0] hi_inout,
	inout  wire        hi_aa,

	output wire        i2c_sda,
	output wire        i2c_scl,
	output wire        hi_muxsel,
	input  wire        clk1,
	input  wire        clk2,
	
	output wire [7:0]  led
   );
   
    parameter NN = 8;
		
    // *** Dump all the declarations here:
    wire         ti_clk;
    wire [30:0]  ok1;
    wire [16:0]  ok2;   
    wire reset_global;

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
    

    
    // *** Deriving clocks from on-board clk1:
    wire rng_clk;

    gen_clk #(.NN(NN)) useful_clocks
    (   .rawclk(clk1), 
        .half_cnt(delay_cnt_max), 
        .clk_out1(), 
        .clk_out2(rng_clk), 
        .clk_out3(),
        .int_neuron_cnt_out() );
                
    wire [36:0] casr_out;
    wire [42:0] lfsr_out;
    wire [31:0] rng_out;
    rng rng_0(
            .clk1(rng_clk),
            .clk2(rng_clk),
            .reset(reset_global),
            .out(rng_out),
            
            .lfsr(lfsr_out),
            .casr(casr_out)
    );


    assign led = rng_out[7:0];

    // *** OpalKelly XEM interface
    okHost okHI(
        .hi_in(hi_in), .hi_out(hi_out), .hi_inout(hi_inout), .hi_aa(hi_aa), .ti_clk(ti_clk),
        .ok1(ok1), .ok2(ok2));

    wire [17*6-1:0]  ok2x;
    okWireOR # (.N(6)) wireOR (ok2, ok2x);
    wire [15:0]  ep00wire, ep01wire, ep02wire;
    assign reset_global = ep00wire[0];
    
    okWireIn     wi00 (.ok1(ok1),                           .ep_addr(8'h00), .ep_dataout(ep00wire));
    okWireIn     wi01 (.ok1(ok1),                           .ep_addr(8'h01), .ep_dataout(ep01wire));
    okWireIn     wi02 (.ok1(ok1),                           .ep_addr(8'h02), .ep_dataout(ep02wire));
    
    okWireOut    wo20 (.ep_datain(rng_out[15:0]), .ok1(ok1), .ok2(ok2x[  0*17 +: 17 ]), .ep_addr(8'h20) );
    okWireOut    wo21 (.ep_datain(rng_out[31:16]), .ok1(ok1), .ok2(ok2x[  1*17 +: 17 ]), .ep_addr(8'h21) );
    okWireOut    wo30 (.ep_datain(casr_out[20:5]), .ok1(ok1), .ok2(ok2x[  2*17 +: 17 ]), .ep_addr(8'h30) );
    okWireOut    wo31 (.ep_datain(casr_out[36:21]), .ok1(ok1), .ok2(ok2x[  3*17 +: 17 ]), .ep_addr(8'h31) );
    okWireOut    wo32 (.ep_datain(lfsr_out[26:11]), .ok1(ok1), .ok2(ok2x[  4*17 +: 17 ]), .ep_addr(8'h32) );
    okWireOut    wo33 (.ep_datain(lfsr_out[42:27]), .ok1(ok1), .ok2(ok2x[  5*17 +: 17 ]), .ep_addr(8'h33) );
    
    wire [15:0] ep50trig;
    okTriggerIn ep50 (.ok1(ok1),  .ep_addr(8'h50), .ep_clk(clk1), .ep_trigger(ep50trig));
endmodule
