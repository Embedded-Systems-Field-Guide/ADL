module RamModule (
    inout  wire Data,    // 1-bit bidirectional data bus
    input  wire I,       // Input/Write enable (acts as CLK for latch when writing)
    input  wire O,       // Output enable (when high, outputs stored data to bus)
    input  wire RST      // Reset signal (active-high)
);

    // Internal signals
    wire stored_data;    // The stored bit from the latch
    wire stored_data_n;  // Complement of stored data (unused but available)
    
    // Data latch with reset to store the bit
    // When I is high, the latch is transparent and stores whatever is on Data
    // When I is low, the latch holds its previous value
    Dlatch storage_latch (
        .D(Data),        // Data input comes from the bidirectional bus
        .EN(I),          // Write enable - when high, latch is transparent
        .Q(stored_data), // Stored data output
        .Qn(stored_data_n) // Complement output (not used)
    );
    
    // Tri-state output control
    // When O is high: drive the stored data onto the bus
    // When O is low: high-impedance (allows other devices to drive the bus)
    assign Data = O ? stored_data : 1'bZ;

endmodule

// Updated RamModule8bit with coordinate selection (fixed the duplicate wire issue)
module RamModule8bit (
    inout  wire [7:0] Data,    // 8-bit bidirectional data bus
    input  wire I,             // Input/Write enable (shared by all bits)
    input  wire O,             // Output enable (shared by all bits)
    input  wire x,             // x Coordinate select
    input  wire y              // y Coordinate select
);
    // Internal wires for cell selection
    wire SelCell = (x & y);         // Cell is selected when both x AND y are high
    wire CellIn = (SelCell & I);    // Write enable when cell is selected AND I is high
    wire CellOut = (SelCell & O);   // Output enable when cell is selected AND O is high
    
    // Instantiate 8 individual 1-bit RAM modules
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : ram_bit_array
            RamModule ram_bit (
                .Data(Data[i]),    // Individual data bit
                .I(CellIn),        // Cell-specific write enable
                .O(CellOut)        // Cell-specific output enable
            );
        end
    endgenerate
endmodule

// 256-byte RAM array (16x16 grid of 8-bit cells)
module RAMCells256 (
    inout  wire [7:0] Data,    // 8-bit bidirectional data bus (shared by all cells)
    input  wire [15:0] x,      // x Coordinate (one-hot encoded, 16 bits)
    input  wire [15:0] y,      // y Coordinate (one-hot encoded, 16 bits)
    input  wire I,             // Input/Write enable (shared by all cells)
    input  wire O              // Output enable (shared by all cells)
);

    // Generate 16x16 grid of RAM cells
    genvar row, col;
    generate
        for (row = 0; row < 16; row = row + 1) begin : ram_rows
            for (col = 0; col < 16; col = col + 1) begin : ram_cols
                RamModule8bit ram_cell (
                    .Data(Data),    // All cells share the same 8-bit data bus
                    .I(I),          // All cells share the same write enable
                    .O(O),          // All cells share the same output enable
                    .x(x[col]),     // Each column gets its specific x coordinate bit
                    .y(y[row])      // Each row gets its specific y coordinate bit
                );
            end
        end
    endgenerate

endmodule

// Address decoder to convert 8-bit address to 16-bit one-hot x,y coordinates
module AddressDecoder (
    input  wire [7:0] Address,   // 8-bit address input
    output wire [15:0] x,        // 16-bit one-hot x coordinate
    output wire [15:0] y         // 16-bit one-hot y coordinate
);
    
    // Split the 8-bit address into 4-bit x and y components
    wire [3:0] x_addr = Address[3:0];   // Lower 4 bits for x coordinate
    wire [3:0] y_addr = Address[7:4];   // Upper 4 bits for y coordinate
    
    // Use 4-bit decoders to convert to one-hot encoding
    Decoder4bit x_decoder (
        .in(x_addr),
        .out(x)
    );
    
    Decoder4bit y_decoder (
        .in(y_addr),
        .out(y)
    );
    
endmodule

// Complete 256-byte RAM module with 8-bit addressing
module RAM256 (

    // System signals
    input  wire CLK,          // System clock
    input  wire MCLR,            // Master clear
    
    
    inout  wire [7:0] Data,      // 8-bit bidirectional data bus
    input  wire WE,              // Write Enable
    input  wire OE,               // Output Enable
    input  wire StoreMAR    //Sore databus in memory access register
    
);
    
    
    wire [7:0] Address;   // 8-bit address (0-255)
        // Instantiate TReg Register (8-bit)
    Register8bit MAR (
        .D   (Data),            // Shared data bus
        .CLK (CLK),       // Shared clock
        .STR (StoreMAR),    // Store TReg signal
        .RST (MCLR),      // Reset from timer controller
        .Q   (Address),         // Timer register output
        .Qn  ()   // Unused complement
    );
    
    
    // Internal coordinate signals
    wire [15:0] x_coords, y_coords;
    
    // Address decoder
    AddressDecoder addr_dec (
        .Address(Address),
        .x(x_coords),
        .y(y_coords)
    );
    
    // RAM cell array
    RAMCells256 ram_array (
        .Data(Data),
        .x(x_coords),
        .y(y_coords),
        .I(WE),
        .O(OE)
    );
    
endmodule




// Simple synthesiser-friendly 256 x 8 RAM
// - synchronous write on rising CLK when WE is asserted
// - asynchronous reset clears memory (optional behaviour)
// - read is combinational from memory[Address] but the output driving the external bus
//   is controlled by OE so internal tristates are avoided.

module RAM256_sync (
    input  wire        CLK,       // system clock
    input  wire        MCLR,      // async reset (active-high) - optional clear behaviour
    inout  wire [7:0]  Data,      // external 8-bit bidirectional data bus
    input  wire        WE,        // write enable (write on rising CLK when WE==1)
    input  wire        OE,        // output enable: when 1, RAM drives Data
    input  wire [7:0]  Address    // 8-bit address (drive from external MAR)
);

    // Internal memory array
    reg [7:0] mem [0:255];

    // Registered read data (combinational read is fine, but registering can help timing)
    reg [7:0] read_data;

    integer i;

    // Optional: asynchronous clear of memory (expensive in synthesis; keep only if really required)
    // If you do not want memory cleared on reset, delete the initial/reset block below.
    always @(posedge CLK or posedge MCLR) begin
        if (MCLR) begin
            // clear memory - take care: clearing 256 bytes may infer extra resources
            for (i = 0; i < 256; i = i + 1)
                mem[i] <= 8'h00;
            read_data <= 8'h00;
        end else begin
            // synchronous write
            if (WE) begin
                mem[Address] <= Data; // write from external bus (assumes Data is valid when WE asserted)
            end
            // optional: register the read for stable output timing
            read_data <= mem[Address];
        end
    end

    // Drive the external bus only at top level and only when OE asserted.
    // This avoids internal tristates per cell and removes loops.
    assign Data = OE ? read_data : 8'bz;

endmodule
