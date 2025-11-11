

module AddSTRReg (
    input  wire [7:0] D_in,    // 8-bit data input bus
    output wire [7:0] D_out,   // Internal Q storage
    input  wire OUT,        // Output enable (active-high)
    input  wire CLK,        // Clock input
    input  wire STR,        // Store enable
    input  wire [7:0] STRBit,    
    input  wire RST        // Asynchronous reset
);

    // Internal storage for the register values

    wire [7:0] Q_internal;   // Internal Q storage
    // Instantiate 8 individual register cells for internal storage
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : reg_array
            Register reg_cell (
                .D   (D_in[i]),
                .CLK (CLK),
                .STR (STR | STRBit[i]),
                .RST (RST),
                .Q   (Q_internal[i]),
                .Qn  ()
            );
        end
    endgenerate

    // Output control with tri-state logic
    // When OUT is high, output the stored values
    // When OUT is low, outputs are high impedance (Z)
    assign D_out  = OUT ? Q_internal  : 8'bZZZZZZZZ;

endmodule



module AddOUTReg (
    input  wire [7:0] D_in,    // 8-bit data input bus
    input  wire OUT,        // Output enable (active-high)
    input  wire [7:0] OUTBit,        // Output enable (active-high)
    input  wire CLK,        // Clock input
    input  wire STR,        // Store enable
    input  wire RST,        // Asynchronous reset
    output wire [7:0] D_out    // 8-bit register output with tri-state control
);

    // Internal storage for the register values
    wire [7:0] Q_internal;   // Internal Q storage
    wire [7:0] Qn_internal;  // Internal Qn storage

    // Instantiate 8 individual register cells for internal storage
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : reg_array
            Register reg_cell (
                .D   (D_in[i]),
                .CLK (CLK),
                .STR (STR),
                .RST (RST),
                .Q   (Q_internal[i]),
                .Qn  (Qn_internal[i])
            );
        end
    endgenerate

    genvar j;
    generate
        for (j = 0; j < 8; j = j + 1) begin : output_array
            assign D_out[j] = (OUT | OUTBit[j]) ? Q_internal[j] : 1'bZ;
        end
    endgenerate

endmodule




module AddIOReg (
    input  wire [7:0] D_in,    // 8-bit data input bus
    input  wire OUT,        // Output enable (active-high)
    input  wire [7:0] OUTBit,        // Output enable (active-high)
    input  wire CLK,        // Clock input
    input  wire STR,        // Store enable
    input  wire [7:0] STRBit,    
    input  wire RST,        // Asynchronous reset
    output wire [7:0] D_out    // 8-bit register output with tri-state control
);

    // Internal storage for the register values
    wire [7:0] Q_internal;   // Internal Q storage
    wire [7:0] Qn_internal;  // Internal Qn storage

    // Instantiate 8 individual register cells for internal storage
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : reg_array
            Register reg_cell (
                .D   (D_in[i]),
                .CLK (CLK),
                .STR (STR| STRBit[i]),
                .RST (RST),
                .Q   (Q_internal[i]),
                .Qn  (Qn_internal[i])
            );
        end
    endgenerate

    genvar j;
    generate
        for (j = 0; j < 8; j = j + 1) begin : output_array
            assign D_out[j] = (OUT | OUTBit[j]) ? Q_internal[j] : 1'bZ;
        end
    endgenerate

endmodule


//Outputs based on bits from TRIS register
module LATReg (
    input  wire [7:0] D_in,    // 8-bit data input bus
    input  wire [7:0] OUTBit,        // Output enable (active-high)
    input  wire CLK,        // Clock input
    input  wire STR,        // Store enable
    input  wire [7:0] STRBit,    
    input  wire RST,        // Asynchronous reset
    output wire [7:0] D_out,    // 8-bit register output with tri-state control
    output wire [7:0] LABits
);


    // Instantiate 8 individual register cells for internal storage
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : reg_array
            Register reg_cell (
                .D   (D_in[i]),
                .CLK (CLK),
                .STR (STR| STRBit[i]),
                .RST (RST),
                .Q   (LABits[i]),
                .Qn  ()
            );
        end
    endgenerate

    genvar j;
    generate
        for (j = 0; j < 8; j = j + 1) begin : output_array
            assign D_out[j] = OUTBit[j] ? LABits[j] : 1'bZ;
        end
    endgenerate

endmodule

module TRISReg (
    input  wire [7:0] D_in,    // 8-bit data input bus
    output wire [7:0] D_out,   // Internal Q storage
    input  wire CLK,        // Clock input
    input  wire STR,        // Store enable
    input  wire [7:0] STRBit,    
    input  wire RST        // Asynchronous reset
);

    // Internal storage for the register values

    // Instantiate 8 individual register cells for internal storage
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : reg_array
            Register reg_cell (
                .D   (D_in[i]),
                .CLK (CLK),
                .STR (STR | STRBit[i]),
                .RST (RST),
                .Q   (D_out[i]),
                .Qn  ()
            );
        end
    endgenerate


endmodule

module PRTDriver (
    inout  wire [7:0] DataBus,    // 8-bit data input bus    
    input  wire CLK,        // Clock input
    input wire MCLR,
    
    input  wire STR_TRIS,        
    input  wire [7:0] STR_TRISBit,    
    input  wire STRLAT,        
    input  wire [7:0] STR_LATBit,    
    
    input  wire ReadPRT,        // Store enable
    input  wire [7:0] ReadPRTBits,   
    
    inout wire [7:0] PRTPins,  
     
    
    //Debug
    output wire [7:0] TrisBits,
    output wire [7:0] LatBits
    
);

    
    
    TRISReg TRISRegister(
    .D_in(DataBus),    // 8-bit data input bus
    .D_out(TrisBits),   // Internal Q storage
    .CLK(CLK),        // Clock input
    .STR(STR_TRIS),        // Store enable    
    .STRBit(STR_TRISBit),    
    .RST(MCLR)        // Asynchronous reset   
    );
    
    LATReg LATRegister(
    .D_in(DataBus),    // 8-bit data input bus
    .OUTBit(TrisBits),        // Output enable (active-high)
    .CLK(CLK),        // Clock input
    .STR(STRLAT),        // Store enable
    .STRBit(STR_LATBit),    
    .RST(MCLR),        // Asynchronous reset
    .LABits(LatBits),
    .D_out(PRTPins)    // 8-bit register output with tri-state control
    );
    
    ADDBusBuffer ReadBuffer(   
        .Bus(PRTPins),    // Input bus
        .Enable(ReadPRT), // Enable signal (active-high)
        .EnableBits(ReadPRTBits), // Enable signal (active-high)
        .out(DataBus)     // Output bus (tri-state)
    );


endmodule 