// PSCTRL.sv
module PSCTRL (
    input  wire        SYSCLK,    // system clock used to synchronise CLK_IN
    input  wire [7:0]  TReg,      // Timer register reference value
    input  wire [7:0]  TC,        // Timer counter current value
    input  wire        Enable,    // Enable signal
    input  wire        CLK_IN,    // Input clock (asynchronous source)
    input  wire        StoreTReg, // Manual load/reset control (async)
    input  wire        CLR,       // Clear signal (async)
    output wire        CLK_Next,  // Output clock for next stage (latched)
    output wire        TC_RST,    // Timer counter reset
    output wire        INC,       // Increment signal
    output wire        Equal      // Debug: 1 when TC == TReg 
);
   
   // Check if bypass mode (TReg == 0)
   wire bypass_mode = (TReg == 8'h00);
   
   // loadable/debug signals (unchanged logic)
   assign Equal = (TC == TReg);
   assign INC   = (CLK_IN & Enable);  
   
   wire EqualSRQ;
   wire ResetCondition = StoreTReg | CLK_Next | CLR;
   
   SRLatch EqualLatch(
       .SYSCLK(SYSCLK),           // System clock for synchronization  
       .Set(Equal & Enable),      // Set signal (synchronous)
       .Reset(TC_RST),            // Reset signal (asynchronous priority)
       .Q(EqualSRQ)               // Output Q
   );
   
   // Normal timing logic output
   wire normal_CLK_Next = ~Equal & EqualSRQ;
   
   // Bypass logic: direct pass-through when TReg == 0
   wire bypass_CLK_Next = CLK_IN & Enable;
   
   // Select between normal and bypass modes
   assign CLK_Next = bypass_mode ? bypass_CLK_Next : normal_CLK_Next;
   
   // TC_RST logic (may need adjustment for bypass mode)
   assign TC_RST = ResetCondition & ~CLK_IN;
   
endmodule


module TMRCTRL (
    input  wire SYSCLK,          // system clock used to synchronise CLK_IN   
    input  wire CLK_IN,          // Input clock
    input  wire [7:0] TReg,      // Timer register reference value
    input  wire [7:0] TC,        // Timer counter current value
    input  wire StoreTReg,       // Manual load/reset control
    input  wire CLR,             // Clear signal
    input  wire TF_CLR,          // Clears the flag
    input  wire MCLR,            // Master clear
    
    // From TCON
    input  wire Enable,          // Enable signal
    input  wire AutoReload,      
    input  wire ENInterrupt,     // Enable interrupt
    input  wire CHOutput,        
    
    output wire TC_RST,          // Timer counter reset
    output wire INC,             // Increment signal
    output wire Equal,           // Debug: 1 when TC == TReg
    output wire INTVector,       // Interrupt vector output
    output wire TFlag,           // Timer flag output
    output wire TMR_CLR,         // MCLR OR CLR, internal clear for timer
    output wire TChannel         // Channel output
);

    assign TMR_CLR = MCLR | CLR;
    wire RaiseFlag;
    wire TFlagn;
    wire TC_RSTScalar;
    
    PSCTRL TIMscalar(
        .SYSCLK(SYSCLK),    // system clock used to synchronise CLK_IN
        .TReg(TReg),      // Timer register reference value
        .TC(TC),        // Timer counter current value
        .Enable(Enable),    // Enable signal
        .CLK_IN(CLK_IN & TFlagn),    // Input clock (asynchronous source)
        .StoreTReg(StoreTReg), // Manual load/reset control (async)
        .CLR(TMR_CLR),       // Clear signal (async)
        .CLK_Next(RaiseFlag),  // Output clock for next stage (latched)
        .TC_RST(TC_RSTScalar),    // Timer counter reset
        .INC(INC),       // Increment signal
        .Equal(Equal)      // Debug: 1 when TC == TReg 
    );
    
       SRLatch FlagLatch(
           .SYSCLK(SYSCLK),           // System clock for synchronization  
           .Set(RaiseFlag),      // Set signal (synchronous)
           .Reset(TF_CLR),            // Reset signal (asynchronous priority)
           .Q(TFlag),               // Output Q
           .Qn(TFlagn)               // Output Q
        );
        
        assign INTVector = TFlag & ENInterrupt;
        assign TC_RST =TC_RSTScalar | TF_CLR;
    
    
endmodule

module PWMCTRL (
    input  wire SYSCLK,          
    input  wire CLK_IN,          
    input  wire [7:0] THReg,      
    input  wire [7:0] TLReg,      
    input  wire StoreTHReg,       
    input  wire StoreTLReg,          
    input  wire TF_CLR,      
    input  wire CLR,              
    input  wire MCLR,            
    
    // From TCON     
    input  wire Enable,      
    input  wire ENInterrupt,    
    input  wire CHOutput,        
    
    //Counter I/O   
    input  wire [7:0] TC,     
    output wire TC_RST,          
    output wire INC,     
            
    output wire INTVector,      
    output wire TFlag,            
    output wire TChannel,     
    output wire TMR_CLR,   
    
    //Debug lines
    output wire Equal,    
    output wire [7:0] TReg,
    output wire TH,
    output wire TL,
    output wire Fset
);
    
    wire [7:0] CurrentCompare;
    wire FlipPoint;
    assign TMR_CLR = CLR | MCLR;
    
     PSCTRL PWMscalar(
       .SYSCLK(SYSCLK),    // system clock used to synchronise CLK_IN
       .TReg(CurrentCompare),      // Timer register reference value
       .TC(TC),        // Timer counter current value
        .Enable(Enable),    // Enable signal
        .CLK_IN(CLK_IN),    // Input clock (asynchronous source)
        .StoreTReg(StoreTHReg | StoreTLReg), // Manual load/reset control (async)
        .CLR(TMR_CLR),       // Clear signal (async)
        .CLK_Next(FlipPoint),  // Output clock for next stage (latched)
        .TC_RST(TC_RST),    // Timer counter reset
        .INC(INC),       // Increment signal
        .Equal(Equal)      // Debug: 1 when TC == TReg 
    );
    
    SRLatch FlagLatch (
        .SYSCLK(SYSCLK),    // System clock for synchronization
        .Set(FlipPoint),       // Set signal (synchronous)
        .Reset(TF_CLR),     // Reset signal (asynchronous priority)
        .Q(TFlag)
    );
    
    
    assign INTVector = ENInterrupt & TFlag;

    wire PWMLatchn;
    wire PWMout;
    DFF PWMLatch (
       .D(PWMLatchn),      // Data input
       .CLK(FlipPoint),    // Clock input
       .RST(TMR_CLR),    // Asynchronous reset (active-high)
       .Q(PWMout),      // Output
       .Qn(PWMLatchn)      // Complement output
    );
    
    assign TChannel = PWMout & CHOutput;
    assign CurrentCompare = PWMout ? THReg : TLReg;
    
endmodule


