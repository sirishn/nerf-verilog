//  integrate dynamics of physical plant
//////////////////////////////////////////////////////////////////////////////////
`default_nettype none

module plant(pos1, pos2, vel1, vel2,
				torque1, torque2, ext_torque, 
				pos_default, vel_default, neuronReset, inputValid, neuronClock, outputValid
    );
	parameter NN = 8;  // (log2(neuronCount) - 1)
	output signed [17:0] pos1, vel1, pos2, vel2;
	input signed [17:0] torque1, torque2;  //torque1 reduces angle, torque2 increases
	input signed [17:0] ext_torque;  //positive increases angle
	input neuronReset, inputValid;
	input signed [17:0] pos_default, vel_default;
	input neuronClock;
	output outputValid;

	wire signed [35:0] I, Iinv, Be, Bf, Ke, Kf, te, tf;  //temp1, temp2, temp3, temp4, temp5, 
	wire signed [35:0] velBf, velBe, posKf, posKe, accf, acce, torque_shift4, pos_ext; //tempe, tempf, tempe1, tempf1;
	wire signed [35:0] acc, torque, ext_torqueL, torque1L, torque2L, acc_new, vel_new, pos_new; 
	//wire signed [35:0] ext_torqueLs, torque1Ls, torque2Ls, tempvo; 
	reg signed [35:0] pos_out, vel_out, acc_out;
	wire pos_overflow, pos_underflow, vel_overflow, vel_underflow;
	reg outputValid;

	//double I = 0.0052 * 28.1;  //based on weight kg*m^2;  weight from Fee+Foulds, scaling from Lebiedowska
	// dec2hex(floor(0.0052 * 28.1 * hex2dec('ffff'))) = 2567
	// Iinv = 6.8437
	// dec2hex(floor((6.8437/8) * hex2dec('ffff'))) = DAFE

	//double Be=0.1666, Bf=0.0883; //N.m.sec/rad  from Fee+Foulds
	// dec2hex(floor(0.1666 * hex2dec('ffff'))) = 2AA6
	// dec2hex(floor(0.1666/8 * hex2dec('ffff'))) = 554
	// dec2hex(floor(0.0883 * hex2dec('ffff'))) = 169A
	// dec2hex(floor(0.0883/8 * hex2dec('ffff'))) = 2D3

	//double Ke=6.008, Kf=2.2663;  //N.m   from Fee+Foulds
	// dec2hex(floor((6.008/8) * hex2dec('ffff'))) = C040  //must be less than 1
	// dec2hex(floor((2.2663/8) * hex2dec('ffff'))) = 4885

	assign Be = {18'h02AA6, 18'h00000};		
	assign Bf = {18'h0169A, 18'h00000};
	//all these values are divided by 8,  so exp=+3
	assign Iinv = {18'h0DAFE, 18'h00000};  
	assign Ke = {18'h0C040, 18'h00000};
	assign Kf = {18'h04885, 18'h00000};

	// torque = 10.0* ext_torque + 5000.0 * (torque1 - torque2)/64;  //Nm.  torque1 is flexor, torque2 is extensor
	//assign torque_in = ext_torque + (torque2 <<< 6) - (torque1 <<< 6);  
	//assign torque = {torque_in, 18'sh00000}; 
	assign ext_torqueL = {ext_torque, 18'h00000};
	assign torque1L = {torque1, 18'sh00000};
	assign torque2L = {torque2, 18'sh00000};
	//all values are shifted right 8 bits to allow max values of 512
	//assign ext_torqueLs = ext_torqueL >>> 8;
	//assign torque1Ls = torque1L >>>2;
	//assign torque2Ls = torque2L >>>2;
	//assign torque = ext_torqueLs + torque2Ls - torque1Ls;
	assign torque = ext_torqueL + torque2L  - torque1L;  // unshifted
	
	/*
	if (vel >= 0)  //flexion
		acc = (torque - Bf*vel - Kf*pos) / I;
	else			//extension
		acc = (torque - Be*vel - Ke*(3.14-pos)) / I;
	*/
	//assign temp4 = vel_out[35:18]; //exp=+4  
	//assign velBf = temp4 * Bf;  
	//*//signed_mult32 sm32a(velBf, vel_out, Bf);  // exp = +4+0 = +4 since max vel = +/- 32 (+/- 8pi rad/sec)
	//assign temp5 = pos_out[35:18];  //exp+1  so max pos = pi rad
	//*//assign posKf = pos_out * Kf;  //exp = +1 +3 = +4  //pos is exp+1  so max pos = pi rad  (runs 0 to 4)
	//assign tempf1 = (velBf + posKf);
	assign torque_shift4 = torque >>> 2; //exp = +4
	assign tf = torque_shift4; // - velBf - posKf;  //exp =+4;
	//assign temp2 = tempf[35:18];
	//assign accf = temp2 * Iinv; //
	signed_mult32 sm32b(accf, tf, Iinv);  //exp=+4 +3 = +7

	//assign velBe = temp4 * Be; 
	//*//signed_mult32 sm32c(velBe, vel_out, Be);  //exp= +4 +0 = +4
	//*//assign pos_ext = 36'sh7ffff_ffff - pos_out;  // exp = +1
	//assign posKe = (temp1 <<< 3) * Ke;  //
	//*//signed_mult32 sm32d(posKe, pos_ext, Ke); //exp = +1 +3 = +4
	//assign tempe1 = (velBe + posKe);
	//assign tempb2 = posKe <<< 1;  //exp =+4
	//*//assign te = torque_shift4; // - velBe - posKe; //exp=+4
	//assign temp3 = tempe[35:18];
	//assign acce = temp3 * Iinv; //
	//*//signed_mult32 sm32e(acce, te, Iinv); //exp = +4 +3 = +7;
	
	//vel += acc * delta_t;
	//pos += vel * delta_t;
	//assign vel = vel_out + (torque >>> 16); //(acc >>> 4);  ////delta_t is always 0.001; shifted right by 4+6=10
	//assign pos = pos_out + (vel >>> 10);
	
	//joint limits
	//	if (pos < 0) {pos = 0; vel = 0;}
	//	if (pos > 3.14) {pos = 3.14 ; vel=0;}
	//	if (vel > 500 * 3.14) vel = 500*3.14;
	//	if (vel < -500 * 3.14) vel = -500*3.14;

	//next timestep
	//  pos goes from 0 to +1, vel goes from -1 to +1.
	//bit 35 is the sign, bit 34 is 1.0, bits 33:0 is a 34-bit value.
	
	/*
	assign temp_overflow = 36'sh7ffff_0000 - pos_out;
	assign pos_overflow = temp_overflow[35];  //(pos_out > 36'sh01ffff_ffff);
	assign pos_underflow = pos_out[35];
	
	assign temp_vel_overflow 36'sh07ffff_0000 - vel_out;
	assign vel_overflow = temp1_vel_overflow[35];
	assign temp_vel_underflow = vel_out + 36'sh07ffff_ffff;
	*/
	
	assign acc_new = accf;  //vel_out[35] ? accf : acce;
	
	assign vel_new = vel_out + (acc_new >>> 3);
	assign vel_overflow = acc_new[35] ? 0 : ((vel_new < vel_out) ? 1 : 0);
	assign vel_underflow = acc_new[35] ? ((vel_new > vel_out) ? 1 : 0) : 0;
	
	assign pos_new = pos_out + (vel_new >>>5);
	assign pos_overflow = vel_new[35] ? 0 : ((pos_new[35]) ? 1 : 0);
	assign pos_underflow = vel_new[35] ? ((pos_new[35]) ? 1 : 0) : 0;
	
	always @ (posedge inputValid)
	begin
		acc_out <= neuronReset? 36'sh0 : (acc_new);
		
		vel_out <= neuronReset? 36'sh0 //{vel_default, 18'sh0}  //: (vel_out + (torque >>> 10));
						: ((pos_overflow || pos_underflow) ? 36'sh0 
						: ((vel_overflow) ? vel_out //((vel_out > 36'sh3ffff_ffff) ? 36'sh3ffff_ffff 
						: ((vel_underflow) ? vel_out //((vel_out[35:33] < -(36'sh3ffff_ffff)) ? -(36'sh3ffff_ffff) 
						: (vel_new))));  //exp +7 -> exp +10 =  shift of 1024 for dt 
				
		pos_out <= neuronReset? 36'sh08000_0000 //{pos_default, 18'sh0}
						: (pos_underflow ? pos_out 
						: (pos_overflow ? pos_out 
						: (pos_new)));  
	end 
	
	always @ (posedge neuronClock) outputValid <= inputValid;
	//pos1 = (signed short) (((double) 0x7fff) * (joint_angle / 3.14));
	//pos2 = 0x7fff - pos1;
	//vel1 = (signed short) (((double) 0x7fff) * (joint_vel / (500*3.14)));
	//vel2 = (signed short) (((double) 0x7fff) * (-joint_vel / (500*3.14)));
	assign pos1 = pos_out[35:18];  //flexor  
	assign pos2 = 18'sh1ffff - pos1;  //max-pos = extensor
	assign vel1 = vel_out[35:18];  //flexion
	assign vel2 = -vel1; //extension

endmodule
