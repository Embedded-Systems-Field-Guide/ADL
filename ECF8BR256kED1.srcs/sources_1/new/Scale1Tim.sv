

module Scale1TimerTCON (
    // System signals
    input  wire SYSCLK,          // System clock
    input  wire MCLR,            // Master clear
    
    // Data and control inputs
    input  wire [7:0] D,         // 8-bit data input bus
    input  wire StoreTreg,       // Store signal for TReg register
    input  wire StoreTCON,       // Store signal for TCON register
    input  wire StoreTPs,        // Store signal for prescaler register
    input  wire CLR,             // Clear signal
    input  wire TF_CLR,          // Timer flag clear
    input  wire CLK_IN,          // Input clock (typically 1Hz from clock divider)
    
    // Timer outputs
    output wire TFlag,           // Timer flag output
    output wire INTVector,       // Interrupt vector output
    output wire TChannel,        // Channel output
    output wire [3:0] TCONLower, // Lower nibble of TCON for another timer
    
    // Debug/monitoring outputs
    output wire CLK_Next,        // Prescaler clock output
    output wire Equal            // Prescaler equal flag
);

    // Internal signal definitions
    wire [7:0] PSVal;            // Prescaler register value
    wire [7:0] PS_TC;            // Prescaler counter output
    wire PS_TC_RST;              // Prescaler counter reset
    wire PS_INC;                 // Prescaler increment
    wire TMR_CLR;                // Timer clear (internal)
    
    // Timer internal signals
    wire [7:0] TReg;             // Timer register value
    wire [7:0] Timer_TC;         // Timer counter current value
    wire Timer_TC_RST;           // Timer counter reset
    wire Timer_INC;              // Timer increment signal
    wire Timer_Equal;            // Timer equal indicator (internal)
    
    // TCON register and control signals
    wire [7:0] TCON;             // Full TCON register
    wire Enable     = TCON[7];   // Enable from TCON[7]
    wire AutoReload = TCON[6];   // Auto reload from TCON[6]
    wire Interrupt  = TCON[5];   // Interrupt enable from TCON[5]
    wire CHOutput   = TCON[4];   // Channel output enable from TCON[4]
    
    // TCON lower nibble output
    assign TCONLower = TCON[3:0];
    
    // Instantiate Prescaler Register (8-bit)
    Register8bit PS_Register (
        .D   (D),                // Shared data bus
        .CLK (SYSCLK),           // System clock
        .STR (StoreTPs),         // Store prescaler signal
        .RST (TMR_CLR),          // Reset from timer controller
        .Q   (PSVal),            // Prescaler register output
        .Qn  ()                  // Unused complement
    );
    
    // Instantiate the PSCTRL module (prescaler controller)
    PSCTRL PS_Control (
        .SYSCLK(SYSCLK),         
        .TReg(PSVal),            // Use PSVal from register
        .TC(PS_TC),              // Prescaler counter value
        .Enable(Enable),         // Enable from TCON register
        .CLK_IN(CLK_IN),         // Input clock
        .StoreTReg(StoreTPs),   // Store trigger
        .CLR(MCLR),              // Master clear
        .CLK_Next(CLK_Next),     // Output to timer
        .TC_RST(PS_TC_RST),      // Counter reset
        .INC(PS_INC),            // Counter increment
        .Equal(Equal)            // Equal flag output
    );
    
    // Instantiate the prescaler counter
    Counter prescaler_counter (
        .INC(PS_INC),            // Increment signal
        .TC_RST(PS_TC_RST),      // Reset signal
        .TC(PS_TC)               // Counter output
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
    
    // Instantiate TCON Register (8-bit)
    Register8bit TCON_Register (
        .D   (D),                // Shared data bus
        .CLK (SYSCLK),           // System clock
        .STR (StoreTCON),        // Store TCON signal
        .RST (TMR_CLR),          // Reset from timer controller
        .Q   (TCON),             // TCON register output
        .Qn  ()                  // Unused complement
    );
    
    // Instantiate the TMRCTRL module (timer controller)
    TMRCTRL TMR_Control (
        .SYSCLK(SYSCLK),         // System clock for synchronization
        .CLK_IN(CLK_Next),       // Input clock from prescaler
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


module Scale1TimerEXTCON (

    input  wire SYSCLK,          
    input  wire MCLR,            

    input  wire [7:0] D,         
    input  wire StoreTreg,       
    input  wire StoreTPs,        
    input  wire CLR,             
    input  wire TF_CLR,          
    input  wire CLK_IN,          

    output wire TFlag,           
    output wire INTVector,       
    output wire TChannel,        
    input wire [3:0] TCONLower, 

    output wire CLK_Next,        
    output wire Equal            
);

    wire [7:0] PSVal;            
    wire [7:0] PS_TC;            
    wire PS_TC_RST;              
    wire PS_INC;                 
    wire TMR_CLR;                

    wire [7:0] TReg;             
    wire [7:0] Timer_TC;         
    wire Timer_TC_RST;           
    wire Timer_INC;              
    wire Timer_Equal;            

    wire Enable     = TCONLower[3];   
    wire AutoReload = TCONLower[2];   
    wire Interrupt  = TCONLower[1];   
    wire CHOutput   = TCONLower[0];   

     Register8bit PS_Register (
        .D   (D),                
        .CLK (CLK_IN),           
        .STR (StoreTPs),         
        .RST (TMR_CLR),          
        .Q   (PSVal),            
        .Qn  ()                  
    );   

    PSCTRL PS_Control (
        .SYSCLK(SYSCLK),         
        .TReg(PSVal),            
        .TC(PS_TC),              
        .Enable(Enable),         
        .CLK_IN(CLK_IN),         
        .StoreTReg(StoreTPs),   
        .CLR(MCLR),              
        .CLK_Next(CLK_Next),     
        .TC_RST(PS_TC_RST),      
        .INC(PS_INC),            
        .Equal(Equal)            
    );

    UnitDelay ClkBDel (
        .sysclk(SYSCLK),
        .Din(CLK_Next),
        .Dout(CLK_NextL)
    );

    Counter prescaler_counter (
        .INC(PS_INC),            
        .TC_RST(PS_TC_RST),      
        .TC(PS_TC)               
    );

    Register8bit TReg_Register (
        .D   (D),                
        .CLK (CLK_IN),           
        .STR (StoreTreg),        
        .RST (TMR_CLR),          
        .Q   (TReg),             
        .Qn  ()                  
    );

    TMRCTRL TMR_Control (
        .SYSCLK(SYSCLK),         
        .CLK_IN(CLK_NextL),       
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