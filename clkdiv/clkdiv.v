module clkdiv 
#(
    parameter W = 3
)
(
input I_clk,
output O_clk
);
    reg[(W-1) : 0] R_count = 0;
    reg D = 0;

    assign O_clk = D;

    always @(posedge I_clk) begin
        R_count <= R_count + 1;
        if (R_count == 0) begin
            D <= !D;
        end
    end
endmodule