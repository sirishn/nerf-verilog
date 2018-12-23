`timescale 1ns / 1ps
`default_nettype none

module spindle(
    input wire [31:0] gamma_dyn,
    input wire [31:0] gamma_sta,
    input wire [31:0] lce,
    input wire clk,
    input wire reset,
    output wire [31:0] out0,
    output wire [31:0] out1,
    output wire [31:0] out2,
    output wire [31:0] out3,
    input  wire [31:0] BDAMP_1,
    input  wire [31:0] BDAMP_2,
    input  wire [31:0] BDAMP_chain
    );


        
    // *** Declarations
	reg [1:0] state;   	
	//wire [1:0] state;
    //assign state = 2'd0;
    reg [31:0] Ia_fiber_2, II_fiber_2;
    reg [31:0] Ia_muscle, II_muscle;
	wire [31:0] IEEE_100000;
	assign IEEE_100000 = 32'h47C3_5000;

	//model derivatives 
	wire [31:0] dx_0;
	wire [31:0] dx_1;
	wire [31:0] dx_2;
	
	wire [31:0] x_0_hat;
	wire [31:0] x_1_hat;
	wire [31:0] x_2_hat;
	wire [31:0] x_0_F0;
	wire [31:0] x_1_F0;
	wire [31:0] x_2_F0;
	
	reg [31:0] x_0_in;
	reg [31:0] x_1_in;
	reg [31:0] x_2_in;
	reg [31:0] dx_0_in;
	reg [31:0] dx_1_in;
	reg [31:0] dx_2_in;

	//State variables
	
	//bag1	
	reg [31:0] x_0;
	reg [31:0] x_1;
	reg [31:0] x_2;
	reg [31:0] dx_0_prev;
	reg [31:0] dx_1_prev;
	reg [31:0] dx_2_prev;
	
	//bag2
	reg [31:0] x_3;
	reg [31:0] x_4;
	reg [31:0] x_5;
	reg [31:0] dx_3_prev;
	reg [31:0] dx_4_prev;
	reg [31:0] dx_5_prev;
    
    //chain
    reg [31:0] x_6;
    reg [31:0] x_7;
    reg [31:0] x_8;
    reg [31:0] dx_6_prev;
    reg [31:0] dx_7_prev;
    reg [31:0] dx_8_prev;
   
	wire [31:0] GI_0, GI_2_chain;
	//assign GI_0 = GI;
   assign GI_0	    = 32'h469C4000;		//20000
	assign GI_2_chain = 32'h461C4000;	//10000
	
	reg [31:0] GI_in;
	always @ (state or reset) begin
        if (reset) begin
            x_0_in = 0;
            x_1_in = 0;
            x_2_in = 0;
            dx_0_in = 0;
            dx_1_in = 0;
            dx_2_in = 0;
            GI_in = 0;
        end
        else begin
		case (state) 
			0: begin //bag1
				x_0_in = x_0;
				x_1_in = x_1;
				x_2_in = x_2;
				dx_0_in = dx_0_prev;
				dx_1_in = dx_1_prev;
				dx_2_in = dx_2_prev;
				GI_in = GI_0;
				end
			1: begin //bag2
				x_0_in = x_3;
				x_1_in = x_4;
				x_2_in = x_5;
				dx_0_in = dx_3_prev;
				dx_1_in = dx_4_prev;
				dx_2_in = dx_5_prev;
				GI_in = GI_2_chain;
				end
			2: begin //chain
				x_0_in = x_6;
				x_1_in = x_7;
				x_2_in = x_8;
				dx_0_in = dx_6_prev;
				dx_1_in = dx_7_prev;
				dx_2_in = dx_8_prev;
				GI_in = GI_2_chain;
				end
			default: begin
					x_0_in = 0;
					x_1_in = 0;
					x_2_in = 0;
					dx_0_in = 0;
					dx_1_in = 0;
					dx_2_in = 0;
					GI_in = 0;
					end
		endcase
        end
	end



    reg [31:0] Ia_fiber_1;

	//State variables

    
    // *** Output layouts
    assign out0 = x_0;
    assign out1 = II_fiber_2;
    assign out2 = II_muscle;
    assign out3 = Ia_muscle;

    // *** BEGIN COMBINATIONAL LOGICS
	
	//Ia fiber pps calculation
	wire [31:0] LSR0_0;	
	assign LSR0_0	= 32'h3D23D70A;


	
	
	wire [31:0] Ia_fiber_RR2, Ia_fiber_R1, Ia_fiber_F0, Ia_fiber_F2;
	add Ia_fiber_a1( .x(x_1_F0), .y(LSR0_0), .out(Ia_fiber_RR2) );
	sub Ia_fiber_s1( .x(lce), .y(Ia_fiber_RR2), .out(Ia_fiber_R1) );
    mult Ia_fiber_m1( .x(GI_in), .y(Ia_fiber_R1), .out(Ia_fiber_F2) );

	wire [31:0] Ia_max_flag;
	sub Ia_fiber_max( .x(IEEE_100000), .y(Ia_fiber_F2), .out(Ia_max_flag));

    assign Ia_fiber_F0 = (Ia_max_flag[31]) ? IEEE_100000 :
                            (Ia_fiber_F2[31]) ? 32'd0 : 
                            Ia_fiber_F2;
	//II fiber pps calculation
	wire [31:0] GII;
	assign GII = 32'h45E2_9000; //7250
	
	wire [31:0] C0; // X[j] * L2nd[j]/LSR0[j] = 0.7
	assign C0 = 32'h3F33_3333; //0.7
	
	wire [31:0] fiber_L;
	assign fiber_L = Ia_fiber_R1; // fiber1_L = ( Lce - (x_4 + LSR0) ) 
	
	wire [31:0] C3; // (1 - X[j]) * L2nd[j]/LPR0[j] = 0.01579
	assign C3 = 32'h3C81_5A08; //0.01579

	wire [31:0] C6; //LSR0[j] + LPRN[j] = 0.96
	assign C6 = 32'h3F75_C28F; //0.96

	wire [31:0] R0, R1, R2, R3, R4; //Intermediate outputs
	mult II_fiber_m2(.x(C0), .y(fiber_L), .out(R1) ); //C0 * fiber_L

	sub II_fiber_s1( .x(lce), .y(fiber_L), .out(R2) );
	sub II_fiber_s2( .x(R2), .y(C6), .out(R3) );
	mult II_fiber_m3( .x(C3), .y(R3), .out(R0) );	// C3 * (Lce - fiber_L - C6)
	
	add II_fiber_a1( .x(R1), .y(R0), .out(R4) );
	
	wire [31:0]II_fiber_F2, II_fiber_F0;
	mult II_fiber_m1( .x(GII), .y(R4), .out(II_fiber_F2) ); // II fiber calculation

	wire [31:0] II_max_flag;
	sub II_fiber_max( .x(IEEE_100000), .y(II_fiber_F2), .out(II_max_flag));	

    assign II_fiber_F0 = (II_max_flag[31]) ? IEEE_100000 :
                            (II_fiber_F2[31]) ? 32'd0 : 
                            II_fiber_F2;
                            
    wire [31:0] II_muscle_F0;
    add II_muscle_a1( .x(II_fiber_2), .y(II_fiber_F0), .out(II_muscle_F0) );

    wire [31:0] Ia_bag2chain;
    add Ia_bag2chain_a1( .x(Ia_fiber_2), .y(Ia_fiber_F0), .out(Ia_bag2chain) );
    
    wire [31:0] Ia_bag1_bag2chain;
    sub Ia_bag1_bag2chain_s1( .x(Ia_fiber_1), .y(Ia_bag2chain), .out(Ia_bag1_bag2chain));
    
    wire [31:0] Ia_larger, Ia_smaller;
    assign Ia_larger = (Ia_bag1_bag2chain[31]) ? Ia_bag2chain : Ia_fiber_1;
    assign Ia_smaller = (Ia_bag1_bag2chain[31]) ? Ia_fiber_1 : Ia_bag2chain;
    
    wire [31:0] Ia_muscle_R1, Ia_muscle_F0;
    wire [31:0] IEEE_ZERO_POINT_ONE_FIVE_SIX;
    assign IEEE_ZERO_POINT_ONE_FIVE_SIX = 32'h3E1F_BE77;
    mult Ia_muscle_m1( .x(Ia_smaller), .y(IEEE_ZERO_POINT_ONE_FIVE_SIX), .out(Ia_muscle_R1) );
    add Ia_muscle_a1( .x(Ia_muscle_R1), .y(Ia_larger), .out(Ia_muscle_F0) );
    
    
	integrator x_0_hat_integrator (	.x(dx_0_in), .int_x(x_0_in), .out(x_0_hat) );
	integrator x_1_hat_integrator (	.x(dx_1_in), .int_x(x_1_in), .out(x_1_hat) );
	integrator x_2_hat_integrator (	.x(dx_2_in), .int_x(x_2_in), .out(x_2_hat) );
	//loeb spindle bag1 derivatives
	spindle_derivatives derivatives(    .state(state),	
                                .reset(reset),
                                 .gamma_dyn(gamma_dyn),
                                .gamma_sta(gamma_sta),                                 
            					.lce(lce), 
				            	.x_0(x_0_hat), 
                                .x_1(x_1_hat), 
            					.x_2(x_2_hat),
            					.dx_0(dx_0),
            					.dx_1(dx_1),
            					.dx_2(dx_2),
                                .BDAMP_1(BDAMP_1),
                                .BDAMP_2(BDAMP_2),
                                .BDAMP_chain(BDAMP_chain)
                                );	
            
    	//integrate state variables (euler integration)
	integrator x_0_integrator (	.x(dx_0), .int_x(x_0_in), .out(x_0_F0) );
	integrator x_1_integrator (	.x(dx_1), .int_x(x_1_in), .out(x_1_F0) );
	integrator x_2_integrator (	.x(dx_2), .int_x(x_2_in), .out(x_2_F0) );


//BEGIN SEQUENTIAL LOGICS

	always @ (posedge clk or posedge reset)
	begin
		if (reset) begin 
            state <= 0;	
        end            
		else begin
            state <= state+1;
            if (state == 2'd2) state <= 0;
        end
	end

	always @ (posedge clk or posedge reset)
	begin
		if (reset) begin
            x_0 <= 32'h0000_0000;
			x_1 <= 32'h3F75_38EF; //0.9579
			x_2 <= 32'h0000_0000;
			x_3 <= 32'h0000_0000;
			x_4 <= 32'h3F75_38EF; //0.9579 
			x_5 <= 32'h0000_0000;
            x_6 <= 32'h0000_0000;
			x_7 <= 32'h3F75_38EF; //0.9579
			x_8 <= 32'h0000_0000;
            dx_0_prev <= 32'd0;
			dx_1_prev <= 32'd0;
			dx_2_prev <= 32'd0;
			dx_3_prev <= 32'd0;
			dx_4_prev <= 32'd0;
			dx_5_prev <= 32'd0;
            dx_6_prev <= 32'd0;
			dx_7_prev <= 32'd0;
			dx_8_prev <= 32'd0;
            Ia_fiber_1 <= 32'h0000_0000;
			Ia_fiber_2 <= 32'h0000_0000;
			II_fiber_2 <= 32'h0000_0000;
            II_muscle <= 32'd0;
            Ia_muscle <= 32'd0;
		end
		else case (state)
        2'd0: begin //bag1
		    	x_0 <= x_0_F0;
		    	x_1 <= x_1_F0;
		    	x_2 <= x_2_F0;
                x_3 <= x_3;
		    	x_4 <= x_4;
		    	x_5 <= x_5;
                x_6 <= x_6;
                x_7 <= x_7;
                x_8 <= x_8;
				dx_0_prev <= dx_0;
				dx_1_prev <= dx_1;
				dx_2_prev <= dx_2;            
                dx_3_prev <= dx_3_prev;
				dx_4_prev <= dx_4_prev;
				dx_5_prev <= dx_5_prev;
                dx_6_prev <= dx_6_prev;
				dx_7_prev <= dx_7_prev;
				dx_8_prev <= dx_8_prev;
                
				//Ia fiber output	
		        Ia_fiber_1 <= Ia_fiber_F0;
                Ia_fiber_2 <= Ia_fiber_2;
                II_fiber_2 <= II_fiber_2;
                II_muscle <= II_muscle;
                Ia_muscle <= Ia_muscle;
              end
			2'd1: begin //bag2
                x_0 <= x_0;
		    	x_1 <= x_1;
		    	x_2 <= x_2;
		    	x_3 <= x_0_F0;
		    	x_4 <= x_1_F0;
		    	x_5 <= x_2_F0;
                x_6 <= x_6;
                x_7 <= x_7;
                x_8 <= x_8;
                dx_0_prev <= dx_0_prev;
				dx_1_prev <= dx_1_prev;
				dx_2_prev <= dx_2_prev;
				dx_3_prev <= dx_0;
				dx_4_prev <= dx_1;
				dx_5_prev <= dx_2;
                dx_6_prev <= dx_6_prev;
				dx_7_prev <= dx_7_prev;
				dx_8_prev <= dx_8_prev;
                
                Ia_fiber_1 <= Ia_fiber_1;
				//Ia fiber output	
		        Ia_fiber_2 <= Ia_fiber_F0;
				// II fiber output	
		        II_fiber_2 <= II_fiber_F0;
                II_muscle <= II_muscle;
                Ia_muscle <= Ia_muscle;
              end
           2'd2: begin //chain
                x_0 <= x_0;
		    	x_1 <= x_1;
		    	x_2 <= x_2;
                x_3 <= x_3;
		    	x_4 <= x_4;
		    	x_5 <= x_5;
                x_6 <= x_0_F0;
                x_7 <= x_1_F0;
                x_8 <= x_2_F0;
                
                dx_0_prev <= dx_0_prev;
				dx_1_prev <= dx_1_prev;
				dx_2_prev <= dx_2_prev;
                dx_3_prev <= dx_3_prev;
				dx_4_prev <= dx_4_prev;
				dx_5_prev <= dx_5_prev;   
                dx_6_prev <= dx_0;
                dx_7_prev <= dx_1;
                dx_8_prev <= dx_2;
                Ia_fiber_1 <= Ia_fiber_1;
                Ia_fiber_2 <= Ia_fiber_2;
                II_fiber_2 <= II_fiber_2;                
                II_muscle <= II_muscle_F0;
                Ia_muscle <= Ia_muscle_F0;
           end
           default: begin     
            x_0 <= x_0;
            x_1 <= x_1;
            x_2 <= x_2;
            x_3 <= x_3;
            x_4 <= x_4;
            x_5 <= x_5;
            x_6 <= x_6;
            x_7 <= x_7;
            x_8 <= x_8;
            dx_0_prev <= dx_0_prev;
            dx_1_prev <= dx_1_prev;
            dx_2_prev <= dx_2_prev;
            dx_3_prev <= dx_3_prev;
            dx_4_prev <= dx_4_prev;
            dx_5_prev <= dx_5_prev;
            dx_6_prev <= dx_6_prev;
            dx_7_prev <= dx_7_prev;
            dx_8_prev <= dx_8_prev;
            Ia_fiber_1 <= Ia_fiber_1;
            Ia_fiber_2 <= Ia_fiber_2;
            II_fiber_2 <= II_fiber_2;
            II_muscle <= II_muscle;
            Ia_muscle <= Ia_muscle;
            end
        endcase
   end // of always
endmodule


module spindle_derivatives(		input wire [1:0] state,
                    input wire reset,
					input wire [31:0]gamma_dyn,
					input wire [31:0]gamma_sta, 
					input wire [31:0]lce, 
					input wire [31:0]x_0, 
					input wire [31:0]x_1, 
					input wire [31:0]x_2,
					output wire [31:0] dx_0,
					output wire [31:0] dx_1,
					output wire [31:0] dx_2,
                    input wire [31:0] BDAMP_1,
                    input wire [31:0] BDAMP_2,
                    input wire [31:0] BDAMP_chain
					);
	wire [31:0] IEEE_SIX_POINT_SEVEN_ONE_ONE, IEEE_FOUR_POINT_EIGHT_SEVEN_EIGHT;
	assign IEEE_SIX_POINT_SEVEN_ONE_ONE = 32'h40D6C083; //bag1
	assign IEEE_FOUR_POINT_EIGHT_SEVEN_EIGHT = 32'h409C1893;//bag2
	reg [31:0] gamma;
	reg [31:0] dx_0_CONSTANT;
    reg [31:0] BDAMP, B0;
	//wire [31:0] BDAMP_1, BDAMP_2, BDAMP_chain;	
	//assign BDAMP_1 = 32'h3E71_4120;//bag 1 BDAMP = 0.2356	 
	//assign BDAMP_2 = 32'h3D14_4674; //bag 2 BDAMP = 0.0362
    //assign BDAMP_chain = 32'h3C58_44D0;// chain BDAMP = 0.0132
    
    reg [31:0] C_KSR_P_KPR;
	wire [31:0] C_KSR_P_KPR_1, C_KSR_P_KPR_2, C_KSR_P_KPR_chain;
	assign C_KSR_P_KPR_1 = 32'h41293DD9;// bag 1 KSR[j]+KPR[j] = 10.4649 + 0.1127 = 10.5776
	assign C_KSR_P_KPR_2 = 32'h412A0903;// bag 2 KSR[j]+KPR[j] = 10.4649 + 0.1623 = 10.6272
    assign C_KSR_P_KPR_chain = C_KSR_P_KPR_2; // chain has same constants as bag2 here
    reg [31:0] F, F0;

    
    reg [31:0] fs_sqr;
	wire [31:0] IEEE_3600, IEEE_0_01, IEEE_8100;
	assign IEEE_3600 = 32'h4561_0000;
    assign IEEE_0_01 = 32'h3C23D70A;
    assign IEEE_8100 = 32'h45FD2000;
    
	always @ (state or reset) begin
        if (reset) begin
					gamma = 0;
					dx_0_CONSTANT = 0;
					BDAMP = 0;
                    B0 = 0;
                    F = 0;
                    F0 = 32'd0;
					C_KSR_P_KPR = 0;
                    fs_sqr = 0;
        end
        else
		case (state)
			0: begin	//bag1
				gamma = gamma_dyn;
				dx_0_CONSTANT = IEEE_SIX_POINT_SEVEN_ONE_ONE;
				BDAMP = BDAMP_1;
                B0 = 32'h3D77CED9;
                F0 = 32'd0;
                F = 32'h3CECBFB1;
				C_KSR_P_KPR = C_KSR_P_KPR_1;
                fs_sqr = IEEE_3600;
				end
			1: begin	//bag2
				gamma = gamma_sta;
				dx_0_CONSTANT = IEEE_FOUR_POINT_EIGHT_SEVEN_EIGHT;
				BDAMP = BDAMP_2;
                B0 = 32'h3DA85879;
                F = 32'h3D8240B8;
                F0 = 32'd0;
				C_KSR_P_KPR = C_KSR_P_KPR_2;
                fs_sqr = IEEE_3600;
				end
			2: begin	//chain
				gamma = gamma_sta;
				dx_0_CONSTANT = 0; // not used in chain
				BDAMP = BDAMP_chain;
                B0 = 32'h3DA85879;
                F = 32'h3DC36113;
                F0 = 32'd0;
				C_KSR_P_KPR = C_KSR_P_KPR_chain;
                fs_sqr = IEEE_8100;
				end
			default: begin
					gamma = 0;
					dx_0_CONSTANT = 0;
					BDAMP = 0;
                    B0 = 0;
                    F = 0;
                    F0 = 32'd0;
                    C_KSR_P_KPR = 0;
                    fs_sqr = 0;
				end
		endcase
	end
				

	//Min Gamma Dynamic Calculation
	//
    	//From spindle.py
	//	mingd = gammaDyn**2/(gammaDyn**2+60**2)
	//
	wire [31:0] min_gamma;
	wire [31:0] gamma_sqr;
	wire [31:0] gamma_R1;

	
	mult min_gamma_dyn_m1( .x(gamma), .y(gamma), .out(gamma_sqr) );
	add min_gamma_dyn_a1( .x(gamma_sqr), .y(fs_sqr), .out(gamma_R1) );
	div min_gamma_dyn_d1( .x(gamma_sqr), .y(gamma_R1), .out(min_gamma) );
	
	//assign mingd = 32'h3F23_D70A;	

	//dx_0 calculation
	//
	//From spindle.py
	//	dx_0 = (mingd-x_0)/0.149
	//
	//wire [31:0] dx_0_R1, IEEE_ZERO_POINT_ONE_FOUR_NINE, IEEE_ZERO_POINT_TWO_ZERO_FIVE;
	//assign IEEE_ZERO_POINT_ONE_FOUR_NINE = 32'h3E18_9375;//bag1
	//assign IEEE_ZERO_POINT_TWO_ZERO_FIVE = 32'h3E51_EB85; //bag2
	wire [31:0] dx_0_R1, dx_0_F0;
	sub dx_0_s1( .x(min_gamma), .y(x_0), .out(dx_0_R1) );
	//div dx_0_d1( .x(dx_0_R1), .y(IEEE_ZERO_POINT_TWO_ZERO_FIVE), .out(dx_0) );
	//replace with multiply by reciprocal
	mult dx_0_m1( .x(dx_0_R1), .y(dx_0_CONSTANT), .out(dx_0_F0) );
	
    assign dx_0 = (state == 2'd2) ? 32'd0 : dx_0_F0; // chain fiber dx_6 = 0
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
	wire [31:0] C_REV_M, C_KSR, C_KPR_M_LPR0, C_KSR_M_LSR0;
	wire [31:0] abs_x2_pow_25, abs_x2_pow_25_unchk;

	wire [31:0] IEEE_ZERO_POINT_FOUR;
	assign IEEE_ZERO_POINT_FOUR = 32'h3ECCCCCC;// 0.4

	assign C_REV_M = 32'h459C4000;//1/M[j] = 1 / 0.0002 = 5000
	assign C_KSR = 32'h4127703B; //KSR=10.4649

	assign C_KSR_M_LSR0 = 32'h3ED652BD;//KSR[j]*LSR0[j] = 10.4649*0.04 = 0.4186
	assign C_KPR_M_LPR0 = 32'h3DAF6944;//KPR[j]*LPR0[j] = 0.1127*0.76= 0.08565
    wire [31:0] flag_abs_x2_pow_25;
	pow_25	abs_dx_2_p1( .x({1'b0, x_2[30:0]}), .out(abs_x2_pow_25) );
    
	
    wire [31:0] IEEE_1 = 32'h3F800000;
        
    wire [31:0] sig, rldfv, x1_rldfv;
    assign rldfv = 32'h3EEB851F;
    sub sig_rldfv_sub( .x(x_1), .y(rldfv), .out(x1_rldfv) );
    assign sig = x1_rldfv[31] ? 0 : x1_rldfv;


	wire [31:0] x_0_in;
	assign x_0_in = (state == 2'd2) ? min_gamma : x_0;
	
    //     C_KSR 	****	lce    =>    dx_2_RLLLLL6
    wire [31:0] dx_2_RLLLLL6;
    mult dx_2_RLLLLL6_mult( .x(C_KSR), .y(lce), .out(dx_2_RLLLLL6) );

    //     C_KSR_P_KPR 	****	x_1    =>    dx_2_RLLLLR6
    wire [31:0] dx_2_RLLLLR6;
    mult dx_2_RLLLLR6_mult( .x(C_KSR_P_KPR), .y(x_1), .out(dx_2_RLLLLR6) );

    //     dx_2_RLLLLL6 	----	dx_2_RLLLLR6    =>    dx_2_RLLLL5
    wire [31:0] dx_2_RLLLL5;
    sub dx_2_RLLLL5_sub( .x(dx_2_RLLLLL6), .y(dx_2_RLLLLR6), .out(dx_2_RLLLL5) );

    //     BDAMP 	****	x_0    =>    dx_2_RLLLRLLRR9
    wire [31:0] dx_2_RLLLRLLRR9;
    mult dx_2_RLLLRLLRR9_mult( .x(BDAMP), .y(x_0_in), .out(dx_2_RLLLRLLRR9) );

    //     B0 	++++	dx_2_RLLLRLLRR9    =>    dx_2_RLLLRLLR8
    wire [31:0] dx_2_RLLLRLLR8;
    add dx_2_RLLLRLLR8_add( .x(B0), .y(dx_2_RLLLRLLRR9), .out(dx_2_RLLLRLLR8) );

    //     CSS 	****	dx_2_RLLLRLLR8    =>    dx_2_RLLLRLL7
    wire [31:0] dx_2_RLLLRLL7;
    mult dx_2_RLLLRLL7_mult( .x(CSS), .y(dx_2_RLLLRLLR8), .out(dx_2_RLLLRLL7) );

    //     dx_2_RLLLRLL7 	****	sig    =>    dx_2_RLLLRL6
    wire [31:0] dx_2_RLLLRL6;
    mult dx_2_RLLLRL6_mult( .x(dx_2_RLLLRLL7), .y(sig), .out(dx_2_RLLLRL6) );

    //     dx_2_RLLLRL6 	****	abs_x2_pow_25    =>    dx_2_RLLLR5
    wire [31:0] dx_2_RLLLR5;
    mult dx_2_RLLLR5_mult( .x(dx_2_RLLLRL6), .y(abs_x2_pow_25), .out(dx_2_RLLLR5) );

    //     dx_2_RLLLL5 	----	dx_2_RLLLR5    =>    dx_2_RLLL4
    wire [31:0] dx_2_RLLL4;
    sub dx_2_RLLL4_sub( .x(dx_2_RLLLL5), .y(dx_2_RLLLR5), .out(dx_2_RLLL4) );

    //     F 	****	x_0    =>    dx_2_RLLRR5
    wire [31:0] dx_2_RLLRR5;
    mult dx_2_RLLRR5_mult( .x(F), .y(x_0_in), .out(dx_2_RLLRR5) );

    //     F0 	++++	dx_2_RLLRR5    =>    dx_2_RLLR4
    wire [31:0] dx_2_RLLR4;
    add dx_2_RLLR4_add( .x(F0), .y(dx_2_RLLRR5), .out(dx_2_RLLR4) );

    //     dx_2_RLLL4 	----	dx_2_RLLR4    =>    dx_2_RLL3
    wire [31:0] dx_2_RLL3;
    sub dx_2_RLL3_sub( .x(dx_2_RLLL4), .y(dx_2_RLLR4), .out(dx_2_RLL3) );

    //     dx_2_RLL3 	----	C_KSR_M_LSR0    =>    dx_2_RL2
    wire [31:0] dx_2_RL2;
    sub dx_2_RL2_sub( .x(dx_2_RLL3), .y(C_KSR_M_LSR0), .out(dx_2_RL2) );

    //     dx_2_RL2 	++++	C_KPR_M_LPR0    =>    dx_2_R1
    wire [31:0] dx_2_R1;
    add dx_2_R1_add( .x(dx_2_RL2), .y(C_KPR_M_LPR0), .out(dx_2_R1) );

    //     C_REV_M 	****	dx_2_R1    =>    dx_2_F0
    wire [31:0] dx_2_F0;
    mult dx_2_F0_mult( .x(C_REV_M), .y(dx_2_R1), .out(dx_2_F0) );


    assign dx_2 = dx_2_F0;

endmodule


