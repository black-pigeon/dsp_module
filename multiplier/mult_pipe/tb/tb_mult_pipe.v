`timescale  1ns / 1ps

module tb_mult_pipe;

// mult_pipe Parameters
parameter PERIOD = 10;
parameter M  = 5;
parameter N  = 4;

// mult_pipe Inputs
reg   clk                                  = 0 ;
reg   rst                                  = 1 ;
reg   mult_in_valid                        = 0 ;
reg   [M-1:0]  mult_in_a                   = 0 ;
reg   [N-1:0]  mult_in_b                   = 0 ;

// mult_pipe Outputs
wire  mult_out_valid                       ;
wire  [M+N-1:0]  mult_out                  ;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    #(PERIOD*2) rst  =  0;
end

mult_pipe #(
    .M ( M ),
    .N ( N ))
 u_mult_pipe (
    .clk                     ( clk                       ),
    .rst                     ( rst                       ),
    .mult_in_valid           ( mult_in_valid             ),
    .mult_in_a               ( mult_in_a        ),
    .mult_in_b               ( mult_in_b        ),
    .mult_out_valid          ( mult_out_valid   ),
    .mult_out                ( mult_out         )
);

initial begin
    @(negedge rst);
    repeat(100) @(posedge clk);

    mult_in_valid = 1'b1;

    mult_in_a = 5'd12;
    mult_in_b = 4'd3;
    @(posedge clk);

    mult_in_a = -5'd12;
    mult_in_b = 4'd3;
    @(posedge clk);

    mult_in_a = -5'd12;
    mult_in_b = -4'd3;
    @(posedge clk);

    mult_in_a = 5'd12;
    mult_in_b = -4'd3;
    @(posedge clk);

    mult_in_a = 5'd15;
    mult_in_b = 4'd7;
    @(posedge clk);

    mult_in_a = -5'd15;
    mult_in_b = -4'd7;
    @(posedge clk);


    mult_in_a = 5'd3;
    mult_in_b = 4'd7;
    @(posedge clk);

    mult_in_a = -5'd15;
    mult_in_b = -4'd7;
    @(posedge clk);

    mult_in_valid = 1'b0;
    
end

endmodule