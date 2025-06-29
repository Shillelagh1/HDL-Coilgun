module cg_top(
    input I_scl,
    inout IO_sda,
    input I_clk,
    output O_indicator,

    // Debug
    output O_started
);

    reg[3:0] R_myaddr = 'd2;
    wire WO_sda, WOE_sda;
    wire[7:0] creg;    

    assign O_indicator = creg[0];
    assign IO_sda = WOE_sda ? WO_sda : 1'bz;

    // Debug
    wire R_started;
    assign O_started = R_started;

    i2c_core I2C(
        .I_sda(IO_sda),
        .O_sda(WO_sda),
        .OE_sda(WOE_sda),
        .I_scl(I_scl),
        .I_clk(I_clk),
        .I_myaddr(R_myaddr),
        .O_creg(creg),
        .O_started(O_started)
    );

endmodule