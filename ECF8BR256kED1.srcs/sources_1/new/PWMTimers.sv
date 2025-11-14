module PWMModule (
    //System inputs
    input  wire SYSCLK,          
    input  wire MCLR,            
    input wire CLK_IN,
    input  wire [7:0] DataBus,   
    
    //Timer Setup
    input  wire StoreTH,         
    input  wire StoreTL,         
    input  wire StorePS,         
    input  wire TF_CLR,          
    input  wire CLR,
    input wire [3:0] TCONBits, 
    
    //Output 
    output wire TFlag,           
    output wire TChannel,        
    output wire INTVector,
    
    //debug
    output wire [7:0] TC,       
    output wire [7:0] TC_PS,            
    output wire CLK_Next               
);
    wire TMR_CLR;                
    wire [7:0] THReg;            
    wire [7:0] TLReg;            
    wire [7:0] TPs;     
             
    wire Enable      = TCONBits[3];  
    wire ENInterrupt = TCONBits[1];  
    wire CHOutput    = TCONBits[0];  
    
    wire TC_RST;                 
    wire INC;                    
    wire TC_RSTPS;               
    wire INCPS;                  
    Register8bit TH_Register (
        .D(DataBus),
        .CLK(SYSCLK),
        .STR(StoreTH),
        .RST(TMR_CLR),
        .Q(THReg),
        .Qn()
    );
    Register8bit TL_Register (
        .D(DataBus),
        .CLK(SYSCLK),
        .STR(StoreTL),
        .RST(TMR_CLR),
        .Q(TLReg),
        .Qn()
    );
    Register8bit PS_Register (
        .D(DataBus),
        .CLK(SYSCLK),
        .STR(StorePS),
        .RST(TMR_CLR),
        .Q(TPs),
        .Qn()
    );
    PWMCTRL PWM_Control (
        .SYSCLK(SYSCLK),
        .CLK_IN(CLK_Next),
        .THReg(THReg),
        .TLReg(TLReg),
        .StoreTHReg(StoreTH),
        .StoreTLReg(StoreTL),
        .TF_CLR(TF_CLR),
        .CLR(CLR),             
        .MCLR(MCLR),
        .TReg(),
        .Equal(),
        .Enable(Enable),
        .ENInterrupt(ENInterrupt),
        .CHOutput(CHOutput),
        .TC(TC),
        .TC_RST(TC_RST),
        .INC(INC),
        .INTVector(INTVector),
        .TFlag(TFlag),
        .TChannel(TChannel),
        .TMR_CLR(TMR_CLR),
        .Fset()
    );
    Counter PWM_Counter (
        .INC(INC),
        .TC_RST(TC_RST),
        .TC(TC)
    );
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
    Counter Prescaler_Counter (
        .INC(INCPS),
        .TC_RST(TC_RSTPS),
        .TC(TC_PS)
    );
endmodule