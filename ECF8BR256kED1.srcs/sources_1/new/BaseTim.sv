module BaseTimerTCON (
    // Base timer with the TCON register - keeps upper nibble, lower nibble to different timer
    
    input  wire SYSCLK,          // system clock used to synchronise CLK_IN   
    input  wire [7:0] D,         // 8-bit data input bus
    input  wire StoreTreg,       // Store signal for TReg register
    input  wire StoreTCON,       // Store signal for TCON register
    input  wire CLK_IN,          // Input clock
    input  wire CLR,             // Clear signal
    input  wire TF_CLR,          // Clears the flag
    input  wire MCLR,            // Master clear
    
    output wire TFlag,           // Timer flag output
    output wire INTVector,       // Interrupt vector output
    output wire TMR_CLR,         // MCLR OR CLR, internal clear for timer
    output wire TChannel,        // Channel output
    
    output wire [3:0] TCONLower  // Lower nibble of TCON for another timer
);

    // Internal wires for TMRCTRL-Counter interconnection
    wire [7:0] TReg;        // Timer register value
    wire [7:0] TC;          // Timer counter current value
    wire TC_RST;            // Timer counter reset
    wire INC;               // Increment signal
    wire Equal;             // Equal indicator (internal)
    
    // Internal wires for TCON register
    wire [7:0] TCON;        // Full TCON register
    
    // TCON upper nibble breakdown (MSB to LSB)
    wire Enable     = TCON[7];  // MSB - Enable
    wire AutoReload = TCON[6];  // Auto reload
    wire Interrupt  = TCON[5];  // Interrupt enable
    wire CHOutput   = TCON[4];  // Channel output enable
    
    // TCON lower nibble output
    assign TCONLower = TCON[3:0];
    
    // Instantiate TReg Register (8-bit)
    Register8bit TReg_Register (
        .D   (D),            // Shared data bus
        .CLK (SYSCLK),       // Shared clock
        .STR (StoreTreg),    // Store TReg signal
        .RST (TMR_CLR),      // Reset from timer controller
        .Q   (TReg),         // Timer register output
        .Qn  ()   // Unused complement
    );
    
    // Instantiate TCON Register (8-bit)
    Register8bit TCON_Register (
        .D   (D),            // Shared data bus
        .CLK (SYSCLK),       // Shared clock
        .STR (StoreTCON),    // Store TCON signal
        .RST (TMR_CLR),      // Reset from timer controller
        .Q   (TCON),         // TCON register output
        .Qn  ()   // Unused complement
    );
    
    // Instantiate the TMRCTRL module
    TMRCTRL TMR_Control (
        .SYSCLK(SYSCLK),         // System clock for synchronization
        .CLK_IN(CLK_IN),         // Input clock
        .TReg(TReg),             // Timer register value
        .TC(TC),                 // Current counter value
        .StoreTReg(StoreTreg),        // Not used in this configuration
        .CLR(CLR),               // Clear signal (direct connection)
        .TF_CLR(TF_CLR),         // Timer flag clear (direct connection)
        .MCLR(MCLR),             // Master clear (direct connection)
        
        // TCON inputs from upper nibble
        .Enable(Enable),         // Enable from TCON[7]
        .AutoReload(AutoReload), // Auto reload from TCON[6]
        .ENInterrupt(Interrupt), // Enable interrupt from TCON[5]
        .CHOutput(CHOutput),     // Channel output enable from TCON[4]
        
        // Outputs (direct connections)
        .TC_RST(TC_RST),         // Reset signal for counter
        .INC(INC),               // Increment signal for counter
        .Equal(Equal),           // Equal indicator (internal)
        .INTVector(INTVector),   // Interrupt vector (direct output)
        .TFlag(TFlag),           // Timer flag (direct output)
        .TMR_CLR(TMR_CLR),       // Internal clear signal (direct output)
        .TChannel(TChannel)      // Channel output (direct output)
    );
    
    // Instantiate the Counter
    Counter Timer_Counter (
        .INC(INC),               // Increment when INC pulses
        .TC_RST(TC_RST),         // Reset when TC_RST is high
        .TC(TC)                  // 8-bit counter output
    );
    
endmodule


module BaseTimerEXTCON (
    // Base timer with the TCON register - keeps upper nibble, lower nibble to different timer
    
    input  wire SYSCLK,          // system clock used to synchronise CLK_IN   
    input  wire [7:0] D,         // 8-bit data input bus
    input  wire StoreTreg,       // Store signal for TReg register
    input  wire CLK_IN,          // Input clock
    input  wire CLR,             // Clear signal
    input  wire TF_CLR,          // Clears the flag
    input  wire MCLR,            // Master clear
    input wire [3:0] TCONLower,  // Lower nibble of TCON from another timer
    
    output wire TFlag,           // Timer flag output
    output wire INTVector,       // Interrupt vector output
    output wire TMR_CLR,         // MCLR OR CLR, internal clear for timer
    output wire TChannel        // Channel output
    
);

    // Internal wires for TMRCTRL-Counter interconnection
    wire [7:0] TReg;        // Timer register value
    wire [7:0] TC;          // Timer counter current value
    wire TC_RST;            // Timer counter reset
    wire INC;               // Increment signal
    wire Equal;             // Equal indicator (internal)
 
    
    // TCON upper nibble breakdown (MSB to LSB)
    wire Enable     = TCONLower[3];  // MSB - Enable
    wire AutoReload = TCONLower[2];  // Auto reload
    wire Interrupt  = TCONLower[1];  // Interrupt enable
    wire CHOutput   = TCONLower[0];  // Channel output enable
    
    
    // Instantiate TReg Register (8-bit)
    Register8bit TReg_Register (
        .D   (D),            // Shared data bus
        .CLK (CLK_IN),       // Shared clock
        .STR (StoreTreg),    // Store TReg signal
        .RST (TMR_CLR),      // Reset from timer controller
        .Q   (TReg),         // Timer register output
        .Qn  ()   // Unused complement
    );
    
    // Instantiate the TMRCTRL module
    TMRCTRL TMR_Control (
        .SYSCLK(SYSCLK),         // System clock for synchronization
        .CLK_IN(CLK_IN),         // Input clock
        .TReg(TReg),             // Timer register value
        .TC(TC),                 // Current counter value
        .StoreTReg(StoreTreg),        // Not used in this configuration
        .CLR(CLR),               // Clear signal (direct connection)
        .TF_CLR(TF_CLR),         // Timer flag clear (direct connection)
        .MCLR(MCLR),             // Master clear (direct connection)
        
        // TCON inputs from upper nibble
        .Enable(Enable),         // Enable from TCON[7]
        .AutoReload(AutoReload), // Auto reload from TCON[6]
        .ENInterrupt(Interrupt), // Enable interrupt from TCON[5]
        .CHOutput(CHOutput),     // Channel output enable from TCON[4]
        
        // Outputs (direct connections)
        .TC_RST(TC_RST),         // Reset signal for counter
        .INC(INC),               // Increment signal for counter
        .Equal(Equal),           // Equal indicator (internal)
        .INTVector(INTVector),   // Interrupt vector (direct output)
        .TFlag(TFlag),           // Timer flag (direct output)
        .TMR_CLR(TMR_CLR),       // Internal clear signal (direct output)
        .TChannel(TChannel)      // Channel output (direct output)
    );
    
    // Instantiate the Counter
    Counter Timer_Counter (
        .INC(INC),               // Increment when INC pulses
        .TC_RST(TC_RST),         // Reset when TC_RST is high
        .TC(TC)                  // 8-bit counter output
    );
    
endmodule
