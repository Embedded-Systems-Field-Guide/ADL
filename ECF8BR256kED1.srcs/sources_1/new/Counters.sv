
// 8-bit Incrementer using optimized half adders
module Incrementer (
    input  wire [7:0] BUS_In,   // 8-bit input bus
    output wire [7:0] BUS_Out   // 8-bit incremented output bus
);

    // Internal carry signals
    wire [6:0] carry;  // carry[0] to carry[6] for bits 1-7

    // LSB (bit 0) - optimized for B=1
    HalfAdderLSB ha_lsb (
        .A(BUS_In[0]),
        .Sum(BUS_Out[0]),
        .Carry(carry[0])
    );

    // Middle bits (1-6) - standard half adders
    genvar i;
    generate
        for (i = 1; i <= 6; i = i + 1) begin : ha_middle
            HalfAdder ha_std (
                .A(BUS_In[i]),
                .B(carry[i-1]),
                .Sum(BUS_Out[i]),
                .Carry(carry[i])
            );
        end
    endgenerate

    // MSB (bit 7) - no carry output needed
    HalfAdderMSB ha_msb (
        .A(BUS_In[7]),
        .B(carry[6]),
        .Sum(BUS_Out[7])
    );

endmodule


//=============================================================================
// 8-BIT COUNTER MODULE
//=============================================================================

// 8-bit Counter using Incrementer and DFF8bit modules
module Counter (
    input  wire INC,                // Clock input
    input  wire TC_RST,                // Asynchronous reset (active-high)
    output wire [7:0] TC  // 8-bit counter output
);

    // Internal signals
    wire [7:0] TCP1;   // TC + 1
    wire [7:0] qn_unused;          // Unused complement outputs from DFF

    // 8-bit D Flip-Flop bank
    DFF8bit counter_dff (
        .D   (TCP1),   // Input from incrementer output
        .CLK (INC),                 // Clock input
        .RST (TC_RST),                 // Reset input
        .Q   (TC),        // Counter output
        .Qn  (qn_unused)           // Unused complement outputs
    );

    // Incrementer - adds 1 to current counter value
    Incrementer inc (
        .BUS_In  (TC),    // Current counter value
        .BUS_Out (TCP1) // Incremented value (CounterValue + 1)
    );

endmodule

// 4-bit Incrementer using optimized half adders
module Incrementer4bit (
    input  wire [3:0] BUS_In,   // 4-bit input bus
    output wire [3:0] BUS_Out   // 4-bit incremented output bus
);

    // Internal carry signals
    wire [2:0] carry;  // carry[0] to carry[2] for bits 1-3

    // LSB (bit 0) - optimized for B=1
    HalfAdderLSB ha_lsb (
        .A(BUS_In[0]),
        .Sum(BUS_Out[0]),
        .Carry(carry[0])
    );

    // Middle bits (1-2) - standard half adders
    genvar i;
    generate
        for (i = 1; i <= 2; i = i + 1) begin : ha_middle
            HalfAdder ha_std (
                .A(BUS_In[i]),
                .B(carry[i-1]),
                .Sum(BUS_Out[i]),
                .Carry(carry[i])
            );
        end
    endgenerate

    // MSB (bit 3) - no carry output needed
    HalfAdderMSB ha_msb (
        .A(BUS_In[3]),
        .B(carry[2]),
        .Sum(BUS_Out[3])
    );

endmodule


//=============================================================================
// 4-BIT COUNTER MODULE
//=============================================================================

// 4-bit Counter using Incrementer4bit and DFF4bit modules
module Counter4bit (
    input  wire INC,                // Clock input
    input  wire TC_RST,             // Asynchronous reset (active-high)
    output wire [3:0] TC,            // 4-bit counter output
    output wire [3:0] TCn            // 4-bit counter output
);

    // Internal signals
    wire [3:0] TCP1;                // TC + 1
    wire [3:0] qn_unused;           // Unused complement outputs from DFF

    // 4-bit D Flip-Flop bank
    DFF4bit counter_dff (
        .D   (TCP1),                // Input from incrementer output
        .CLK (INC),                 // Clock input
        .RST (TC_RST),              // Reset input
        .Q   (TC),                  // Counter output
        .Qn  (TCn)            // Unused complement outputs
    );

    // Incrementer - adds 1 to current counter value
    Incrementer4bit inc (
        .BUS_In  (TC),              // Current counter value
        .BUS_Out (TCP1)             // Incremented value (CounterValue + 1)
    );

endmodule



