module UARTDriver(
    // System signals
    input  wire sysclk,          // System clock
    input  wire CLK_IN,          // Input clock (can be reduced clock)
    input  wire MCLR,            // Master clear/reset
    input  wire CLR,             // Additional clear signal
    
    // Data bus
    input  wire [7:0] DataBus,   // 8-bit data bus for configuration/data
    
    // Configuration signals
    input  wire StoreBR,         // Store baud rate divisor
    input  wire StoreBPS,        // Store baud prescaler
    input  wire STR_COMCON,      // Store COMCON register
    input  wire CLR_RXFlag,      // Clear RX flag
    
    // TX control signals
    input  wire Load,            // Load data into TX buffer
    input  wire SendTx,          // Start transmission
    
    // UART pins
    input  wire Rx,              // UART receive pin
    output wire Tx,              // UART transmit pin
    
    // Status and data outputs
    output wire RX_Flag,         // RX data ready flag
    output wire INTVector,        // Interrupt vector output
    input wire ReadRxBuf,
    output wire [7:0] RxBufRead,
    
    //Debug
    output wire [7:0] RxBuf
    
);

    // Internal wires
    wire UART_CLR = MCLR | CLR;
    wire TxBaudCLK,TxBaudCLKn;
    wire RxBaudCLK,RxBaudCLKn;
    wire EN_BAUD_TX, EN_BAUD_RX;
    wire EN_BAUD_TX_Raw, EN_BAUD_RX_Raw;
    
     Dlatch TxBAUDSync(
        .D(EN_BAUD_TX_Raw),     // Data input
        .EN(sysclk),    // Enable input (active-high)
        .Q(EN_BAUD_TX)
    );  
    
    Dlatch RxBAUDSync(
        .D(EN_BAUD_RX_Raw),     // Data input
        .EN(sysclk),    // Enable input (active-high)
        .Q(EN_BAUD_RX)
    );
    
    wire CLK_Sel, EN_RX, EN_RXINT;
    wire [7:0] COMCON;
    
    // RX signals
    wire RXCLK, RXINC, RXC_RST;
    wire [3:0] RXC;
    
    // TX signals
    wire TXCLK, TXINC, TXC_RST;
    wire StoreTxBuf, BUFLSB;
    wire [3:0] TXC;
    
    //=============================================================
    // Baudrate Generators
    //=============================================================
    BaudrateGenerator Txbaudgen(
        .SYSCLK(sysclk),
        .CLK_IN(CLK_IN),
        .CLK_Sel(CLK_Sel),
        .D(DataBus),
        .StoreBR(StoreBR),
        .StoreBPS(StoreBPS),
        .CLR(UART_CLR),
        .Enable(EN_BAUD_TX),
        .BaudCLK(TxBaudCLK),
        .BaudCLKn(TxBaudCLKn)
    );
    
    BaudrateGenerator Rxbaudgen(
        .SYSCLK(sysclk),
        .CLK_IN(CLK_IN),
        .CLK_Sel(CLK_Sel),
        .D(DataBus),
        .StoreBR(StoreBR),
        .StoreBPS(StoreBPS),
        .CLR(UART_CLR),
        .Enable(EN_BAUD_RX),
        .BaudCLK(RxBaudCLK),
        .BaudCLKn(RxBaudCLKn)
    );
    
    //=============================================================
    // COMCON Register
    //=============================================================
    Register8bit ComCon_inst(
        .D(DataBus),
        .CLK(CLK_IN),
        .STR(STR_COMCON),
        .RST(UART_CLR),
        .Q(COMCON)
    );
    
    // COMCON bit assignments
    assign EN_RX = COMCON[0];
    assign EN_RXINT = COMCON[1];
    assign CLK_Sel = COMCON[2];
    
    //=============================================================
    // RX Section
    //=============================================================
    RxCTRL RxController_inst(
        .SYSCLK(sysclk),
        .RXINC(RXINC),
        .RXC_RST(RXC_RST),
        .RXC(RXC),
        .EN_RX(EN_RX),
        .EN_RXINT(EN_RXINT),
        .BCLK(RxBaudCLK),
        .BCLK_n(RxBaudCLKn),
        .CLRF(CLR_RXFlag),
        .CLR(CLR),
        .EN_BAUD(EN_BAUD_RX_Raw),
        .INTVector(INTVector),
        .RX_Flag(RX_Flag),
        .Rx(Rx),
        .RXCLK(RXCLK),
        .UART_CLR(UART_CLR)
    );
    
    RxBuf RXBuffer(
        .D(Rx),
        .CLK(RXCLK),
        .CLR(UART_CLR),
        .RegOut(RxBuf)
    );
    
    Counter4bit RxCounter_inst(
        .INC(RXINC),
        .TC_RST(RXC_RST),
        .TC(RXC)
    );
    
    //=============================================================
    // TX Section
    //=============================================================
    TxCTRL TxController_inst(
        .SYSCLK(sysclk),
        .TXINC(TXINC),
        .TXC_RST(TXC_RST),
        .TXC(TXC),
        .BCLK_n(TxBaudCLKn),
        .EN_BAUD(EN_BAUD_TX_Raw),
        .Tx(Tx),
        .SendTx(SendTx),
        .BUFLSB(BUFLSB),
        .CLK_IN(CLK_IN),
        .Load(Load),
        .TXCLK(TXCLK),
        .StoreTxBuf(StoreTxBuf),
        .UART_CLR(UART_CLR)
    );
    
    Counter4bit TxCounter_inst(
        .INC(TXINC),
        .TC_RST(TXC_RST),
        .TC(TXC)
    );
    
    TxBuffer TxBuffer_inst(
        .DataBus(DataBus),
        .Shift(EN_BAUD_TX),
        .Load(Load),
        .CLK(TXCLK),
        .STR(StoreTxBuf),
        .CLR(UART_CLR),
        .Serial_out(BUFLSB)
    );
    
        //=============================================================
        // Read Rx Buffer
        //=============================================================
    
        BusBuffer RXBusBuffer (
//            .Bus(RxBuf),    // Input bus
            .Bus(8'd52),    // Input bus
            .Enable(ReadRxBuf), // Enable signal (active-high)
            .out(RxBufRead)     // Output bus (tri-state)
        );

endmodule


module RxCTRL(  
    input wire SYSCLK,
   
    output wire RXINC,          
    output wire RXC_RST,        
    input  wire [3:0] RXC,       
     
    input wire EN_RX,           
    input wire EN_RXINT,        
    
    input wire BCLK,
    input wire BCLK_n,
    
    input wire CLRF,            
    input wire CLR,             
       
    output wire EN_BAUD,        
    output wire INTVector,      
    output wire RX_Flag,        
     
    input wire Rx,              
    
    output wire RXCLK,          
    input wire UART_CLR,        
    
    //debug
    
    output wire StopCondition
       

        
);
    wire [3:0] rxc_debug = RXC;  // Prevent optimisation
    wire StopRx = (RXC[3] & ~RXC[2] &RXC[1] &~RXC[0]);
   
    assign RXINC = EN_BAUD & BCLK;
    

    SRLatch StopRxLatch(
        .SYSCLK(SYSCLK),    
        .Set(StopRx),    
        .Reset(RXC_RST),    
        .Q(StopCondition)         
    );
        
    SRLatch RXActivelLtch(
    .SYSCLK(SYSCLK),    
    .Set(~(~EN_RX | EN_BAUD | Rx)),       
    .Reset(UART_CLR| (StopCondition & BCLK_n)),     
    .Q(EN_BAUD),         
    .Qn(RXC_RST)         
);
    
    assign RXCLK = RXINC & ~StopCondition; 
    
    SRLatch RXFlag(
        .SYSCLK(SYSCLK),    
        .Set(StopRx),       
        .Reset(CLRF | UART_CLR),     
        .Q(RX_Flag)     
    ); 
    
    assign INTVector = EN_RXINT & RX_Flag;

    
    
endmodule 


                
module TxCTRL( 
   input wire SYSCLK,
   
    output wire TXINC,          
    output wire TXC_RST,        
    input  wire [3:0] TXC,       
     
    input wire BCLK_n,
                          
    
    output wire EN_BAUD,          
     
    input wire Tx,
    input wire SendTx,
    input wire Load,    
    input wire BUFLSB,    
    input wire UART_CLR,  
    input wire CLK_IN,     
    
    output wire TXCLK,   
    output wire StoreTxBuf,
    
    //debug
    output wire SendTxBuffer,
    output wire StopCondition
);
    wire [3:0] TXC_debug = TXC;  
    assign StopCondition = (TXC[3] & ~TXC[2] &TXC[1] &TXC[0]);
    wire TxStop = UART_CLR | StopCondition;
    
    
    reg SendTx_d;

    always @(posedge SYSCLK or posedge UART_CLR)
    begin
        if (UART_CLR)
            SendTx_d <= 1'b0;
        else
            SendTx_d <= SendTx;
    end
    
    wire SendTx_rise = SendTx & ~SendTx_d;  // 1-cycle pulse on rising edge
    
    
    DFF SendBuffer (
        .D(1'b1),
        .CLK(SendTx_rise),
        .RST(TxStop),
        .Q(SendTxBuffer),
        .Qn(ResetTxActive)
    );
    
    
    
    SRLatch TxActivelatch(
        .SYSCLK(SYSCLK),    
        .Set(SendTxBuffer & BCLK_n),       
        .Reset(ResetTxActive),     
        .Q(EN_BAUD),         
        .Qn(TXC_RST)         
    );
    
    assign Tx = ( TXC_RST| (BUFLSB & EN_BAUD));
    assign StoreTxBuf = (Load | EN_BAUD);
    assign TXINC = BCLK_n & EN_BAUD;
    assign TXCLK = ( (CLK_IN & TXC_RST) | (TXINC & EN_BAUD));

endmodule 


module TxDriver (
    input  wire [7:0] D,          // 8-bit data input bus
    input  wire clk,              // System clock (12 MHz)
    input  wire reset_n,          // Active-low reset
    input  wire StoreTxBuf,       // Store/send trigger (pulse on rising edge)
    output reg  uart_txd,         // UART TX line (idle = '1')
    output wire idle_o            // High when idle, low when transmitting
);

    // Baud rate generator for 9600 baud @ 12 MHz
    localparam CLK_PER_BIT = 1250;
    localparam BIT_CNT_W   = $clog2(CLK_PER_BIT);
    
    reg [BIT_CNT_W-1:0] baud_cnt;
    reg                 baud_tick;
    
    // Generate baud tick (9600 Hz pulse)
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            baud_cnt  <= 0;
            baud_tick <= 0;
        end else begin
            if (baud_cnt == CLK_PER_BIT-1) begin
                baud_cnt  <= 0;
                baud_tick <= 1;
            end else begin
                baud_cnt  <= baud_cnt + 1;
                baud_tick <= 0;
            end
        end
    end
    
    // 11-bit shift register: [10]=buffer, [9]=buffer, [8]=start, [7:0]=data, stop bit shifts in as '1'
    // Format: 11_0_D[7:0]_1 when loaded
    // As it shifts right, eventually becomes: 11111111111 (all idle)
    reg [10:0] shift_reg;
    reg        transmitting;
    
    assign idle_o = ~transmitting;
    
    // Edge detection for StoreTxBuf
    reg store_prev;
    wire store_edge = StoreTxBuf & ~store_prev;
    
    // add:
    reg [3:0] bits_left;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            shift_reg <= 11'b11111111111; // All 1s (idle state)
            transmitting <= 0;
            uart_txd <= 1'b1;
            store_prev <= 0;
            bits_left <= 0;
        end else begin
            store_prev <= StoreTxBuf;

            // Load new frame on rising edge of StoreTxBuf when idle
            if (store_edge && !transmitting) begin
                // Correct load: LSB = start bit (0), then data LSB..MSB, then stop/idle '1's
                shift_reg <= {2'b11, D, 1'b0}; // 11 bits: [10]=1,[9]=1,[8]=D7,...,[1]=D0,[0]=0
                transmitting <= 1;
                bits_left <= 11;
                uart_txd <= 1'b1; // keep idle until first baud tick
            end
            // Shift out data on baud tick
            else if (transmitting && baud_tick) begin
                uart_txd <= shift_reg[0]; // Output LSB (start first)
                shift_reg <= {1'b1, shift_reg[10:1]}; // Shift right, fill with '1' (stop/idle)
                bits_left <= bits_left - 1;
                if (bits_left == 1) begin
                    transmitting <= 0; // we've just sent the last bit
                end
            end
            else if (!transmitting) begin
                uart_txd <= shift_reg[0]; // Continuously output '1' when idle
            end
        end
    end



endmodule