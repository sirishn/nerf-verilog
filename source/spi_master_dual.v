`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: USC
// Engineer: JFS
// 
// Create Date:    00:05:49 01/22/2012 
// Design Name: 
// Module Name:    spi_master 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 	1) Trigger a rising edge on "SIMCK"
//						2) Buffer "data_32" into [tx_register]
//						3) Start transferring the [tx_register] to SPI_slave
//						4) See if "MISO" data is coherent
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module spi_master(
    input  wire reset,
    input  wire en,
	 input  wire clk,
    input  wire SIMCK,
	
	 input  wire [23:0] clkdiv,
	 output  wire DATA_OUT0,
    output  wire DATA_OUT1,
	 input  wire [31:0] data32_0,
	 input  wire [31:0] data32_1,
   
	 output  wire SSEL,
    output  wire SCK,
	 output  wire [31:0] rx_data
    );
	 
//     assign MISO = 0;
	 //define wires and regs
	 reg [2:0] SIMCKr; always @(negedge clk) SIMCKr <= {SIMCKr[1:0], SIMCK};	//trigger SIM CLK
	 wire SIMCK_risingedge;
	 assign SIMCK_risingedge = (SIMCKr[2:0] == 3'b011);
	 
	 reg [1:0] MISOr; always @(negedge clk) MISOr <= {MISOr[0], 0};
	 wire MISO_data;
	 assign MISO_data = MISOr[1];
	 
	 reg [1:0] SCK_internalr; always @(negedge clk) SCK_internalr <= {SCK_internalr[0],SCK_internal};
	 wire SCK_internal_fallingedge;
	 //wire SCK_internal_risingedge;
	 assign SCK_internal_fallingedge = (SCK_internalr[1:0] == 2'b10);
	 //assign SCK_internal_risingedge = (SCK_internalr[1:0] == 2'b01);
	 
	 reg SSEL_gen = 1'b1;
	 
	 //counts 32 bits - 5-bit counter
	 reg [5:0] bitcnt = 6'b000000;
	 reg [31:0] data_sent_0, data_sent_1;
	 reg [31:0] data_received_internal =0, data_received = 0;
	 
	 //some pre/post counter for SPI timing
	 reg [3:0] pre_counter = 4'h0, post_counter = 4'h0;
	 reg startmsg = 0, endmsg=0;
	 reg SSEL_active = 0;
		 
	 //******************************************************// 
	 //shiftout sending (DATA_OUT)
	 //make SSEL signal
	 //start pre-counter
	 //******************************************************//
	 always @(posedge clk)
		begin
		
			if(reset || ~en)	//reset/en
				begin
					bitcnt <= 6'b000000;
					SSEL_gen <= 1'b1;
					data_sent_0 <= 0;
					data_sent_1 <= 0;
				end
			
			else if(SIMCK_risingedge && (bitcnt < 6'b100000 )) 	//detect SIMCK_risingedge
				begin
					SSEL_gen <= 0;
					//pre-load data32
					data_sent_0 <= data32_0;
					data_sent_1 <= data32_1;
					SSEL_active <= 1;	//set flag
				end	
		
			else if(SCK_internal_fallingedge)		//sendout data in SCK clock
				begin
					bitcnt <= bitcnt + 6'b000001;
					data_sent_0 <= {data_sent_0[30:0], 1'b0};
					data_sent_1 <= {data_sent_1[30:0], 1'b0};
				end
		
			else if(endmsg)	//start post-counter
				begin
					startmsg	<= 0;
					pre_counter <= 0;
					post_counter <= post_counter + 4'h1;
					if (post_counter == 4'hF)
						begin
							SSEL_active <= 0;		//disable SSEL
							SSEL_gen <= 1;			//set SSEL high
							endmsg <= 0;
							bitcnt <= 0;					
						end
						
				end
				
			if(SSEL_active)
				begin
					pre_counter <= pre_counter + 4'h1;
					if (pre_counter == 4'hF)
						begin
							pre_counter <= 0;
							startmsg <= 1;
						end
				end		

			//stop tx/rx after 32-bit data tx/rx
			if(bitcnt == 6'b100000)
				begin
					endmsg <= 1;
				end
							
		end

	 assign SSEL = SSEL_gen;
	 assign DATA_OUT0 = data_sent_0[31];	//send MSB --> LSB
	 assign DATA_OUT1 = data_sent_1[31];
		 
		 
	 //******************************************************//	
	 //clk divider -- ref from counter example
	 //SCK clock will be generated from here
	 //******************************************************//
	 reg [23:0] div = 24'h00000F;
	 reg clk_gen =0;
	 //reg counter =0;
	 reg SCK_internal =0;
	 
	 always @(posedge clk)
		 begin
			if(startmsg)
				begin
					div <= div - 24'h000001;
					if (div == 24'h000000)
						begin
							//div <= 24'h400000;	//can be modified
							div <= clkdiv;
							clk_gen <= 1;
						end
					else clk_gen <= 0;
				 
					if (clk_gen == 1)
						begin
							if (reset || endmsg) 
								SCK_internal <= 0;
							else
								SCK_internal <= SCK_internal + 1'b1;		//I think it will roll over
						end
				end
		 end
		 
	 assign SCK =SCK_internal;	


	//******************************************************//
	//Receiving part (MISO)
	//******************************************************//
	always @(posedge SCK_internal)
	begin
		data_received_internal <= {data_received_internal[30:0], MISO_data};
	end
		
	always @(posedge clk)
		begin
			if(endmsg)
				data_received <= data_received_internal;
		end
		
	assign rx_data = data_received;	//out to output port


endmodule
