module i2c_core(
input I_sda,
output O_sda,
output OE_sda,

input I_scl,
input I_clk,
input[3:0] I_myaddr,

// registers
output[7:0] O_creg,
output[23:0] O_dly,
output[23:0] O_lmt,
input[7:0] I_eflg,
input[23:0] I_acc,

// debug
output O_started,
output[7:0] dbg
);
    localparam STATE_RDADDR = 8'd0;
    localparam STATE_SENDACK = 8'd1;
    localparam STATE_WRITE_RDADDR = 8'd2;
    localparam STATE_WRITE_REGACK = 8'd5;
    localparam STATE_WRITE = 8'd3;
    localparam STATE_WRITE_DATACK = 8'd7;
    localparam STATE_READ = 8'd4;
    localparam STATE_READ_ACK = 8'd6;

    localparam ADDR_CREG = 8'd0;
    localparam ADDR_EFLG = 8'd1;
    localparam ADDR_ACC = 8'd2;
    localparam ADDR_DLY = 8'd3;
    localparam ADDR_LMT = 8'd4;

    // Process Registers
    reg R_started = 0;
    reg[7:0] R_state = 0;
    reg[7:0] R_count = 0;
    reg[7:0] R_addr = 0;    // [7:1]: Address, [0]: R/|W
    reg[7:0] R_regaddr = 0;

    // Input registers
    reg[2:0] R_I_scl = 0;
    reg R_I_sda = 0;

    // Output registers
    reg R_O_sda = 0;    
    reg R_OE_sda = 0;

    assign O_sda = R_O_sda;
    assign OE_sda = R_OE_sda;

    // I2C registers
    reg[7:0] U_creg = 0;
    reg[23:0] U_dly = 0;
    reg[23:0] U_lmt = 'b000011110000111100001111;
    assign O_creg = U_creg;
    assign O_dly = U_dly;
    assign O_lmt = U_lmt;

    // Debug ===== REMOVE =====
    assign O_started = R_started;
    assign dbg = R_count;

    always @(posedge I_clk) begin
        R_I_scl <= {R_I_scl[1:0], I_scl};
        R_I_sda <= I_sda;

        // START sequence
        if ((R_I_sda & !I_sda) & I_scl) begin
            R_started <= 1;
            R_addr <= 0;
            R_state <= STATE_RDADDR;
            R_count <= 7;
        end

        // STOP sequence
        if ((!R_I_sda & I_sda) & I_scl) begin
            R_started <= 0;
        end

        // Posedge SCL
        if ((R_I_scl == 3'b011) & R_started) begin
            case(R_state)
                // Read I2C address
                STATE_RDADDR: begin
                    R_addr[R_count] <= I_sda;
                    if (R_count == 0) begin
                        // If we read our address, move onto ACK, if not stop listening.
                        if (R_addr[7:1] == {I_myaddr, 3'b100}) begin
                            R_state <= STATE_SENDACK;
                        end else begin
                            R_started <= 0;
                        end
                    end else begin
                        R_count <= R_count - 1;
                    end
                end

                // Branch to proper state according to R/W bit
                STATE_SENDACK: begin
                    if (R_addr[0] == 0) begin
                        R_count <= 7;
                        R_state <= STATE_WRITE_RDADDR;
                    end else begin
                        case(R_regaddr)
                            ADDR_CREG: begin
                                R_count <= 7;
                                R_state <= STATE_READ;
                            end
                            ADDR_EFLG: begin
                                R_count <= 7;
                                R_state <= STATE_READ;
                            end
                            ADDR_ACC: begin
                                R_count <= 23;
                                R_state <= STATE_READ;
                            end
                            ADDR_DLY: begin
                                R_count <= 23;
                                R_state <= STATE_READ;
                            end
                            ADDR_LMT: begin
                                R_count <= 23;
                                R_state <= STATE_READ;
                            end
                            default: begin
                                R_state <= 0;
                                R_started <= 0;
                            end
                        endcase
                    end
                end

                // Get the address the master is planning to write/read to.
                STATE_WRITE_RDADDR: begin
                    R_regaddr[R_count] <= I_sda;
                    if (R_count == 0) begin
                        case(R_regaddr)
                            ADDR_CREG: begin
                                R_count <= 7;
                                R_state <= STATE_WRITE_REGACK;
                            end
                            ADDR_ACC: begin
                                R_count <= 0;
                                R_state <= STATE_WRITE_REGACK;
                            end
                            ADDR_LMT: begin
                                R_count <= 23;
                                R_state <= STATE_WRITE_REGACK;
                            end
                            ADDR_DLY: begin
                                R_count <= 23;
                                R_state <= STATE_WRITE_REGACK;
                            end
                            default: begin
                                R_state <= STATE_RDADDR;
                                R_started <= 0;
                            end
                        endcase
                    end else begin
                        R_count <= R_count - 1;
                    end
                end

                STATE_WRITE_REGACK: begin
                    R_state <= STATE_WRITE;
                end

                // Read the bits into the selected register
                STATE_WRITE: begin
                    case(R_regaddr)
                        ADDR_CREG: begin
                            U_creg[R_count] <= I_sda;
                        end
                        ADDR_DLY: begin
                            U_dly[R_count] <= I_sda;
                        end
                        ADDR_LMT: begin
                            U_lmt[R_count] <= I_sda;
                        end
                    endcase
                    R_count <= R_count - 1;
                    if (R_count[2:0] == 0) begin
                        R_state <= STATE_WRITE_DATACK;
                    end
                end

                STATE_WRITE_DATACK: begin
                    if (R_count == 0) begin
                        R_started <= 0;
                        R_state <= STATE_RDADDR;
                    end else begin
                        R_state <= STATE_WRITE;
                    end
                end

                STATE_READ: begin
                    R_count <= R_count - 1;
                    if (R_count[2:0] == 0) begin
                        R_state <= STATE_READ_ACK;
                    end
                end

                STATE_READ_ACK: begin
                    if (!I_sda) begin
                        R_state <= STATE_READ;
                    end else begin
                        R_started <= 0;
                    end
                end
            endcase
        end

        // Negedge SCL
        if ((R_I_scl & !I_scl) & R_started) begin
            case(R_state)
                STATE_RDADDR: begin
                    R_O_sda <= 1;   // don't do anything here
                    R_OE_sda <= 0;
                end

                // Send ACK bit for address
                STATE_SENDACK: begin
                    R_O_sda <= 0;   // ACK
                    R_OE_sda <= 1;
                end

                STATE_WRITE_RDADDR: begin
                    R_O_sda <= 1;   // don't do anything here
                    R_OE_sda <= 0;
                end

                // Send ACK bit for register select
                STATE_WRITE_REGACK: begin
                    R_O_sda <= 0;   // ACK
                    R_OE_sda <= 1;
                end

                STATE_WRITE: begin
                    R_O_sda <= 1;
                    R_OE_sda <= 0;                   
                end

                STATE_WRITE_DATACK: begin
                    R_O_sda <= 0;   // ACK
                    R_OE_sda <= 1;
                end

                STATE_READ: begin
                    R_OE_sda <= 1;
                    case(R_regaddr)
                        ADDR_CREG: begin
                            R_O_sda <= U_creg[R_count];
                        end
                        ADDR_EFLG: begin
                            R_O_sda <= I_eflg[R_count];
                        end
                        ADDR_ACC: begin
                            R_O_sda <= I_acc[R_count];
                        end
                        ADDR_DLY: begin
                            R_O_sda <= U_dly[R_count];
                        end
                        ADDR_LMT: begin
                            R_O_sda <= U_lmt[R_count];
                        end
                    endcase
                end

                STATE_READ_ACK: begin
                    R_OE_sda <= 0;
                end
            endcase
        end
    end
endmodule