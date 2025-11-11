module BaudController(
    input  wire        SYSCLK,    // system clock used to synchronise CLK_IN
    input  wire [7:0]  TReg,      // Timer register reference value
    input  wire [7:0]  TC,        // Timer counter current value
    input  wire        Enable,    // Enable signal
    input  wire        CLK_IN,    // Input clock (asynchronous source)
    input  wire        StoreTReg, // Manual load/reset control (async)
    input  wire        CLR,       // Clear signal (async)
        
    output wire        TC_RST,    // Timer counter reset
    output wire        INC,       // Increment signal
    
    output wire        BaudCLK,  
    output wire        BaudCLKn  
);
    
    wire CLK_Next;
    // Instantiate the PSCTRL module (prescaler controller)
    PSCTRL PS_Control (
        .SYSCLK(SYSCLK),         
        .TReg(TReg),            // Use PSVal from register
        .TC(TC),              // Prescaler counter value
        .Enable(Enable),         // Enable from TCON register
        .CLK_IN(CLK_IN),         // Input clock
        .StoreTReg(StoreBPSStoreTReg),   // Store trigger
        .CLR(CLR),              // Master clear
        .CLK_Next(CLK_Next),     // Output to timer
        .TC_RST(TC_RST),      // Counter reset
        .INC(INC),            // Counter increment
        .Equal()            // Equal flag output
    );
    
     DFF BaudDFF(
        .D(BaudCLKn),      // Data input
        .CLK(CLK_Next),    // Clock input
        .RST(CLR | (CLK_IN & ~Enable)),    // Asynchronous reset (active-high)
        .Q(BaudCLK),      // Output
        .Qn(BaudCLKn)      // Complement output
    );


endmodule 



module BaudrateGenerator (
    // System signals
    input  wire SYSCLK,          // System clock
    input  wire CLK_IN,          // Input clock
    input wire CLK_Sel,
   
    // Data and control inputs
    input  wire [7:0] D,         // 8-bit data input bus
    input  wire StoreBR,       // Store signal for TReg register
    input  wire StoreBPS,        // Store signal for prescaler register
    input  wire CLR,             // Clear signal
    input wire Enable,
    
   
    output wire        BaudCLK,  
    output wire        BaudCLKn, 
    
    //Debug
    output wire         CLK_Next,
    output wire [7:0] Timer_TC,         // Timer counter current value  
    output wire TimClock
    
);

    // Internal signal definitions
    wire [7:0] PSVal;            // Prescaler register value
    wire [7:0] PS_TC;            // Prescaler counter output
    wire PS_TC_RST;              // Prescaler counter reset
    wire PS_INC;                 // Prescaler increment
    
    // Timer internal signals
    wire [7:0] TReg;             // Timer register value
    wire Timer_TC_RST;           // Timer counter reset
    wire Timer_INC;              // Timer increment signal
    wire CLK_SEL_N;
    assign CLK_SEL_N = ~CLK_Sel;


     BitMux CLKSelect (
        .A(SYSCLK),      // Input A
        .SelA(CLK_Sel),   // Select A (active-high)
        .B(CLK_IN),      // Input B  
        .SelB(CLK_SEL_N),   // Select B (active-high)
        .out(TimClock)     // Output
    );   
    
    // Instantiate Prescaler Register (8-bit)
    Register8bit PS_Register (
        .D   (D),                // Shared data bus
        .CLK (CLK_IN),           // System clock
        .STR (StoreBPS),         // Store prescaler signal
        .RST (CLR),          // Reset from timer controller
        .Q   (PSVal),            // Prescaler register output
        .Qn  ()                  // Unused complement
    );
    
    // Instantiate the PSCTRL module (prescaler controller)
    PSCTRL PS_Control (
        .SYSCLK(SYSCLK),         
        .TReg(PSVal),            // Use PSVal from register
        .TC(PS_TC),              // Prescaler counter value
        .Enable(Enable),         // Enable from TCON register
        .CLK_IN(TimClock),         // Input clock
        .StoreTReg(StoreBPS),   // Store trigger
        .CLR(CLR),              // Master clear
        .CLK_Next(CLK_Next),     // Output to timer
        .TC_RST(PS_TC_RST),      // Counter reset
        .INC(PS_INC)            // Counter increment
    );
    
    // Instantiate the prescaler counter
    Counter prescaler_counter (
        .INC(PS_INC),            // Increment signal
        .TC_RST(PS_TC_RST),      // Reset signal
        .TC(PS_TC)               // Counter output
    );
    
    // Instantiate TReg Register (8-bit)
    Register8bit TBR_Register (
        .D   (D),                // Shared data bus
        .CLK (SYSCLK),           // System clock
        .STR (StoreBR),        // Store TReg signal
        .RST (CLR),          // Reset from timer controller
        .Q   (TReg),             // Timer register output
        .Qn  ()                  // Unused complement
    );
   
    
     BaudController BaudCTRL(
     
     .SYSCLK(SYSCLK),    // system clock used to synchronise CLK_IN
    .TReg(TReg),      // Timer register reference value
    .TC(Timer_TC),        // Timer counter current value
    .Enable(Enable),    // Enable signal
    .CLK_IN(CLK_Next),    // Input clock (asynchronous source)
    .StoreTReg(StoreBR), // Manual load/reset control (async)
    .CLR(CLR),       // Clear signal (async)
         
  
    .TC_RST(Timer_TC_RST),    // Timer counter reset
    .INC(Timer_INC),       // Increment signal
    
    .BaudCLK(BaudCLK),  
    .BaudCLKn(BaudCLKn) 
     );
    
    // Instantiate the Timer Counter
    Counter Timer_Counter (
        .INC(Timer_INC),         // Increment when INC pulses
        .TC_RST(Timer_TC_RST),   // Reset when TC_RST is high
        .TC(Timer_TC)            // 8-bit counter output
    );
    
endmodule