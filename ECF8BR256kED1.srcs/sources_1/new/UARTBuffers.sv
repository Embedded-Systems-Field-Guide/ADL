module TxBuffer(
    input  wire [7:0] DataBus,    // 8-bit parallel data input
    input  wire Shift,            // Shift enable (active-high)
    input  wire Load,             // Load parallel data enable (active-high)
    input  wire CLK,              // Clock input
    input  wire STR,              // Store enable
    input  wire CLR,              // Clear/Reset input (active-high)
    output wire Serial_out        // Serial data output
);
    // Internal signals for chaining units (now 9 units)
    wire [8:0] q_outputs;         // Q outputs from each unit
    wire [8:0] serial_chain;      // Serial data chain between units
    
   
    Register StopBit (
        .D   (Load|Shift),  // Data from multiplexer
        .CLK (CLK),         // Clock input
        .STR (STR),         // Store enable
        .RST (CLR),         // Reset input
        .Q   (serial_chain[0])           // Register output
    );
    
    // Chain the units: each unit's Q output goes to next unit's SD input
    genvar i;
    generate
        for (i = 1; i < 9; i = i + 1) begin : chain_assign
            assign serial_chain[i] = q_outputs[i-1];
        end
    endgenerate
    
    // Instantiate 9 PSIOUnits
    generate
        // First 8 units (bits 0-7): Data bits from DataBus in reverse order
        for (i = 0; i < 8; i = i + 1) begin : piso_units
            PSIOUnit unit (
                .PD   (DataBus[7-i]),      // DataBus[7] to unit 0, DataBus[0] to unit 7
                .Shift(Shift),
                .Load (Load),
                .SD   (serial_chain[i]),
                .CLK  (CLK),
                .STR  (STR),
                .CLR  (CLR),
                .Q    (q_outputs[i])
            );
        end
        
        wire StartBit;
        // 9th unit (bit 8): Start bit - PD always 0
        PSIOUnit unit_start (
            .PD   (1'b0),                  // Start bit: always 0
            .Shift(Shift),
            .Load (Load),
            .SD   (serial_chain[8]),       // Gets data from unit 7
            .CLK  (CLK),
            .STR  (STR),
            .CLR  (CLR),
            .Q    (StartBit)
        );
        
            PSIOUnit BufferBit (
            .PD   (1'b1),                  // buffer bit allwasy 1
            .Shift(Shift),
            .Load (Load),
            .SD   (StartBit),       
            .CLK  (CLK),
            .STR  (STR),
            .CLR  (CLR),
            .Q    (Serial_out)
        );
    endgenerate
    
endmodule



module RxBuf(
    input  wire D,          // Serial data input
    input  wire CLK,        // Clock input
    input  wire CLR,        // Clear/Reset input (active-high)
    output wire [7:0] RegOut // 8-bit parallel output
);

    // Internal signals for chaining DFFs
    wire [7:0] q_internal;      // Q outputs from each DFF
    wire [7:0] qn_unused;       // Unused complement outputs

    // First DFF - receives serial input D
    DFF StopBitReg (
        .D   (D),
        .CLK (CLK),
        .RST (CLR),
        .Q   (StopBit)
    );

    // First DFF - receives serial input D
    DFF dff0 (
        .D   (StopBit),
        .CLK (CLK),
        .RST (CLR),
        .Q   (q_internal[0])
    );

    // Chain the remaining 7 DFFs
    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin : dff_chain
            DFF dff_inst (
                .D   (q_internal[i-1]),  // D input is Q of previous DFF
                .CLK (CLK),
                .RST (CLR),
                .Q   (q_internal[i])
            );
        end
    endgenerate

    // Connect all Q outputs to the parallel output
    assign RegOut = q_internal;

endmodule
