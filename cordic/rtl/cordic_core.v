// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// Author 	 : WCC 1530604142@qq.com
// File   	 : cordic_core
// Create 	 : 2022-12-06
// Revise 	 : 2022-
// Editor 	 : Vscode, tab size (4)
// Version	 : v1.0  
// Functions : Top module of cordic core, 1+6+STAGE clocks delay in total
// License	  : License: LGPL-3.0-or-later
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
module cordic_core #(
    parameter CORDIC_MODE = "NCO",
    parameter IDW = 12,
    parameter ODW = IDW+2,
    parameter AW = 20,
    parameter STAGE = 10
) (
    input   wire                clk     ,
    input   wire                rst     ,
    input   wire                pi_dv   ,
    input   wire    [IDW-1:0]   pi_x    ,
    input   wire    [IDW-1:0]   pi_y    ,
    input   wire    [AW-1:0]    pi_z    ,

    output  wire                po_dv   ,
    output  wire    [ODW-1:0]   po_x    ,// NCO mode output
    output  wire    [ODW-1:0]   po_y    ,

    output  wire    [AW-1:0]    po_angle   ,// ANGLE mode output
    output  wire    [ODW-1:0]   po_amp
);

    wire                pre_po_dv       ;
    wire [ODW-1:0]      pre_po_x        ;
    wire [ODW-1:0]      pre_po_y        ;
    wire [AW-1:0]       pre_po_z        ;
    wire [AW+2-1:0]     pre_po_info     ;

    wire [ODW-1:0]      int_po_x    [STAGE-1:0]    ;
    wire [ODW-1:0]      int_po_y    [STAGE-1:0]    ;
    wire [AW-1:0]       int_po_z    [STAGE-1:0]    ;
    wire [AW+2-1:0]     int_po_info [STAGE-1:0]    ;
    wire                int_po_dv   [STAGE-1:0]    ;

    // 1 clock delay
    cordic_pre#(
        .CORDIC_MODE ( CORDIC_MODE ),
        .IDW         ( IDW ),
        .ODW         ( ODW ),
        .AW          ( AW )
    )u_cordic_pre(
        .clk         ( clk         ),
        .rst         ( rst         ),
        .pi_dv       ( pi_dv       ),
        .pi_x        ( pi_x        ),
        .pi_y        ( pi_y        ),
        .pi_z        ( pi_z        ),
        .po_dv       ( pre_po_dv       ),
        .po_x        ( pre_po_x        ),
        .po_y        ( pre_po_y        ),
        .po_z        ( pre_po_z        ),
        .po_info     ( pre_po_info     )
    );

    // STAGE clock delay
    generate
        genvar i;
        for ( i=0; i < STAGE ; i=i +1) begin
            if (i==0) begin
                cordic_unit#(
                .CORDIC_MODE ( CORDIC_MODE ),
                .STAGE_N     ( 0 ),
                .DW          ( ODW ),
                .AW          ( AW )
                )u_cordic_unit(
                    .clk         ( clk         ),
                    .rst         ( rst         ),
                    .pi_dv       ( pre_po_dv       ),
                    .pi_info     ( pre_po_info     ),
                    .pi_x        ( pre_po_x        ),
                    .pi_y        ( pre_po_y        ),
                    .pi_z        ( pre_po_z        ),
                    .po_dv       ( int_po_dv[0]       ),
                    .po_info     ( int_po_info[0]     ),
                    .po_x        ( int_po_x[0]        ),
                    .po_y        ( int_po_y[0]        ),
                    .po_z        ( int_po_z[0]        )
                );
            end else begin
                cordic_unit#(
                .CORDIC_MODE ( CORDIC_MODE ),
                .STAGE_N     ( i ),
                .DW          ( ODW ),
                .AW          ( AW )
                )u_cordic_unit(
                    .clk         ( clk         ),
                    .rst         ( rst         ),
                    .pi_dv       ( int_po_dv[i-1]       ),
                    .pi_info     ( int_po_info[i-1]     ),
                    .pi_x        ( int_po_x[i-1]        ),
                    .pi_y        ( int_po_y[i-1]        ),
                    .pi_z        ( int_po_z[i-1]        ),
                    .po_dv       ( int_po_dv[i]       ),
                    .po_info     ( int_po_info[i]     ),
                    .po_x        ( int_po_x[i]        ),
                    .po_y        ( int_po_y[i]        ),
                    .po_z        ( int_po_z[i]        )
                );
            end
        end
        
    endgenerate

    //6 clock delay
    cordic_post#(
        .CORDIC_MODE ( CORDIC_MODE ),
        .DW          ( ODW ),
        .AW          ( AW )
    )u_cordic_post(
        .clk         ( clk         ),
        .rst         ( rst         ),
        .pi_dv       ( int_po_dv[STAGE-1]       ),
        .pi_info     ( int_po_info[STAGE-1]     ),
        .pi_x        ( int_po_x[STAGE-1]        ),
        .pi_y        ( int_po_y[STAGE-1]        ),
        .pi_z        ( int_po_z[STAGE-1]        ),
        .po_dv       ( po_dv       ),
        .po_x        ( po_x        ),
        .po_y        ( po_y        ),
        .po_angle    ( po_angle    ),
        .po_amp      ( po_amp      )
    );


    
endmodule