module gen_SPI_slave_clk(rawclk, SSEL_startmessage, half_cnt, clk_out1, //clk_out2,
             clk_out3, int_neuron_cnt_out);
    parameter NN = 8; // 2^(NN+1) = NUM_NEURON
    parameter SR = 10; // 2^SR = SAMPLING_RATE
    input rawclk;
    input SSEL_startmessage;
    input [31:0] half_cnt;
    output reg clk_out1;    // neuron clk 
    //output reg clk_out2;  // sim_clk
    output reg clk_out3;  //spindle clk
    output [31:0] int_neuron_cnt_out;
	reg SSEL_startmessage_up;
    reg [31:0] delay_cnt;
	
    always @ (posedge rawclk) begin

        if (delay_cnt < half_cnt) begin
            clk_out1 <= clk_out1;
            delay_cnt <= delay_cnt + 1;
	
        end
        else begin
            clk_out1 <= ~clk_out1;
            delay_cnt <= 0;
        end

    end
	
	reg [31:0] SSEL_counter; 
    always @ (posedge rawclk) begin
		if (SSEL_startmessage) begin
			SSEL_startmessage_up <= 1;
			SSEL_counter <= 2*half_cnt;
		end
		else if (SSEL_counter == 0) begin
			SSEL_startmessage_up <= 0;
			SSEL_counter <= SSEL_counter;
		end 
		else begin
			SSEL_startmessage_up <= SSEL_startmessage_up;
			SSEL_counter <= SSEL_counter - 1;
		end
	end

	reg [NN+2:0] neuronCounter;
	wire [NN:0] neuronIndex;

	assign neuronIndex = neuronCounter[NN+2:2];
              

	always @ (posedge clk_out1)
	begin
        if (SSEL_startmessage_up) begin
            neuronCounter <= 0;
//            clk_out3 <= {(neuronIndex == 0) || (neuronIndex == 9'd85) || 
//                (neuronIndex == 9'd170)};
        end
        else begin 
           neuronCounter <= neuronCounter + 1'b1;
            //clk_out2 <= {neuronCounter == 0};
           clk_out3 <= {(neuronIndex == 0) || (neuronIndex == 9'd85) || 
                (neuronIndex == 9'd170)};
        end
	end

    assign int_neuron_cnt_out = neuronCounter;
endmodule
