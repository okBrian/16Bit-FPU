`timescale 1ns / 1ps

module pre_norm(
    input [15:0] oper1_in, [15:0] oper2_in,
    input clk,
    input add,
    output reg [5:0] outExpo,
    output reg outSign,
    output reg [39:0] outMantBig, reg [39:0] outMantSmall
    );
    
    wire aSign = oper1_in[15];
    wire bSign = oper2_in[15];
    wire [5:0] aExpo = oper1_in[14:10];
    wire [5:0] bExpo = oper2_in[14:10];
    wire [9:0] aMant = oper1_in[9:0];
    wire [9:0] bMant = oper2_in[9:0];
    
    // Calculate the difference between both exponents
    wire [5:0] gExpo, lExpo, diffExpo;
    assign gExpo = (aExpo > bExpo) ? aExpo : bExpo;
    assign lExpo = (aExpo > bExpo) ? bExpo : aExpo;
    assign diffExpo = gExpo - lExpo;
    
    // We subtract 1 to ensure normal +/- denormal arthimetic is correct
    wire [5:0] diff;
    assign diff = (aExpo == 5'b00000 ^ bExpo == 5'b00000) ? diffExpo : diffExpo - 1;
    
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
    wire [5:0] shftAmnt;
    assign shftAmnt = (diff > 40) ? 6'b101000 : diff;
    
    // Bit Shift to align mantissas
    wire [39:0] postShft;
    assign postShft = tempShft >> shftAmnt;
    
    // Use sticky bit to keep precision
    reg sticky;
    integer i;
    
    always @(*) begin
        sticky = 1'b0;
        for (i = 0; i <= shftAmnt; i = i + 1) begin
            sticky = sticky | tempShft[i];
        end
    end

    
    // The final post normalized smaller value with aligned mantissa
    wire [39:0] finalSm;
    assign finalSm = { {postShft[39:1]}, {postShft[0] | sticky} };
    
    // The fianl post normalized bigger value 
    wire [39:0] finalBi;
    assign finalBi = { {op_dn}, {gMant}, {16'b0} };
    
    wire [2:0] sign;
    assign sign = aSign & bSign & add;
    
    always @(*) begin
        case(sign) 
            3'b001: outSign = 0;
            3'b011: outSign = (bMant > aMant) ? 1 : 0;
            3'b101: outSign = (bMant > aMant) ? 0 : 1;
            3'b111: outSign = 1;
            default: outSign = 0;
        endcase;
   end
    
    // if expa == expb and fracta == fractb and denorm exp = 1 else exp = larger exp
    always @(posedge(clk)) begin
        outMantSmall = finalSm;
        outMantBig = finalBi;
        if ((aExpo == bExpo) & (aMant == bMant) & (op_dn == 1)) 
            outExpo = 1;
        else
            outExpo = gExpo;
    
    end
    
    
endmodule
