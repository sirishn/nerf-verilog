module limb(trq1, trq2, ext_trq, pos_default, vel_default, reset, clk, trq_out, pos_out, vel_out, acc_out);
   
input [31:0]      trq1; // unsigned, increases joint angle
input [31:0]      trq2; // unsigned, decreases joint angle
input [31:0]      ext_trq; // ~ between + and -
input             reset;
input             clk;
input [31:0]      pos_default;
input [31:0]      vel_default;
output reg [31:0] trq_out;
output reg [31:0] pos_out;
output reg [31:0] vel_out;
output reg [31:0] acc_out;

wire [31:0] Be, Bf, Iinv, Ke, Kf, POSMAX;

assign POSMAX = 32'h4048F5C2; //Pi rad, 180 deg
assign Be=32'h0000_0000; //placeholder
assign Bf=32'h0000_0000; //placeholder
assign Ke=32'h0000_0000; //placeholder
assign Kf=32'h0000_0000; //placeholder
assign Iinv=32'h41d7_0a3d; //I=0.0372, 1/I=26.88

// *** Trq -> Acc
wire [31:0] trq_1_2, trq_F0;
wire [31:0] acc_F0, vel_F0, pos_F0;


sub sub1(.x(trq1), .y(trq2), .out(trq_1_2));
add add1(.x(ext_trq), .y(trq_1_2), .out(trq_F0));
mult mult1(.y(trq_F0), .x(Iinv), .out(acc_F0));

// *** Acc -> Vel
integrator int_acc(.x(acc_out), .int_x(vel_out), .out(vel_F0));

// *** Vel -> Pos
wire [31:0] pos_raw, min_detection, max_detection;
integrator int_vel(.x(vel_out), .int_x(pos_out), .out(pos_raw));
sub sub3(.x(pos_raw), .y(32'd0), .out(min_detection));
sub sub4(.x(POSMAX), .y(pos_raw), .out(max_detection));
assign pos_F0 = (min_detection[31]) ? 32'd0 : ((max_detection[31]) ? POSMAX : pos_raw);

//
//assign vel1=vel_out;
//assign vel2={~vel1[31], vel1[30:0]};


// *** outputs
always @(posedge clk or posedge reset) begin
    if (reset) begin
        acc_out <= 32'd0;
        vel_out <= vel_default;
        pos_out <= pos_default;
        trq_out <= 32'd0;
    end
    else begin
        acc_out <= acc_F0;
        vel_out <= vel_F0;
        pos_out <= pos_F0;
        trq_out <= trq_F0;
    end
end

endmodule
