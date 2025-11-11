`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/10/2025 06:54:13 PM
// Design Name: 
// Module Name: ALUMux
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// ALUMux.sv - ALU Output Multiplexer using Bus Buffers

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

    // Instantiate 8 BusBuffer modules from Utils.sv
    BusBuffer buf_sum (
        .Bus(SUM),
        .Enable(Sel_SUM),
        .out(ALU_Out)
    );
    
    BusBuffer buf_and (
        .Bus(AND),
        .Enable(Sel_AND),
        .out(ALU_Out)
    );
    
    BusBuffer buf_or (
        .Bus(OR),
        .Enable(Sel_OR),
        .out(ALU_Out)
    );
    
    BusBuffer buf_xor (
        .Bus(XOR),
        .Enable(Sel_XOR),
        .out(ALU_Out)
    );
    
    BusBuffer buf_nota (
        .Bus(NOTA),
        .Enable(Sel_NOTA),
        .out(ALU_Out)
    );
    
    BusBuffer buf_notb (
        .Bus(NOTB),
        .Enable(Sel_NOTB),
        .out(ALU_Out)
    );
    
    BusBuffer buf_shift_right (
        .Bus(ShiftRight),
        .Enable(Sel_ShiftRight),
        .out(ALU_Out)
    );
    
    BusBuffer buf_shift_left (
        .Bus(ShiftLeft),
        .Enable(Sel_ShiftLeft),
        .out(ALU_Out)
    );

endmodule
