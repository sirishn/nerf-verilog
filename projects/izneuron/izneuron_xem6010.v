`timescale 1ns / 1ps

module izneuron_xem6010(
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

    reg [31:0] I;
    always @(posedge ep50trig[6] or posedge reset_global)
    begin
        if (reset_global)
            I <= 32'd10240;
        else
            I <= {ep02wire, ep01wire};  //firing rate
    end      

    
    // *** Deriving clocks from on-board clk1:
    wire neuron_clk;
    wire sim_clk;

    gen_clk #(.NN(NN)) useful_clocks
    (   .rawclk(clk1), 
        .half_cnt(delay_cnt_max), 
        .clk_out1(neuron_clk), 
        .clk_out2(sim_clk), 
        .clk_out3(),
        .int_neuron_cnt_out() );
                
    wire [36:0] casr_out;
    wire [42:0] lfsr_out;
    wire [31:0] random_out;
    rng rng_0(
            .clk1(neuron_clk),
            .clk2(neuron_clk),
            .reset(reset_global),
            .out(random_out),
            
            .lfsr(lfsr_out),
            .casr(casr_out)
    );
    
    wire [31:0] noisy_I;
    assign noisy_I = {I[31:10], random_out[9:0]};
    
    wire [31:0] v;
    wire spike;
    wire [127:0] population;
    izneuron neuron_0(
                .clk(neuron_clk),
                .reset(reset_global),
                .I_in(noisy_I),
                .v_out(v),
                .spike(spike),
                
                .population(population)
    );


    assign led[7:1] = 7'b1111111;
    assign led[0] = ~spike;

    // *** OpalKelly XEM interface
    okHost okHI(
        .hi_in(hi_in), .hi_out(hi_out), .hi_inout(hi_inout), .hi_aa(hi_aa), .ti_clk(ti_clk),
        .ok1(ok1), .ok2(ok2));

    wire [17*11-1:0]  ok2x;
    okWireOR # (.N(11)) wireOR (ok2, ok2x);
    wire [15:0]  ep00wire, ep01wire, ep02wire;
    assign reset_global = ep00wire[0];
    
    okWireIn     wi00 (.ok1(ok1),                           .ep_addr(8'h00), .ep_dataout(ep00wire));
    okWireIn     wi01 (.ok1(ok1),                           .ep_addr(8'h01), .ep_dataout(ep01wire));
    okWireIn     wi02 (.ok1(ok1),                           .ep_addr(8'h02), .ep_dataout(ep02wire));
    
    okWireOut    wo20 (.ep_datain(v[15:0]), .ok1(ok1), .ok2(ok2x[  0*17 +: 17 ]), .ep_addr(8'h20) );
    okWireOut    wo21 (.ep_datain(v[31:16]), .ok1(ok1), .ok2(ok2x[  1*17 +: 17 ]), .ep_addr(8'h21) );
    okWireOut    wo30 (.ep_datain(population[15:0]), .ok1(ok1), .ok2(ok2x[  2*17 +: 17 ]), .ep_addr(8'h30) );
    okWireOut    wo31 (.ep_datain(population[31:16]), .ok1(ok1), .ok2(ok2x[  3*17 +: 17 ]), .ep_addr(8'h31) );
    okWireOut    wo32 (.ep_datain(population[47:32]), .ok1(ok1), .ok2(ok2x[  4*17 +: 17 ]), .ep_addr(8'h32) );
    okWireOut    wo33 (.ep_datain(population[63:48]), .ok1(ok1), .ok2(ok2x[  6*17 +: 17 ]), .ep_addr(8'h33) );
    okWireOut    wo34 (.ep_datain(population[79:64]), .ok1(ok1), .ok2(ok2x[  7*17 +: 17 ]), .ep_addr(8'h34) );
    okWireOut    wo35 (.ep_datain(population[95:80]), .ok1(ok1), .ok2(ok2x[  8*17 +: 17 ]), .ep_addr(8'h35) );
    okWireOut    wo36 (.ep_datain(population[111:96]), .ok1(ok1), .ok2(ok2x[  9*17 +: 17 ]), .ep_addr(8'h36) );
    okWireOut    wo37 (.ep_datain(population[127:112]), .ok1(ok1), .ok2(ok2x[  10*17 +: 17 ]), .ep_addr(8'h37) );    
    wire [15:0] ep50trig;
    okTriggerIn ep50 (.ok1(ok1),  .ep_addr(8'h50), .ep_clk(clk1), .ep_trigger(ep50trig));
endmodule