module Scale2TimerTCON (

    input  wire SYSCLK,
    input  wire MCLR,

    input  wire [7:0] D,
    input  wire StoreTreg,
    input  wire StoreTCON,
    input  wire StoreTPsA,
    input  wire StoreTPsB,
    input  wire CLR,
    input  wire TF_CLR,
    input  wire CLK_IN,

    output wire TFlag,
    output wire INTVector,
    output wire TChannel,
    output wire [3:0] TCONLower,

    output wire CLK_NextA,
    output wire CLK_NextB,
    output wire EqualA,
    output wire EqualB,
    output wire [7:0] PS_TCA,
    output wire [7:0] PS_TCB,


    output wire CLK_NextA_dbg,
    output wire CLK_NextB_dbg
);

    // --- internal wires added / clarified ---
    wire TMR_CLR;

    // Prescaler A internal values
    wire [7:0] PSValA;
    wire PS_TC_RSTA;
    wire CLK_NextAL;        // <--- explicit declaration

    // Prescaler B internal values
    wire [7:0] PSValB;
    wire PS_TC_RSTB;
    wire PS_INCB;
    wire CLK_NextBL;        // <--- explicit declaration

    // Timer register / counter wires
    wire [7:0] TReg;
    wire [7:0] Timer_TC;
    wire Timer_TC_RST;
    wire Timer_INC;
    wire Timer_Equal;

    // Internal TCON register
    wire [7:0] TCON;
    wire Enable     = TCON[7];
    wire AutoReload = TCON[6];
    wire Interrupt  = TCON[5];
    wire CHOutput   = TCON[4];
    assign IsEnabled = Enable;

    assign TCONLower = TCON[3:0];

    // Keep PS_TCA/PS_TCB/PS_INCA visible to top-level if you want,
    // but drive them from internal wires (avoid accidental port-direction bugs).
    wire [7:0] ps_tca_int;
    wire [7:0] ps_tcb_int;
    wire ps_inca_int;

    assign PS_TCA = ps_tca_int;
    assign PS_TCB = ps_tcb_int;
    assign PS_INCA = ps_inca_int;

    Register8bit PS_Register (
        .D   (D),
        .CLK (CLK_IN),
        .STR (StoreTPsA),
        .RST (TMR_CLR),
        .Q   (PSValA),
        .Qn  ()
    );

    PSCTRL PS_Control (
        .SYSCLK(SYSCLK),
        .TReg(PSValA),
        .TC(ps_tca_int),         // internal wire
        .Enable(Enable),
        .CLK_IN(CLK_IN),
        .StoreTReg(StoreTPsA),
        .CLR(MCLR),
        .CLK_Next(CLK_NextA),
        .TC_RST(PS_TC_RSTA),
        .INC(ps_inca_int),
        .Equal(EqualA)
    );

    Counter prescaler_counter (
        .INC(ps_inca_int),
        .TC_RST(PS_TC_RSTA),
        .TC(ps_tca_int)
    );

    Register8bit PS_RegisterB (
        .D   (D),
        .CLK (CLK_IN),
        .STR (StoreTPsB),
        .RST (TMR_CLR),
        .Q   (PSValB),
        .Qn  ()
    );

    UnitDelay ClkADel (
        .sysclk(SYSCLK),
        .Din(CLK_NextA),
        .Dout(CLK_NextAL)   // now declared
    );

    PSCTRL PSB_Control (
        .SYSCLK(SYSCLK),
        .TReg(PSValB),
        .TC(ps_tcb_int),         // internal wire
        .Enable(Enable),
        .CLK_IN(CLK_NextAL),
        .StoreTReg(StoreTPsB),
        .CLR(MCLR),
        .CLK_Next(CLK_NextB),
        .TC_RST(PS_TC_RSTB),
        .INC(PS_INCB),
        .Equal(EqualB)
    );

    Counter prescaler_counterB (
        .INC(PS_INCB),
        .TC_RST(PS_TC_RSTB),
        .TC(ps_tcb_int)
    );

    Register8bit TReg_Register (
        .D   (D),
        .CLK (CLK_IN),
        .STR (StoreTreg),
        .RST (TMR_CLR),
        .Q   (TReg),
        .Qn  ()
    );

    Register8bit TCON_Register (
        .D   (D),
        .CLK (CLK_IN),
        .STR (StoreTCON),
        .RST (TMR_CLR),
        .Q   (TCON),
        .Qn  ()
    );

    UnitDelay ClkBDel (
        .sysclk(SYSCLK),
        .Din(CLK_NextB),
        .Dout(CLK_NextBL)   // now declared
    );

    TMRCTRL TMR_Control (
        .SYSCLK(SYSCLK),
        .CLK_IN(CLK_NextBL),
        .TReg(TReg),
        .TC(Timer_TC),
        .StoreTReg(StoreTreg),
        .CLR(CLR),
        .TF_CLR(TF_CLR),
        .MCLR(MCLR),

        .Enable(Enable),
        .AutoReload(AutoReload),
        .ENInterrupt(Interrupt),
        .CHOutput(CHOutput),

        .TC_RST(Timer_TC_RST),
        .INC(Timer_INC),
        .Equal(Timer_Equal),
        .INTVector(INTVector),
        .TFlag(TFlag),
        .TMR_CLR(TMR_CLR),
        .TChannel(TChannel)
    );

    Counter Timer_Counter (
        .INC(Timer_INC),
        .TC_RST(Timer_TC_RST),
        .TC(Timer_TC)
    );

endmodule

module Scale2TimerEXTCON (
    // System signals
    input  wire SYSCLK,          // System clock
    input  wire MCLR,            // Master clear
    
    // Data and control inputs
    input  wire [7:0] D,         // 8-bit data input bus
    input  wire StoreTreg,       // Store signal for TReg register
    input  wire StoreTCON,       // Store signal for TCON register
    input  wire StoreTPsA,        // Store signal for prescaler register
    input  wire StoreTPsB,        // Store signal for prescaler register
    input  wire CLR,             // Clear signal
    input  wire TF_CLR,          // Timer flag clear
    input  wire CLK_IN,          // Input clock (typically 1Hz from clock divider)
    
    // Timer outputs
    output wire TFlag,           // Timer flag output
    output wire INTVector,       // Interrupt vector output
    output wire TChannel,        // Channel output
    input wire [3:0] TCONLower, // Lower nibble of TCON for another timer
    
    // Debug/monitoring outputs
    output wire CLK_NextA,        // Prescaler clock output
    output wire CLK_NextB,        // Prescaler clock output
    output wire EqualA,            // Prescaler equal flag
    output wire EqualB            // Prescaler equal flag
);

    // Internal signal definitions
    wire TMR_CLR;                // Timer clear (internal)
    
    
    wire [7:0] PSValA;            // Prescaler register value
    wire [7:0] PS_TCA;            // Prescaler counter output
    wire PS_TC_RSTA;              // Prescaler counter reset
    wire PS_INCA;                 // Prescaler increment
    
    wire [7:0] PSValB;            // Prescaler register value
    wire [7:0] PS_TCB;            // Prescaler counter output
    wire PS_TC_RSTB;              // Prescaler counter reset
    wire PS_INCB;                 // Prescaler increment  
    
    // Timer internal signals
    wire [7:0] TReg;             // Timer register value
    wire [7:0] Timer_TC;         // Timer counter current value
    wire Timer_TC_RST;           // Timer counter reset
    wire Timer_INC;              // Timer increment signal
    wire Timer_Equal;            // Timer equal indicator (internal)
    
    // TCON register and control signals
    wire Enable     = TCONLower[7];   // Enable from TCON[7]
    wire AutoReload = TCONLower[6];   // Auto reload from TCON[6]
    wire Interrupt  = TCONLower[5];   // Interrupt enable from TCON[5]
    wire CHOutput   = TCONLower[4];   // Channel output enable from TCON[4]

    
    // Instantiate Prescaler Register (8-bit)
    Register8bit PS_Register (
        .D   (D),                // Shared data bus
        .CLK (SYSCLK),           // System clock
        .STR (StoreTPsA),         // Store prescaler signal
        .RST (TMR_CLR),          // Reset from timer controller
        .Q   (PSValA),            // Prescaler register output
        .Qn  ()                  // Unused complement
    );
    
    // Instantiate the PSCTRL module (prescaler controller)
    PSCTRL PS_Control (
        .SYSCLK(SYSCLK),         
        .TReg(PSValA),            // Use PSVal from register
        .TC(PS_TCA),              // Prescaler counter value
        .Enable(Enable),         // Enable from TCON register
        .CLK_IN(CLK_IN),         // Input clock
        .StoreTReg(StoreTPsA),   // Store trigger
        .CLR(MCLR),              // Master clear
        .CLK_Next(CLK_NextA),     // Output to timer
        .TC_RST(PS_TC_RSTA),      // Counter reset
        .INC(PS_INCA),            // Counter increment
        .Equal(EqualA)            // Equal flag output
    );
    
    // Instantiate the prescaler counter
    Counter prescaler_counter (
        .INC(PS_INCA),            // Increment signal
        .TC_RST(PS_TC_RSTA),      // Reset signal
        .TC(PS_TCA)               // Counter output
    );
    
    
        // Instantiate Prescaler Register (8-bit)
    Register8bit PS_RegisterB (
        .D   (D),                // Shared data bus
        .CLK (SYSCLK),           // System clock
        .STR (StoreTPsB),         // Store prescaler signal
        .RST (TMR_CLR),          // Reset from timer controller
        .Q   (PSValB),            // Prescaler register output
        .Qn  ()                  // Unused complement
    );
    
    // Instantiate the PSCTRL module (prescaler controller)
    PSCTRL PSB_Control (
        .SYSCLK(SYSCLK),         
        .TReg(PSValB),            // Use PSVal from register
        .TC(PS_TCB),              // Prescaler counter value
        .Enable(Enable),         // Enable from TCON register
        .CLK_IN(CLK_NextA),         // Input clock
        .StoreTReg(StoreTPsB),   // Store trigger
        .CLR(MCLR),              // Master clear
        .CLK_Next(CLK_NextB),     // Output to timer
        .TC_RST(PS_TC_RSTB),      // Counter reset
        .INC(PS_INCB),            // Counter increment
        .Equal(EqualB)            // Equal flag output
    );
    
    // Instantiate the prescaler counter
    Counter prescaler_counterB (
        .INC(PS_INCB),            // Increment signal
        .TC_RST(PS_TC_RSTB),      // Reset signal
        .TC(PS_TCB)               // Counter output
    );
    
    
    // Instantiate TReg Register (8-bit)
    Register8bit TReg_Register (
        .D   (D),                // Shared data bus
        .CLK (SYSCLK),           // System clock
        .STR (StoreTreg),        // Store TReg signal
        .RST (TMR_CLR),          // Reset from timer controller
        .Q   (TReg),             // Timer register output
        .Qn  ()                  // Unused complement
    );
    
    // Instantiate the TMRCTRL module (timer controller)
    TMRCTRL TMR_Control (
        .SYSCLK(SYSCLK),         // System clock for synchronization
        .CLK_IN(CLK_NextB),       // Input clock from prescaler
        .TReg(TReg),             // Timer register value
        .TC(Timer_TC),           // Current counter value
        .StoreTReg(StoreTreg),   // Store trigger
        .CLR(CLR),               // Clear signal
        .TF_CLR(TF_CLR),         // Timer flag clear
        .MCLR(MCLR),             // Master clear
        
        // TCON inputs from upper nibble
        .Enable(Enable),         // Enable from TCON[7]
        .AutoReload(AutoReload), // Auto reload from TCON[6]
        .ENInterrupt(Interrupt), // Enable interrupt from TCON[5]
        .CHOutput(CHOutput),     // Channel output enable from TCON[4]
        
        // Outputs
        .TC_RST(Timer_TC_RST),   // Reset signal for counter
        .INC(Timer_INC),         // Increment signal for counter
        .Equal(Timer_Equal),     // Equal indicator (internal)
        .INTVector(INTVector),   // Interrupt vector output
        .TFlag(TFlag),           // Timer flag output
        .TMR_CLR(TMR_CLR),       // Internal clear signal
        .TChannel(TChannel)      // Channel output
    );
    
    // Instantiate the Timer Counter
    Counter Timer_Counter (
        .INC(Timer_INC),         // Increment when INC pulses
        .TC_RST(Timer_TC_RST),   // Reset when TC_RST is high
        .TC(Timer_TC)            // 8-bit counter output
    );
    
endmodule
