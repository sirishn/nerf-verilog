`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: USC
// Engineer: JFS
// 
// Create Date:    22:10:26 01/21/2012 
// Modified: S
// Design Name: 
// Module Name:    spi_slave 
// Project Name: 
// Target Devices: XS6
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module spi_slave(
    input wire reset,
    input wire en,
    input wire DATA_IN0,
	 input wire DATA_IN1,
    input wire SCK,
    input wire SSEL,
	 input wire clk,
    // input [31:0] data32,   //added feb03
	 
    //output MISO,
    output wire [31:0] rx_out0,
	 output wire [31:0] rx_out1,
    output wire rdy
    );

	//define wires and regs
	reg [2:0] SCKr;
	wire SCK_risingedge, SCK_fallingedge;
	
	reg [2:0] SSELr;
	wire SSEL_active, SSEL_startmessage;
	//wire SSEL_endmessage;
	
	reg [1:0] MOSIr_0, MOSIr_1;
	wire MOSI_data_0, MOSI_data_1;
	
	//counts 32 bits - need 5-bit counter
	reg [4:0] bitcnt = 5'b00000;
	
	reg [31:0] data_sent = 32'hF0F0F0;
	reg [31:0] data_received_internal_0 =0, data_received_0 =0;
	reg [31:0] data_received_internal_1 =0, data_received_1 =0;
	reg rdy_internal =0;
	
	
	//some combination logics
	assign SCK_risingedge = (SCKr[2:0] == 3'b011);
	assign SCK_fallingedge = (SCKr[2:0] == 3'b100);
	assign SSEL_startmessage = (SSELr[2:0] == 3'b100);
	//assign SSEL_endmessage = (SSELr[2:0] == 3'b011);
	assign SSEL_active = ~SSELr[1];	//SSEL active low
	
	assign MOSI_data_0 = MOSIr_0[1];
	assign MOSI_data_1 = MOSIr_1[1];
	
	
	always @ (negedge clk)
		begin
			//keep track of SPI signals
			SCKr <= {SCKr[1:0], SCK};
			SSELr <= {SSELr[1:0], SSEL};
			MOSIr_0 <= {MOSIr_0[0], DATA_IN0};
			MOSIr_1 <= {MOSIr_1[0], DATA_IN1};
		end
	
	//******************************************************//
	//DATA_IN
	//******************************************************//
	always @ (posedge clk)
		begin
			if(reset || ~SSEL_active || ~en)
				begin
					bitcnt <= 5'b00000;
					rdy_internal <= 0;
				end
			else
				if(SCK_risingedge)
				begin
					bitcnt <= bitcnt + 5'b00001;
					//shift-left reg (MSB --> LSB)
					data_received_internal_0 <= {data_received_internal_0[30:0], MOSI_data_0};
					data_received_internal_1 <= {data_received_internal_1[30:0], MOSI_data_1};
				end	
				
			rdy_internal <= (bitcnt ==5'b11111) &&SSEL_active &&SCK_risingedge;
            if(rdy_internal) begin
                data_received_0 <= data_received_internal_0;
					 data_received_1 <= data_received_internal_1;
			   end
		end
		
	assign rdy = rdy_internal;
	
	
	//******************************************************//
	//MISO
	//******************************************************//
	reg [31:0] ack = 0;
	always @ (posedge clk) 
        begin 
            if(SSEL_startmessage) ack <= ack+1;	//just ack with cnt
            else if(reset) ack <= 0;
        end
//    
//	always @ (posedge clk)
//		if(SSEL_active)
//			begin
//				if(SSEL_startmessage)
//					data_sent <=data32;
//				else
//					if(SCK_fallingedge)
//					begin
//						if(bitcnt==5'b00000)
//							data_sent <= 32'h00000000;
//						else
//							data_sent <= {data_sent[30:0], 1'b0};
//					end
//			end
	
	//assign MISO = data_sent[31];  // send MSB first
	assign rx_out0 = data_received_0;
	assign rx_out1 = data_received_1;



endmodule
