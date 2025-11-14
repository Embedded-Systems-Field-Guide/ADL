module Scale2Timer (
    //System inputs
    input  wire SYSCLK,
    input  wire MCLR,
    input  wire [7:0] D,
    input  wire CLK_IN,
      
    //Timer Setup
    input  wire StoreTreg,
    input  wire StoreTPsA,
    input  wire StoreTPsB,
    input  wire CLR,
    input  wire TF_CLR,
    input wire [3:0] TCONBits,
    
    //Outputs
    output wire TFlag,
    output wire INTVector,
    output wire TChannel,
    
    //Debug
    output wire CLK_NextA_dbg,
    output wire CLK_NextB_dbg
);
     wire CLK_NextA;
     wire CLK_NextB;
     wire CLK_NextAL;
     wire CLK_NextBL;
     
    assign CLK_NextA_dbg = CLK_NextA;
    assign CLK_NextB_dbg = CLK_NextB;
    
    
    wire TMR_CLR;
    
    wire [7:0] PSValA;
    wire PS_TC_RSTA;
     wire PS_INCA;
     
    wire [7:0] PSValB;
    wire PS_TC_RSTB;
    wire PS_INCB;
    
    wire [7:0] TReg;
    wire [7:0] Timer_TC;
    
    wire Timer_TC_RST;
    wire Timer_INC;
    wire Timer_Equal;
    
    
    wire Enable     = TCONBits[3];
    wire AutoReload = TCONBits[2];
    wire Interrupt  = TCONBits[1];
    wire CHOutput   = TCONBits[0];
    
    wire [7:0] ps_tca_int;
    wire [7:0] ps_tcb_int;
    wire ps_inca_int;
    
    
     //For some reason unknown to man and God does it not want to run without adding:
    //Oscillating DFFs with no function usage to force the clock to stay
    //Hours wasted with "normal" methods: 14
    wire ClkABuffern;
    DFF ClkABuffer(
        .D(ClkABuffern),
        .CLK(CLK_NextA_dbg),
        .Qn(ClkABuffern)
    );
    wire ClkBBuffern;
    DFF ClkBBuffer(
        .D(ClkBBuffern),
        .CLK(CLK_NextB_dbg),
        .Qn(ClkBBuffern)
    );
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
        .TC(ps_tca_int),         
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
        .Dout(CLK_NextAL)   
    );
    PSCTRL PSB_Control (
        .SYSCLK(SYSCLK),
        .TReg(PSValB),
        .TC(ps_tcb_int),         
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

    
    UnitDelay ClkBDel (
        .sysclk(SYSCLK),
        .Din(CLK_NextB),
        .Dout(CLK_NextBL)   
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