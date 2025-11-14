module Scale1Timer(
    //System inputs
    input  wire SYSCLK,          
    input  wire MCLR,            
    input  wire [7:0] D,          
    input  wire CLK_IN,  
    
    //TimConfig      
    input  wire StoreTreg,        
    input  wire StoreTPs, 
    input  wire CLR,             
    input  wire TF_CLR,  
    input wire [3:0] TCONBits, 
       
     //Outputs             
    output wire TFlag,           
    output wire INTVector,       
    output wire TChannel,   
    
    //Debug     
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
    wire Enable     = TCONBits[3];   
    wire AutoReload = TCONBits[2];   
    wire Interrupt  = TCONBits[1];   
    wire CHOutput   = TCONBits[0];   
    Register8bit PS_Register (
        .D   (D),                
        .CLK (SYSCLK),           
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
    Counter prescaler_counter (
        .INC(PS_INC),            
        .TC_RST(PS_TC_RST),      
        .TC(PS_TC)               
    );
    Register8bit TReg_Register (
        .D   (D),                
        .CLK (SYSCLK),           
        .STR (StoreTreg),        
        .RST (TMR_CLR),          
        .Q   (TReg),             
        .Qn  ()                  
    );


    TMRCTRL TMR_Control (
        .SYSCLK(SYSCLK),         
        .CLK_IN(CLK_Next),       
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