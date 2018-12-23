module spike_counter(spike, int_cnt_out, slow_clk, reset, clear_out, cnt, read, wait_for_one_more_spike);
    input   spike, slow_clk, reset;
    output  reg    [31:0]  int_cnt_out;
    output reg     [31:0]  cnt;
	 reg slow_clk_up; 
    output clear_out, read;
	 output reg [1:0] wait_for_one_more_spike;
    assign clear_out = slow_clk_up;
	 
    always @(posedge reset or posedge slow_clk or posedge spike) begin
        if (reset) begin 
            //slow_clk_up <= 1'b0;
				wait_for_one_more_spike <= 2'd0;
        end 
		  else if (slow_clk) begin 
			   //slow_clk_up <= 1'b1;
				wait_for_one_more_spike <= 2'd2;
		  end
		  else begin//if (spike) begin
				//slow_clk_up <= 1'b0;
				if (wait_for_one_more_spike > 0) 
					wait_for_one_more_spike <= (wait_for_one_more_spike - 1'b1);
		  end
    end 
	 
	 //wire read;
    //assign read = slow_clk ^ slow_clk_up;
	 
	 
	 // spike and slow_clk_up are not mutually exclusive in ISIM env. 
	 // Try make intermediate variable to wait for two spikes (lose one spike count) 

	 
    always @(posedge reset or posedge spike) begin
	  if (reset) begin
			cnt <= 32'd0;
			int_cnt_out <= 32'd0;
						
	  end
	  else if (wait_for_one_more_spike == 2'd1) begin
	  		int_cnt_out <= cnt;
			cnt <= 32'd0;     
	  end
	  else begin //if (spike) begin //   SPIKE HIGH ONLY
			int_cnt_out <= int_cnt_out;
			cnt <= cnt + 32'd1;
	  end

//	  else if (!slow_clk_up && (spike == 1'b0)) begin  // SLOW CLK UP, NO SPIKE
//			int_cnt_out <= cnt;
//			cnt <= 32'd0;    // count being renewed at every posedge of slow clock = read.
//	  end

  end  

endmodule
// Button experiment
     
//    always @(posedge reset or posedge button1 or posedge button2 or posedge spike) begin
//             if (reset) begin
//                button1_response <= 1'b0;
//                button2_response <= 1'b0;
//                spike_out <= 1'b0;
//             end
//             else if (button1) begin
//                button1_response <= 1'b1;
//                button2_response <= 1'b0;
//                spike_out <= 1'b0;
//             end
//             else if (button2) begin
//                button1_response <= 1'b0;
//                button2_response <= 1'b1;
//                spike_out <= 1'b0;
//             end
//             else begin
//                button1_response <= 1'b0;
//                button2_response <= 1'b0;
//                spike_out <= 1'b1;
//             end
//         end
//          
    


