
module PISO(
    input  wire [7:0] DataBus,    // 8-bit parallel data input
    input  wire Shift,            // Shift enable (active-high)
    input  wire Load,             // Load parallel data enable (active-high)
    input  wire CLK,              // Clock input
    input  wire STR,              // Store enable
    input  wire CLR,              // Clear/Reset input (active-high)
    output wire Serial_out        // Serial data output
);

    // Internal signals for chaining units
    wire [7:0] q_outputs;         // Q outputs from each unit
    wire [7:0] qn_unused;         // Unused complement outputs
    wire [7:0] serial_chain;      // Serial data chain between units

    // Create serial chain connections
    // First unit (bit 0) gets 0 as serial input
    assign serial_chain[0] = 1'b0;
    
    // Chain the units: each unit's Q output goes to next unit's SD input
    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin : chain_assign
            assign serial_chain[i] = q_outputs[i-1];
        end
    endgenerate

    // Instantiate 8 PSIOUnits
    generate
        for (i = 0; i < 8; i = i + 1) begin : piso_units
            PSIOUnit unit (
                .PD   (DataBus[i]),      // Parallel data bit
                .Shift(Shift),           // Shift control (shared)
                .Load (Load),            // Load control (shared)
                .SD   (serial_chain[i]), // Serial data from previous unit
                .CLK  (CLK),             // Clock (shared)
                .STR  (STR),             // Store enable (shared)
                .CLR  (CLR),             // Clear (shared)
                .Q    (q_outputs[i]),    // Output to next unit's serial chain
                .Qn   (qn_unused[i])     // Unused complement
            );
        end
    endgenerate

    // Serial output comes from the last unit (bit 7)
    assign Serial_out = q_outputs[7];

endmodule

module PSIOUnit(
    input  wire PD,     // Parallel data input
    input  wire Shift,  // Shift enable (active-high)
    input  wire Load,   // Load parallel data enable (active-high)
    input  wire SD,     // Serial data input
    input  wire CLK,    // Clock input
    input  wire STR,    // Store enable
    input  wire CLR,    // Clear/Reset input (active-high)
    output wire Q,      // Register output
    output wire Qn      // Register complement output
);

    // Internal signal from BitMux to Register
    wire mux_to_reg;

    // BitMux selects between parallel data (PD) and serial data (SD)
    // Priority: if Load is high, select PD; if Shift is high, select SD
    BitMux data_mux (
        .A    (PD),     // Parallel data input
        .SelA (Load),   // Select parallel data when Load is high
        .B    (SD),     // Serial data input  
        .SelB (Shift),  // Select serial data when Shift is high
        .out  (mux_to_reg)
    );

    // 1-bit Register stores the selected data
    Register reg_cell (
        .D   (mux_to_reg),  // Data from multiplexer
        .CLK (CLK),         // Clock input
        .STR (STR),         // Store enable
        .RST (CLR),         // Reset input
        .Q   (Q),           // Register output
        .Qn  (Qn)           // Complement output
    );

endmodule

module SIPO(
    input  wire D,          // Serial data input
    input  wire CLK,        // Clock input
    input  wire CLR,        // Clear/Reset input (active-high)
    output wire [7:0] RegOut // 8-bit parallel output
);

    // Internal signals for chaining DFFs
    wire [7:0] q_internal;      // Q outputs from each DFF
    wire [7:0] qn_unused;       // Unused complement outputs

    // First DFF - receives serial input D
    DFF dff0 (
        .D   (D),
        .CLK (CLK),
        .RST (CLR),
        .Q   (q_internal[0]),
        .Qn  (qn_unused[0])
    );

    // Chain the remaining 7 DFFs
    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin : dff_chain
            DFF dff_inst (
                .D   (q_internal[i-1]),  // D input is Q of previous DFF
                .CLK (CLK),
                .RST (CLR),
                .Q   (q_internal[i]),
                .Qn  (qn_unused[i])
            );
        end
    endgenerate

    // Connect all Q outputs to the parallel output
    assign RegOut = q_internal;

endmodule


