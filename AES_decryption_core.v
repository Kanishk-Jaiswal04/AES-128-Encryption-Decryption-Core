`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/14/2026 12:46:44 AM
// Design Name: 
// Module Name: AES_decryption_core
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


module AES_decryption_core(
    input clk,
    input rst,
    input start,
    input key_en,
    input [127:0] plaintext,
    input [127:0] key,
    output reg [127:0] ciphertext,
    output reg done
    );
    
    reg [3:0] round_cnt;
    reg [127:0] text_reg;
    reg [127:0] key_reg;
    reg [1:0] state;
    
    wire [127:0] key_out, invsub_out, invmix_out, invshift_out;
    
    parameter IDLE = 2'b00;
    parameter KEY_GENERATION = 2'b01;
    parameter CIPHER_ROUND = 2'b10;
    parameter STOP = 2'b11;
    
    ExpandKey keygen (.clk(clk), .round_no(round_cnt), .in_key(key_reg), .out_key(key_out));
    InvSubBytes invsub (.in_block(text_reg), .out_block(invsub_out));
    InvShiftRows invshift (.in_block(invsub_out), .out_block(invshift_out));
    InvMixColumns invmix (.in_block(invshift_out), .out_block(invmix_out));
    
    always @(posedge clk) begin
        if (rst) begin
        
        
        
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        if (key_en) 
                            state <= KEY_GENERATION;
                        else begin
                    end
                end
            endcase
        end
    end
endmodule
