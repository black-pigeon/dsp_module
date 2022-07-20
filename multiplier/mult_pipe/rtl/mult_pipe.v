// -----------------------------------------------------------------------------
// Copyright (c) 2019-2022 All rights reserved
// -----------------------------------------------------------------------------
// Author 	 : WCC 1530604142@qq.com
// File   	 : mult_pipe
// Create 	 : 2022-07-19
// Revise 	 : 2022-
// Editor 	 : Vscode, tab size (4)
// Functions : multiplier pipeline 
// 			   
// -----------------------------------------------------------------------------
module mult_pipe #(
    parameter M = 5 ,
    parameter N = 4        
) (
    input   wire                clk             ,
    input   wire                rst             ,
    input   wire                mult_in_valid   ,
    input   wire    [M-1:0]     mult_in_a       ,
    input   wire    [N-1:0]     mult_in_b       ,

    output  reg                 mult_out_valid  ,
    output  reg     [M+N-1:0]   mult_out            
);

    wire    [0:0]       mult_shift_valid [N:0];
    wire    [M+N-1:0]   mult_shift_a [N:0]  ;
    wire    [M+N-1:0]   mult_shift_b [N:0]  ;
    wire    [M+N-1:0]   mult_shift_acc [N:0];
    wire    [1:0]       sign_out [N:0]      ;


    mult_pipe_cell#(
        .M               ( M ),
        .N               ( N ),
        .PIPE_STAGE      ( 0 )
    )u_mult_pipe_cell(
        .clk             ( clk                  ),
        .rst             ( rst                  ),
        .mult_in_valid   ( mult_in_valid        ),
        .mult_in_a       ( {{N{mult_in_a[M-1]}}, mult_in_a}            ),
        .mult_in_b       ( {{M{mult_in_b[N-1]}}, mult_in_b}            ),
        .mult_in_acc     ( 'd0                  ),
        .sign_in         ( 'd0                  ),
        .mult_out_valid  ( mult_shift_valid[0]  ),
        .sign_out        ( sign_out[0]          ),
        .mult_out_a      ( mult_shift_a[0]      ),
        .mult_out_b      ( mult_shift_b[0]      ),
        .mult_out_acc    ( mult_shift_acc[0]    )
    );

    genvar i;
    generate
        for(i=1; i<N+1; i=i+1)begin
            mult_pipe_cell#(
                .M               ( M ),
                .N               ( N ),
                .PIPE_STAGE      ( i )
            )u_mult_pipe_cell(
                .clk             ( clk                  ),
                .rst             ( rst                  ),
                .mult_in_valid   ( mult_shift_valid[i-1]      ),
                .sign_in         ( sign_out[i-1]      ),
                .mult_in_a       ( mult_shift_a[i-1]      ),
                .mult_in_b       ( mult_shift_b[i-1]      ),
                .mult_in_acc     ( mult_shift_acc[i-1]      ),
                
                .mult_out_valid  ( mult_shift_valid[i]  ),
                .sign_out        ( sign_out[i]          ),
                .mult_out_a      ( mult_shift_a[i]      ),
                .mult_out_b      ( mult_shift_b[i]      ),
                .mult_out_acc    ( mult_shift_acc[i]    )
            );
        end
    endgenerate 


    always @(posedge clk ) begin
        if (rst==1'b1) begin
            mult_out <= 'd0;
        end
        else if (mult_shift_valid[N] == 1'b1) begin
            mult_out <= ^sign_out[N] ? ~mult_shift_acc[N] + 1 : mult_shift_acc[N];
        end
    end

    always @(posedge clk ) begin
        if (rst==1'b1) begin
            mult_out_valid <= 1'b0;
        end
        else begin
            mult_out_valid <= mult_shift_valid[N];
        end
    end



endmodule