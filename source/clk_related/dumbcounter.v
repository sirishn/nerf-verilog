module dumbcounter(spike, int_cnt_out, reset);
    input   spike, reset;
    output  [31:0] int_cnt_out;
          
    reg     [31:0]  cnt;
    
    always @(posedge spike or posedge reset) begin
        if (reset) begin
            cnt <= 32'd1;
        end
        else begin
            cnt <= cnt + 32'd1;
        end
    end
    
    assign int_cnt_out = cnt;
         
endmodule
