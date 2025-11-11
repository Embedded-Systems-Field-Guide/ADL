
//=============================================================================
// CLOCK DIVIDER MODULE
//=============================================================================

// Clock divider to convert 12MHz to 1Hz
// Clock divider to convert 12MHz to configurable output frequency
module ClockDivider (
    input  wire clk_in,     // 12MHz input clock
    output wire clk_out     // Configurable frequency output clock
);
    
    // ========== FREQUENCY CONFIGURATION ==========
    // Change this value to set the output frequency
    // Formula: DIVIDE_BY = (INPUT_FREQ / OUTPUT_FREQ) / 2
    // Examples for 12MHz input:
    //   1Hz:     DIVIDE_BY = 6,000,000
    //   10Hz:    DIVIDE_BY = 600,000  
    //   100Hz:   DIVIDE_BY = 60,000
    //   1kHz:    DIVIDE_BY = 6,000
    //   10kHz:   DIVIDE_BY = 600
    parameter DIVIDE_BY = 24'd5; 
    // =============================================
    
    // Counter to divide input frequency
    // Need 24 bits to count up to 6,000,000 for 1Hz
    reg [23:0] counter;
    reg clk_out_reg;
    
    always @(posedge clk_in) begin
        if (counter >= DIVIDE_BY - 1) begin
            counter <= 24'd0;
            clk_out_reg <= ~clk_out_reg;  // Toggle output
        end else begin
            counter <= counter + 1;
        end
    end
    
    assign clk_out = clk_out_reg;
endmodule
//=============================================================================
// DECODERS
//=============================================================================

// 1-bit decoder (1-to-2)
module Decoder1bit (
    input  wire       in,     // 1-bit input
    output wire [1:0] out     // 2 output lines
);
    assign out[0] = ~in;  // Active when in=0
    assign out[1] = in;   // Active when in=1
endmodule

// 2-bit decoder (2-to-4)
module Decoder2bit (
    input  wire [1:0] in,     // 2-bit input
    output wire [3:0] out     // 4 output lines
);
    assign out[0] = ~in[1] & ~in[0];  // in = 00
    assign out[1] = ~in[1] &  in[0];  // in = 01
    assign out[2] =  in[1] & ~in[0];  // in = 10
    assign out[3] =  in[1] &  in[0];  // in = 11
endmodule

// 3-bit decoder (3-to-8)
module Decoder3bit (
    input  wire [2:0] in,     // 3-bit input
    output wire [7:0] out     // 8 output lines
);
    assign out[0] = ~in[2] & ~in[1] & ~in[0];  // in = 000
    assign out[1] = ~in[2] & ~in[1] &  in[0];  // in = 001
    assign out[2] = ~in[2] &  in[1] & ~in[0];  // in = 010
    assign out[3] = ~in[2] &  in[1] &  in[0];  // in = 011
    assign out[4] =  in[2] & ~in[1] & ~in[0];  // in = 100
    assign out[5] =  in[2] & ~in[1] &  in[0];  // in = 101
    assign out[6] =  in[2] &  in[1] & ~in[0];  // in = 110
    assign out[7] =  in[2] &  in[1] &  in[0];  // in = 111
endmodule

// 4-bit decoder (4-to-16)
module Decoder4bit (
    input  wire [3:0]  in,    // 4-bit input
    output wire [15:0] out    // 16 output lines
);
    assign out[0]  = ~in[3] & ~in[2] & ~in[1] & ~in[0];  // in = 0000
    assign out[1]  = ~in[3] & ~in[2] & ~in[1] &  in[0];  // in = 0001
    assign out[2]  = ~in[3] & ~in[2] &  in[1] & ~in[0];  // in = 0010
    assign out[3]  = ~in[3] & ~in[2] &  in[1] &  in[0];  // in = 0011
    assign out[4]  = ~in[3] &  in[2] & ~in[1] & ~in[0];  // in = 0100
    assign out[5]  = ~in[3] &  in[2] & ~in[1] &  in[0];  // in = 0101
    assign out[6]  = ~in[3] &  in[2] &  in[1] & ~in[0];  // in = 0110
    assign out[7]  = ~in[3] &  in[2] &  in[1] &  in[0];  // in = 0111
    assign out[8]  =  in[3] & ~in[2] & ~in[1] & ~in[0];  // in = 1000
    assign out[9]  =  in[3] & ~in[2] & ~in[1] &  in[0];  // in = 1001
    assign out[10] =  in[3] & ~in[2] &  in[1] & ~in[0];  // in = 1010
    assign out[11] =  in[3] & ~in[2] &  in[1] &  in[0];  // in = 1011
    assign out[12] =  in[3] &  in[2] & ~in[1] & ~in[0];  // in = 1100
    assign out[13] =  in[3] &  in[2] & ~in[1] &  in[0];  // in = 1101
    assign out[14] =  in[3] &  in[2] &  in[1] & ~in[0];  // in = 1110
    assign out[15] =  in[3] &  in[2] &  in[1] &  in[0];  // in = 1111
endmodule

// 4-bit decoder with enable
module Decoder4bitEnable (
    input  wire [3:0]  in,    // 4-bit input
    input  wire        en,    // Enable signal (active-high)
    output wire [15:0] out    // 16 output lines
);
    wire [15:0] decoded;
    
    // Internal decoder
    Decoder4bit decoder (
        .in(in),
        .out(decoded)
    );
    
    // Enable control - outputs are only active when enabled
    assign out = en ? decoded : 16'b0;
endmodule


//=============================================================================
// MULTIPLEXERS
//=============================================================================

// Bit multiplexer - selects between two single-bit inputs
module BitMux (
    input  wire A,      // Input A
    input  wire SelA,   // Select A (active-high)
    input  wire B,      // Input B  
    input  wire SelB,   // Select B (active-high)
    output wire out     // Output
);
    // Priority: if both selects are high, A takes priority
    // If neither select is high, output is 0
    assign out = SelA ? A : (SelB ? B : 1'b0);
endmodule

// Bus multiplexer - selects between two 8-bit buses
// 2-to-1 Bus multiplexer with priority select logic
module BusMux (
    input  wire [7:0] A,     // Input bus A
    input  wire       SelA,  // Select A (active-high)
    input  wire [7:0] B,     // Input bus B
    input  wire       SelB,  // Select B (active-high)
    output reg  [7:0] out    // Output bus
);
    // Priority: if both selects are high, A takes priority
    // If neither select is high, output is all zeros
    always @(*) begin
        if (SelA)
            out = A;
        else if (SelB)
            out = B;
        else
            out = 8'b00000000;
    end
endmodule

//=============================================================================
// BUFFERS
//=============================================================================

// Bus buffer with tri-state output
module BusBuffer (
    input  wire [7:0] Bus,    // Input bus
    input  wire       Enable, // Enable signal (active-high)
    output wire [7:0] out     // Output bus (tri-state)
);
    // When Enable=1: pass Bus through
    // When Enable=0: high impedance (Z)
    assign out = Enable ? Bus : 8'bZZZZZZZZ;
endmodule

module ADDBusBuffer (
    input  wire [7:0] Bus,
    input  wire       Enable,
    input  wire [7:0] EnableBits,
    output wire [7:0] out
);
    // Per-bit tri-state control
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : bit_buffer
            assign out[i] = (Enable & EnableBits[i]) ? Bus[i] : 1'bZ;
        end
    endgenerate
endmodule

module Enabler16 (
    input  wire [15:0] Bus,    
    input  wire       Enable, 
    output wire [15:0] out     
);

    assign out = Enable ? Bus : 16'b0;
endmodule


module Enabler8 (
    input  wire [7:0] Bus,    
    input  wire       Enable, 
    output wire [7:0] out     
);

    assign out = Enable ? Bus : 8'b0;
endmodule









// ==========================================
// Multi-bit version (for buses)
// ==========================================

module UnitDelay8bit (
    input  wire sysclk,
    input  wire [7:0] Din,
    output reg  [7:0] Dout
);

    always @(posedge sysclk) begin
        Dout <= Din;
    end

endmodule


// ==========================================
// Parameterized version (any bit width)
// ==========================================

(* keep_hierarchy = "yes", dont_touch = "true" *)
module UnitDelay #(
    parameter WIDTH = 1
) (
    input wire sysclk,
    input wire [WIDTH-1:0] Din,
    (* keep = "true", dont_touch = "true" *) output reg [WIDTH-1:0] Dout
);
    always @(posedge sysclk)
        Dout <= Din;
endmodule
