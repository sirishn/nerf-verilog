`timescale 1ns / 1ps
// hi@siri.sh
// Spartan 6 Block RAM project

module block_ram_test(
	input  wire [7:0]  hi_in,
	output wire [1:0]  hi_out,
	inout  wire [15:0] hi_inout,
	inout  wire        hi_aa,

	output wire        i2c_sda,
	output wire        i2c_scl,
	output wire        hi_muxsel,

	input  wire        clk1,
	output wire [7:0]  led
	);

// Target interface bus:
wire         ti_clk;
wire [30:0]  ok1;
wire [16:0]  ok2;

assign i2c_sda = 1'bz;
assign i2c_scl = 1'bz;
assign hi_muxsel = 1'b0;

// Endpoint connections:
wire [15:0]  ep00wire;
wire [15:0]  rcv_errors;



// Pipe In
wire        pipe_in_write;
wire        pipe_in_ready;
wire [15:0] pipe_in_data;

// Pipe Out
wire        pipe_out_read;
wire        pipe_out_valid;
wire [15:0] pipe_out_data;

wire [15:0] WireIn10;
wire [15:0] TrigIn40;
wire [15:0] TrigIn41;
wire [15:0] TrigOut60;

wire reset;
wire start;

assign reset        = WireIn10[0];
assign start        = TrigIn40[0];

// PERFORM READ/COMPUTE/WRITE CYCLE ON RAM CONTENTS
reg read_complete;
reg execute_complete;
reg execute;
reg write;
reg [9:0] compute_index;
always @ (posedge clk1) begin
    if (reset == 1'b1) begin
        read_complete <= 1'b1;
        execute <= 0;
        write <= 0;
        execute_complete <= 0;
    end else begin
        if (start == 1'b1 || execute == 1'b1) begin
            execute <= 1'b1;
            execute_complete <= 0;
            if (compute_index[9] == 1'b0) begin
                execute <= 1'b1;
                if (read_complete == 1'b1) begin
                    read_complete <= 1'b0;
                    write <= 1'b1;
                end else begin
                    read_complete <= 1'b1;
                    write <= 0;
                end
            end else begin
                execute <= 1'b0;
                execute_complete <= 1'b1;
            end
        end
    end   
end

assign TrigOut60[0] = execute_complete;


always @ (negedge clk1) begin
    if (reset == 1'b1) begin
        compute_index <= 0;
    end else begin
        compute_index <= compute_index;
        if (read_complete == 1'b1 && execute == 1'b1) compute_index <= compute_index + 1'b1;
        //if (compute_index[9] == 1'b1) compute_index <= compute_index;
    end
end


wire [31:0] bbc_a_data;
wire [31:0] bbc_a_out;
assign led = 8'b10101010;
reg [9:0] ramI_addrA, ramO_addrA;
always @(posedge ti_clk) begin
	if (reset == 1'b1) begin
		ramI_addrA <= 10'd0;
		ramO_addrA <= 10'd0;
	end else begin
		if (pipe_in_write == 1'b1)
			ramI_addrA <= ramI_addrA + 1;
		if (pipe_out_read == 1'b1)
			ramO_addrA <= ramO_addrA + 1;
	end
end

wire [9:0] pipe_addr;
assign pipe_addr = pipe_in_write ? ramI_addrA : ramO_addrA;

/*
// 16-bit wide data
RAMB16_S18_S18 ram_O(.CLKA(ti_clk), .SSRA(reset), .ENA(1'b1),
                     .WEA(pipe_in_write), .ADDRA(pipe_addr),
                     .DIA(pipe_in_data), .DIPA(2'b0), .DOA(pipe_out_data), .DOPA(),
                     .CLKB(clk1), .SSRB(reset), .ENB(1'b1),
                     .WEB(write), .ADDRB(compute_index),
                     .DIB(bbc_a_out[15:0]), .DIPB(2'b0), .DOB(bbc_a_data[15:0]), .DOPB());      
*/
// 32-bit wide data
RAMB16_S18_S36 ram_O(.CLKA(ti_clk), .SSRA(reset), .ENA(1'b1),
                     .WEA(pipe_in_write), .ADDRA(pipe_addr),
                     .DIA(pipe_in_data), .DIPA(2'b0), .DOA(pipe_out_data), .DOPA(),
                     .CLKB(clk1), .SSRB(reset), .ENB(1'b1),
                     .WEB(write), .ADDRB(compute_index),
                     .DIB(bbc_a_out), .DIPB(2'b0), .DOB(bbc_a_data), .DOPB()); 
/*
bram_tdp #( .DATA(16), .ADDR(9) ) RAM_0(    .a_clk(ti_clk),
                                            .a_wr(pipe_in_write),
                                            .a_addr(pipe_addr[8:0]),
                                            .a_din(pipe_in_data),
                                            .a_dout(pipe_out_data),
                                            
                                            .b_clk(clk1),
                                            .b_wr(write),
                                            .b_addr(compute_index[8:0]),
                                            .b_din(bbc_a_out[15:0]),
                                            .b_dout(bbc_a_data[15:0])
                                            );

*/                     
black_box_compute #( .DATA(32) ) bbc0 (     .a_in(bbc_a_data), 
                                            .b_in(), 
                                            .a_out(bbc_a_out), 
                                            .b_out() 
                                            );
                                          
// Instantiate the okHost and connect endpoints.
// Host interface
okHost okHI(
	.hi_in(hi_in), .hi_out(hi_out), .hi_inout(hi_inout), .hi_aa(hi_aa), .ti_clk(ti_clk),
	.ok1(ok1), .ok2(ok2));

wire [17*3-1:0]  ok2x;

okWireOR # (.N(3)) wireOR (ok2, ok2x);

okWireIn     ep10 (.ok1(ok1),                           .ep_addr(8'h10), .ep_dataout(WireIn10));
okTriggerIn  ep40 (.ok1(ok1),                           .ep_addr(8'h40), .ep_clk(clk1), .ep_trigger(TrigIn40));
okTriggerIn  ep41 (.ok1(ok1),                           .ep_addr(8'h41), .ep_clk(ti_clk), .ep_trigger(TrigIn41));
okTriggerOut ep60 (.ok1(ok1), .ok2(ok2x[ 0*17 +: 17 ]), .ep_addr(8'h60), .ep_clk(clk1), .ep_trigger(TrigOut60));
okPipeIn     ep80 (.ok1(ok1), .ok2(ok2x[ 1*17 +: 17 ]), .ep_addr(8'h80), .ep_write(pipe_in_write), .ep_dataout(pipe_in_data));
okPipeOut    epA0 (.ok1(ok1), .ok2(ok2x[ 2*17 +: 17 ]), .ep_addr(8'ha0), .ep_read(pipe_out_read), .ep_datain(pipe_out_data));
endmodule


// A parameterized, inferable, true dual-port, dual-clock block RAM in Verilog.
// http://danstrother.com/2010/09/11/inferring-rams-in-fpgas/
module bram_tdp #(
    parameter DATA = 18,
    parameter ADDR = 9
) (
    // Port A
    input   wire                a_clk,
    input   wire                a_wr,
    input   wire    [ADDR-1:0]  a_addr,
    input   wire    [DATA-1:0]  a_din,
    output  reg     [DATA-1:0]  a_dout,
    
    // Port B
    input   wire                b_clk,
    input   wire                b_wr,
    input   wire    [ADDR-1:0]  b_addr,
    input   wire    [DATA-1:0]  b_din,
    output  reg     [DATA-1:0]  b_dout
);

// Shared memory
reg [DATA-1:0] mem [(2**ADDR)-1:0];

// Port A
always @(posedge a_clk) begin
    a_dout      <= mem[a_addr];
    if(a_wr) begin
        a_dout      <= a_din;
        mem[a_addr] <= a_din;
    end
end

// Port B
always @(posedge b_clk) begin
    b_dout      <= mem[b_addr];
    if(b_wr) begin
        b_dout      <= b_din;
        mem[b_addr] <= b_din;
    end
end

endmodule

module black_box_compute #(
    parameter DATA = 18
    ) (
    input   signed  [DATA-1:0]  a_in,
    input   signed  [DATA-1:0]  b_in,
    output  signed  [DATA-1:0]  a_out,
    output  signed  [DATA-1:0]  b_out
    );

//assign a_out = a_in + 1;

//add add1( .x(a_in), .y(32'h4000_000), .out(a_out) ); //floating point add 2
wire signed [8:0] new_exp;
assign new_exp = a_in[30:23] + 1;

assign a_out = {a_in[31], new_exp, a_in[22:0]};
assign b_out = b_in << 2;

endmodule
