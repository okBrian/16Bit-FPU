`timescale 1ns / 1ps

module pre_norm(
    input [15:0] oper1_in, [15:0] oper2_in,
    input clk,
    output [5:0] outExpo
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
    
    // if expa == expb and fracta == fractb and subtracitng exp = 0 else exp = larger exp
//    always @(posedge(clk)) begin 
//        if 
    
//    end

    
    
    
    
endmodule
