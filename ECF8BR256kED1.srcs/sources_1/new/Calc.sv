
module HalfAdder (
    input  wire A,      // Input A
    input  wire B,      // Input B
    output wire Sum,    // Sum output (A XOR B)
    output wire Carry   // Carry output (A AND B)
);
    assign Sum = A ^ B;
    assign Carry = A & B;
endmodule

// Optimized LSB Half Adder (B is always 1)
module HalfAdderLSB (
    input  wire A,      // Input A (B is implicitly 1)
    output wire Sum,    // Sum output (~A since A XOR 1 = ~A)
    output wire Carry   // Carry output (A since A AND 1 = A)
);
    assign Sum = ~A;
    assign Carry = A;
endmodule

// Optimized MSB Half Adder (no carry output needed)
module HalfAdderMSB (
    input  wire A,      // Input A
    input  wire B,      // Input B
    output wire Sum     // Sum output (A XOR B)
);
    assign Sum = A ^ B;
endmodule


module SubtFullAdder (
    input  wire A,      
    input  wire B,     
    input wire CarryIn,   
    input wire Subtract,   
    output wire Sum,    
    output wire CarryOut   
);
    wire BM = B ^ Subtract;
    wire AANDB = BM & A;
    wire AXORB = BM ^ A;
    assign Sum = AXORB ^  CarryIn;
    assign CarryOut = AANDB | (AXORB & CarryIn);
endmodule
