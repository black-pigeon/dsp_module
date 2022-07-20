// -----------------------------------------------------------------------------
// Copyright (c) 2019-2022 All rights reserved
// -----------------------------------------------------------------------------
// Author 	 : WCC 1530604142@qq.com
// File   	 : mult_basic
// Create 	 : 2022-07-15
// Revise 	 : 2022-
// Editor 	 : Vscode, tab size (4)
// Functions : multiple 
// 			   
// -----------------------------------------------------------------------------
module mult_basic #(
    parameter M = 5,
    parameter N = 4
) (
    input   wire                clk         ,
    input   wire                rst         ,
    input   wire                mult_enable ,
    input   wire    [M-1:0]     mult_in_a   ,
    input   wire    [N-1:0]     mult_in_b   ,

    output  reg     [M+N-1:0]   mult_out    ,  
    output  reg                 mult_out_valid
);

    //====================================================
    // parameter define
    //====================================================


    //====================================================
    // internal signals and registers
    //====================================================
    reg     [5:0]       cnt_pipe_idx    ;
    reg                 shift_flag      ;
    reg     [1:0]       sign            ;
    reg     [M+N-1:0]   mult_shift_a    ;
    reg     [M+N-1:0]   mult_shift_b    ;
    reg     [M+N-1:0]   mult_acc        ;
    reg                 mult_acc_valid  ;

    //----------------sign------------------
    always @(posedge clk ) begin
        if (rst==1'b1) begin
            sign <= 'd0;
        end
        else if (mult_enable == 1'b1) begin
            sign <= {mult_in_a[M-1], mult_in_b[N-1]};
        end
    end

    //----------------mult_shift------------------
    always @(posedge clk ) begin
        if (rst==1'b1) begin
            mult_shift_a <= 'd0;
            mult_shift_b <= 'd0;
        end
        else if (mult_enable == 1'b1) begin
            mult_shift_a[M-1:0] <= mult_in_a[M-1]? ~mult_in_a + 1 : mult_in_a;
            mult_shift_b[N-1:0] <= mult_in_b[N-1]? ~mult_in_b + 1 : mult_in_b;
            mult_shift_a[M+N-1:M] <= 'd0;
            mult_shift_b[M+N-1:N] <= 'd0;
        end
        else if (cnt_pipe_idx < N) begin
            mult_shift_a <= mult_shift_a << 1;
            mult_shift_b <= mult_shift_b >> 1;
        end
    end

    //----------------cnt_pipe_idx------------------
    always @(posedge clk ) begin
        if (rst==1'b1) begin
            shift_flag <= 'd0;
        end
        else if (mult_enable == 1'b1) begin
            shift_flag <= 1'b1;
        end
        else if (cnt_pipe_idx == N -1) begin
            shift_flag <= 1'b0;
        end
    end

    //----------------cnt_pipe_idx------------------
    always @(posedge clk ) begin
        if (rst==1'b1) begin
            cnt_pipe_idx <= 'd0;
        end
        else if (mult_enable == 1'b1) begin
            cnt_pipe_idx <= 'd0;
        end
        else if (shift_flag == 1'b1) begin
            cnt_pipe_idx <= cnt_pipe_idx + 1'b1;
        end
    end

    //----------------mult_acc------------------
    always @(posedge clk ) begin
        if (rst==1'b1) begin
            mult_acc <= 'd0;
        end
        else if (mult_enable == 1'b1) begin
            mult_acc <= 'd0;
        end
        else if (cnt_pipe_idx < N) begin
            mult_acc <= mult_shift_b[0] ? mult_acc + mult_shift_a : mult_acc;
        end
    end

    //----------------mult_acc_valid------------------
    always @(posedge clk ) begin
        if (rst==1'b1) begin
            mult_acc_valid <= 1'b0;
        end
        else if (cnt_pipe_idx == N-1) begin
            mult_acc_valid <= 1'b1;
        end
        else  begin
            mult_acc_valid <=  1'b0;
        end
    end

    //----------------mult_out------------------
    always @(posedge clk ) begin
        if (rst==1'b1) begin
            mult_out <= 'd0;
        end
        else if (mult_acc_valid) begin
            mult_out <= ^sign ? ~mult_acc + 1 : mult_acc;
        end
    end

    //----------------mult_out_valid------------------
    always @(posedge clk ) begin
        if (rst==1'b1) begin
            mult_out_valid <= 1'b0;
        end
        else  begin
            mult_out_valid <= mult_acc_valid;
        end
    end
endmodule