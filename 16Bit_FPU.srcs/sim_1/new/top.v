`timescale 1ns / 1ps

module add_sub_tb;

    reg [15:0] oper1_in;
    reg [15:0] oper2_in;
    reg add;
    reg clk;


    wire [39:0] sum, dbgA, dbgB;
    wire [4:0] outExpo;
    wire outSign;
    wire [4:0] dbg;

    // Instantiate the Unit Under Test (UUT)
    add_sub uut (
        .oper1_in(oper1_in), 
        .oper2_in(oper2_in), 
        .clk(clk), 
        .add(add), 
        .sum(sum), 
        .dbgA(dbgA),
        .dbgB(dbgB),
        .outExpo(outExpo), 
        .outSign(outSign),
        .dbg(dbg)
    );

 
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Stimulus
    initial begin

        oper1_in = 16'b0;
        oper2_in = 16'b0;
        add = 1'b0;

        #10;

        // Apply test cases
        oper1_in = 16'b0100000010000000;  
        oper2_in = 16'b0100010110000000;  
        add = 1'b1;                    
        #20;                              

        $finish;
    end

endmodule
