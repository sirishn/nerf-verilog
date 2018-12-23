module gen_clk(rawclk, reset, half_cnt, clk_out1, clk_out2, clk_out3, int_neuron_cnt_out);
    parameter NN = 6; // 2^(NN+1) = NUM_NEURON
    parameter SR = 10; // 2^SR = SAMPLING_RATE
    input rawclk;
    input reset;
    input [31:0] half_cnt;
    output reg clk_out1, clk_out2, clk_out3;
    output [31:0] int_neuron_cnt_out;

    reg [31:0] delay_cnt;

    always @ (posedge rawclk) begin
	     if (reset) begin
            clk_out1 <= 0;
		  end 
		  else begin
			  if (delay_cnt < half_cnt) begin
					clk_out1 <= clk_out1;
					delay_cnt <= delay_cnt + 1;
			  end
			  else begin
					clk_out1 <= ~clk_out1;
					delay_cnt <= 0;
			  end
		  end
    end

	reg [NN+2:0] neuronCounter;
	wire [NN:0] neuronIndex;

	assign neuronIndex = neuronCounter[NN+2:2];

	always @ (posedge clk_out1 or posedge reset)
	begin
        if (reset) begin
            neuronCounter <= 0;
				clk_out2 <= 0;
				clk_out3 <= 0;
        end else begin
            neuronCounter <= neuronCounter + 1'b1;
            clk_out2 <= {neuronCounter == 0};
            clk_out3 <= {(neuronIndex == 0) || (neuronIndex == 9'd85) ||
                        (neuronIndex == 9'd170)};
            end
	end

    assign int_neuron_cnt_out = neuronCounter;
endmodule
