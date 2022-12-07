// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// Author 	 : WCC 1530604142@qq.com
// File   	 : cordic_unit
// Create 	 : 2022-12-06
// Revise 	 : 2022-
// Editor 	 : Vscode, tab size (4)
// Version	 : v1.0  
// Functions : 
// License	  : License: LGPL-3.0-or-later   
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
module cordic_unit #(
    parameter CORDIC_MODE = "NCO",  // mode of this module, NCO mode or angle/amp mode
    parameter STAGE_N = 1,          // loop idx
    parameter DW = 20,              // data width 
    parameter AW = 20               // angle width 

) (
    input   wire                clk     ,
    input   wire                rst     ,
    input   wire                pi_dv   ,
    input   wire    [AW+2-1:0]  pi_info ,
    input   wire    [DW-1:0]    pi_x    ,
    input   wire    [DW-1:0]    pi_y    ,
    input   wire    [AW-1:0]    pi_z    ,

    output  reg                 po_dv   ,
    output  reg     [AW+2-1:0]  po_info ,
    output  reg     [DW-1:0]    po_x    ,
    output  reg     [DW-1:0]    po_y    ,
    output  reg     [AW-1:0]    po_z
);

    //====================================================
    // internal signals
    //====================================================
    // [0, 2pi] is mapped to [0, 2^20], so the following 
    // angle is calculated as the same.
    // atan(2^-0) =     20'h20000;
    // atan(2^-1) =     20'h12e40;
    // atan(2^-2) =     20'h9fb4;
    // atan(2^-3) =     20'h5111;
    // atan(2^-4) =     20'h28b1;
    // atan(2^-5) =     20'h145d;
    // atan(2^-6) =     20'ha2f;
    // atan(2^-7) =     20'h518;
    // atan(2^-8) =     20'h28c;
    // atan(2^-9) =     20'h146;
    // atan(2^-10) =    20'ha3;
    // atan(2^-11) =    20'h51;
    // atan(2^-12) =    20'h29;
    // atan(2^-13) =    20'h14;
    // atan(2^-14) =    20'ha;
    // atan(2^-15) =    20'h5;
    // atan(2^-16) =    20'h3;
    // atan(2^-17) =    20'h1;
    wire    [AW-1:0]    theta_lut [17:0];   // rotation angle lookup table

    reg                 rota_dir; // rotation direction, 1:counterclockwise, 0:clockwise

    reg     [DW-1:0]    delta_x ; // x variation  per rotation
    reg     [DW-1:0]    delta_y ; // y variation  per rotation
    reg     [AW-1:0]    delta_z ; // z variation  per rotation

    reg     [DW-1:0]    x_int ;
    reg     [DW-1:0]    y_int ;
    reg     [AW-1:0]    z_int ;
    reg     [AW+2-1:0]  info_int ;
    reg                 dv_int  ;

    assign theta_lut[0]  =    20'h20000;
    assign theta_lut[1]  =    20'h12e40;
    assign theta_lut[2]  =    20'h9fb4;
    assign theta_lut[3]  =    20'h5111;
    assign theta_lut[4]  =    20'h28b1;
    assign theta_lut[5]  =    20'h145d;
    assign theta_lut[6]  =    20'ha2f;
    assign theta_lut[7]  =    20'h518;
    assign theta_lut[8]  =    20'h28c;
    assign theta_lut[9]  =    20'h146;
    assign theta_lut[10] =    20'ha3;
    assign theta_lut[11] =    20'h51;
    assign theta_lut[12] =    20'h29;
    assign theta_lut[13] =    20'h14;
    assign theta_lut[14] =    20'ha;
    assign theta_lut[15] =    20'h5;
    assign theta_lut[16] =    20'h3;
    assign theta_lut[17] =    20'h1;

    //====================================================
    // cordic iteration unit
    // X(n + 1) = Xn - Sn * 2^(-n) * Yn
    // Y(n + 1) = Yn + Sn * 2^(-n) * Xn
    // Z(n + 1) = Xn - Sn * arctan(2^(-n))
    //====================================================


    generate
        if (CORDIC_MODE == "NCO") begin
            // in nco module the first stage need anticlockwise rotation
            if (STAGE_N == 0) begin
                always @(posedge clk) begin
                    if (rst==1'b1) begin
                        po_x <= 'd0;
                        po_y <= 'd0;
                        po_z <= 'd0;
                        po_dv<= 1'b0;
                        po_info <= 'd0;
                    end else if(pi_dv == 1'b1)begin
                        po_x <= pi_x - pi_y;
                        po_y <= pi_y + pi_x;
                        po_z <= pi_z + theta_lut[0];
                        po_info <= pi_info;
                        po_dv<= 1'b1;
                    end else begin
                        po_dv<= 1'b0;
                    end
                end
            end else begin
                always @(posedge clk) begin
                    if (rst==1'b1) begin
                        po_x <= 'd0;
                        po_y <= 'd0;
                        po_z <= 'd0;
                        po_dv<= 1'b0;
                        po_info <= 'd0;
                    end else if(pi_dv == 1'b1)begin
                        po_dv<= 1'b1;
                        po_info <= pi_info;
                        // if current angle is in forth quarant, anticlockwise rotation
                        if (pi_z[AW-1]) begin
                            po_x <= pi_x - {{STAGE_N{pi_y[DW-1]}}, pi_y[DW-1 : STAGE_N]};
                            po_y <= pi_y + {{STAGE_N{pi_x[DW-1]}}, pi_x[DW-1 : STAGE_N]};
                            po_z <= pi_z + theta_lut[STAGE_N];
                        end else begin
                            // if current angle is greater than the aim angle, clockwise
                            if (pi_z > pi_info[AW-1:0]) begin
                                po_x <= pi_x + {{STAGE_N{pi_y[DW-1]}}, pi_y[DW-1 : STAGE_N]};
                                po_y <= pi_y - {{STAGE_N{pi_x[DW-1]}}, pi_x[DW-1 : STAGE_N]};
                                po_z <= pi_z - theta_lut[STAGE_N];
                            // else current angle is smaller than the aim angle, anticlockwise
                            end else begin
                                po_x <= pi_x - {{STAGE_N{pi_y[DW-1]}}, pi_y[DW-1 : STAGE_N]};
                                po_y <= pi_y + {{STAGE_N{pi_x[DW-1]}}, pi_x[DW-1 : STAGE_N]};
                                po_z <= pi_z + theta_lut[STAGE_N];
                            end
                        end
                    end else begin
                        po_dv<= 1'b0;			
                    end
                end              
            end
            
        end else if(CORDIC_MODE == "ANGLE") begin
            // in angle module the first stage need clockwise rotation
            if (STAGE_N == 0) begin
                always @(posedge clk) begin
                    if (rst==1'b1) begin
                        po_x <= 'd0;
                        po_y <= 'd0;
                        po_z <= 'd0;
                        po_info <= 'd0;
                        po_dv <= 1'b0;
                    end else if(pi_dv == 1'b1)begin
                        po_x <= pi_x + pi_y;
                        po_y <= pi_y - pi_x;
                        po_z <= pi_z - theta_lut[0];
                        po_info <= pi_info;
                        po_dv<= 1'b1;
                    end else begin
                        po_dv <= 1'b0;
                    end
                end
            end else begin
                always @(posedge clk) begin
                    if (rst==1'b1) begin
                        po_x <= 'd0;
                        po_y <= 'd0;
                        po_z <= 'd0;
                        po_info <= 'd0;
                        po_dv<= 1'b0;
                    end else if(pi_dv == 1'b1)begin
                        po_dv <= 1'b1;
                        po_info <= pi_info;
                        if (pi_y[DW-1] == 1'b1) begin
                            po_x <= pi_x - {{STAGE_N{pi_y[DW-1]}}, pi_y[DW-1 : STAGE_N]};
                            po_y <= pi_y + {{STAGE_N{pi_x[DW-1]}}, pi_x[DW-1 : STAGE_N]};
                            po_z <= pi_z + theta_lut[STAGE_N];
                        // else clockwise
                        end else begin
                            po_x <= pi_x + {{STAGE_N{pi_y[DW-1]}}, pi_y[DW-1 : STAGE_N]};
                            po_y <= pi_y - {{STAGE_N{pi_x[DW-1]}}, pi_x[DW-1 : STAGE_N]};
                            po_z <= pi_z - theta_lut[STAGE_N];
                        end
                    end else begin
                        po_dv<= 1'b0;
                    end
                end              
            end    
        end else begin
            always @(posedge clk ) begin
                if (rst==1'b1) begin
                    po_x <= 'd0;
                    po_y <= 'd0;
                    po_z <= 'd0;
                    po_info <= 'd0;
                    po_dv<= 1'b0;	
                end else begin
                    po_x <= 'd0;
                    po_y <= 'd0;
                    po_z <= 'd0;
                    po_info <= 'd0;
                    po_dv<= 1'b0;	
                end
            end
        end
    endgenerate


endmodule