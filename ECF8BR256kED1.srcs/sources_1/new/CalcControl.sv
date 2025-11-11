
module InputControlSystem(
   input wire SYSCLK,
   input wire CLK_IN,
   input wire MCLR,
   
   //Opperation inputs
   input wire RST,
   input wire ADD,
   input wire SBT,
   input wire MULT,
   input wire DIV,
   input wire SR,
   input wire SL,
   input wire AND,
   input wire OR,
   input wire XOR,
   input wire NTA,
   input wire NTB,
   input wire CALC,
   input wire User_SM,
   input wire DontSubtract, //(ADD)
   
   output wire Operations,          //Assigned
   output wire LogicOperation,      //Asisgned
   output wire Adding,              //Assigned
   output wire Subtracting,         //Assigned
   output wire Multiplying,         //Assigned
   output wire Evaluating,          //Assigned
   output wire Dividing,            //Assigned
   output wire StoreA1,
   output wire StoreB1,
   output wire StoreA2,
   output wire CLR_DP,
   output wire ENMainInput,         //Assigned
   output wire SubtractALU,
   output wire SM
   
    
);


assign Operations = CLK_IN & (SR | SL | AND | OR| XOR |NTA | NTB);
assign CLR_DP = RST | MCLR;
wire OpenToStart = ~(Adding | Subtracting | Multiplying | Dividing| LogicOperation);

    SRLatch ActiveLatch (
        .SYSCLK(SYSCLK),
        .Set(RST),
        .Reset(MCLR),
        .Qn(DP_Inactive)  
    );
    
    
    SRLatch AddingLatch(
        .SYSCLK(SYSCLK),    
        .Set(CLK_IN & OpenToStart &ADD),       
        .Reset(CLR_DP),     
        .Q(Adding)         
    );
    
    SRLatch SubtractingLatch(
        .SYSCLK(SYSCLK),    
        .Set(CLK_IN & OpenToStart &SBT),      
        .Reset(CLR_DP),     
        .Q(Subtracting)         
    );

    SRLatch MultiplyingLatch(
        .SYSCLK(SYSCLK),    
        .Set(CLK_IN & OpenToStart &MULT),       
        .Reset(CLR_DP),     
        .Q(Multiplying),     
        .Qn(NTMultiplying)         
    );
    SRLatch DividngLatch(
        .SYSCLK(SYSCLK),    
        .Set(CLK_IN & OpenToStart &DIV),       
        .Reset(CLR_DP),     
        .Q(Dividing)         
    );
    SRLatch LogicOperationLatch(
        .SYSCLK(SYSCLK),    
        .Set(CLK_IN & OpenToStart & Operations),       
        .Reset(CLR_DP),     
        .Q(LogicOperation)         
    );
    SRLatch CalcLatch(
        .SYSCLK(SYSCLK),    
        .Set(CLK_IN & ~OpenToStart &CALC),       
        .Reset(CLR_DP),     
        .Q(Evaluating)         
    );
    
    
    assign ENMainInput = ~(CLR_DP | Evaluating);
    assign StoreA1 = ~(DP_Inactive | ~OpenToStart);
    assign StoreA2 = ~(NTMultiplying | Evaluating);
    
    assign StoreB1 = ~(OpenToStart | Evaluating | Multiplying);
    
    assign SM = User_SM | (Subtracting | Dividing);
    
    assign SubtractALU = (~DontSubtract & (Subtracting | Dividing));
    

endmodule 

module BasicLogic (
    input wire SR,
   input wire SL,
   input wire AND,
   input wire OR,
   input wire XOR,
   input wire NTA,
   input wire NTB,
   input wire LogicOperation,   
   input wire Adding,
   input wire Operations,
   input wire Evaluating,
   input wire Subtracting,
   
   output wire BasicLogicOut,
   
   output wire AStored,
   output wire BStored,
   output wire CStored
   
   
   

);

    assign BasicLogicOut = Evaluating & (Adding| Subtracting| LogicOperation);
    
    assign AStored = 1'b0;
    assign BStored = 1'b0;
    assign CStored = 1'b0;

endmodule 
