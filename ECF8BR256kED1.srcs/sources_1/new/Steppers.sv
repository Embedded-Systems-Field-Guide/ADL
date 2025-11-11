
module SteppeModule(
        input wire CLR,
        input wire CLK,
        
        output wire CurrentStep,
        output wire CurrentStepN,
        input wire PrevStep,
        
        output wire CurrentOR,
        input wire NextOR
        
    );
    
    DFF StepLatch(
        .D(PrevStep &CurrentStepN),
        .CLK(CLK),
        .RST(CLR),
        .Q(CurrentStep)
    );
    assign CurrentOR = (NextOR |CurrentStep);
    assign CurrentStepN = ~ CurrentOR;
    
endmodule


module StepChain #(
    parameter N = 3
)(
    input  wire CLK,
    input  wire CLR,
    output wire [N:0] StepBus   // Step 0..N (includes CurrentStepN[0])
);

    // Internal interconnects
    wire [N-1:0] CurrStep;
    wire [N-1:0] CurrStepN;
    wire [N-1:0] CurrOR;

    // OR chaining requires N wires + 1 for terminal (NextOR)
    wire [N:0] OR_chain;
    assign OR_chain[N] = 1'b0; // final termination

    // generate N step modules
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : StepGen
            SteppeModule StepUnit (
                .CLR(CLR),
                .CLK(CLK),
                .CurrentStep(CurrStep[i]),
                .CurrentStepN(CurrStepN[i]),
                .PrevStep((i == 0) ? 1'b1 : CurrStep[i-1]), // first module enabled
                .CurrentOR(OR_chain[i]),
                .NextOR(OR_chain[i+1])
            );
        end
    endgenerate


    assign StepBus = { CurrStep, CurrStepN[0] };

endmodule



module CountControl(
    input wire sysclk,
    input wire MCLR,
    input wire CLK,
    input wire CLKn,
    
    input wire [2:0] Cycles,
   
    output wire [3:0] StepBus,
    
    output wire Run
);



    wire RunCondtition = ( (StepBus[1] & Cycles[0]) | (StepBus[2] & Cycles[1]) | (StepBus[3] & Cycles[2]) );
    
    wire RunN;
    wire EdgeDetected;
    // Instantiate 4Step version of StepChain
    StepChain #(.N(3)) ThreeStep (
        .CLK(CLK),
        .CLR(MCLR| (RunCondtition & CLKn)),
        .StepBus(StepBus)
    );
    
    DFF EdgeDetection (
        .D(EdgeDetected),
        .CLK(CLK),
        .RST((RunN & CLKn) | MCLR),
        .Qn(EdgeDetected)
    );
    
    
    SRLatch RunLatch (
        .Set(RunCondtition),
        .Reset( ~RunCondtition & EdgeDetected),
        .SYSCLK(sysclk),
        .Q(Run),
        .Qn(RunN)
    );
    
    
    


endmodule 
