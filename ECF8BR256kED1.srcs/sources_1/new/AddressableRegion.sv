

module AddressableRegion(
    input wire SYSCLK,
    input wire CLK_IN,
    input wire MCLR,
    
    input wire [7:0] WriteAdd,
    input wire [7:0] ReadAdd,
    inout wire [7:0] DataBus,
    
    output wire [7:0] DPTR_A,
    output wire [7:0] DPTR_B,
    
    output wire [7:0] MARA,
    output wire [7:0] MARB,
    output wire [7:0] MARC,
    
    output wire RAMRead,
    output wire RAMWrite,
    
    
    //Interrupts
    output wire T1_int,
    output wire T2_int,
    output wire T3_int,
    output wire T4_int,
    output wire UART_int,
    
    output wire [4:0] DP_Flags,
    
    
    //GPIO
    inout wire [7:0] PORTA,
    inout wire [7:0] PORTB,
    output wire TCA,
    output wire TCB,
    output wire Tx,
    input wire Rx,
    
    
    //Debug
    
    output wire ReadEMPTY,
    output wire WriteEMPTY,
    output wire [7:0] BusOut,
    
       output wire [7:0] REGA1,    // Direct output from register A1
    output wire [7:0] REGA2,    // Direct output from register A2
    output wire [7:0] REGB1,    // Direct output from register B1
    output wire [7:0] REGB2,     // Direct output from register B2
    
    output wire [7:0] Debuglines,
    output wire [7:0] DebugBusA,
    output wire [7:0] DebugBusB,
    output wire [7:0] ALU_BUS,
    
    output wire [7:0] Tim1Counter,
    output wire [7:0] TC_PS,
    output wire [7:0] RxBufPass,
    output wire [7:0] TxBufferVal
    
    
    
    );
    

    //=============================================
    //Read space 
    //=============================================
    wire [15:0] ReadAddSel;
    Decoder4bit ReadSpaceSelector(
        .in(ReadAdd[7:4]),   
        .out(ReadAddSel)    
    );
    
    wire MainRead = ReadAddSel[0]; 
    wire BitAddRead = ReadAddSel[1]; 
    wire PRTABRead = ReadAddSel[2]; 
    wire FlagsRead = ReadAddSel[4]; 
    
    
    wire [15:0] MainSelected;
    Decoder4bitEnable Main_Selector(
        .in(ReadAdd[3:0]),    
        .en(MainRead),    
        .out(MainSelected)    
    );
    
    
    assign ReadEMPTY = MainSelected[0];   
    wire ALU    = MainSelected[1];
    assign RAMRead    = MainSelected[2];
    wire R_1     = MainSelected[3];
    wire R_2     = MainSelected[4];
    wire R_3     = MainSelected[5];
    wire R_4     = MainSelected[6];
    wire PRT_A   = MainSelected[7];
    wire PRT_B   = MainSelected[8];
    wire RX_BUF  = MainSelected[11];
    wire IR_1  = MainSelected[12];
    wire IR_2  = MainSelected[13];

    wire [15:0] BitAddReadSelected;
    Decoder4bitEnable BitAddRead_Selector(
        .in(ReadAdd[3:0]),    
        .en(BitAddRead),    
        .out(BitAddReadSelected)    
    );
    
    wire [7:0] R_1Bits = BitAddReadSelected[7:0];
    wire [7:0] R_2Bits = BitAddReadSelected[15:8];

   
    
    
    wire [15:0] PRTABReadSelected;
    Decoder4bitEnable PRTABRead_Selector(
        .in(ReadAdd[3:0]),    
        .en(PRTABRead),    
        .out(PRTABReadSelected)    
    );
    
    wire [7:0] PRTABits = PRTABReadSelected[7:0];
    wire [7:0] PRTBBits = PRTABReadSelected[15:8];
     
    
    
    wire [15:0] FlagsReadSelected;
    Decoder4bitEnable FlagsRead_Selector(
        .in(ReadAdd[3:0]),    
        .en(FlagsRead),    
        .out(FlagsReadSelected)    
    );
    
    wire T1F        =FlagsReadSelected[0];
    wire T2F        =FlagsReadSelected[1];
    wire T3F        =FlagsReadSelected[2];
    wire T4F        =FlagsReadSelected[3];
    wire RXF        =FlagsReadSelected[4];
    wire TX_Idle    =FlagsReadSelected[5];

    //=============================================
    //Write space 
    //=============================================
    
    wire [15:0] WriteAddSel;
    Decoder4bit WriteSpaceSelector(
        .in(WriteAdd[7:4]),   
        .out(WriteAddSel)    
    );
    
    wire AlUWrite = WriteAddSel[0]; 
    wire MISCWrite = WriteAddSel[1]; 
    wire TimersWrite = WriteAddSel[2]; 
    wire BitAddWrite = WriteAddSel[3]; 
    wire BigDataWrite = WriteAddSel[4]; 
    wire BitPRTABWrite = WriteAddSel[5]; 
    wire COMSWrite = WriteAddSel[7];
    
    wire [15:0] AlUWriteSelected;
    Decoder4bitEnable AlUWrite_Selector(
        .in(WriteAdd[3:0]),    
        .en(AlUWrite),    
        .out(AlUWriteSelected)    
    );      
    
    assign WriteEMPTY =AlUWriteSelected[0];
    wire RST    =AlUWriteSelected[1];
    wire ADD    =AlUWriteSelected[2];
    wire SBT    =AlUWriteSelected[3];
    wire MUL    =AlUWriteSelected[4];
    wire DIV    =AlUWriteSelected[5];
    wire SR    =AlUWriteSelected[6];
    wire SL    =AlUWriteSelected[7];
    wire AND    =AlUWriteSelected[8];
    wire OR    =AlUWriteSelected[9];
    wire XOR    =AlUWriteSelected[10];
    wire NTA    =AlUWriteSelected[11];
    wire NTB    =AlUWriteSelected[12];
    wire CALC    =AlUWriteSelected[13];


   
      
    wire [15:0] MISCWriteSelected;
    Decoder4bitEnable MISCWrite_Selector(
        .in(WriteAdd[3:0]),    
        .en(MISCWrite),    
        .out(MISCWriteSelected)    
    );       
    
    wire T1_F   = MISCWriteSelected[0];
    wire T2_F   = MISCWriteSelected[1];
    wire T3_F   = MISCWriteSelected[2];
    wire T4_F   = MISCWriteSelected[3];
    wire RX_F   = MISCWriteSelected[4];
    wire TCON12 = MISCWriteSelected[5];
    wire TCON34 = MISCWriteSelected[6];
    wire COM_CON= MISCWriteSelected[7];
    wire ALU_CON= MISCWriteSelected[8];
    wire DPTRA = MISCWriteSelected[9];
    wire DPTRB = MISCWriteSelected[10];
    wire INC_DPTR = MISCWriteSelected[11];
    wire INC_IR1 = MISCWriteSelected[12];
    wire INC_IR2 = MISCWriteSelected[13];
    wire StoreMARB = MISCWriteSelected[14];
    wire StoreMARC = MISCWriteSelected[15];
   
    wire [15:0] TimersWriteSelected;
    Decoder4bitEnable TimersWrite_Selector(
        .in(WriteAdd[3:0]),    
        .en(TimersWrite),    
        .out(TimersWriteSelected)    
    );       
    
    wire T1_TH  =  TimersWriteSelected[0];
    wire T1_TL  =  TimersWriteSelected[1];
    wire T1_PS  =  TimersWriteSelected[2];
    wire T1_CLR =  TimersWriteSelected[3];
    wire T2_TH  =  TimersWriteSelected[4];
    wire T2_TL  =  TimersWriteSelected[5];
    wire T2_PS  =  TimersWriteSelected[6];
    wire T2_CLR =  TimersWriteSelected[7];
    wire T3_REG =  TimersWriteSelected[8];
    wire T3_PSA =  TimersWriteSelected[9];
    wire T3_PSB =  TimersWriteSelected[10];
    wire T3_CLR =  TimersWriteSelected[11];
    wire T4_REG =  TimersWriteSelected[12];
    wire T4_PS  =  TimersWriteSelected[13];
    wire T4_CLR =  TimersWriteSelected[14];

    wire [15:0] BitAddWriteSelected;
    Decoder4bitEnable BitAddWrite_Selector(
        .in(WriteAdd[3:0]),    
        .en(BitAddWrite),    
        .out(BitAddWriteSelected)    
    );    
    
    wire [7:0] R1Bits  = BitAddWriteSelected[7:0];
    wire [7:0] R2Bits = BitAddWriteSelected[15:8];


    
       
    wire [15:0] BigDataWriteSelected;
    Decoder4bitEnable BigDataWrite_Selector(
        .in(WriteAdd[3:0]),    
        .en(BigDataWrite),    
        .out(BigDataWriteSelected)    
    );      
    
    
    wire R1         = BigDataWriteSelected[0];
    wire R2         = BigDataWriteSelected[1];
    wire R3         = BigDataWriteSelected[2];
    wire R4         = BigDataWriteSelected[3];
    wire StoreMARA        = BigDataWriteSelected[4];
    assign RAMWrite   = BigDataWriteSelected[5];
    wire TRISA      = BigDataWriteSelected[6];
    wire TRISB      = BigDataWriteSelected[7];
    wire LATA       = BigDataWriteSelected[10];
    wire LATB       = BigDataWriteSelected[11];
    
    wire IR1       = BigDataWriteSelected[14];
    wire IR2       = BigDataWriteSelected[15];
 
    wire [15:0] BitPRTABWriteSelected;
    Decoder4bitEnable BitPRTABWrite_Selector(
        .in(WriteAdd[3:0]),    
        .en(BitPRTABWrite),    
        .out(BitPRTABWriteSelected)    
    );      
    
    
    wire [7:0] LATABits = BitPRTABWriteSelected[7:0];
    wire [7:0] LATBBits = BitPRTABWriteSelected[15:8];
   
 
    wire [15:0] COMSWriteSelected;
    Decoder4bitEnable COMSWrite_Selector(
        .in(WriteAdd[3:0]),    
        .en(COMSWrite),    
        .out(COMSWriteSelected)    
    );   
    
    wire UART1_BR = COMSWriteSelected[0];
    wire UART1_BRPS = COMSWriteSelected[1];
    wire UART1_CLR = COMSWriteSelected[2];
    wire UART1_TxBuf = COMSWriteSelected[3];
    wire UART1_Send = COMSWriteSelected[4];
    
    
        //=============================================
    //Flags Read 
    //=============================================  
 
    wire [7:0] Flagbus;
    wire RX_Flag;
    wire TX_Idle_Flag;
    wire T1Flag;
    wire T2Flag;
    wire T3Flag;
    wire T4Flag;
    
    
    UnitDelay #(.WIDTH(8)) FlagLatch (
        .sysclk(SYSCLK),
        .Din({TX_Idle_Flag, RX_Flag, T4Flag, T3Flag, T2Flag, T1Flag}),
        .Dout({TX_Idle_FlagL, RX_FlagL, T4FlagL, T3FlagL, T2FlagL, T1FlagL})
    );
    
    FlagManager #(
        .NUM_FLAGS(6),
        .BUS_WIDTH(8)
    ) flag_mgr (
        .flag_enables({TX_Idle, RXF, T4F, T3F, T2F, T1F}),
        .flag_values({TX_Idle_FlagL, RX_FlagL, T4FlagL, T3FlagL, T2FlagL, T1FlagL}),
        .data_bus(DataBus)
    );
    
    //=============================================
    //Registers 
    //=============================================
    AddIOReg Reg1 (
        .D_in(DataBus),    // 8-bit data input bus
        .OUT(R_1),        // Output enable (active-high)
        .OUTBit(R_1Bits),        // Output enable (active-high)
        .CLK(CLK_IN),        // Clock input
        .STR(R1),        // Store enable
        .STRBit(R1Bits),    
        .RST(MCLR),        // Asynchronous reset
        .D_out(DataBus)    // 8-bit register output with tri-state control
    );
     
    
    AddIOReg Reg2 (
        .D_in(DataBus),    // 8-bit data input bus
        .OUT(R_2),        // Output enable (active-high)
        .OUTBit(R_2Bits),        // Output enable (active-high)
        .CLK(CLK_IN),        // Clock input
        .STR(R2),        // Store enable
        .STRBit(R2Bits),    
        .RST(MCLR),        // Asynchronous reset
        .D_out(DataBus)    // 8-bit register output with tri-state control
    );
           
        
         IORegister8bit Reg3(
            .D(DataBus),    
            .OUT(R_3),       
            .CLK(CLK_IN),       
            .STR(R3),        
            .RST(MCLR),        
            .Q(DataBus)
        );
          
         IORegister8bit Reg4(
            .D(DataBus),    
            .OUT(R_4),       
            .CLK(CLK_IN),       
            .STR(R4),        
            .RST(MCLR),        
            .Q(DataBus)
        );      

     INCRegEN INCReg1(
        .D(DataBus),       // 8-bit data input bus
        .OUT(IR_1),           // Output enable (active-high)
        .CLK(CLK_IN),           // Clock input
        .STR(IR1),           // Store enable
        .INC(INC_IR1),           // Increment enable
        .RST(MCLR),           // Asynchronous reset
        .Q(DataBus)       // 8-bit register output with tri-state control
    
    );
    

      INCRegEN INCReg2(
        .D(DataBus),       // 8-bit data input bus
        .OUT(IR_2),           // Output enable (active-high)
        .CLK(CLK_IN),           // Clock input
        .STR(IR2),           // Store enable
        .INC(INC_IR2),           // Increment enable
        .RST(MCLR),           // Asynchronous reset
        .Q(DataBus)       // 8-bit register output with tri-state control
    
    ); 
     
    //=============================================
    //Timers 
    //=============================================
    
   
   wire [7:0] TCON12Reg;
    Register8bit TCON12_Register (
        .D(DataBus),
        .CLK(SYSCLK),
        .STR(TCON12),
        .RST(MCLR),
        .Q(TCON12Reg),
        .Qn()
    );
    
    
     PWMModule Tim1(
        //System inputs
        .SYSCLK(SYSCLK),       
        .MCLR(MCLR),         
        .CLK_IN(CLK_IN),
        .DataBus(DataBus),   
    
        //Timer Setup
        .StoreTH(T1_TH),        
        .StoreTL(T1_TL),         
        .StorePS(T1_PS),         
        .TF_CLR(T1_F),          
        .CLR(T1_CLR),
        .TCONBits(TCON12Reg[7:4]), 
        
        
        // Outputs
        .TFlag(T1Flag),           
        .INTVector(T1_int),       
        .TChannel(TCA)        
             
    );
    
      PWMModule Tim2(
        //System inputs
        .SYSCLK(SYSCLK),       
        .MCLR(MCLR),         
        .CLK_IN(CLK_IN),
        .DataBus(DataBus),   
    
        //Timer Setup
        .StoreTH(T2_TH),        
        .StoreTL(T2_TL),         
        .StorePS(T2_PS),         
        .TF_CLR(T2_F),          
        .CLR(T2_CLR),
        .TCONBits(TCON12Reg[3:0]), 
        
        
        // Outputs
        .TFlag(T2Flag),           
        .INTVector(T2_int),       
        .TChannel(TCB)        
             
    );
    
   
    
   wire [7:0] TCON34Reg;
    Register8bit TCON34_Register (
        .D(DataBus),
        .CLK(SYSCLK),
        .STR(TCON34),
        .RST(MCLR),
        .Q(TCON34Reg),
        .Qn()
    );
       
    Scale2Timer Tim3 (

        .SYSCLK(SYSCLK),          // System clock
        .MCLR(MCLR),            // Master clear
        .CLK_IN(CLK_IN),
        
        // Data and control inputs
        .D(DataBus),   // 8-bit data input bus
        .StoreTreg(T3_REG),       // Store signal for TReg register
        .StoreTPsA(T3_PSA),        // Store signal for prescaler register
        .StoreTPsB(T3_PSB),        // Store signal for prescaler register
        .CLR(T3_CLR),             // Clear signal
        .TF_CLR(T3_F),          // Timer flag clear
        
        // Timer outputs
        // Timer outputs
        // Outputs
        .TFlag(T3Flag),           // Timer flag output
        .INTVector(T3_int),       // Interrupt vector output
        .TCONBits(TCON34Reg[7:4]),
        .CLK_NextA_dbg(),
        .CLK_NextB_dbg()
    );
    
    
     
    
    
    Scale1Timer Tim4 (
        // System signals
        .SYSCLK(SYSCLK),          // System clock
        .MCLR(MCLR),            // Master clear
        .CLK_IN(CLK_IN),
        
        // Data and control inputs
        .D(DataBus),   // 8-bit data input bus
        .StoreTreg(T4_REG),       // Store signal for TReg register
        .StoreTPs(T4_PS),        // Store signal for prescaler register
        .CLR(T4_CLR),             // Clear signal
        .TF_CLR(T4_F),          // Timer flag clear
        
        // Timer outputs
        .TFlag(T4Flag),           // Timer flag output
        .INTVector(T4_int),       // Interrupt vector output
        .TCONBits(TCON34Reg[3:0]) // Lower nibble of TCON for another timer
        
    );
    
    
   
    
    
     //=============================================
    //Datapath 
    //=============================================   
    
     DataPath DPCore(
       //Fundemetnal inputs
       .SYSCLK(SYSCLK),
       .DataBus(DataBus),
       .CLK_IN(CLK_IN),
       . MCLR(MCLR),
       
       //Opperation inputs
        .RST(RST),
        .ADD(ADD),
        .SBT(SBT),
        .MULT(MUL),
        .DIV(DIV),
        .SR(SR),
        .SL(SL),
        .AND(AND),
        .OR(OR),
        .XOR(XOR),
        .NTA(NTA),
        .NTB(NTB),
        .CALC(CALC),
    
       
       .STR_ALUCON(ALU_CON),
       .READ_DP(ALU),
       
       //output flags
       
       .ZeroF(DP_Flags[4]),
       .NegativeF(DP_Flags[3]),
       .EqualF(DP_Flags[2]),
       .ALBF(DP_Flags[1]), //A > B
       .OverflowF(DP_Flags[0]),
       
       .REGA1(REGA1),
       .REGA2(REGA2),
       .REGB1(REGB1),
       .REGB2(REGB2),
       .DP_output(DataBus),
       
       .ALU_BUS(ALU_BUS)
    
     
    );
    
     //=============================================
    // InternalRam 
    //=============================================   
    
    
    
//        wire [7:0] MARAddress;   // 8-bit address (0-255)
//        // Instantiate TReg Register (8-bit)
//    Register8bit MAR_Inst (
//        .D   (Data),            // Shared data bus
//        .CLK (CLK),       // Shared clock
//        .STR (StoreMAR),    // Store TReg signal
//        .RST (MCLR),      // Reset from timer controller
//        .Q   (MARAddress),         // Timer register output
//        .Qn  ()   // Unused complement
//    ); 
//    RAM256_sync RAM256_isnt (
    
//        // System signals
//        .CLK(CLK_IN),          // System clock
//        .MCLR(MCLR),            // Master clear
        
        
//        .Data(DataBus),      // 8-bit bidirectional data bus
//        .WE(RAMWrite),              // Write Enable
//        .OE(RAMRead),               // Output Enable
//        .Address(MARAddress)    //Sore databus in memory access register
        
//    );

    
     //=============================================
    // External Ram 
    //=============================================   
        // MAR - Memory Address Register (19 bits total)
    // Lower 8 bits (MemAdr[0:7])
    Register8bit ADD0To7 (
        .D   (DataBus),
        .CLK (CLK_IN),
        .STR (StoreMARA),      // Strobe signal to load this register
        .RST (MCLR),
        .Q   (MARA) // Connect to lower 8 address bits
    );
    
    // Middle 8 bits (MemAdr[8:15])
    Register8bit ADD8To15 (
        .D   (DataBus),
        .CLK (CLK_IN),
        .STR (StoreMARB),      // Different strobe signal for this register
        .RST (MCLR),
        .Q   (MARB) // Connect to middle 8 address bits
    );
    
    // Upper 3 bits (MemAdr[16:18]) - only need 3 bits but using 8-bit register
    Register8bit ADD16To18 (
        .D   (DataBus),
        .CLK (CLK_IN),
        .STR (StoreMARC),      // Different strobe signal for this register
        .RST (MCLR),
        .Q   (MARC) // Connect to upper 3 address bits (bits [18:16])
                             // Note: Only lower 3 bits of Q are used
    );
    
    
//    =============================================
//    Ports 
//    =============================================      
     PRTDriver PRTA (
        .DataBus(DataBus),    // 8-bit data input bus    
        .CLK(CLK_IN),        // Clock input
        .MCLR(MCLR),
        
        .STR_TRIS(TRISA),        
        .STR_TRISBit(),    
        .STRLAT(LATA),        
        .STR_LATBit(LATABits),    
        
        .ReadPRT(PRT_A),        // Store enable
        .ReadPRTBits(PRTABits),   
        
        .PRTPins(PORTA)   
        
    );
    
         PRTDriver PRTB (
        .DataBus(DataBus),    // 8-bit data input bus    
        .CLK(CLK_IN),        // Clock input
        .MCLR(MCLR),
        
        .STR_TRIS(TRISB),        
        .STR_TRISBit(),    
        .STRLAT(LATB),        
        .STR_LATBit(LATBBits),    
        
        .ReadPRT(PRT_B),        // Store enable
        .ReadPRTBits(PRTBBits),   
        
        .PRTPins(PORTB)   
        
    );
    
    
    //=============================================
    //Serial coms 
    //=============================================   

//    UARTDriver UART1(
//        // System signals
//       .sysclk(SYSCLK),          // System clock
//        .CLK_IN(CLK_IN),          // Input clock (can be reduced clock)
//        .MCLR(MCLR),            // Master clear/reset
//        .CLR(CLR),             // Additional clear signal
        
//        // Data bus
//        .DataBus(DataBus),   // 8-bit data bus for configuration/data
        
//        // Configuration signals
//        .StoreBR(BR),         // Store baud rate divisor
//        .StoreBPS(BRPS),        // Store baud prescaler
//        .STR_COMCON(COM_CON),      // Store COMCON register
//        .CLR_RXFlag(RX_F),      // Clear RX flag
        
//        // TX control signals
//        .Load(TxBuf),            // Load data into TX buffer
//        .SendTx(Send),          // Start transmission
        
//        // UART pins
//        .Rx(Rx),              // UART receive pin
//        .Tx(Tx),              // UART transmit pin
        
//        // Status and data outputs
//        .RX_Flag(RX_Flag),         // RX data ready flag
//        .INTVector(UART_int),        // Interrupt vector output
//        .ReadRxBuf(RX_BUF),
//        .RxBufRead(DataBus),
        
//        .RxBuf(RxBufPass)
              
//    );

        reg reset_n = 0;
        integer rst_cnt = 0;
        always @(posedge SYSCLK) begin
            if (rst_cnt < 100) begin
                rst_cnt <= rst_cnt + 1;
                reset_n <= 0;
            end else
                reset_n <= 1;
        end
        
        uart_rx u_rx (
            .clk      (SYSCLK),
            .reset_n  (reset_n | UART1_CLR),
            .uart_rxd (Rx),   
            .RXBUF    (RxBufPass),
            .RxFlag   (RX_Flag),
            .CLR_Flag (RX_F)
        );
        
        BusBuffer RXBusBuffer (
            .Bus(RxBufPass),    // Input bus
            .Enable(RX_BUF), // Enable signal (active-high)
            .out(DataBus)     // Output bus (tri-state)
        );
             
             
    assign DataBusReversed = {
        DataBus[0], DataBus[1], DataBus[2], DataBus[3],
        DataBus[4], DataBus[5], DataBus[6], DataBus[7]
    };

            TxDriver uart_txDriver_inst (
            .D(DataBus),    // 8-bit data input bus
            .clk(SYSCLK),
            .reset_n(reset_n | UART1_CLR),
            .StoreTxBuf(UART1_TxBuf & CLK_IN),
            .uart_txd(Tx),
            .idle_o(TX_Idle_Flag)
        );




        
    
       

        
         
    
   
   
        
     //=============================================
    //Datapointer 
    //=============================================    
     
//       Register8bit DatapointerA (
//        .D(DataBus),    // 8-bit data input bus
//        .CLK(CLK_IN),        // Clock input
//        .STR(DPTRA),        // Store enable
//        .RST(MCLR),        // Asynchronous reset
//        .Q(DPTR_A)
//    );
    
//         Register8bit DatapointerB (
//        .D(DataBus),    // 8-bit data input bus
//        .CLK(CLK_IN),        // Clock input
//        .STR(DPTRB),        // Store enable
//        .RST(MCLR),        // Asynchronous reset
        
//        .Q(DPTR_B)
//    );   
    
   
     wire Carr_DPTR;
       INCReg DatapointerA (
        .D(DataBus),    // 8-bit data input bus
        .CLK(CLK_IN),        // Clock input
        .STR(DPTRA),        // Store enable
        .RST(MCLR),        // Asynchronous reset
        .Q(DPTR_A),
        .INC(Carr_DPTR)
    );
    
         INCReg DatapointerB (
        .D(DataBus),    // 8-bit data input bus
        .CLK(CLK_IN),        // Clock input
        .STR(DPTRB),        // Store enable
        .RST(MCLR),        // Asynchronous reset
        .Carr_out(Carr_DPTR),
        .INC(INC_DPTR),
        .Q(DPTR_B)
    );   
    

     
endmodule


module FlagManager #(
    parameter NUM_FLAGS = 6,  // Number of flag sources
    parameter BUS_WIDTH = 8   // Width of output bus
)(
    input  wire [NUM_FLAGS-1:0] flag_enables,  // Enable signals for each flag
    input  wire [NUM_FLAGS-1:0] flag_values,   // Flag values
    output wire [BUS_WIDTH-1:0] data_bus       // Output data bus (tri-state)
);

    wire [BUS_WIDTH-1:0] flag_bus;
    wire any_flag_enabled;
    
    // Upper bits are always 0
    assign flag_bus[BUS_WIDTH-1:1] = {(BUS_WIDTH-1){1'b0}};
    
    // Combine all flags with OR logic
    assign flag_bus[0] = |(flag_enables & flag_values);
    
    // Any flag enable active
    assign any_flag_enabled = |flag_enables;
    
    // Tri-state buffer
    assign data_bus = any_flag_enabled ? flag_bus : {BUS_WIDTH{1'bz}};

endmodule