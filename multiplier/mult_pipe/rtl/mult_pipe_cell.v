// -----------------------------------------------------------------------------
// Copyright (c) 2019-2022 All rights reserved
// -----------------------------------------------------------------------------
// Author 	 : WCC 1530604142@qq.com
// File   	 : mult_pipe
// Create 	 : 2022-07-19
// Revise 	 : 2022-
// Editor 	 : Vscode, tab size (4)
// Functions : multiplier pipeline basic cell
// 			   
// -----------------------------------------------------------------------------

module mult_pipe_cell #(
    parameter M = 5         ,
    parameter N = 4         ,
    parameter PIPE_STAGE = 1
) (
    input   wire                clk             ,
    input   wire                rst             ,
    input   wire                mult_in_valid   ,
    input   wire    [M+N-1:0]   mult_in_a       ,
    input   wire    [M+N-1:0]   mult_in_b       ,
    input   wire    [M+N-1:0]   mult_in_acc     ,
    input   wire    [1:0]       sign_in         ,


    output  reg                 mult_out_valid  ,
    output  reg     [1:0]       sign_out        ,
    output  reg     [M+N-1:0]   mult_out_a      ,
    output  reg     [M+N-1:0]   mult_out_b      ,
    output  reg     [M+N-1:0]   mult_out_acc         
);

    generate
        if (PIPE_STAGE == 0) begin
            //----------------sign_out------------------
            always @(posedge clk ) begin
                if (rst==1'b1) begin
                    sign_out <= 'd0;
                    mult_out_a <= 'd0;
                    mult_out_b <= 'd0;
                    mult_out_acc <= 'd0;
                end
                else if (mult_in_valid == 1'b1) begin
                    sign_out <= {mult_in_a[M+N-1], mult_in_b[M+N-1]};
                    mult_out_a <= mult_in_a[M+N-1] ? ~mult_in_a + 1 : mult_in_a;
                    mult_out_b <= mult_in_b[M+N-1] ? ~mult_in_b + 1 : mult_in_b;
                    mult_out_acc <= 'd0;
                end
            end
        end
        else begin
            //----------------sign_out------------------
            always @(posedge clk ) begin
                if (rst==1'b1) begin
                    sign_out <= 'd0;
                    mult_out_a <= 'd0;
                    mult_out_b <= 'd0;
                    mult_out_acc <= 'd0;
                end
                else if (mult_in_valid == 1'b1) begin
                    sign_out <= sign_in;
                    mult_out_a <= mult_in_a << 1'b1;
                    mult_out_b <= mult_in_b >> 1'b1;
                    mult_out_acc <= mult_in_b[0] ? mult_in_acc + mult_in_a : mult_in_acc;
                end
            end
            
        end
    endgenerate
    
    //----------------mult_out_valid ------------------
    always @(posedge clk ) begin
        if (rst==1'b1) begin
            mult_out_valid <= 1'b0; 
        end
        else  begin
            mult_out_valid <= mult_in_valid; 
        end
    end
endmodule