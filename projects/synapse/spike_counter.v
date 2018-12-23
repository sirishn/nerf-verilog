`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:30:33 06/07/2012 
// Design Name: 
// Module Name:    spike_counter 
// Project Name: 
// Target Devices: 
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
module spike_counter(
                        input wire clk,
                        input wire reset,
                        input wire spike_in,
                        output reg [31:0] spike_count
    );

    reg spike;
    reg state;
    reg [6:0] neuron_index;
    reg [31:0] count;
    always @ (posedge clk or posedge reset)
    begin
        if (reset) begin
            state <= 1;
            neuron_index<=0;
            spike <= 0;
        end else begin
            case(state)
                0:  begin
                    neuron_index <= neuron_index + 1;
                    state <= 1;
                    spike <= spike;
                    end
                1:  begin
                    neuron_index <= neuron_index;
                    state <= 0;
                    spike <= spike_in;
                    end
             endcase
        end
    end
    
    wire reset_bar;
assign reset_bar = ~reset;

always @ (negedge clk or negedge reset_bar) begin
    if (~reset_bar) begin
       count <= 0;
       spike_count <= 0;
    end else begin
        if (state) begin
            count <= count + spike;
            if (neuron_index == 7'h7f) begin
                count <= spike;
                spike_count <= count;
            end
        end
    end
end
    
endmodule
