module spindle_bag1(gamma_dyn, lce, clk, reset, out0, out1, out2, out3);

input [31:0] gamma_dyn;
input [31:0] lce;
input clk;
input reset;
output wire [31:0] out0;
output wire [31:0] out1;
output wire [31:0] out2;
output wire [31:0] out3;
        
    // *** Declarations
    reg [31:0] Ia_fiber;
	wire [31:0] IEEE_100000;
	assign IEEE_100000 = 32'h47C3_5000;

	//model derivatives 
	wire [31:0] dx_0;
	wire [31:0] dx_1;
	wire [31:0] dx_2;

	wire [31:0] x_0_F0;
	wire [31:0] x_1_F0;
	wire [31:0] x_2_F0;

	//State variables
	reg [31:0] x_0;
	reg [31:0] x_1;
	reg [31:0] x_2;
    
    // *** Output layouts
    assign out0 = x_0;
    assign out1 = x_1;
    assign out2 = x_2;
    assign out3 = Ia_fiber;

    // *** BEGIN COMBINATIONAL LOGICS
	
	//Ia fiber pps calculation
	wire [31:0] LSR0_0;	
	assign LSR0_0	= 32'h3D23D70A;

	wire [31:0] GI_0;
	assign GI_0	    = 32'h469C4000;

	wire [31:0] Ia_fiber_RR2, Ia_fiber_R1, Ia_fiber_F0;
	add Ia_fiber_a1( .x(x_1_F0), .y(LSR0_0), .out(Ia_fiber_RR2) );
	sub Ia_fiber_s1( .x(lce), .y(Ia_fiber_RR2), .out(Ia_fiber_R1) );
    mult Ia_fiber_m1( .x(GI_0), .y(Ia_fiber_R1), .out(Ia_fiber_F0) );
    //
	//assign Ia_fiber = Ia_fiber_F0;
	
	
	wire [31:0] Ia_max_flag;
	sub Ia_fiber_max( .x(IEEE_100000), .y(Ia_fiber_F0), .out(Ia_max_flag));


	//loeb spindle bag1 derivatives
	spindle_bag1_derivatives	
    dev_for_bag1(	
            .gamma_dyn(gamma_dyn), 
            .lce(lce), 
            .x_0(x_0), 
            .x_1(x_1), 
            .x_2(x_2),
            .dx_0(dx_0),
            .dx_1(dx_1),
            .dx_2(dx_2) );	
            
    //integrate state variables (euler integration)
	integrator x_0_integrator (	.x(dx_0), .int_x(x_0), .out(x_0_F0) );
	integrator x_1_integrator (	.x(dx_1), .int_x(x_1), .out(x_1_F0) );
	integrator x_2_integrator (	.x(dx_2), .int_x(x_2), .out(x_2_F0) );


//BEGIN SEQUENTIAL LOGICS
	always @ (posedge clk or posedge reset)
	begin
		if (reset) begin
			Ia_fiber <= 32'h0000_0000;
			x_0 <= 32'h0000_0000;
			x_1 <= 32'h3F75_38EF; //0.9579 
			x_2 <= 32'h0000_0000;
		end
		else begin
            x_0 <= x_0_F0;
            x_1 <= x_1_F0;
            x_2 <= x_2_F0;	
            if (Ia_fiber_F0[31]) begin // if Ia_fr < 0 pps
                Ia_fiber <= 32'h0000_0000;
                //Ia_fiber <= x_0_F0;
            end
            else begin // if Ia_fr > 0
                if (Ia_max_flag[31]) begin // if Ia_fr > 10000 pps
                    Ia_fiber <= IEEE_100000;
                    //Ia_fiber <= x_0_F0;

                end
                else begin // Ia_fr fine
                    Ia_fiber<=Ia_fiber_F0;
                    //Ia_fiber <= x_0_F0;
                end
            end
        end
	end	
endmodule


module spindle_bag1_derivatives(	input [31:0]gamma_dyn, 
					input [31:0]lce, 
					input [31:0]x_0, 
					input [31:0]x_1, 
					input [31:0]x_2,
					output [31:0] dx_0,
					output [31:0] dx_1,
					output [31:0] dx_2
					);

	//Min Gamma Dynamic Calculation
	//
    	//From spindle.py
	//	mingd = gammaDyn**2/(gammaDyn**2+60**2)
	//
	wire [31:0] mingd;
	wire [31:0] gamma_dyn_sqr;
	wire [31:0] gamma_dyn_R1;
	wire [31:0] IEEE_3600, IEEE_0_01;
	assign IEEE_3600 = 32'h4561_0000;
    assign IEEE_0_01 = 32'h3C23D70A;
	
	mult min_gamma_dyn_m1( .x(gamma_dyn), .y(gamma_dyn), .out(gamma_dyn_sqr) );
	add min_gamma_dyn_a1( .x(gamma_dyn_sqr), .y(IEEE_3600), .out(gamma_dyn_R1) );
	div min_gamma_dyn_d1( .x(gamma_dyn_sqr), .y(gamma_dyn_R1), .out(mingd) );
	
	//assign mingd = 32'h3F23_D70A;	

	//dx_0 calculation
	//
	//From spindle.py
	//	dx_0 = (mingd-x_0)/0.149
	//
	wire [31:0] dx_0_R1, IEEE_ZERO_POINT_ONE_FOUR_NINE;
	assign IEEE_ZERO_POINT_ONE_FOUR_NINE = 32'h3E18_9375;
	sub dx_0_s1( .x(mingd), .y(x_0), .out(dx_0_R1) );
	div dx_0_d1( .x(dx_0_R1), .y(IEEE_ZERO_POINT_ONE_FOUR_NINE), .out(dx_0) );

	//dx_1 calculation
	//
	//From spindle.py
	//    dx_1 = x_2
	//
	assign dx_1 = x_2;

	//CSS calculation
	//
	//From spindle.py
    	//if (-1000.0*x_2 > 100.0):
        //	CSS = -1.0
    	//elif (-1000.0*x_2 < -100.0):
        //	CSS = 1.0
    	//else:
        //	CSS = (2.0 / (1.0 + exp(-1000.0*x_2) ) ) - 1.0
	//
	//approximating this to copysign(1.0, x_2)
	wire [31:0] CSS;
	assign CSS[30:0] = 31'h3F80_0000;
	assign CSS[31] = x_2[31];

	//dx_2 calculation
	//
	//From spindle.py
	//dx_2 = (1/MASS) * (KSR*lce - (KSR+KPR)*x_1 - CSS*(BDAMP*x_0)*(abs(x_2)**0.25) - 0.4)
	//
	wire [31:0] C_REV_M, C_KSR, C_KSR_P_KPR, C_KPR_M_LSR0, C_KSR_M_LSR0;
	wire [31:0] abs_x2_pow_25, abs_x2_pow_25_unchk;
	wire [31:0] BDAMP;
	wire [31:0] dx_2_RRRRR5, dx_2_RRRRLR6, dx_2_RRRRL5, dx_2_RRRR4;
	wire [31:0] dx_2_RRRLRR6, dx_2_RRRLRLR7, dx_2_RRRLRL6, dx_2_RRRLR5;
	wire [31:0] dx_2_RRRL4, dx_2_RRR3, dx_2_RRL3, dx_2_RR2, dx_2_RL2;
	wire [31:0] dx_2_R1, dx_2_F0;
	wire [31:0] IEEE_ZERO_POINT_FOUR;
	wire [31:0] dx_2_RRLL4;

	assign IEEE_ZERO_POINT_FOUR = 32'h3ECCCCCC;// 0.4
	assign BDAMP = 32'h3E71_4120;//BDAMP = 0.2356	
	assign C_REV_M = 32'h459C4000;//1/M[j] = 1 / 0.0002 = 5000
	assign C_KSR = 32'h4127703B; //KSR=10.4649
	assign C_KSR_P_KPR = 32'h41293DD9;//KSR[j]+KPR[j] = 10.4649 + 0.1127 = 10.5776
	assign C_KSR_M_LSR0 = 32'h3ED652BD;//KSR[j]*LSR0[j] = 10.4649*0.04 = 0.4186
	assign C_KPR_M_LSR0 = 32'h3DAF6944;//KPR[j]*LPR0[j] = 0.1127*0.76= 0.08565
    wire [31:0] flag_abs_x2_pow_25;
	
	pow_25	dx_2_p1(	.x({1'b0, x_2[30:0]}), .out(abs_x2_pow_25_unchk) );
    sub abs_x2_pow_25_max( .x(IEEE_0_01), .y({1'b0, x_2[30:0]}), .out(flag_abs_x2_pow_25));

    assign abs_x2_pow_25 = (flag_abs_x2_pow_25[31]) ? abs_x2_pow_25_unchk : {1'b0, x_2[30:0]};
	
	wire [31:0] css_bdamp;
	assign css_bdamp = {x_2[31], BDAMP[30:0]};

	mult dx_2_RRRLRL6_mult( .x(css_bdamp), .y(x_0), .out(dx_2_RRRLRL6) );

	mult dx_2_RRRLR5_mult( .x(dx_2_RRRLRL6), .y(abs_x2_pow_25), .out(dx_2_RRRL4) );

	add dx_2_RRR3_add( .x(dx_2_RRRL4), .y(IEEE_ZERO_POINT_FOUR), .out(dx_2_RRR3) );


	mult dx_2_RRL3_mult( .x(C_KSR_P_KPR), .y(x_1), .out(dx_2_RRL3) );
	//     - dx_2_RRL3  @@@@  dx_2_RRR3    =>    dx_2_RR2
	add dx_2_RR2_add( .x(dx_2_RRL3), .y(dx_2_RRR3), .out(dx_2_RR2) );
	//     * KSR_0  @@@@  LCE_0    =>    dx_2_RL2
	mult dx_2_RL2_mult( .x(C_KSR), .y(lce), .out(dx_2_RL2) );
	//     - dx_2_RL2  @@@@  dx_2_RR2    =>    dx_2_R1
	sub dx_2_R1_sub( .x(dx_2_RL2), .y(dx_2_RR2), .out(dx_2_R1) );
	//     * C_REV_M  @@@@  dx_2_R1    =>    dx_2
	mult dx_2_F0_mult( .x(C_REV_M), .y(dx_2_R1), .out(dx_2) );
endmodule


