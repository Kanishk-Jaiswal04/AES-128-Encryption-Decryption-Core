`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/09/2026 10:57:14 PM
// Design Name: 
// Module Name: ExpandKey
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ExpandKey(
    input clk,
    input [3:0] round_no,
    input [127:0] in_key,
    output reg [127:0] out_key
    );
    
    wire [31:0] w0, w1, w2, w3;
    wire [31:0] w0n, w1n, w2n, w3n;
    wire [31:0] t;
    wire [31:0] sbox_wire;

    assign w0 = in_key[127:96];
    assign w1 = in_key[95:64];
    assign w2 = in_key[63:32];
    assign w3 = in_key[31:0];

    wire [31:0] rot_w3;
    assign rot_w3 = rotword(w3);

    sbox inst1 (.in_byte(rot_w3[31:24]), .out_byte(sbox_wire[31:24]));
    sbox inst2 (.in_byte(rot_w3[23:16]), .out_byte(sbox_wire[23:16]));
    sbox inst3 (.in_byte(rot_w3[15:8]),  .out_byte(sbox_wire[15:8]));
    sbox inst4 (.in_byte(rot_w3[7:0]),   .out_byte(sbox_wire[7:0]));
    
    assign t = sbox_wire ^ rcon(round_no);

    assign w0n = w0 ^ t;
    assign w1n = w1 ^ w0n;
    assign w2n = w2 ^ w1n;
    assign w3n = w3 ^ w2n;
    
    always @(negedge clk)
        out_key <= {w0n, w1n, w2n, w3n};
        
    function [31:0] rotword;
        input [31:0] w;
        begin
            rotword = { w[23:0], w[31:24] };
        end
    endfunction

    function [31:0] rcon;
        input [3:0] r;
        begin
            case (r)
                4'd1: rcon = 32'h01000000;
                4'd2: rcon = 32'h02000000;
                4'd3: rcon = 32'h04000000;
                4'd4: rcon = 32'h08000000;
                4'd5: rcon = 32'h10000000;
                4'd6: rcon = 32'h20000000;
                4'd7: rcon = 32'h40000000;
                4'd8: rcon = 32'h80000000;
                4'd9: rcon = 32'h1b000000;
                4'd10:rcon = 32'h36000000;
                default: rcon = 32'h00000000;
            endcase
        end
    endfunction   
    
endmodule
