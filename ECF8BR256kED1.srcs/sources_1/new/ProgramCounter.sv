
module ProgramCounter(
    input  wire        MCLR,          
    input  wire        CLK_IN,        
    input  wire        Pause,         
    input  wire        INC,           
    input  wire [7:0]  Offset,        
    input  wire        Subtract,      
    input  wire        SetVal,        
    input  wire [12:0] AddressJump,   

    output wire [12:0] Counterval     
);

    wire [12:0] PCP1;  
    wire [12:0] D;     

    DFF13bit PC_dff (
        .D   (D),
        .CLK (CLK_IN & ~Pause),
        .RST (MCLR),
        .Q   (Counterval)
    );

    Incrementer13Bit PCinc (
        .BUS_In  (Counterval),
        .BUS_Out (PCP1),
        .Offset  (Offset),
        .SUBT    (Subtract),
        .INC     (INC)
    );

    assign D = (SetVal) ? AddressJump : PCP1;

endmodule



module DFF13bit (
    input  wire [12:0] D,   
    input  wire CLK,        
    input  wire RST,        
    output wire [12:0] Q,    
    output wire [12:0] Qn    
);

    genvar i;
    generate
        for (i = 0; i < 13; i = i + 1) begin : dff_array
            DFF dff_cell (
                .D   (D[i]),
                .CLK (CLK),
                .RST (RST),
                .Q   (Q[i]),
                .Qn  (Qn[i])
            );
        end
    endgenerate

endmodule


module Incrementer13Bit (
    input  wire        INC,        // Increment control
    input  wire        SUBT,       // Subtract control
    input  wire [7:0]  Offset,     // 8-bit offset input
    input  wire [12:0] BUS_In,     // 13-bit input bus
    output wire [12:0] BUS_Out     // 13-bit output bus
);

    // Internal carry signals
    wire [11:0] carry;  // carry[0] to carry[11] for bits 1-12

    // Generate 13 instances of SubtFullAdder
    genvar i;
    generate
        for (i = 0; i < 13; i = i + 1) begin : adder_chain
            wire B_input;

            // For bits 0-7, use Offset[i], else 0
            assign B_input = (i < 8) ? Offset[i] : 1'b0;

            // First stage gets INC | SUBT as CarryIn
            if (i == 0) begin
                SubtFullAdder adder_lsb (
                    .A(BUS_In[i]),
                    .B(B_input),
                    .CarryIn(INC | SUBT),
                    .Subtract(SUBT),
                    .Sum(BUS_Out[i]),
                    .CarryOut(carry[i])
                );
            end else if (i < 12) begin
                // Middle stages chain carry
                SubtFullAdder adder_mid (
                    .A(BUS_In[i]),
                    .B(B_input),
                    .CarryIn(carry[i-1]),
                    .Subtract(SUBT),
                    .Sum(BUS_Out[i]),
                    .CarryOut(carry[i])
                );
            end else begin
                // MSB has no output carry connected
                SubtFullAdder adder_msb (
                    .A(BUS_In[i]),
                    .B(B_input),
                    .CarryIn(carry[i-1]),
                    .Subtract(SUBT),
                    .Sum(BUS_Out[i]),
                    .CarryOut() // Unused
                );
            end
        end
    endgenerate

endmodule


