//~ `New testbench
`timescale  1ns / 1ps

module tb_cordic_nco;

    // cordic_core Parameters
    parameter PERIOD       = 10   ;
    parameter CORDIC_MODE  = "NCO";
    parameter IDW          = 12   ;
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
    wire  [AW-1:0]  po_angle                   ;
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
        .pi_x                    ( FIXONE      ),
        .pi_y                    ( 0      ),
        .pi_z                    ( pi_z      ),

        .po_dv                   ( po_dv     ),
        .po_x                    ( po_x      ),
        .po_y                    ( po_y      ),
        .po_angle                ( po_angle  ),
        .po_amp                  ( po_amp    )
    );

    initial begin
        @(negedge rst);
        repeat(100)@(posedge clk);
        forever begin
            @(posedge clk) begin
                pi_dv          = 1'b1 ;
                if (pi_z >= TWO_PI - PHASE_INC) begin
                    pi_z = 0 ;
                end else begin
                    pi_z = pi_z + PHASE_INC;
                end
            end
        end
    end


    initial begin
        PHASE_INC = 1<<7;
        repeat(40000) @(posedge clk);
        PHASE_INC = 1<<10;
        repeat(40000) @(posedge clk);
        PHASE_INC = 1<<9;
        repeat(40000) @(posedge clk);
        PHASE_INC = 1<<11;
    end

endmodule