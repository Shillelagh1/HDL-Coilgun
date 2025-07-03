module cg_top(
inout IO_sda,
input I_scl,
input I_mclk,

input I_trig,
input I_gate,
input I_reset,
output O_ext,
output O_soe
);
    localparam MY_SUBADDR = 4'b0010;
    wire 
        O_sda, 
        OE_sda, 
        O_soe, 
        I2C_clk;
    wire[7:0] 
        creg, 
        eflg;
    wire[23:0] 
        acc, 
        dly, 
        lmt;

    cg_core CGC(
        .clk(I_mclk),
        .I_TRIG(I_trig),
        .I_GATE(I_gate),
        .I_RST(I_reset),
        .O_EXT(O_ext),
        .O_SOE(O_soe),
        .I_LMT(lmt),
        .I_DLY(dly),
        .O_ACC(acc),
        .I_EN(creg[0]),
        .I_OE(creg[1]),
        .I_LEN(creg[2]),
        .I_DDS(creg[3]),
        .I_LDS(creg[4])
    );

    i2c_core I2C(
        .I_scl(I_scl),
        .I_sda(IO_sda),
        .O_sda(O_sda),
        .OE_sda(OE_sda),
        .I_clk(I2C_clk),
        .I_myaddr(MY_SUBADDR),
        .O_creg(creg),
        .O_dly(dly),
        .O_lmt(lmt),
        .I_eflg(eflg),
        .I_acc(acc)
    );

    clkdiv I2C_clkdiv(
        .I_clk(I_mclk),
        .O_clk(I2C_clk)
    );
endmodule