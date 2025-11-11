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
