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
    input [127:0] ciphertext,
    input [127:0] key,
    output reg [127:0] plaintext,
    output reg done
    );
    
    reg [3:0] round_cnt;
    reg [127:0] text_reg;
    reg [127:0] key_reg;
    reg [1:0] state;
    
    reg [127:0] key_buffer [0:10];
    
    wire [127:0] key_out, invsub_out, invmix_in, invmix_out, invshift_out;
    
    parameter IDLE = 2'b00;
    parameter KEY_GENERATION = 2'b01;
    parameter CIPHER_ROUND = 2'b10;
    parameter STOP = 2'b11;
    
    assign invmix_in = (state == KEY_GENERATION) ? key_out : 
                       (state == CIPHER_ROUND) ? invshift_out : 
                       128'b0; // small power optimisation
    
    ExpandKey keygen (.clk(clk), .round_no(round_cnt), .in_key(key_reg), .out_key(key_out));
    InvSubBytes invsub (.in_block(text_reg), .out_block(invsub_out));
    InvShiftRows invshift (.in_block(invsub_out), .out_block(invshift_out));
    InvMixColumns invmix (.in_block(invmix_in), .out_block(invmix_out));
    
    always @(posedge clk) begin
        if (rst) begin
            round_cnt <= 'b0;
            key_reg <= 'b0;
            text_reg <= 'b0;
            state <= IDLE;
            plaintext <= 'b0;
            done <= 'b0;
        end else begin
            case (state)
                IDLE: begin
                    key_reg <= key;
                    done <= 1'b0;
                    if (start) begin
                        if (key_en) begin
                            state <= KEY_GENERATION;
                            round_cnt <= 4'd1;
                            key_buffer[0] <= key_reg;
                        end else begin
                            state <= CIPHER_ROUND;
                            text_reg <= ciphertext ^ key_buffer[10];
                            round_cnt <= 4'd9;
                        end
                    end
                end
                
                KEY_GENERATION: begin
                    if (round_cnt == 4'd10) begin
                        state <= CIPHER_ROUND;
                        round_cnt <= 4'd9;
                        key_buffer[10] <= key_out;
                        text_reg <= ciphertext ^ key_out;
                    end else begin
                        key_buffer[round_cnt] <= invmix_out;
                        key_reg <= key_out; 
                        round_cnt <= round_cnt + 1'b1;
                    end
                end
                
                CIPHER_ROUND: begin
                    if (round_cnt == 4'd0) begin
                        plaintext <= invshift_out ^ key_buffer[0]; 
                        done <= 1'b1;                              
                        state <= IDLE;                             
                    end else begin
                        text_reg <= invmix_out ^ key_buffer[round_cnt];
                        round_cnt <= round_cnt - 1'b1;
                    end 
                end
                
            endcase
        end
    end
endmodule
