module spikecnt(spike, int_cnt_out, fast_clk, slow_clk, reset, clear_out);
    input   spike, slow_clk, fast_clk, reset;
    output  reg [31:0] int_cnt_out;
    output  clear_out;
          
    reg     [31:0]  cnt;
    reg     t2;
    reg t1;
    always @(posedge reset or posedge slow_clk) begin
        if (reset) begin
            t1 <= t2;
        end
        else begin
            if (~read) t1 <= ~t1;
				else t1 <= t1;
        end
    end
    
    always @(negedge spike or posedge reset) begin
        if (reset) begin
            t2 <= t1;
        end
        else begin
            if (read) t2 <= ~t2;
				else t2 <= t2;
        end
    end
    
    wire    read = t1 ^ t2;
    wire    out_flag = read && slow_clk;
    
    always @(posedge spike) begin
        if (read) begin
            cnt <= 32'd1;
        end
        else begin
            cnt <= cnt + 32'd1;
        end
    end
         
    always @(posedge slow_clk or posedge reset) begin
        if (reset || read) begin
            int_cnt_out <= 32'd0;
        end
        else begin
            int_cnt_out <= cnt;
        end
    end
    
    assign clear_out = out_flag;

endmodule

//module spikecnt(spike, int_cnt_out, fast_clk, slow_clk, reset, clear_out);
//    input   spike, slow_clk, fast_clk, reset;
//    output  reg [31:0] int_cnt_out;
//    output  clear_out;
//          
//    reg     [31:0]  cnt;
//    reg     t2;
//    always @(posedge spike or posedge reset) begin
//        if (reset) begin
//            cnt <= 32'd0;
//        end
//        else begin
//            cnt = cnt + 32'd1;
//            if (read) begin 
//                t2 = ~t2;
//                cnt = 32'd0;
//            end
//        end
//    end
//    
//    always @(posedge slow_clk or posedge reset) begin
//        if (reset) begin
//            int_cnt_out <= 32'd0;
//        end
//        else begin
//            int_cnt_out <= cnt;
//        end
//    end
//    
//    reg t1;
//    always @(posedge reset or posedge slow_clk) begin
//        if (reset) begin
//            t1 <= 0;
//        end
//        else begin
//            if (read) t1 <= t1;
//            else t1 <= ~t1;
//        end
//    end
//    
//    wire    read = t1 ^ t2;
//    wire    out_flag = read && slow_clk;
//    assign clear_out = out_flag;
//
//endmodule



//module spikecnt(spike, int_cnt_out, fast_clk, slow_clk, reset, clear_out, t1, t2, read, cnt);
//   input   spike, slow_clk, fast_clk, reset;
//   output  reg [31:0] int_cnt_out;
//   output  clear_out;
//        output  t1, t2, read;
//        output  [31:0] cnt;
//         
//   reg     [31:0]  cnt;
//   reg     t2;
//    always @(posedge spike or posedge out_flag) begin
////        if (reset) begin
////            cnt <= 32'd0;
////                                t2 <= 0;
////        end
//       //else begin
//        if (out_flag) begin
//            cnt <= 32'd0;
//        end
//        cnt <= cnt + 32'd1;
//        if (read) begin
//            t2 <= ~t2;
//        end
//
//       //end
//   end
//   
//   always @(posedge slow_clk or posedge reset) begin
//       if (reset) begin
//           int_cnt_out <= 32'd0;
//       end
//       else begin
//           int_cnt_out <= cnt;
//           //cnt <= 32'd0;
//       end
//   end
//   
//   reg t1;
//   always @(posedge reset or posedge slow_clk) begin
//       if (reset) begin
//           t1 <= 0;
//       end
//       else begin
//           if (read) t1 <= t1;
//           else t1 <= ~t1;
//       end
//   end
//   
//   wire    read = t1 ^ t2;
//   wire    out_flag = read && slow_clk;
//   assign clear_out = out_flag;
//
//endmodule