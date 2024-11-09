`timescale 1ns / 1ps

module add_sub(
    input [15:0] oper1_in, [15:0] oper2_in,
    input clk,
    input add,
    output [39:0] sum,
    output [39:0] dbgA, [39:0] dbgB,
    output reg [4:0] outExpo,
    output reg outSign,
    output [4:0] dbg
    );
    
    wire aSign = oper1_in[15];
    wire bSign = oper2_in[15];
    wire [4:0] aExpo = oper1_in[14:10];
    wire [4:0] bExpo = oper2_in[14:10];
    wire [9:0] aMant = oper1_in[9:0];
    wire [9:0] bMant = oper2_in[9:0];
    
    // Calculate the difference between both exponents
    wire [4:0] gExpo, lExpo, diffExpo;
    
    assign gExpo = (aExpo > bExpo) ? aExpo : bExpo;
    assign lExpo = (aExpo > bExpo) ? bExpo : aExpo;
    assign diffExpo = gExpo - lExpo;
    
    // We subtract 1 to ensure normal +/- denormal arthimetic is correct
    wire [4:0] diff, diff_pre;
    assign diff_pre = (aExpo == 4'b0000 || bExpo == 4'b0000) ? diffExpo - 1: diffExpo;
    assign diff = (aExpo == 4'b0000 && bExpo == 4'b0000) ? 2'b0000 : diff_pre;
    
    assign dbg = diff_pre;
    // Denormal Present?
    // 0 == denormal, 1 == normal
    wire op_dn;
    assign op_dn = |lExpo;
    
    // Get Smaller Mantissa
    wire [9:0] lMant, gMant;
    assign lMant = (aExpo > bExpo) ? bMant : aMant;
    assign gMant = (aExpo > bExpo) ? aMant : bMant;
    // Create a Temp Mantissa with 40 bits
    wire [39:0] tempShft;
    assign tempShft = { {op_dn}, {lMant}, {16'b0} };
    
    // Ensure we aren't over shifting bits out
    wire [4:0] shftAmnt;
    assign shftAmnt = (diff > 31) ? 5'b11111 :  diff;
    
    // Bit Shift to align mantissas
    wire [39:0] postShft;
    assign postShft = tempShft >> shftAmnt;
    
    // Use sticky bit to keep precision
    reg sticky;
    integer i;
    
    always @(*) begin
        sticky = 1'b0;
        for (i = 0; i < shftAmnt; i = i + 1) begin
            sticky = sticky || tempShft[i];
        end
    end

    
    // The final post normalized smaller value with aligned mantissa
    wire [39:0] finalA, finalB;
    assign finalA = (aExpo < bExpo) ? { {postShft[39:1]}, {postShft[0] | sticky} } : { {op_dn}, {gMant}, {16'b0} };
    assign finalB = (aExpo > bExpo) ? { {postShft[39:1]}, {postShft[0] | sticky} } : { {op_dn}, {gMant}, {16'b0} };
    
    wire [2:0] sign;
    assign sign = aSign & bSign & add;
    
    always @(*) begin
        case(sign) 
            // Addition
            3'b001: outSign = 0;
            3'b011: outSign = (bMant > aMant) ? 1 : 0;
            3'b101: outSign = (bMant > aMant) ? 0 : 1;
            3'b111: outSign = 1;
            
            // Subtraction
            3'b000: outSign = 0;
            3'b010: outSign = 1;
            3'b100: outSign = 1;
            3'b110: outSign = 0;
            
            default: outSign = 0;
        endcase
   end
    
    // if expa == expb and fracta == fractb and denorm exp = 1 else exp = larger exp
    always @(posedge(clk)) begin
        if ((aExpo == bExpo) & (aMant == bMant) & (op_dn == 1)) 
            outExpo = 1;
        else
            outExpo = gExpo;
    
    end
       
    assign dbgA = finalA;
    assign dbgB = finalB;
    assign sum = (add) ? finalA + finalB : finalA - finalB;
    
    
endmodule
