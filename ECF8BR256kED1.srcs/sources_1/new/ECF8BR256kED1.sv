(* keep_hierarchy = "yes", dont_touch = "true" *)

module ECF8F24(
    input  wire sysclk,    // 12 MHz system clock
    output wire uart_rxd_out,
    input wire uart_txd_in,
    
    output wire [18:0] MemAdr,
    inout wire [7:0] MemDB,
    
    output wire RamOEn,
    output wire RamWEn,
    output wire RamCEn,
    
    input  wire MCLR,      
    output wire DLG_LED,   // Debug LED output (1Hz clock)
    // Control inputs/outputs
    inout  wire PRTA1,     
    inout  wire PRTA2,     
    inout  wire PRTA3,     
    inout  wire PRTA4,    
    inout  wire PRTA5,     
    inout wire PRTA6,     
    inout wire PRTA7,     
    inout wire PRTA8,    
    inout  wire PRTB1,     
    inout  wire PRTB2,     
    inout  wire PRTB3,     
    inout  wire PRTB4,     
    inout  wire PRTB5,     
    inout  wire PRTB6,     
    inout  wire PRTB7,     
    inout  wire PRTB8,     
    inout  wire D1,        
    inout  wire D2,        
    inout  wire D3,        
    inout  wire D4,        
    inout  wire D5,        
    inout  wire D6,        
    inout  wire D7,       
    inout  wire D8,    
    
    output wire Add1, 
    output wire Add2, 
    output wire Add3, 
    output wire Add4,
    output wire Add5, 
    output wire Add6, 
    output wire Add7, 
    output wire Add8,  
    output wire Add9, 
    output wire Add10, 
    output wire Add11, 
    output wire Add12,    
    output wire Add13,    
    
    input wire RxPin,
    output wire TxPin,
    
    output wire TCA,
    output wire TCB
    
);
 
 // Synchronize MCLR button (prevent metastability)
    reg mclr_sync1, mclr_sync2;
    always @(posedge sysclk) begin
        mclr_sync1 <= MCLR;
        mclr_sync2 <= mclr_sync1;
    end
    
    // Extend reset for more clock cycles
    reg [7:0] reset_counter = 0;
    reg reset_n = 0;
    
    always @(posedge sysclk) begin
        if (!mclr_sync2) begin
            reset_counter <= 0;
            reset_n <= 0;
        end else if (reset_counter < 200) begin  // Hold reset for 200 clocks
            reset_counter <= reset_counter + 1;
            reset_n <= 0;
        end else begin
            reset_n <= 1;
        end
    end
    
    assign MCLR_sync = reset_n;
 
 
    wire USR_Flag;  
    wire CLK2,CLK3,CLK4,CLK5,CLK6,CLK7,CLK8; 
      wire [3:0] RXC;      
      wire [3:0] RXCn;  
      
    ClockManager ClockControlUnit (
        .sysclk   (sysclk),
        .MCLR     (MCLR_sync),
        .CLK2     (CLK2),
        .CLK3     (CLK3),
        .CLK4     (CLK4),
        .CLK5     (CLK5),
        .CLK6     (CLK6),
        .CLK7     (CLK7),
        .CLK8     (CLK8),
        .USR_Flag (USR_Flag),
        .Clock2   (Clock2),
        .Clock3   (Clock3),
        .Clock4   (Clock4),
        .Clock5   (Clock5),
        .Clock6   (Clock6),
        .Clock7   (Clock7),
        .Clock8   (Clock8),
        .RedCLK   (RedCLK)
    );

    
//    assign PRTA8 = CLK8;
//    assign PRTA7 = CLK7;
//    assign PRTA6 = CLK6;
//    assign PRTA5 = CLK5;
//    assign PRTA4 = CLK4;
//    assign PRTA3 = CLK3;
//    assign PRTA2 = CLK2;
//    assign PRTA1 = USR_Flag;


    
    
    assign DLG_LED = RedCLK;
   
    wire [7:0] RomByte = {D8, D7, D6, D5, D4, D3, D2, D1};  
    wire [12:0] AddressBus = {Add13, Add12, Add11, Add10, Add9,Add8, Add7, Add6, Add5, Add4, Add3, Add2, Add1};
    
    wire [7:0] PRTA = {PRTA8, PRTA7, PRTA6, PRTA5, PRTA4, PRTA3, PRTA2, PRTA1};  
    wire [7:0] PRTB = {PRTB8, PRTB7, PRTB6, PRTB5, PRTB4, PRTB3, PRTB2, PRTB1};  
    
    
    wire [7:0] DPTR_A;
    wire [7:0] DPTR_B;
    
    wire [7:0] WriteAdd;
    wire [7:0] ReadAdd;
    wire [7:0] DataBus /* synthesis keep */;


    
    wire [7:0] Bus_A,Bus_B,Bus_C,Bus_D,Bus_E,Bus_F,Bus_G,Bus_H,Bus_I,Bus_J,Bus_K,Bus_L,Bus_M;
    
    assign Bus_A = WriteAdd;
    assign Bus_B = ReadAdd;
    assign Bus_C = DataBus;
    wire SysCLR;
    SerialDebug SerialDebug_INST(
        .sysclk(sysclk),
        .uart_rxd_out(uart_rxd_out),
        .uart_txd_in(uart_txd_in),
        .SysCLR(SysCLR),
        .USR_Flag(USR_Flag),
        .CLK2(CLK2),
        .CLK3(CLK3),
        .CLK4(CLK4),
        .CLK5(CLK5),
        .CLK6(CLK6),
        .CLK7(CLK7),
        .CLK8(CLK8),
        .Bus_A(Bus_A),  //WriteAdd
        .Bus_B(Bus_B),  //ReadAdd
        .Bus_C(Bus_C),  //DataBus
        .Bus_D(Bus_D),  //Instruction_Reg
        .Bus_E(Bus_E),  //Write_Offset_Reg
        .Bus_F(Bus_F),  //Read_Data_Reg
        .Bus_G(Bus_G),  //ALU_BUS
        .Bus_H(Bus_H),  //RXBUF
        .Bus_I(Bus_I),  
        .Bus_J(Bus_J),  
        .Bus_K(Bus_K),  
        .Bus_L(Bus_L),  
        .Bus_M(Bus_M),
        //Debug
        .Buffer()
    );
    
    
      

    wire CLKn;
    wire [7:0] DebugBits;
    wire [4:0] DP_Flags;
    
    assign Bus_I = DPTR_B;
    assign BUS_J = DPTR_A;
    ControlRegion ECF_CTRL(
        .sysclk(sysclk),
        .MCLR(MCLR_sync),
        .CLK_IN(RedCLK),
        .CLKn(CLKn),
        .Pause(),
        .DPTRA(DPTR_A),
        .DPTRB(DPTR_B),
        
        .IntFlags(),
        .ALUFlags(DP_Flags),
        .RomByte(RomByte),
        .AddressLookup(AddressBus),
        
        .WriteBus(WriteAdd),
        .ReadBus(ReadAdd),
        .DataBus(DataBus),
        
        
        //Debug
        .Instruction_Reg(Bus_D),
        .Write_Offset_Reg(Bus_E),
        .Read_Data_Reg(Bus_F),
        
        .DebugBits(DebugBits)
    );
    
    
    wire [7:0] Debuglines;
    wire [7:0] MARA;
    wire [7:0] MARB;
    wire [7:0] MARC;
    assign  MemAdr[7:0] = MARA;
    assign MemAdr[15:8] = MARB;
    assign MemAdr[18:16] = MARC[2:0];
    assign RamCEn = 1'b0;
    wire RAMRead;
    wire RAMWrite;
    assign RamOEn = ~RAMRead;
    assign RamWEn = ~RAMWrite;
    assign DataBus = MemDB;
    
    AddressableRegion ECFAddRegion(
    .SYSCLK(sysclk),
    .CLK_IN(CLKn),
    .MCLR(MCLR_sync),
    
     .MARA(MARA),
     .MARB(MARB),
     .MARC(MARC),
     
     .RAMRead(RAMRead),
     .RAMWrite(RAMWrite),
    
    .WriteAdd(WriteAdd),
    .ReadAdd(ReadAdd),
    .DataBus(DataBus),
    
    .DPTR_A(DPTR_A),
    .DPTR_B(DPTR_B),
    
    //Interrupts
//    output wire T1_int,
//    output wire T2_int,
//    output wire T3_int,
//    output wire T4_int,
//    output wire UART_int,
    
    .DP_Flags(DP_Flags),
    
    
    //GPIO
//    .PORTA(PRTA),
    .PORTB(PRTB),
    .TCA(TCA),
    .TCB(TCB),
    .Tx(TxPin),
    .Rx(RxPin),
    
    .RxBufPass(Bus_H),
    
    .ALU_BUS(BUS_G),

    .Debuglines(Debuglines),
    .DebugBusA(),
    .DebugBusB()
    
    
    
    );
   
    
    assign PRTA1 = Debuglines[0];
    assign PRTA2 = Debuglines[1];
    assign PRTA3 = Debuglines[2];
    assign PRTA4 = Debuglines[3];
    assign PRTA5 = Debuglines[4];
    
  
    
    
endmodule


//==========================================================
// Module: ClockManager
// Purpose: Divide system clock and multiplex outputs
//          based on selector flags. Once any flag is raised,
//          the module latches into mux mode until reset (MCLR).
//==========================================================
module ClockManager (
    input  wire sysclk,       // 12 MHz base clock
    input  wire MCLR,         // active-high master reset (returns to default)
    input  wire CLK2,         // selector flag for 1.2 MHz (default)
    input  wire CLK3,         // selector flag for 120 kHz
    input  wire CLK4,         // selector flag for 12 kHz
    input  wire CLK5,         // selector flag for 1.2 kHz
    input  wire CLK6,         // selector flag for 120 Hz
    input  wire CLK7,         // selector flag for 12 Hz
    input  wire CLK8,         // selector flag for 1.2 Hz
    input  wire USR_Flag,     // manual clock, mirrored directly
    output wire Clock2,       // 1.2 MHz
    output wire Clock3,       // 120 kHz
    output wire Clock4,       // 12 kHz
    output wire Clock5,       // 1.2 kHz
    output wire Clock6,       // 120 Hz
    output wire Clock7,       // 12 Hz
    output wire Clock8,       // 1.2 Hz
    output wire RedCLK        // final selected clock
);

    // -------------------------------------------------------
    // Clock divider chain
    // -------------------------------------------------------
    ClockDivider clk_div1 (.clk_in(sysclk), .clk_out(Clock2));
    ClockDivider clk_div2 (.clk_in(Clock2), .clk_out(Clock3));
    ClockDivider clk_div3 (.clk_in(Clock3), .clk_out(Clock4));
    ClockDivider clk_div4 (.clk_in(Clock4), .clk_out(Clock5));
    ClockDivider clk_div5 (.clk_in(Clock5), .clk_out(Clock6));
    ClockDivider clk_div6 (.clk_in(Clock6), .clk_out(Clock7));
    ClockDivider clk_div7 (.clk_in(Clock7), .clk_out(Clock8));

    // -------------------------------------------------------
    // Flag management and mode control
    // -------------------------------------------------------
    wire any_flag = CLK2 | CLK3 | CLK4 | CLK5 | CLK6 | CLK7 | CLK8 | USR_Flag;

    reg mux_mode;  // 0 = default (Clock2), 1 = mux mode

    always @(posedge sysclk or posedge MCLR) begin
        if (MCLR)
            mux_mode <= 1'b0;          // reset to default mode
        else if (any_flag)
            mux_mode <= 1'b1;          // once any flag seen, stay in mux mode
    end

    // -------------------------------------------------------
    // Priority encoder for mux mode
    // -------------------------------------------------------
    reg [2:0] sel_code;

    always @(*) begin
        if (any_flag) begin
            if (CLK8)          sel_code = 3'd6;
            else if (CLK7)     sel_code = 3'd5;
            else if (CLK6)     sel_code = 3'd4;
            else if (CLK5)     sel_code = 3'd3;
            else if (CLK4)     sel_code = 3'd2;
            else if (CLK3)     sel_code = 3'd1;
            else if (USR_Flag) sel_code = 3'd7;
            else               sel_code = 3'd0; // CLK2
        end else begin
            sel_code = 3'd0; // default placeholder
        end
    end

    // -------------------------------------------------------
    // Output selection logic
    // -------------------------------------------------------
    assign RedCLK =
        (!mux_mode)                ? Clock2   : // normal mode
        (any_flag && sel_code==3'd0) ? Clock2   :
        (any_flag && sel_code==3'd1) ? Clock3   :
        (any_flag && sel_code==3'd2) ? Clock4   :
        (any_flag && sel_code==3'd3) ? Clock5   :
        (any_flag && sel_code==3'd4) ? Clock6   :
        (any_flag && sel_code==3'd5) ? Clock7   :
        (any_flag && sel_code==3'd6) ? Clock8   :
        (any_flag && sel_code==3'd7) ? USR_Flag :
        1'b0; // mux mode but no active flag -> constant low

endmodule

