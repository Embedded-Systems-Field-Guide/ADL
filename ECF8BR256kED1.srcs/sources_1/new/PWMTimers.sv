
module PWMTCONTCON (
    // System signals
    input  wire SYSCLK,          // System clock
    input  wire MCLR,            // Master clear
    input wire CLK_IN,
    
    // Data bus
    input  wire [7:0] DataBus,   // 8-bit data input bus
    
    // Control inputs
    input  wire StoreTCON,       // Store TCON register
    input  wire StoreTH,         // Store TH register
    input  wire StoreTL,         // Store TL register
    input  wire StorePS,         // Store Prescaler register
    input  wire TF_CLR,          // Timer flag clear
    input  wire CLR,
    
    // Outputs
    output wire [7:0] TC,        // Timer counter output (address bus)
    output wire TFlag,           // Timer flag
    output wire TChannel,        // Timer channel output
    output wire INTVector,
    
    //debug
    output wire [3:0] TCONLower, // Lower nibble of TCON for another timer   
    output wire [7:0] TC_PS,            // Prescaler counter
    output wire CLK_Next               // Clock from prescaler
);

    wire TMR_CLR;          // Timer clear signal
    // Internal registers
    wire [7:0] TCONReg;          // Timer Control Register
    wire [7:0] THReg;            // Timer High Period Register
    wire [7:0] TLReg;            // Timer Low Period Register
    wire [7:0] TPs;              // Prescaler Register
    
    // Extract control signals from TCON register
    wire Enable      = TCONReg[7];  // Bit 7: Timer Enable
    
    wire ENInterrupt = TCONReg[5];  // Bit 5: Interrupt enable
    wire CHOutput    = TCONReg[4];  // Bit 4: Channel output enable
    assign TCONLower = TCONReg[3:0];
    
    // Internal PWM control signals
    wire TC_RST;                 // Timer counter reset
    wire INC;                    // Timer increment signal
    
    // Prescaler signals
    wire TC_RSTPS;               // Prescaler counter reset
    wire INCPS;                  // Prescaler increment
    
    // TCON Register (Timer Control Register)
    Register8bit TCON_Register (
        .D(DataBus),
        .CLK(SYSCLK),
        .STR(StoreTCON),
        .RST(TMR_CLR),
        .Q(TCONReg),
        .Qn()
    );
    
    // TH Register (Timer High Period)
    Register8bit TH_Register (
        .D(DataBus),
        .CLK(SYSCLK),
        .STR(StoreTH),
        .RST(TMR_CLR),
        .Q(THReg),
        .Qn()
    );
    
    // TL Register (Timer Low Period)
    Register8bit TL_Register (
        .D(DataBus),
        .CLK(SYSCLK),
        .STR(StoreTL),
        .RST(TMR_CLR),
        .Q(TLReg),
        .Qn()
    );
    
    // Prescaler Register
    Register8bit PS_Register (
        .D(DataBus),
        .CLK(SYSCLK),
        .STR(StorePS),
        .RST(TMR_CLR),
        .Q(TPs),
        .Qn()
    );
    
    // PWM Control Module
    PWMCTRL PWM_Control (
        .SYSCLK(SYSCLK),
        .CLK_IN(CLK_Next),
        .THReg(THReg),
        .TLReg(TLReg),
        .StoreTHReg(StoreTH),
        .StoreTLReg(StoreTL),
        .TF_CLR(TF_CLR),
        .CLR(CLR),              // Assuming CLR was meant to be tied to ground
        .MCLR(MCLR),
        
        // Debug outputs (unused)
        .TReg(),
        .Equal(),
        
        // TCON control inputs
        .Enable(Enable),
//        .AutoReload(AutoReload),
        .ENInterrupt(ENInterrupt),
        .CHOutput(CHOutput),
        
        // Counter interface
        .TC(TC),
        .TC_RST(TC_RST),
        .INC(INC),
        
        // Outputs
        .INTVector(INTVector),
        .TFlag(TFlag),
        .TChannel(TChannel),
        .TMR_CLR(TMR_CLR),
        .Fset()
    );
    
    // Main Timer Counter
    Counter PWM_Counter (
        .INC(INC),
        .TC_RST(TC_RST),
        .TC(TC)
    );
    
    // Prescaler Control Module
    PSCTRL PS_Control (
        .SYSCLK(SYSCLK),
        .TReg(TPs),
        .TC(TC_PS),
        .Enable(Enable),
        .CLK_IN(CLK_IN),
        .StoreTReg(StorePS),
        .CLR(TMR_CLR),
        .CLK_Next(CLK_Next),
        .TC_RST(TC_RSTPS),
        .INC(INCPS),
        .Equal()
    );
    
    // Prescaler Counter
    Counter Prescaler_Counter (
        .INC(INCPS),
        .TC_RST(TC_RSTPS),
        .TC(TC_PS)
    );

endmodule


module PWMTCONEXTCON (
    // System signals
    input  wire SYSCLK,          // System clock
    input  wire MCLR,            // Master clear
    input wire CLK_IN,
    
    // Data bus
    input  wire [7:0] DataBus,   // 8-bit data input bus
    
    // Control inputs
    input  wire StoreTH,         // Store TH register
    input  wire StoreTL,         // Store TL register
    input  wire StorePS,         // Store Prescaler register
    input  wire TF_CLR,          // Timer flag clear
    input  wire CLR,
    
    // Outputs
    output wire [7:0] TC,        // Timer counter output (address bus)
    output wire TFlag,           // Timer flag
    output wire TChannel,        // Timer channel output
    output wire INTVector,
    input wire [3:0] TCONLower // Lower nibble of TCON for another timer
);

    wire TMR_CLR;          // Timer clear signal
    // Internal registers
    wire [7:0] TCONReg;          // Timer Control Register
    wire [7:0] THReg;            // Timer High Period Register
    wire [7:0] TLReg;            // Timer Low Period Register
    wire [7:0] TPs;              // Prescaler Register
    
    // Extract control signals from TCON register
    wire Enable      = TCONLower[3];  // Bit 7: Timer Enable
    wire AutoReload  = TCONLower[2];  // Bit 6: Auto-reload enable
    wire ENInterrupt = TCONLower[1];  // Bit 5: Interrupt enable
    wire CHOutput    = TCONLower[0];  // Bit 4: Channel output enable
    
    // Internal PWM control signals
    wire TC_RST;                 // Timer counter reset
    wire INC;                    // Timer increment signal
    wire CLK_Next;               // Clock from prescaler
    
    // Prescaler signals
    wire [7:0] TC_PS;            // Prescaler counter
    wire TC_RSTPS;               // Prescaler counter reset
    wire INCPS;                  // Prescaler increment
    
    // TH Register (Timer High Period)
    Register8bit TH_Register (
        .D(DataBus),
        .CLK(SYSCLK),
        .STR(StoreTH),
        .RST(TMR_CLR),
        .Q(THReg),
        .Qn()
    );
    
    // TL Register (Timer Low Period)
    Register8bit TL_Register (
        .D(DataBus),
        .CLK(SYSCLK),
        .STR(StoreTL),
        .RST(TMR_CLR),
        .Q(TLReg),
        .Qn()
    );
    
    // Prescaler Register
    Register8bit PS_Register (
        .D(DataBus),
        .CLK(SYSCLK),
        .STR(StorePS),
        .RST(TMR_CLR),
        .Q(TPs),
        .Qn()
    );
    
    // PWM Control Module
    PWMCTRL PWM_Control (
        .SYSCLK(SYSCLK),
        .CLK_IN(CLK_Next),
        .THReg(THReg),
        .TLReg(TLReg),
        .StoreTHReg(StoreTH),
        .StoreTLReg(StoreTL),
        .TF_CLR(TF_CLR),
        .CLR(CLR),              // Assuming CLR was meant to be tied to ground
        .MCLR(MCLR),
        
        // Debug outputs (unused)
        .TReg(),
        .Equal(),
        
        // TCON control inputs
        .Enable(Enable),
//        .AutoReload(AutoReload),
        .ENInterrupt(ENInterrupt),
        .CHOutput(CHOutput),
        
        // Counter interface
        .TC(TC),
        .TC_RST(TC_RST),
        .INC(INC),
        
        // Outputs
        .INTVector(INTVector),
        .TFlag(TFlag),
        .TChannel(TChannel),
        .TMR_CLR(TMR_CLR),
        .Fset()
    );
    
    // Main Timer Counter
    Counter PWM_Counter (
        .INC(INC),
        .TC_RST(TC_RST),
        .TC(TC)
    );
    
    // Prescaler Control Module
    PSCTRL PS_Control (
        .SYSCLK(SYSCLK),
        .TReg(TPs),
        .TC(TC_PS),
        .Enable(Enable),
        .CLK_IN(CLK_IN),
        .StoreTReg(StorePS),
        .CLR(TMR_CLR),
        .CLK_Next(CLK_Next),
        .TC_RST(TC_RSTPS),
        .INC(INCPS),
        .Equal()
    );
    
    // Prescaler Counter
    Counter Prescaler_Counter (
        .INC(INCPS),
        .TC_RST(TC_RSTPS),
        .TC(TC_PS)
    );

endmodule