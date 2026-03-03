`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/04/2026 01:28:16 AM
// Design Name: 
// Module Name: AES_encryption_decryption_top
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


module AES_encryption_decryption_top(
    input clk, 
    input rst,
    input start,
    input enc_dec_en,    // 1 for Enc, 0 for Dec
    input key_en_in,     // Controlled via AXI register
    input [127:0] text_input,
    input [127:0] key,
    output [127:0] text_output,
    output done
    );
    
    // Internal Wires to prevent multiple drivers
    wire [127:0] text_out_enc, text_out_dec;
    wire done_enc, done_dec;
    reg start_enc, start_dec;

    // 1. Multiplexer for Outputs
    assign text_output = (enc_dec_en) ? text_out_enc : text_out_dec;
    assign done        = (enc_dec_en) ? done_enc     : done_dec;

    // 2. Start Logic (Combinational Steering)
    always @(*) begin
        start_enc = 1'b0;
        start_dec = 1'b0;
        if (start) begin
            if (enc_dec_en) start_enc = 1'b1;
            else            start_dec = 1'b1;
        end
    end

    // 3. Instance Calls
    AES_encryption_core encrypt (
        .clk(clk), .rst(rst), .start(start_enc), 
        .plaintext(text_input), .key(key), 
        .ciphertext(text_out_enc), .done(done_enc)
    );

    AES_decryption_core decrypt (
        .clk(clk), .rst(rst), .start(start_dec), 
        .key_en(key_en_in), .ciphertext(text_input), .key(key), 
        .plaintext(text_out_dec), .done(done_dec)
    );
        
endmodule
