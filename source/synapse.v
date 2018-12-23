////////////////////////////////////////
//// Synapse ///////////////////////////
////////////////////////////////////////
// Acts to create an exponentially falling current at the output 
// from a spike input and a weight which can be +/-
// up to three spike inputs are defined, each with its own weight
module synapse_int(I_out,spk1,w1,spk2,w2,spk3,w3,clk,reset);

	output reg [17:0] I_out; 				//the simulated current
	input spk1,spk2,spk3;     			// the spike inputs
	input signed [17:0] w1,w2,w3;   //weights

	input clk, reset;
	reg  [17:0] syn1_trace, syn2_trace, syn3_trace;  // current synaptic traces
	wire  [17:0] I_F0, syn1_trace_F0, syn2_trace_F0, syn3_trace_F0; // synaptic traces delayed by 1 clk cycle
	
	//maintain "traces" that are decaying functions of the last spike time
	//if spike comes in then reset count, otherwise multiply by 0.875 = 0.5 + 0.25 + 0.125

	//assign syn1_trace_F0 = spk1 ? 9'sh0ff : ((syn1_trace >>> 1) + (syn1_trace >>> 2) + (syn1_trace >>> 3));
	//assign syn2_trace_F0 = spk2 ? 9'sh0ff : ((syn2_trace >>> 1) + (syn2_trace >>> 2) + (syn2_trace >>> 3));
	//assign syn3_trace_F0 = spk3 ? 9'sh0ff : ((syn3_trace >>> 1) + (syn3_trace >>> 2) + (syn3_trace >>> 3));	//not used
    
    
//	assign syn1_trace_F0 = spk1 ? 18'sh3ffff : (syn1_trace - (syn1_trace >>> 10));  // allow half life in 500 clk cycles.
//    assign syn2_trace_F0 = spk2 ? 18'sh3ffff : (syn2_trace - (syn2_trace >>> 10));  // xn = (0.9991)*xn_1  (for 10 bit shift)
//	assign syn3_trace_F0 = spk3 ? 18'sh3ffff : (syn3_trace - (syn3_trace >>> 10)); 
	
    assign syn1_trace_F0 = spk1 ? 18'sh3ffff : ((syn1_trace >>> 1) + (syn1_trace >>> 2) + (syn1_trace >>> 3) + (syn1_trace >>> 4) + (syn1_trace >>> 5) + (syn1_trace >>> 6) + (syn1_trace >>> 7) + (syn1_trace >>> 8) + (syn1_trace >>> 9));  // allow half life in 500 clk cycles.
    assign syn2_trace_F0 = spk2 ? 18'sh3ffff : ((syn2_trace >>> 1) + (syn2_trace >>> 2) + (syn2_trace >>> 3) + (syn2_trace >>> 4) + (syn2_trace >>> 5) + (syn2_trace >>> 6) + (syn2_trace >>> 7) + (syn2_trace >>> 8) + (syn2_trace >>> 9));  // xn = (0.9991)*xn_1  (for 10 bit shift)
	assign syn3_trace_F0 = spk3 ? 18'sh3ffff : ((syn3_trace >>> 1) + (syn3_trace >>> 2) + (syn3_trace >>> 3) + (syn3_trace >>> 4) + (syn3_trace >>> 5) + (syn3_trace >>> 6) + (syn3_trace >>> 7) + (syn3_trace >>> 8) + (syn3_trace >>> 9));
    
	assign I_F0 = syn1_trace * w1 + syn2_trace * w2 + syn3_trace * w3;
	
   always @(posedge clk or posedge reset) begin
        if (reset) begin
				syn1_trace <= 18'd0;
				syn2_trace <= 18'd0;
				syn3_trace <= 18'd0;
				I_out <= 18'd0;
        end
        else begin
				I_out <= I_F0;
				syn1_trace <= syn1_trace_F0;
				syn2_trace <= syn2_trace_F0;
				syn3_trace <= syn3_trace_F0;
        end
    end

endmodule

