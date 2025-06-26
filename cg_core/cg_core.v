module cg_core(
input clk,

input I_TRIG,
input I_GATE,
input I_RST,
output O_EXT,
output O_SOE,

input[23:0] I_LMT,
input[23:0] I_DLY,
input I_OE,                 // Output Enabled (from CREG)
input I_EN,                 // Logic Enabled (from CREG)
input I_DDS,                // Delay Divider Select (from CREG)
input I_LDS,                // Limit Divider Select (from CREG)
input I_LEN,                // Limit Enable (from CREG)
output O_RTE,               // Runtime Exceeded Flag
output[23:0] O_ACC
);
    reg[23:0] R_ACC = 0;    // Accumulator Register

    reg R_SOE = 0;          // Solenoid Enable Register
    reg R_CD = 0;           // Count Direction Register
    reg R_CDIV = 0;         // Clock divider
    
    reg R_I_TRIG = 0;       // Trigger edge detection register (Previous Value)
    reg R_I_GATE = 0;       // Gate edge detection register
    reg R_I_RST = 0;        // Reset edge detection register

    assign O_EXT = !R_SOE & R_CD & I_EN;
    assign O_SOE = R_SOE & R_CD & I_OE & I_EN;
    assign O_RTE = (R_ACC >= I_LMT) & R_CD & I_LEN;
    assign O_ACC = R_ACC;

    always @(posedge clk) begin
        R_CDIV <= !R_CDIV;

        // Edge detection register
        R_I_RST <= I_RST;
        R_I_TRIG <= I_TRIG;
        R_I_GATE <= I_GATE;

        // Reset functionality
        if ((!R_I_RST && I_RST)) begin
            R_SOE <= 0;
            R_CD <= 0;
            R_CDIV <= 0;
            R_ACC <= 0;
            R_I_TRIG <= 0;
            R_I_GATE <= 0;
        end

        // Trigger functionality
        if ((!R_I_TRIG && I_TRIG) & I_EN & !R_SOE) begin
            R_SOE <= 1;
            R_CD <= 0;
            R_CDIV <= 0;
            R_ACC <= I_DLY;
        end

        // Gate functionality
        if ((!R_I_GATE && I_GATE) & R_SOE) begin
            R_SOE <= 0;
        end

        // Counter Functionality
        // Second half of condition is clock division logic
        if (R_SOE && (R_CDIV || (R_CD ? I_LDS : I_DDS))) begin
            if (R_CD) begin
                R_ACC <= R_ACC + 1;
                if (R_ACC >= I_LMT && I_LEN) begin
                    R_SOE <= 0;
                end
            end 
            if (!R_CD) begin
                if (R_ACC <= 0) begin
                    R_CD <= 1;
                end else begin
                    R_ACC <= R_ACC - 1;
                end
            end
        end
    end
endmodule