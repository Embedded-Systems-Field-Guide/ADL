module uart_tx (
    input  wire clk,          // 12 MHz system clock
    input  wire reset_n,      // active-low reset (optional)
    input  wire trigger_i,    // send request (MCLR in top level)
    output reg  uart_txd,     // TX line (idle = '1')    
    output wire idle_o,
    input wire [7:0]  ToSend
);
    localparam CLK_PER_BIT = 1250;
    localparam BIT_CNT_W   = $clog2(CLK_PER_BIT);   // 11 bits
    
    assign idle_o = (state == IDLE);
    
    reg [BIT_CNT_W-1:0] baud_cnt;
    reg                 baud_tick;   // one-cycle pulse at 9600 Hz
    
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
    
    typedef enum logic [3:0] {
        IDLE   = 4'd0,
        START  = 4'd1,
        DATA0  = 4'd2,
        DATA1  = 4'd3,
        DATA2  = 4'd4,
        DATA3  = 4'd5,
        DATA4  = 4'd6,
        DATA5  = 4'd7,
        DATA6  = 4'd8,
        DATA7  = 4'd9,
        STOP   = 4'd10,
        DONE   = 4'd11
    } tx_state_t;
    
    tx_state_t state, next_state;
    reg [7:0]  shift_reg;
    reg [3:0]  bit_idx;      // 0-7 for data bits
    
    // Next-state logic
    always @* begin
        next_state = state;
        case (state)
            IDLE:   if (trigger_i)                 next_state = START;
            START:  if (baud_tick)                 next_state = DATA0;
            DATA0:  if (baud_tick)                 next_state = DATA1;
            DATA1:  if (baud_tick)                 next_state = DATA2;
            DATA2:  if (baud_tick)                 next_state = DATA3;
            DATA3:  if (baud_tick)                 next_state = DATA4;
            DATA4:  if (baud_tick)                 next_state = DATA5;
            DATA5:  if (baud_tick)                 next_state = DATA6;
            DATA6:  if (baud_tick)                 next_state = DATA7;
            DATA7:  if (baud_tick)                 next_state = STOP;
            STOP:   if (baud_tick)                 next_state = DONE;
            DONE:   if (baud_tick)                 next_state = IDLE;
            default:                               next_state = IDLE;
        endcase
    end
    
    // State register
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // Shift register load & TX output
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            uart_txd   <= 1'b1;      // idle high
            shift_reg  <= 8'h00;
            bit_idx    <= 4'd0;
        end else begin
            case (state)
                IDLE: begin
                    uart_txd <= 1'b1;
                    if (trigger_i) begin
                        shift_reg <= ToSend;
                        bit_idx   <= 4'd0;
                    end
                end
                
                START: begin
                    uart_txd <= 1'b0;                // start bit
                    // Prepare first data bit - don't shift yet!
                end
                
                DATA0, DATA1, DATA2, DATA3,
                DATA4, DATA5, DATA6, DATA7: begin
                    // Output current LSB
                    uart_txd <= shift_reg[0];
                    
                    // Only shift when moving to next bit (on baud_tick)
                    if (baud_tick && next_state != state) begin
                        shift_reg <= {1'b0, shift_reg[7:1]};
                        bit_idx   <= bit_idx + 1;
                    end
                end
                
                STOP: begin
                    uart_txd <= 1'b1;                // stop bit
                end
                
                DONE: begin
                    uart_txd <= 1'b1;
                end
                
                default: uart_txd <= 1'b1;
            endcase
        end
    end

endmodule


module uart_rx (
    input  wire clk,          // 12 MHz
    input  wire reset_n,
    input  wire uart_rxd,     // idle = '1'
    output reg  [7:0] RXBUF,   // received byte
    input  wire CLR_Flag,   // external signal to clear the flag
    output reg  RxFlag      // raised when a byte is received

);

    localparam CLK_PER_BIT     = 1250;                 // full bit
    localparam HALF_BIT        = CLK_PER_BIT / 2;      // 625
    localparam CNT_W           = $clog2(CLK_PER_BIT);

    reg [CNT_W-1:0] baud_cnt;
    reg            baud_tick;   // one-cycle pulse at 9600 Hz

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

    (* ASYNC_REG = "TRUE" *) reg [1:0] rxd_sync;
    always @(posedge clk or negedge reset_n)
        if (!reset_n) rxd_sync <= 2'b11;
        else          rxd_sync <= {rxd_sync[0], uart_rxd};

    wire rxd = rxd_sync[1];

    reg rxd_prev;
    always @(posedge clk) rxd_prev <= rxd;
    wire start_edge = rxd_prev & ~rxd;   // 1→0

    typedef enum logic [3:0] {
        IDLE,
        START_HALF,   // wait half-bit to centre of start bit
        START_FULL,   // wait full bit after centre-sample of start
        DATA,
        STOP
    } rx_state_t;

    rx_state_t state, next_state;

    always @* begin
        next_state = state;
        case (state)
            IDLE:       if (start_edge)               next_state = START_HALF;
            START_HALF: if (baud_tick)                next_state = START_FULL;
            START_FULL: if (baud_tick)                next_state = DATA;
            DATA:       if (baud_tick && bit_cnt==7)  next_state = STOP;
            STOP:       if (baud_tick)                next_state = IDLE;
            default:                                  next_state = IDLE;
        endcase
    end

    always @(posedge clk or negedge reset_n)
        if (!reset_n) state <= IDLE;
        else          state <= next_state;

    reg [2:0] bit_cnt;   // 0-7
    reg [7:0] shift_reg;

        always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            bit_cnt   <= 0;
            shift_reg <= 0;
            RXBUF     <= 0;
            RxFlag    <= 0;    // reset flag
        end else begin

            if (CLR_Flag)
                RxFlag <= 0;    // clear when commanded

            case (state)
                IDLE: bit_cnt <= 0;

                START_FULL: if (baud_tick) begin
                    shift_reg <= {rxd, shift_reg[7:1]};
                    bit_cnt   <= 1;
                end

                DATA: if (baud_tick) begin
                    shift_reg <= {rxd, shift_reg[7:1]};
                    bit_cnt   <= bit_cnt + 1;
                end

                STOP: if (baud_tick) begin
                    RXBUF  <= shift_reg;
                    RxFlag <= 1;    // raise flag when byte received
                end
            endcase
        end
    end


endmodule

module SerialDebug(
    input wire sysclk,
    output wire uart_rxd_out,
    input wire uart_txd_in,
    output wire SysCLR,
    input wire [7:0] Bus_A,Bus_B,Bus_C,Bus_D,Bus_E,Bus_F,Bus_G,Bus_H,Bus_I,Bus_J,Bus_K,Bus_L,Bus_M,
    output wire USR_Flag,
    output wire CLK2,
    output wire CLK3,
    output wire CLK4,
    output wire CLK5,
    output wire CLK6,
    output wire CLK7,   
    output wire CLK8,
    
    output wire [7:0] Buffer
);
    reg reset_n = 0;
    integer rst_cnt = 0;
    always @(posedge sysclk) begin
        if (rst_cnt < 100) begin
            rst_cnt <= rst_cnt + 1;
            reset_n <= 0;
        end else
            reset_n <= 1;
    end
    
    assign SysCLR = reset_n;
    
    wire RxFlag;
    wire uart_idle;
    
    reg [7:0] ToSend;
    reg [7:0] selected_bus;
    reg [2:0] send_index = 0;  // 3 bits for 0-4
    reg sending = 0;
    reg send_trigger = 0;
    reg prev_idle = 1;
    
    // Add edge detection for RxFlag to make it single-shot
    reg prev_RxFlag = 0;
    wire RxFlag_edge = RxFlag & ~prev_RxFlag;
    
    wire tx_ready = uart_idle & ~send_trigger;
    
    // Function to convert 8-bit value to decimal ASCII digits with CR+LF
    function [7:0] get_decimal_digit;
        input [7:0] value;
        input [2:0] digit_pos;  // 0=CR, 1=hundreds, 2=tens, 3=ones, 4=LF
        reg [7:0] hundreds, tens, ones;
        begin
            hundreds = value / 100;
            tens = (value / 10) % 10;
            ones = value % 10;
            
            case (digit_pos)
                0: get_decimal_digit = 8'h0D;  // Carriage Return '\r'
                1: get_decimal_digit = hundreds + 8'h30;  // ASCII '0' = 0x30
                2: get_decimal_digit = tens + 8'h30;
                3: get_decimal_digit = ones + 8'h30;
                4: get_decimal_digit = 8'h0A;  // Newline '\n'
                default: get_decimal_digit = 8'h30;
            endcase
        end
    endfunction
    
    always @(posedge sysclk) begin
        prev_idle <= uart_idle;
        prev_RxFlag <= RxFlag;
        
        if (!reset_n) begin
            sending <= 0;
            send_index <= 0;
            ToSend <= 8'h00;
            send_trigger <= 0;
            selected_bus <= 8'h00;
        end else begin
            // Start sending sequence only on rising edge of RxFlag
            if (RxFlag_edge & !sending) begin
                send_index <= 0;
                sending <= 1;
                send_trigger <= 0;
                
                // Capture the bus value based on received command
                case (Buffer)
                    8'h41: selected_bus <= Bus_A;  // 'A'
                    8'h42: selected_bus <= Bus_B;  // 'B'
                    8'h43: selected_bus <= Bus_C;  // 'C'
                    8'h44: selected_bus <= Bus_D;  // 'D'
                    8'h45: selected_bus <= Bus_E;  // 'E'
                    8'h46: selected_bus <= Bus_F;  // 'F'
                    8'h47: selected_bus <= Bus_G;  // 'G'
                    8'h48: selected_bus <= Bus_H;  // 'H'
                    8'h49: selected_bus <= Bus_I;  // 'I'
                    8'h4A: selected_bus <= Bus_J;  // 'J'
                    8'h4B: selected_bus <= Bus_K;  // 'K'
                    8'h4C: selected_bus <= Bus_L;  // 'L'
                    8'h4D: selected_bus <= Bus_M;  // 'M'
                    default: selected_bus <= 8'h00;
                endcase
            end 
            // While sending, wait for UART to be idle before triggering next byte
            else if (sending) begin
                if (tx_ready) begin
                    // Select character based on received byte and index
                    case (Buffer)
                        8'h30: begin // ASCII '0' -> send "\r( )\n"
                            case (send_index)
                                0: ToSend <= 8'h0D; // '\r'
                                1: ToSend <= 8'h28; // '('
                                2: ToSend <= 8'h20; // ' '
                                3: ToSend <= 8'h29; // ')'
                                4: ToSend <= 8'h0A; // '\n'
                            endcase
                        end
                        8'h31: begin // ASCII '1' -> send "\r[^]\n"
                            case (send_index)
                                0: ToSend <= 8'h0D; // '\r'
                                1: ToSend <= 8'h5B; // '['
                                2: ToSend <= 8'h5E; // '^'
                                3: ToSend <= 8'h5D; // ']'
                                4: ToSend <= 8'h0A; // '\n'
                            endcase
                        end

                        8'h41, 8'h42, 8'h43, 8'h44,  // 'A', 'B', 'C', 'D'
                        8'h45, 8'h46, 8'h47, 8'h48,  // 'E', 'F', 'G', 'H'
                        8'h49, 8'h49, 8'h4A, 8'h4B, 8'h4C, 8'h4D: begin // 'I', 'J', 'K', 'L', 'M'
                            // Send "\r" + decimal value (000-255) + "\n"
                            ToSend <= get_decimal_digit(selected_bus, send_index);
                        end
                        default: ToSend <= 8'h00;
                    endcase
                    
                    send_trigger <= 1;  // Trigger UART transmission
                    
                    // Move to next character or finish (now 5 characters: 0-4)
                    if (send_index < 4) begin
                        send_index <= send_index + 1;
                    end else begin
                        sending <= 0;
                        send_index <= 0;
                    end
                end else begin
                    send_trigger <= 0;  // Clear trigger after one cycle
                end
            end else begin
                send_trigger <= 0;
            end
        end
    end
    
    wire SendBack = sending;
    
    // Instantiate uart_tx with idle flag
    uart_tx uart_tx_inst (
        .clk(sysclk),
        .reset_n(reset_n),
        .trigger_i(send_trigger),
        .uart_txd(uart_rxd_out),
        .ToSend(ToSend),
        .idle_o(uart_idle)
    );
    
    uart_rx u_rx (
        .clk      (sysclk),
        .reset_n  (reset_n),
        .uart_rxd (uart_txd_in),   
        .RXBUF    (Buffer),
        .RxFlag   (RxFlag),
        .CLR_Flag (SendBack)
    );
    
    SRLatch USRFLag(
        .SYSCLK(sysclk),
        .Set(Buffer == 8'h31),
        .Reset(Buffer == 8'h30),
        .Q(USR_Flag)
    );
    
    SRLatch CLK2Latch(
        .SYSCLK(sysclk),
        .Set(Buffer == 8'h32),
        .Reset(Buffer == 8'h30),
        .Q(CLK2)
    );
    SRLatch CLK3Latch(
        .SYSCLK(sysclk),
        .Set(Buffer == 8'h33),
        .Reset(Buffer == 8'h30),
        .Q(CLK3)
    );
    SRLatch CLK4Latch(
        .SYSCLK(sysclk),
        .Set(Buffer == 8'h34),
        .Reset(Buffer == 8'h30),
        .Q(CLK4)
    );
    SRLatch CLK5Latch(
        .SYSCLK(sysclk),
        .Set(Buffer == 8'h35),
        .Reset(Buffer == 8'h30),
        .Q(CLK5)
    );
    SRLatch CLK6Latch(
        .SYSCLK(sysclk),
        .Set(Buffer == 8'h36),
        .Reset(Buffer == 8'h30),
        .Q(CLK6)
    );
    SRLatch CLK7Latch(
        .SYSCLK(sysclk),
        .Set(Buffer == 8'h37),
        .Reset(Buffer == 8'h30),
        .Q(CLK7)
    );
    SRLatch CLK8Latch(
        .SYSCLK(sysclk),
        .Set(Buffer == 8'h38),
        .Reset(Buffer == 8'h30),
        .Q(CLK8)
    );
endmodule