//~ `New testbench
`timescale  1ns / 1ps

module tb_cordic_angle;

    // cordic_core Parameters
    parameter PERIOD       = 10   ;
    parameter CORDIC_MODE  = "ANGLE";
    parameter IDW          = 16   ;
    parameter ODW          = IDW+2;
    parameter AW           = 20   ;
    parameter STAGE        = IDW   ;

    // fixed poined data, 1bit sign, 2bit integer 9bit fractional part
    localparam FIXONE = 1<<(IDW-1);
    localparam TWO_PI = 1<<AW;

    reg [31:0] PHASE_INC;
    // cordic_core Inputs
    reg   clk                                  = 0 ;
    reg   rst                                  = 1 ;
    reg   pi_dv                                = 0 ;
    reg   [IDW-1:0]  pi_x                      = 0 ;
    reg   [IDW-1:0]  pi_y                      = 0 ;
    reg   [AW-1:0]  pi_z                       = 0 ;

    // cordic_core Outputs
    wire  po_dv                                ;
    wire  [ODW-1:0]  po_x                      ;
    wire  [ODW-1:0]  po_y                      ;
    wire  [AW-1:0]   po_angle                   ;
    wire  [ODW-1:0]  po_amp                    ;


    initial
    begin
        forever #(PERIOD/2)  clk=~clk;
    end

    initial
    begin
        #(PERIOD*2) rst  =  0;
    end

    cordic_core #(
        .CORDIC_MODE ( CORDIC_MODE ),
        .IDW         ( IDW         ),
        .ODW         ( ODW         ),
        .AW          ( AW          ),
        .STAGE       ( STAGE       ))
    u_cordic_core (
        .clk                     ( clk       ),
        .rst                     ( rst       ),
        .pi_dv                   ( pi_dv     ),
        .pi_x                    ( pi_x      ),
        .pi_y                    ( pi_y      ),
        .pi_z                    ( 'd0      ),

        .po_dv                   ( po_dv     ),
        .po_x                    ( po_x      ),
        .po_y                    ( po_y      ),
        .po_angle                ( po_angle  ),
        .po_amp                  ( po_amp    )
    );

    initial begin
        @(negedge rst);
        repeat(100)@(posedge clk);
        pi_dv =1;
        pi_x = 100;
        pi_y = 100;
        @(posedge clk)
        pi_x = -100;
        pi_y = 100;
        @(posedge clk)
        pi_x = 100;
        pi_y = -100;
        @(posedge clk)
        pi_x = -100;
        pi_y = -100;
        @(posedge clk)

        pi_x = 200;
        pi_y = 100;
        @(posedge clk)

        pi_x = -100;
        pi_y = 300;
        @(posedge clk)
        pi_dv = 0;

        repeat(100)@(posedge clk);
        pi_dv =1;
        pi_x = 512;
        pi_y = 512;
        @(posedge clk)
        pi_dv =0;
    end



endmodule