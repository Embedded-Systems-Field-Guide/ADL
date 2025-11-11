

module DataPath(
   //Fundemetnal inputs
   input wire SYSCLK,
   input wire [7:0] DataBus,
   input wire CLK_IN,
   input wire MCLR,
   
   //Opperation inputs
   input wire RST,
   input wire ADD,
   input wire SBT,
   input wire MULT,
   input wire DIV,
   input wire SR,
   input wire SL,
   input wire AND,
   input wire OR,
   input wire XOR,
   input wire NTA,
   input wire NTB,
   input wire CALC,
   
   input wire STR_ALUCON,
   input wire READ_DP,
   
   //output flags
   
   output wire ZeroF,
   output wire NegativeF,
   output wire EqualF,
   output wire ALBF, //A > B
   output wire OverflowF,
   
   output wire [7:0] DP_output,
   
   //Debug outputs
    output wire [7:0] REGA1,    // Direct output from register A1
    output wire [7:0] REGA2,    // Direct output from register A2
    output wire [7:0] REGB1,    // Direct output from register B1
    output wire [7:0] REGB2,     // Direct output from register B2
    
    output wire [7:0] DPInternal,
    output wire  OutDP,
    output wire StoreA1,
    output wire StoreA2,
    output wire StoreB1,
    output wire [7:0] DPBus, 
    output wire [7:0] ALU_BUS, 
    output wire [7:0] BUS_A, 
    output wire [7:0] BUS_B, 
    output wire SubtractALU,
    output wire SM,
    output wire Neg_A,
    output wire OutputA1,
    output wire OutputA2,
    output wire OutputB1,
    output wire OutputB2
    
    
    
   
    );

    wire [7:0] ALUCon;
    wire User_SM = ALUCon[0];
    wire MOD = ALUCon[1];
    
    Register8bit ALUConReg(
        .D(DataBus),    // 8-bit data input bus
        .CLK(CLK_In),        // Clock input
        .STR(STR_ALUCON),        // Store enable
        .RST(CLR_DP),        // Asynchronous reset
        .Q(ALUCon)    // 8-bit register output
    );
    
    
  

    CoreALU DPALU(
        // Inputs
        .BUS_A(BUS_A),        // 8-bit input bus A
        .BUS_B(BUS_B),        // 8-bit input bus B
        .Sel_C(CStored),        // Selection bit C
        .Sel_B(BStored),        // Selection bit B
        .Sel_A(AStored),        // Selection bit A
        .Subtract(SubtractALU),     // Subtract control signal
        .SignedMode(SM),   // Signed mode control
        .NEG_A(Neg_A),        // Negate A control signal
        
        // Outputs
        .ALU_BUS(ALU_BUS),      // Final ALU result bus
        .Zero(ZeroF),         // Zero flag
        .Negative(NegativeF),     // Negative flag
        .AEqualB(EqualF),      // A equals B flag
        .ALargerB(ALBF),     // A larger than B flag
        .Overflow(OverflowF)      // Overflow flag
    );


    ALURegs ALUData(
        .D(DPBus),        // Shared 8-bit data input bus
        .CLK(CLK_IN),            // Shared clock input
        .RST(CLR_DP),            // Shared asynchronous reset
        
        // Individual store enables for each register
        .STR_A1(StoreA1),         // Store enable for register A1
        .STR_A2(StoreA2),         // Store enable for register A2
        .STR_B1(StoreB1),         // Store enable for register B1
        .STR_B2(StoreB2),         // Store enable for register B2
        
        // Multiplexer select signals
        .Sel_A1(OutA1),         // Select A1 for BUS_A output (when high)
        .Sel_A2(OutA2),         // Select A2 for BUS_A output (when high)
        .Sel_B1(OutB1),         // Select B1 for BUS_B output (when high)
        .Sel_B2(OutB2),         // Select B2 for BUS_B output (when high)
        
        // Output buses
        .BUS_A(BUS_A),     // Multiplexed output bus A (A1 or A2)
        .BUS_B(BUS_B),     // Multiplexed output bus B (B1 or B2)
        
        //set LSB to 1
        .LSBA(1'b0),
        .LSBB(1'b0),      
        
            // Direct register outputs (bypass multiplexers)
        .REGA1(REGA1),    
        .REGA2(REGA2),    
        .REGB1(REGB1),    
        .REGB2(REGB2)    
    );  
    
    
    ALUInputMux ALUInputMux_inst(

    .CLR(MCLR),

    .LSBA(LSBA),
//    .MultLSBA(),
//    .CDLSBA(),
    
    .LSBB(LSBB),
    
    .OutA1(OutA1),
    .LOOutA1(BasicLogicOut),
//    input wire MultOutA1,
//    input wire CDOutA1,
//    input wire NDOutA1,
//    input wire SDROutA1,
    
    
    .OutB1(OutB1),
    .LOOutB1(BasicLogicOut),
//    input wire MultOutB1,
//    input wire CDOutB1,
//    input wire NDOutB1,
    
    .OutB2(OutB2),
//    input wire MultOutB2,
//    input wire CDOutB2,
//    input wire SDROutB2,
    
    .StoreA1(StoreA1),
    .ICSStoreA1(ICSStoreA1),
//    input wire NDStoreA1,
//    input wire CDStoreA1,
//    input wire SDRStoreA1,
    
    
    .StoreB1(StoreB1),
    .ICSStoreB1(ICSStoreB1),
//    input wire MultStoreB1,
//    input wire NDStoreB1,
    
    .StoreB2(StoreB2),
//    input wire MultStoreB2,
//    input wire CDStoreB2,
//    input wire SDRStoreB2,
    
    . OutALU(OutALU),
    .LOOutALU(BasicLogicOut),
//    input wire MultOutALU,
//    input wire NDOutALU,
//    input wire CDOutALU,
//    input wire SDROutALU,
    
    .OutDP(OutDP),
    .LOOutDP(BasicLogicOut),
//    input wire MultOutDP,
//    input wire SDROutDP,
    
    .Neg_A(Neg_A),
//    input wire NDNeg_A,
//    input wire SDRNeg_A,
    
    .DontSubtract(DontSubtract)
//    input wire NDNotDontSubtract,
//    input wire CDNotDontSubtract,
//    input wire SDRNotDontSubtract

);


Enabler8 Enable (
    .Bus(DPBus),    
    .Enable(OutDP), 
    .out(DPInternal)     
);

BusBuffer ReadDpBuffer (
    .Bus(DPInternal),    // Input bus
    .Enable(READ_DP), // Enable signal (active-high)
    .out(DP_output)     // Output bus (tri-state)
);

 BusMux DPBusMUX (
     .A(DataBus),     // Input bus A
    .SelA(ENMainInput),  // Select A (active-high)
    .B(ALU_BUS),     // Input bus B
    .SelB(OutALU),  // Select B (active-high)
    .out(DPBus)    // Output bus
);

 InputControlSystem ICS(
   .SYSCLK(SYSCLK),
   .CLK_IN(CLK_IN),
   .MCLR(MCLR),
   
   //Opperation inputs
   .RST(RST),
   .ADD(ADD),
   .SBT(SBT),
   .MULT(MULT),
   .DIV(DIV),
   .SR(SR),
   .SL(SL),
   .AND(AND),
   .OR(OR),
   .XOR(XOR),
   .NTA(NTA),
   .NTB(NTB),
   .CALC(CALC),
   .User_SM(User_SM),
   .DontSubtract(DontSubtract), //(ADD)
   
   .Operations(Operations),         
   .LogicOperation(LogicOperation),      
   .Adding(Adding),              
   .Subtracting(Subtracting),         
   .Multiplying(Multiplying),         
   .Evaluating(Evaluating),         
   .Dividing(Dividing),            
   .StoreA1(ICSStoreA1),
   .StoreB1(ICSStoreB1),
   .StoreA2(StoreA2),
   .CLR_DP(CLR_DP),
   .ENMainInput(ENMainInput),         
   .SubtractALU(SubtractALU),
   .SM(SM)
      
);

 BasicLogic AddSubLogicUnit (
   .SR(SR),
   .SL(SL),
   .AND(AND),
   .OR(OR),
   .XOR(XOR),
   .NTA(NTA),
   .NTB(NTB),
   .LogicOperation(LogicOperation),   
   .Adding(Adding),
   .Operations(Operations),
   .Evaluating(Evaluating),
   .Subtracting(Subtracting),
   
   .BasicLogicOut(BasicLogicOut),
   
   .AStored(AStored),
   .BStored(BStored),
   .CStored(CStored)
   

);
    
endmodule
