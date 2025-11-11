// ALURegs.sv - 4 Register8bit modules with multiplexed outputs
module ALURegs (
    input  wire [7:0] D,        // Shared 8-bit data input bus
    input  wire CLK,            // Shared clock input
    input  wire RST,            // Shared asynchronous reset
    
    // Individual store enables for each register
    input  wire STR_A1,         // Store enable for register A1
    input  wire STR_A2,         // Store enable for register A2
    input  wire STR_B1,         // Store enable for register B1
    input  wire STR_B2,         // Store enable for register B2
    
    // Multiplexer select signals
    input  wire Sel_A1,         // Select A1 for BUS_A output (when high)
    input  wire Sel_A2,         // Select A2 for BUS_A output (when high)
    input  wire Sel_B1,         // Select B1 for BUS_B output (when high)
    input  wire Sel_B2,         // Select B2 for BUS_B output (when high)
    
    // Output buses
    output reg [7:0] BUS_A,     // Multiplexed output bus A (A1 or A2)
    output reg [7:0] BUS_B,     // Multiplexed output bus B (B1 or B2)
    input wire LSBA,
    input wire LSBB,
        
    // Direct register outputs (bypass multiplexers)
    output wire [7:0] REGA1,    // Direct output from register A1
    output wire [7:0] REGA2,    // Direct output from register A2
    output wire [7:0] REGB1,    // Direct output from register B1
    output wire [7:0] REGB2     // Direct output from register B2
    

);
    // Internal register outputs
    wire [7:0] Q_A1, Q_A2, Q_B1, Q_B2;
    wire [7:0] Qn_A1, Qn_A2, Qn_B1, Qn_B2; // Complement outputs (not used)
    
    // Instantiate the 4 Register8bit modules
    Register8bit reg_A1 (
        .D   (D),
        .CLK (CLK),
        .STR (STR_A1),
        .RST (RST),
        .Q   (Q_A1),
        .Qn  (Qn_A1)
    );
    
    Register8bit reg_A2 (
        .D   (D),
        .CLK (CLK),
        .STR (STR_A2),
        .RST (RST),
        .Q   (Q_A2),
        .Qn  (Qn_A2)
    );
    
    Register8bit reg_B1 (
        .D   (D),
        .CLK (CLK),
        .STR (STR_B1),
        .RST (RST),
        .Q   (Q_B1),
        .Qn  (Qn_B1)
    );
    
    Register8bit reg_B2 (
        .D   (D),
        .CLK (CLK),
        .STR (STR_B2),
        .RST (RST),
        .Q   (Q_B2),
        .Qn  (Qn_B2)
    );
    
    // Connect direct outputs (bypass multiplexers)
    assign REGA1 = Q_A1;
    assign REGA2 = Q_A2;
    assign REGB1 = Q_B1;
    assign REGB2 = Q_B2;
    
// Bus multiplexers using BusMux modules
wire [7:0] mux_out_A;  // Internal wire for mux A output
wire [7:0] mux_out_B;  // Internal wire for mux B output

BusMux mux_A (
    .A    (Q_A1),
    .SelA (Sel_A1),
    .B    (Q_A2),
    .SelB (Sel_A2),
    .out  (mux_out_A)
);

BusMux mux_B (
    .A    (Q_B1),
    .SelA (Sel_B1),
    .B    (Q_B2),
    .SelB (Sel_B2),
    .out  (mux_out_B)
);
    
//assign BUS_A = {mux_out_A[7:1], mux_out_A[0] | LSBA};
//assign BUS_B = {mux_out_B[7:1], mux_out_B[0] | LSBB};
assign BUS_A = mux_out_A;
assign BUS_B = mux_out_B;
endmodule



module ALUInputMux(

    input wire CLR,

    output  wire LSBA,
    input wire MultLSBA,
    input wire CDLSBA,
    
    output  wire LSBB,
    
    output  wire OutA1,
    input wire LOOutA1,
    input wire MultOutA1,
    input wire CDOutA1,
    input wire NDOutA1,
    input wire SDROutA1,
    
    
    output  wire OutB1,
    input wire LOOutB1,
    input wire MultOutB1,
    input wire CDOutB1,
    input wire NDOutB1,
    
    output  wire OutB2,
    input wire MultOutB2,
    input wire CDOutB2,
    input wire SDROutB2,
    
    output  wire StoreA1,
    input wire ICSStoreA1,
    input wire NDStoreA1,
    input wire CDStoreA1,
    input wire SDRStoreA1,
    
    
    output  wire StoreB1,
    input wire ICSStoreB1,
    input wire MultStoreB1,
    input wire NDStoreB1,
    
    output  wire StoreB2,
    input wire MultStoreB2,
    input wire CDStoreB2,
    input wire SDRStoreB2,
    
    output wire OutALU,
    input wire LOOutALU,
    input wire MultOutALU,
    input wire NDOutALU,
    input wire CDOutALU,
    input wire SDROutALU,
    
    output wire OutDP,
    input wire LOOutDP,
    input wire MultOutDP,
    input wire SDROutDP,
    
    output wire Neg_A,
    input wire NDNeg_A,
    input wire SDRNeg_A,
    
    output wire DontSubtract,
    input wire NDNotDontSubtract,
    input wire CDNotDontSubtract,
    input wire SDRNotDontSubtract
    
    
);

assign LSBA = MultLSBA | CDLSBA;
assign LSBB = Neg_A;

assign OutA1 = LOOutA1| MultOutA1 | CDOutA1 | NDOutA1 | SDROutA1;
assign OutB1 = LOOutB1|MultOutB1|MultOutB1|CDOutB1|NDOutB1;
assign OutB2 = MultOutB2|CDOutB2||SDROutB2;

assign StoreA1 =  ICSStoreA1|  NDStoreA1|CDStoreA1|SDRStoreA1;
assign StoreB1 =   ICSStoreB1|MultStoreB1|NDStoreB1;
assign StoreB2 = MultStoreB2 | CDStoreB2 | SDRStoreB2;

assign OutALU = LOOutALU|MultOutALU|NDOutALU|CDOutALU|SDROutALU;
assign  OutDP = LOOutDP|MultOutDP|SDROutDP;
 assign Neg_A = NDNeg_A |  SDRNeg_A;
assign DontSubtract = NDNotDontSubtract | CDNotDontSubtract | SDRNotDontSubtract;

endmodule