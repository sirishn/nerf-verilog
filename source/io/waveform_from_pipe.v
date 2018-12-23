`timescale 1ns / 1ps
// @sirishn

module waveform_from_pipe(	
	input  wire             ti_clk,
	input  wire             reset,
	input	 wire					repop,
	input  wire             feed_data_valid,
	input  wire [15:0]      feed_data,
	
	output wire [31:0]      current_element,
	input  wire					test_clk,
	output reg					done_feeding

    );

	reg [31:0] mem [1023:0];
	reg [10:0] mem_index;		// cycle count for pipe in command
	reg is_hi_word;					// Hi word flag for pipe in command

	reg [15:0] feed_data_lo_word;	//	lower 16 bits of floating point number
	wire [31:0] pipe_out_float;		// 32bit number to be piped out

	always @ (posedge ti_clk or posedge reset) begin
		if (reset) begin
			mem_index	<=	11'd0;
			feed_data_lo_word	<=	16'd0;
			is_hi_word	<=	0;
			done_feeding <= 0;
		end
		else if ( feed_data_valid ) begin
			if (mem_index <= 11'd1023) begin
				done_feeding <= 0;
				if (~is_hi_word) begin
					feed_data_lo_word	    <=	feed_data;
					is_hi_word		<=	1;
				end
				else if (is_hi_word) begin
					is_hi_word 			<=	0;
					mem[mem_index[9:0]]	    <=	{feed_data,feed_data_lo_word};
					mem_index			<=	mem_index + 1;
                    if (mem_index == 11'd1023) begin // ??? Here if "==" changes to ">=", pipe in will FAIL!
						  done_feeding <= 1;
						  mem_index		<= 11'd0;
                    end
				end
			end
		end
	end
	
	reg [9:0] pop_index;
	wire [31:0] test_wave;
	
	assign test_wave = mem[pop_index];
	assign current_element = test_wave;
	
	always @ (posedge test_clk or posedge repop) begin
		//XEM3020 doesn't accept this: if (repop || ~done_feeding || feed_data_valid) begin
        if (repop) begin
			pop_index <=0;
		end
        else begin
            if (~done_feeding) begin 
                pop_index <=0;
            end
            else begin
                if (feed_data_valid) begin
                    pop_index <= 0;
                end
                else begin
                    if (done_feeding) begin
                        pop_index <= pop_index + 1;
                    end
                    else begin
                        pop_index <= pop_index;
                    end
                end
            end
        end
	end
		
endmodule
