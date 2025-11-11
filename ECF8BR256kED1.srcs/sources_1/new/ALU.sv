
// Final ALU Module - Top level integration of all ALU components
module CoreALU (
    // Inputs
    input  wire [7:0] BUS_A,        // 8-bit input bus A
    input  wire [7:0] BUS_B,        // 8-bit input bus B
    input  wire       Sel_C,        // Selection bit C
    input  wire       Sel_B,        // Selection bit B
    input  wire       Sel_A,        // Selection bit A
    input  wire       Subtract,     // Subtract control signal
    input  wire       SignedMode,   // Signed mode control
    input  wire       NEG_A,        // Negate A control signal
    
    // Outputs
    output wire [7:0] ALU_BUS,      // Final ALU result bus
    output wire       Zero,         // Zero flag
    output wire       Negative,     // Negative flag
    output wire       AEqualB,      // A equals B flag
    output wire       ALargerB,     // A larger than B flag
    output wire       Overflow      // Overflow flag
);

    // Internal wires for connecting modules
    wire [7:0] sum_internal;
    wire [7:0] and_internal;
    wire [7:0] or_internal;
    wire [7:0] xor_internal;
    wire [7:0] nota_internal;
    wire [7:0] notb_internal;
    wire [7:0] shiftleft_internal;
    wire [7:0] shiftright_internal;
    
    // Decoder outputs for mux selection (one-hot encoded)
    wire [7:0] decoder_out;
    
    // Extract individual selection signals from decoder output
    wire sel_sum        = decoder_out[0];
    wire sel_and        = decoder_out[1];
    wire sel_or         = decoder_out[2];
    wire sel_xor        = decoder_out[3];
    wire sel_nota       = decoder_out[4];
    wire sel_notb       = decoder_out[5];
    wire sel_shiftright = decoder_out[6];
    wire sel_shiftleft  = decoder_out[7];

    // Instantiate 8-bit ALU
    ALU8bit alu_8bit_inst (
        // Inputs
        .A         (BUS_A),
        .B         (BUS_B),
        .neg_a     (NEG_A),
        .subtract  (Subtract),
        
        // Outputs
        .SUM       (sum_internal),
        .AND       (and_internal),
        .OR        (or_internal),
        .XOR       (xor_internal),
        .NOTA      (nota_internal),
        .NOTB      (notb_internal),
        .ShiftLeft (shiftleft_internal),
        .ShiftRight(shiftright_internal),
        
        // Status flags
        .Overflow  (Overflow),
        .AEqualB   (AEqualB),
        .ALargerB  (ALargerB)
    );

    // Instantiate ALU Multiplexer
    ALUMux alu_mux_inst (
        // 8-bit input buses
        .SUM       (sum_internal),
        .AND       (and_internal),
        .OR        (or_internal),
        .XOR       (xor_internal),
        .NOTA      (nota_internal),
        .NOTB      (notb_internal),
        .ShiftRight(shiftright_internal),
        .ShiftLeft (shiftleft_internal),
        
        // Selection inputs (one-hot encoded)
        .Sel_SUM       (sel_sum),
        .Sel_AND       (sel_and),
        .Sel_OR        (sel_or),
        .Sel_XOR       (sel_xor),
        .Sel_NOTA      (sel_nota),
        .Sel_NOTB      (sel_notb),
        .Sel_ShiftRight(sel_shiftright),
        .Sel_ShiftLeft (sel_shiftleft),
        
        // Output
        .ALU_Out   (ALU_BUS)
    );

    // Instantiate Flags and Decode module
    FlagsAndDecode flags_decode_inst (
        // Inputs
        .SM        (SignedMode),
        .Sel_A     (Sel_A),
        .Sel_B     (Sel_B),
        .Sel_C     (Sel_C),
        .Overflow  (Overflow),
        .ALU_Bus   (ALU_BUS),        
        
        // Outputs
        .Zero      (Zero),
        .Negative  (Negative),
        .decoder_out(decoder_out)
    );

endmodule


// FlagsAndDecode.sv - ALU Flags Generation and Selection Decoding

module FlagsAndDecode (
    input  wire        SM,          // Signed mode
    input  wire        Sel_A,       // Selection bit A
    input  wire        Sel_B,       // Selection bit B  
    input  wire        Sel_C,       // Selection bit D
    input  wire        Overflow,    // Overflow input
    input  wire [7:0]  ALU_Bus,     // ALU result bus
    
    output wire        Zero,        // Zero flag
    output wire        Negative,    // Negative flag
    output wire [7:0]  decoder_out  // Decoded outputs 1-8 from 3-bit decoder
);

    // Internal signals
    wire [2:0] decoder_input;
    wire       Byte_zero;
    wire       No_Overflow;

    // Combine selection bits for 3-bit decoder input
    assign decoder_input = {Sel_C, Sel_B, Sel_A};

    // Instantiate 3-bit decoder from Utils.sv
    Decoder3bit decoder_inst (
        .in(decoder_input),
        .out(decoder_out)
    );

    // Generate Byte_zero: NOR all bits of ALU_Bus together
    // This is true when all bits of ALU_Bus are 0
    assign Byte_zero = ~(ALU_Bus[7] | ALU_Bus[6] | ALU_Bus[5] | ALU_Bus[4] | 
                        ALU_Bus[3] | ALU_Bus[2] | ALU_Bus[1] | ALU_Bus[0]);

    // Generate No_Overflow: Overflow NAND (NOT SM)
    assign No_Overflow = ~(Overflow & ~SM);

    // Generate flags
    assign Negative = SM & ALU_Bus[7];        // Negative flag: SM AND MSB of ALU_Bus
    assign Zero = No_Overflow & Byte_zero;            // Zero flag: No_Overflow AND Byte_zero

endmodule

module ALUMux (
    // 8-bit input buses for different ALU operations
    input  wire [7:0] SUM,         // Addition result
    input  wire [7:0] AND,         // Bitwise AND result
    input  wire [7:0] OR,          // Bitwise OR result
    input  wire [7:0] XOR,         // Bitwise XOR result
    input  wire [7:0] NOTA,        // NOT A result
    input  wire [7:0] NOTB,        // NOT B result
    input  wire [7:0] ShiftRight,  // Right shift result
    input  wire [7:0] ShiftLeft,   // Left shift result
    
    // Selection inputs (one-hot encoded)
    input  wire       Sel_SUM,         // Enable SUM output
    input  wire       Sel_AND,         // Enable AND output
    input  wire       Sel_OR,          // Enable OR output
    input  wire       Sel_XOR,         // Enable XOR output
    input  wire       Sel_NOTA,        // Enable NOTA output
    input  wire       Sel_NOTB,        // Enable NOTB output
    input  wire       Sel_ShiftRight,  // Enable ShiftRight output
    input  wire       Sel_ShiftLeft,   // Enable ShiftLeft output
    
    // Common output bus
    output wire [7:0] ALU_Out      // Final ALU result
);

    // Use a proper multiplexer with case statement
    reg [7:0] alu_out_reg;
    
    always @* begin
        case (1'b1)  // Synthesis will optimize this to a priority encoder
            Sel_SUM:        alu_out_reg = SUM;
            Sel_AND:        alu_out_reg = AND;
            Sel_OR:         alu_out_reg = OR;
            Sel_XOR:        alu_out_reg = XOR;
            Sel_NOTA:       alu_out_reg = NOTA;
            Sel_NOTB:       alu_out_reg = NOTB;
            Sel_ShiftRight: alu_out_reg = ShiftRight;
            Sel_ShiftLeft:  alu_out_reg = ShiftLeft;
            default:        alu_out_reg = 8'b0;  // Default case
        endcase
    end
    
    assign ALU_Out = alu_out_reg;

endmodule

// 1-bit ALU module for building an 8-bit ALU
module ALU1bit (
    // Inputs
    input  wire EqualSoFar,      // Equality comparison from previous bit
    input  wire ALargerPrev,     // A > B from previous bit  
    input  wire Carry_in,        // Carry input for addition
    input  wire neg_a,           // Negate A input (for subtraction)
    input  wire subtract,        // Subtract control (negates B)
    input  wire A,               // Input bit A
    input  wire B,               // Input bit B
    
    // Outputs
    output wire CarryOut,        // Carry output for addition
    output wire CurrentlyEqual,  // Equality for this bit position
    output wire ALarger,         // A > B output
    
    // ALU operation results
    output wire SUM,             // Addition/subtraction result
    output wire AND,             // Bitwise AND result
    output wire OR,              // Bitwise OR result
    output wire XOR,             // Bitwise XOR result
    output wire NOTA,            // NOT A result
    output wire NOTB             // NOT B result
);

    // Internal signals
    wire A_Modified;
    wire B_Modified;
    wire AXORB;
    wire AORB;
    wire AANDB;
    wire OtherCarry;
    wire Largercheck;

    // Step 1: Modify inputs based on control signals
    assign A_Modified = A ^ neg_a;      // A XOR neg_a
    assign B_Modified = B ^ subtract;   // B XOR subtract

    // Step 2: Basic logic operations on modified inputs
    assign AXORB = A_Modified ^ B_Modified;  // A_Modified XOR B_Modified
    assign AORB  = A_Modified | B_Modified;  // A_Modified OR B_Modified
    assign AANDB = A_Modified & B_Modified;  // A_Modified AND B_Modified

    // Step 3: Addition logic
    assign SUM = AXORB ^ Carry_in;           // Sum = AXORB XOR Carry_in
    assign OtherCarry = Carry_in & AXORB;    // Carry from Carry_in and AXORB
    assign CarryOut = AANDB | OtherCarry;    // Final carry out

    // Step 4: Comparison logic
    assign CurrentlyEqual = EqualSoFar & ~AXORB;              // Equal if previous equal AND current bits same
    assign Largercheck = EqualSoFar & A_Modified & AXORB;     // A larger if equal so far, A=1, and bits different
    assign ALarger = ALargerPrev | Largercheck;               // A larger if previously larger OR larger at this bit

    // Step 5: Output assignment for logic operations
    assign AND  = AANDB;        // AND result
    assign OR   = AORB;         // OR result  
    assign XOR  = AXORB;        // XOR result
    assign NOTA = ~A_Modified;  // NOT A result
    assign NOTB = ~B_Modified;  // NOT B result

endmodule


// 8-bit ALU module built from cascaded 1-bit ALU modules
module ALU8bit (
    // Inputs
    input  wire [7:0] A,         // 8-bit input A
    input  wire [7:0] B,         // 8-bit input B
    input  wire       neg_a,     // Negate A control signal
    input  wire       subtract,  // Subtract control signal
    
    // Outputs - 8-bit buses for each operation
    output wire [7:0] SUM,       // Addition/subtraction result
    output wire [7:0] AND,       // Bitwise AND result
    output wire [7:0] OR,        // Bitwise OR result
    output wire [7:0] XOR,       // Bitwise XOR result
    output wire [7:0] NOTA,      // NOT A result
    output wire [7:0] NOTB,      // NOT B result
    output wire [7:0] ShiftLeft,      
    output wire [7:0] ShiftRight,      
    
    // Status flags
    output wire       Overflow,  // Overflow flag (carry out from MSB)
    output wire       AEqualB,   // A equals B flag
    output wire       ALargerB   // A larger than B flag
);

    // Internal cascade signals for carry propagation
    wire [8:0] carry;  // carry[0] is carry_in, carry[8] is final carry_out
    
    // Internal cascade signals for comparison propagation
    wire [8:0] equal_cascade;   // equal_cascade[8] gets constant 1, equal_cascade[0] is final
    wire [8:0] larger_cascade;  // larger_cascade[8] gets constant 0, larger_cascade[0] is final
    
    // Set up initial cascade values
    assign carry[0] = subtract;          // First carry_in comes from subtract signal
    assign equal_cascade[8] = 1'b1;      // Start with "equal so far" = true
    assign larger_cascade[8] = 1'b0;     // Start with "A larger so far" = false
    
    // Generate 8 cascaded 1-bit ALU modules
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : alu_cascade
            ALU1bit alu_bit (
                // Inputs
                .EqualSoFar    (equal_cascade[i+1]),   // From higher bit (or initial)
                .ALargerPrev   (larger_cascade[i+1]),  // From higher bit (or initial)
                .Carry_in      (carry[i]),             // From lower bit (or initial)
                .neg_a         (neg_a),                // Common control signal
                .subtract      (subtract),             // Common control signal
                .A             (A[i]),                 // Bit i of input A
                .B             (B[i]),                 // Bit i of input B
                
                // Outputs
                .CarryOut      (carry[i+1]),           // To higher bit
                .CurrentlyEqual(equal_cascade[i]),     // To lower bit
                .ALarger       (larger_cascade[i]),    // To lower bit
                
                // ALU operation results
                .SUM           (SUM[i]),               // Bit i of SUM output
                .AND           (AND[i]),               // Bit i of AND output
                .OR            (OR[i]),                // Bit i of OR output
                .XOR           (XOR[i]),               // Bit i of XOR output
                .NOTA          (NOTA[i]),             // Bit i of NOTA output
                .NOTB          (NOTB[i])              // Bit i of NOTB output
            );
        end
    endgenerate
    
    // Shift operations on SUM result
    assign ShiftLeft = {SUM[6:0], 1'b0};  // Left shift: shift left by 1, fill with 0
    assign ShiftRight = {1'b0, SUM[7:1]}; // Right shift: shift right by 1, fill with 0
    
    // Final output flags
    assign Overflow = carry[8];        // Carry out from MSB (bit 7)
    assign AEqualB = equal_cascade[0]; // Final equality result from LSB (bit 0)
    assign ALargerB = larger_cascade[0]; // Final comparison result from LSB (bit 0)

endmodule