
module ControlRegion(
        input wire sysclk,
        input wire MCLR,
        input wire CLK_IN,
        output wire CLKn,
        input wire Pause,
        input wire [7:0] DPTRA,
        input wire [7:0] DPTRB,
        
        input wire [7:0] IntFlags,
        input wire [4:0] ALUFlags,
        input wire [7:0] RomByte,
        output wire [12:0] AddressLookup,
        
        output wire [7:0] WriteBus,
        output wire [7:0] ReadBus,
        inout wire [7:0] DataBus,
        
        
        //Debug
        output wire [7:0] Instruction_Reg,
        output wire [7:0] Write_Offset_Reg,
        output wire [7:0] Read_Data_Reg,
        output wire [7:0] DebugBits,
        output wire [7:0] DebugBus
    );
        //==========================================
        //internal Signals
        //==========================================
            

        assign CLKn = ~CLK_IN;
        //Space1
        wire JMPF;
        wire JMPB;
        wire MOVX;
        wire SETB;
        wire CLRB;

        wire JZ;        
        wire JN;        
        wire JL;        
        wire JC;        
        wire JE;     
        
        //space 2
        wire JMPA;
        wire MOV;
        wire MOVR;
        wire MOVD;
        
        wire AJZ;        
        wire AJN;        
        wire AJL;        
        wire AJC;        
        wire AJE;  
        
        //space 3
        wire CJNZ;
        
        
        
        //==========================================
        //Program counter
        //==========================================       
        wire SetVal;
        wire [7:0] Offset;
        wire INC;
        wire [12:0] AddressJump;
        wire [12:0] Counterval;
        ProgramCounter ProgramCounter_inst(
            .MCLR(MCLR),
            .CLK_IN(CLK_IN),
            .Pause(Pause),
            .INC(INC),
            .Offset(Offset),
            .Subtract(JMPB),
            .SetVal(SetVal),
            .AddressJump(AddressJump),
            
            .Counterval(Counterval)         
        );
      

        //==========================================
        //Count conntroller
        //==========================================
        wire [3:0] StepBus;
        wire Run;
        wire [2:0] Cycles;
        
         CountControl CountControl_INST(
            .sysclk(sysclk),
            .MCLR(MCLR),
            .CLK(CLK_IN),
            .CLKn(CLKn),
            
            .Cycles(Cycles),
            
        
            .StepBus(StepBus),
            
            .Run(Run)
        );
        //==========================================
        //Instruction regs
        //==========================================    
         InstrcutionRegs InstrcutionRegs_isnt (
            .Ins_Data(RomByte & {8{~MOVX}}),
            .Reg_Data(RomByte),   
            .STR_0(StepBus[0]),   
            .STR_1(StepBus[1]),   
            .STR_2(StepBus[2]),   
            .CLK_IN(CLK_IN),
            .MCLR(MCLR),
            
            .Instruction(Instruction_Reg),
            .Write_Offset(Write_Offset_Reg),
            .Read_Data(Read_Data_Reg)
         );   
        
        
        //==========================================
        //Decoding instructions regs
        //==========================================    
        wire [3:0] InstructionSpaces;
        Decoder2bit InstructionTopNibble (
            .in(Instruction_Reg[5:4]),     // 2-bit input
            .out(InstructionSpaces)     // 4 output lines
        );
             
        assign Cycles[1:0] =  InstructionSpaces[1:0];  
        assign Cycles[2] = InstructionSpaces[2] | InstructionSpaces[3];
        
        wire [15:0] DecodedInstruction;
        Decoder4bit InstructionBotNibble (
            .in(Instruction_Reg[3:0]),    // 4-bit input
            .out(DecodedInstruction)    // 16 output lines
        );
        
        wire [15:0] L2Ins;  
        Enabler16 Space1Inst (
            .Bus(DecodedInstruction),    
            .Enable(Run & InstructionSpaces[1]), 
            .out(L2Ins)     
        );
    
    
        assign JMPF = L2Ins[0];
        assign JMPB= L2Ins[1];
        assign MOVX= L2Ins[2];
        assign SETB= L2Ins[3];
        assign CLRB= L2Ins[4];

        assign JZ= L2Ins[6];        
        assign JN= L2Ins[7];        
        assign JL= L2Ins[8];        
        assign JC= L2Ins[9];        
        assign JE= L2Ins[10]; 
        
        
        wire [4:0] Forwardjumps = {JZ , JN, JL, JC,JE};  
        
    wire [15:0] L3Ins;  
    Enabler16 Space2Inst (
        .Bus(DecodedInstruction),    
        .Enable(Run & InstructionSpaces[2]), 
        .out(L3Ins)     
    );
    
        assign JMPA= L3Ins[0]; 
        assign MOV= L3Ins[1]; 
        assign MOVR= L3Ins[2];
        assign MOVD= L3Ins[3];
        
        assign AJZ= L3Ins[5];        
        assign AJN= L3Ins[6];        
        assign AJL= L3Ins[7];        
        assign AJC= L3Ins[8];        
        assign AJE= L3Ins[9];  
        
        
        wire [4:0] Addressjumps = {AJZ , AJN, AJE, AJL,AJC};  

        assign CJNZ = InstructionSpaces[3] &Run;
        
        
        //==========================================
        //Control signals
        //==========================================
       assign SetVal = |(Addressjumps & ALUFlags) | {5{JMPA}};
       wire OffsetConditon = |(Forwardjumps & ALUFlags) | {5{JMPF| JMPB}};
       wire BusIsZero = (DataBus == 0);
       
       wire INCn = OffsetConditon | (~BusIsZero & CJNZ);
       assign INC = ~INCn;
       
       assign Offset = {8{INCn}} & Write_Offset_Reg;
       
       assign AddressJump[7:0] = Read_Data_Reg;
       assign AddressJump[12:8] = Write_Offset_Reg[4:0];
       
        //==========================================
        //output busses
        //==========================================
              
              wire result;
             or_generator #(.N(6)) my_or (
                .in({SETB, CLRB, MOV, MOVR, MOVD, MOVX}),
                .y(result)
            );

       
        assign WriteBus = Write_Offset_Reg & {8{result}};
        
        assign ReadBus = Read_Data_Reg & {8{CJNZ | MOV}};
        
//        wire [7:0] DataBusRaw = (({8{MOVD}} & Read_Data_Reg) | (RomByte & {8{RomByte | {8{MOVR}}}}) | {8{SETB}});
        
        wire [7:0] DB1 = Read_Data_Reg & {8{MOVD}};
        wire [7:0] DB2 = {8{SETB}};
        
        wire [7:0] DB3 = RomByte & {8{MOVX | MOVR}};
        wire [7:0] DataBusRaw = DB1 | DB2 |DB3;
        
        BusBuffer DataBusBuffer (
            .Bus(DataBusRaw),    // Input bus
            .Enable(CLRB | SETB | MOVX | MOVR | MOVD), // Enable signal (active-high)
            .out(DataBus)     // Output bus (tri-state)
        );
        
         //==========================================
        //AddressLookup
        //==========================================       
        
        wire [12:0] DPTRAddress;
        wire [12:0] FirstPCSelect;
        assign DPTRAddress[7:0] = DPTRB;
        assign DPTRAddress[12:8] = DPTRA[4:0];

        assign FirstPCSelect = MOVR ? {5'b00000, Read_Data_Reg} : Counterval;
        assign AddressLookup = MOVX ? DPTRAddress : FirstPCSelect;
        
        
        assign DebugBits[0] = SETB;
        assign DebugBits[1] = CLRB;
        assign DebugBus = DB2;
        
      
       
endmodule



module InstrcutionRegs(
    input wire [7:0] Ins_Data,
    input wire [7:0] Reg_Data,
    input wire STR_0,
    input wire STR_1,
    input wire STR_2,
    input wire CLK_IN,
    input wire MCLR,
    
    output wire [7:0] Instruction,
    output wire [7:0] Write_Offset,
    output wire [7:0] Read_Data

);

     Register8bit INS_Reg (
        .D(Ins_Data),    
        .CLK(CLK_IN),        
        .STR(STR_0),       
        .RST(MCLR),        
        .Q(Instruction)    
    );

    
     Register8bit Write_Reg (
        .D(Reg_Data),    
        .CLK(CLK_IN),        
        .STR(STR_1),       
        .RST(MCLR),        
        .Q(Write_Offset)    
    );

     Register8bit Read_Reg (
        .D(Reg_Data),    
        .CLK(CLK_IN),        
        .STR(STR_2),       
        .RST(MCLR),        
        .Q(Read_Data)    
    );


endmodule 




//==========================================================
// Structural Variable-Input OR Gate Generator
//==========================================================
module or_generator #(
    parameter int N = 4  // Number of inputs
) (
    input  logic [N-1:0] in,
    output logic         y
);

    // Internal signal chain
    logic [N-2:0] chain;

    // First OR gate
    assign chain[0] = in[0] | in[1];

    // Generate remaining OR gates
    genvar i;
    generate
        for (i = 2; i < N; i++) begin : gen_or
            assign chain[i-1] = chain[i-2] | in[i];
        end
    endgenerate

    // Final output
    assign y = chain[N-2];

endmodule
