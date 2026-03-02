`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/17/2026 07:58:00 PM
// Design Name: 
// Module Name: AES_encryption_block
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


module AES_encryption_core(
    input clk,
    input rst,
    input start,
    input [127:0] plaintext,
    input [127:0] key,
    output reg [127:0] ciphertext,
    output reg done
    );
    
    reg [3:0] round_cnt;
    reg [127:0] text_reg;
    reg [127:0] key_reg;
    reg [1:0] state;
    
    wire [127:0] key_out, sub_out, shift_out, mix_out;
    
    parameter IDLE = 2'b00;
    parameter CIPHER_ROUND = 2'b01;
    parameter STOP = 2'b10;
    
    ExpandKey keygen (.clk(clk), .round_no(round_cnt), .in_key(key_reg), .out_key(key_out));
    SubBytes bytesub (.in_block(text_reg), .out_block(sub_out));
    ShiftRows rowshift (.in_block(sub_out), .out_block(shift_out));
    MixColumns columnmix (.in_block(shift_out), .out_block(mix_out));
    
    always @(posedge clk) begin
        if (rst) begin
            ciphertext <= 0;
            done <= 0;
            round_cnt <= 0;
            text_reg <= 0;
            key_reg <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    key_reg <= key;
                    if (start) begin
                        // Round 0: Initial AddRoundKey happens instantly
                        text_reg <= plaintext ^ key;
                        round_cnt <= 4'd1; 
                        state <= CIPHER_ROUND;
                    end
                end
                
                CIPHER_ROUND: begin
                    // FIX 1: Bypass MixColumns for the final round
                    // FIX 2: key_out will now be the expansion of key_reg from the PREVIOUS cycle
                    if (round_cnt == 4'd10) begin
                        text_reg <= shift_out ^ key_out; 
                        state <= STOP;
                    end else begin
                        text_reg <= mix_out ^ key_out;
                        key_reg <= key_out; // Prepare key for the next round expansion
                        round_cnt <= round_cnt + 1'b1;
                    end
                end
                
                STOP: begin
                    ciphertext <= text_reg;
                    done <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
