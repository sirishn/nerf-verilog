module fastspk(spike_out, reset);
    input   reset;
    output  spike_out;
          
    reg     t2;
    reg     t1;
    always @(negedge spike_out or posedge reset) begin
        if (reset) begin
            if (~spike_out) begin
                t1 <= ~t1;
            end
        end
        else begin
            if (~spike_out) t1 <= ~t1;
        end
    end    
        
    always @(posedge spike_out) begin
        t2 <= ~t2;

    end
//    wire t1 = (spike_out) ? ~t1 : t1;
//    wire t2 = (~spike_out) ? ~t2 : t2;
    
    assign    spike_out = t1 ^ t2;


endmodule

