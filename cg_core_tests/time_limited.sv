`timescale 1ns/1ps
`define CLKPERIOD 10
`define DELAY 30

module test;
    reg clk = 0;
    reg trigger = 0;
    reg gate = 0;
    reg rst = 0;
    wire ext;
    wire soe;

    reg[23:0] limit = 0;
    reg[23:0] delay = 0;
    reg oe = 0;
    reg en = 0;
    reg dds = 0;
    reg lds = 0;
    reg len = 0;
    wire rte;
    wire[23:0] acc;
        
    cg_core CORE(
        .clk(clk),
        .I_TRIG(trigger),
        .I_GATE(gate),
        .I_RST(rst),
        .O_EXT(ext),
        .O_SOE(soe),

        .I_LMT(limit),
        .I_DLY(delay),
        .I_OE(oe),
        .I_EN(en),
        .I_DDS(dds),
        .I_LDS(lds),
        .I_LEN(len),
        .O_RTE(rte),
        .O_ACC(acc)
    );

    always #`CLKPERIOD clk <= !clk;

    initial begin
        $dumpvars(0, test);

        dds = 1;
        lds = 1;
        len = 1;
        en = 1;
        oe = 1;
        limit = 200; #`DELAY

        rst = 1; #`DELAY
        rst = 0; #`DELAY

        trigger = 1; #`DELAY

        #400

        trigger = 0; #`DELAY

        $finish;
    end
endmodule