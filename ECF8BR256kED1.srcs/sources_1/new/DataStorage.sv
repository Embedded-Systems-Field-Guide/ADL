module SRLatch (
    input  wire SYSCLK,    // System clock for synchronization
    input  wire Set,       // Set signal (synchronous)
    input  wire Reset,     // Reset signal (asynchronous priority)
    output wire Q,         // Output Q
    output wire Qn         // Output Q negated (optional)
);

    // Internal register to hold the latch state
    reg q_reg;
    
    // Synchronous SR latch with asynchronous reset
    // Reset has priority over Set (same behavior as your original code)
    always_ff @(posedge SYSCLK or posedge Reset) begin
        if (Reset)
            q_reg <= 1'b0;          // Asynchronous reset
        else if (Set)
            q_reg <= 1'b1;          // Synchronous set
        else
            q_reg <= q_reg;         // Hold current state
    end
    
    // Output assignments
    assign Q = q_reg;
    assign Qn = ~q_reg;

endmodule

// Standard level-sensitive D Latch (transparent when EN=1)
module Dlatch (
    input  wire D,     // Data input
    input  wire EN,    // Enable input (active-high)
    output reg  Q,     // Latched data
    output wire Qn     // Complement of Q
);

    always @(*) begin
        if (EN) begin
            // While EN=1, pass data through
            Q = D;
        end
        // Else, Q holds its previous value automatically
        // (because Q is a reg and not being assigned)
    end

    assign Qn = ~Q;

endmodule


module DlatchRST (
    input  wire D,      // Data input
    input  wire EN,     // Enable input (active-high)
    input  wire RST,    // Asynchronous reset (active-high)
    output reg  Q,      // Latched data
    output wire Qn      // Complement
);

    always @(*) begin
        if (RST) begin
            Q = 1'b0;   // Reset overrides everything
        end
        else if (EN) begin
            Q = D;      // Transparent when enabled
        end
        // Else Q holds
    end

    assign Qn = ~Q;

endmodule


// Master-Slave D Flip-Flop with asynchronous reset
module DFF (
    input  wire D,      // Data input
    input  wire CLK,    // Clock input
    input  wire RST,    // Asynchronous reset (active-high)
    output wire Q,      // Output
    output wire Qn      // Complement output
);

    wire master_Q;
    wire master_Qn;

    // Master latch (transparent when CLK=0)
    Dlatch master (
        .D(D),
        .EN(~CLK),   // Active when CLK=0
        .Q(master_Q),
        .Qn(master_Qn)
    );

    // Slave latch with async reset (transparent when CLK=1)
    DlatchRST slave (
        .D(master_Q),
        .EN(CLK),    // Active when CLK=1
        .RST(RST),   // Async reset
        .Q(Q),
        .Qn(Qn)
    );

endmodule


// Register cell built from DFF and NAND-based mux
module Register (
    input  wire D,      // Data input
    input  wire CLK,    // Clock input
    input  wire STR,    // Store enable
    input  wire RST,    // Asynchronous reset
    output wire Q,      // Register output
    output wire Qn      // Complement
);

    wire n1, n2, D_in;

    // First NAND: (~STR) NAND Q
    assign n1 = ~(~STR & Q);

    // Second NAND: (STR) NAND D
    assign n2 = ~(STR & D);

    // Final NAND combining both
    assign D_in = ~(n1 & n2);

    // Flip-flop with async reset
    DFF dff_inst (
        .D(D_in),
        .CLK(CLK),
        .RST(RST),
        .Q(Q),
        .Qn(Qn)
    );

endmodule


// 8-bit Register built from individual Register cells
module Register8bit (
    input  wire [7:0] D,    // 8-bit data input bus
    input  wire CLK,        // Clock input
    input  wire STR,        // Store enable
    input  wire RST,        // Asynchronous reset
    output wire [7:0] Q,    // 8-bit register output
    output wire [7:0] Qn    // 8-bit complement output
);

    // Instantiate 8 individual register cells
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : reg_array
            Register reg_cell (
                .D   (D[i]),
                .CLK (CLK),
                .STR (STR),
                .RST (RST),
                .Q   (Q[i]),
                .Qn  (Qn[i])
            );
        end
    endgenerate

endmodule


// 8-bit I/O Register with Output Enable control
module IORegister8bit (
    input  wire [7:0] D,    // 8-bit data input bus
    input  wire OUT,        // Output enable (active-high)
    input  wire CLK,        // Clock input
    input  wire STR,        // Store enable
    input  wire RST,        // Asynchronous reset
    output wire [7:0] Q,    // 8-bit register output with tri-state control
    output wire [7:0] Qn,    // 8-bit complement output with tri-state control
    
    //debug    
    output [7:0] Q_internal   // Internal Q storage
);

    // Internal storage for the register values
    wire [7:0] Qn_internal;  // Internal Qn storage

    // Instantiate 8 individual register cells for internal storage
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : reg_array
            Register reg_cell (
                .D   (D[i]),
                .CLK (CLK),
                .STR (STR),
                .RST (RST),
                .Q   (Q_internal[i]),
                .Qn  (Qn_internal[i])
            );
        end
    endgenerate

    // Output control with tri-state logic
    // When OUT is high, output the stored values
    // When OUT is low, outputs are high impedance (Z)
    assign Q  = OUT ? Q_internal  : 8'bZZZZZZZZ;
    assign Qn = OUT ? Qn_internal : 8'bZZZZZZZZ;

endmodule


// 8-bit D Flip-Flop bank using individual DFF cells
module DFF8bit (
    input  wire [7:0] D,    // 8-bit data input bus
    input  wire CLK,        // Clock input (shared)
    input  wire RST,        // Asynchronous reset (shared, active-high)
    output wire [7:0] Q,    // 8-bit output bus
    output wire [7:0] Qn    // 8-bit complement output bus
);

    // Instantiate 8 individual DFF cells
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : dff_array
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

// 8-bit D Flip-Flop bank using individual DFF cells
module DFF4bit (
    input  wire [3:0] D,    // 8-bit data input bus
    input  wire CLK,        // Clock input (shared)
    input  wire RST,        // Asynchronous reset (shared, active-high)
    output wire [3:0] Q,    // 8-bit output bus
    output wire [3:0] Qn    // 8-bit complement output bus
);

    // Instantiate 8 individual DFF cells
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : dff_array
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


// Base INCReg module without tri-state control
module INCReg(
    input  wire [7:0] D,       // 8-bit data input bus
    input  wire CLK,           // Clock input
    input  wire STR,           // Store enable
    input  wire INC,           // Increment enable
    input  wire RST,           // Asynchronous reset
    output wire [7:0] Q,       // 8-bit register output (always driven)
    output wire [7:0] Qn,      // 8-bit complement output (always driven)
    output wire Carr_out       // Carry-out flag (high when increment wraps around)
);
    // Internal storage for the register values
    wire [7:0] Qn_internal;    // Internal Qn storage
    wire [7:0] Inc_Result;     // Incremented value
    wire [7:0] Carry;          // Internal carry chain
    
    // --- Increment logic (using HalfAdders) ---
    HalfAdderLSB ha0 (
        .A     (Q[0]),
        .Sum   (Inc_Result[0]),
        .Carry (Carry[0])
    );
    
    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin : inc_adders
            HalfAdder ha (
                .A     (Q[i]),
                .B     (Carry[i-1]),
                .Sum   (Inc_Result[i]),
                .Carry (Carry[i])
            );
        end
    endgenerate
    
    assign Carr_out = INC & Carry[7];
    
    // --- Input selection logic ---
    wire [7:0] D_mux = STR ? D : (INC ? Inc_Result : Q);
    
    // Instantiate 8 individual register cells for internal storage
    generate
        for (i = 0; i < 8; i = i + 1) begin : reg_array
            Register reg_cell (
                .D   (D_mux[i]),
                .CLK (CLK),
                .STR (STR | INC),   // Update on either Store or Increment
                .RST (RST),
                .Q   (Q[i]),
                .Qn  (Qn_internal[i])
            );
        end
    endgenerate
    
    // Direct assignment - no tri-state
    assign Qn = Qn_internal;
endmodule


// INCReg with output enable (tri-state control)
module INCRegEN(
    input  wire [7:0] D,       // 8-bit data input bus
    input  wire OUT,           // Output enable (active-high)
    input  wire CLK,           // Clock input
    input  wire STR,           // Store enable
    input  wire INC,           // Increment enable
    input  wire RST,           // Asynchronous reset
    output wire [7:0] Q,       // 8-bit register output with tri-state control
    output wire [7:0] Qn,      // 8-bit complement output with tri-state control
    output wire Carr_out       // Carry-out flag (high when increment wraps around)
);
    // Internal wires for base module outputs
    wire [7:0] Q_internal;
    wire [7:0] Qn_internal;
    
    // Instantiate the base INCReg module
    INCReg base_reg (
        .D        (D),
        .CLK      (CLK),
        .STR      (STR),
        .INC      (INC),
        .RST      (RST),
        .Q        (Q_internal),
        .Qn       (Qn_internal),
        .Carr_out (Carr_out)
    );
    
    // Add tri-state control
    assign Q  = OUT ? Q_internal  : 8'bZZZZZZZZ;
    assign Qn = OUT ? Qn_internal : 8'bZZZZZZZZ;
endmodule




