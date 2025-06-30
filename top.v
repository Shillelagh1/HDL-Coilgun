module cg_top(
    input I_scl,
    inout IO_sda,
    input I_clk,
    output O_indicator,

    // Debug
    output O_started,
    output O_I2C_clk,
    output[2:0] dbg
);
    assign O_indicator = creg[0];

    // Debug signals
    // ==== REMOVE ALL ====
    wire R_started;
    wire[7:0] R_dbg;
    assign O_started = R_started;
    assign O_I2C_clk = I2C_clk;
    assign dbg = R_dbg;

    // I2C Modules & Signals
    reg[23:0] R_acc = 'b000011110000111100001111;
    reg[7:0] R_eflg = 'b10101010;
    reg[3:0] R_myaddr = 'd2;
    wire WO_sda, WOE_sda;
    wire[7:0] creg;    
    assign IO_sda = WOE_sda ? WO_sda : 1'bz;

    wire I2C_clk;
    clkdiv I2C_DIV(
        .I_clk(I_clk),
        .O_clk(I2C_clk)
    );

    i2c_core I2C(
        .I_sda(IO_sda),
        .O_sda(WO_sda),
        .OE_sda(WOE_sda),
        .I_scl(I_scl),
        .I_clk(I2C_clk),
        .I_myaddr(R_myaddr),
        .O_creg(creg),
        .I_eflg(R_eflg),
        .I_acc(R_acc),
        .O_started(R_started),
        .dbg(R_dbg)
    );

endmodule