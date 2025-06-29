`timescale 1ns/1ns
`define CLKW 4
`define DELAY 30
`define BCLK 25
`define SCLW 50

module test;
    reg in_sda = 0;
    wire out_sda;
    wire oe_sda;

    reg scl = 0;
    reg rst = 0;
    reg clk = 0;
    reg[3:0] addr = 2;

i2c_core I2C(
    .I_sda(in_sda), 
    .O_sda(out_sda), 
    .OE_sda(oe_sda),
    .I_scl(scl),
    .I_rst(rst),
    .I_clk(clk),
    .I_myaddr(addr)
);

always #`CLKW clk <= !clk;

initial begin
    $dumpvars(0, test);

    // Write
    startseq;
    address;
    in_sda = 0; clock; // Write Mode
    in_sda = 1; clock; // ACK
    in_sda = 0; clock; clock; clock; clock; clock; clock; clock; clock; // Reg addr (0)
    in_sda = 1; clock; // ACK
    in_sda = 1; clock; clock; clock; clock; 
    in_sda = 0; clock; clock; clock; clock; // Reg data (F0)
    in_sda = 1; clock; // ACK
    stopseq;

    // Read
    startseq;
    address;
    in_sda = 1; clock; // Read
    in_sda = 1; clock; // ACK
    clock; clock; clock; clock; clock; clock; clock; clock;
    in_sda = 1; clock; // NACK
    stopseq;


    $finish;
end

task clock;
    #`BCLK
    scl = 1; #`SCLW
    scl = 0; #`SCLW;
endtask

task address;
    in_sda = 0; clock;
    in_sda = 0; clock;
    in_sda = 1; clock;
    in_sda = 0; clock;
    in_sda = 1; clock;
    in_sda = 0; clock;
    in_sda = 0; clock;
endtask

task startseq;
    scl = 0;
    in_sda = 1; #20
    scl = 1; #`BCLK
    in_sda = 0; #`BCLK
    scl = 0; #`SCLW;
endtask

task stopseq;
    scl = 0;
    in_sda = 0; #20
    scl = 1; #`BCLK
    in_sda = 1; #`BCLK
    scl = 0; #`SCLW;
endtask
endmodule