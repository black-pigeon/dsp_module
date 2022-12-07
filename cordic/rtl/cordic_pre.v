// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// Author 	 : WCC 1530604142@qq.com
// File   	 : cordic_pre
// Create 	 : 2022-12-06
// Revise 	 : 2022-
// Editor 	 : Vscode, tab size (4)
// Version	 : v1.0  initial
// Functions : cordic preparation, store the quadrant and angle information.
//             Convert coordinates to first quadrant.  
// License	 : License: LGPL-3.0-or-later
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
module cordic_pre #(
    parameter CORDIC_MODE = "NCO", //mode of this module, NCO mode or angle/amp mode
    parameter IDW = 12   ,
    parameter ODW = IDW+2,  // for cordic, 2 bit growth is enough
    parameter AW = 20   
) (
    input   wire                clk     ,
    input   wire                rst     ,
    input   wire                pi_dv   ,
    input   wire    [IDW-1:0]   pi_x    ,
    input   wire    [IDW-1:0]   pi_y    ,
    input   wire    [AW-1:0]    pi_z    ,

    output  reg                 po_dv   ,
    output  reg     [ODW-1:0]   po_x    ,
    output  reg     [ODW-1:0]   po_y    ,
    output  reg     [AW-1:0]    po_z    ,
    output  reg     [AW+2-1:0]  po_info     // po_info[AW+2-1:AW+2-2] is the quadrant infor, x and y axis symbol
                                            // po_info[AW-1:0] is the angle in first quarant
);
    localparam TWO_PI = (1<<AW)-1;
    localparam ONE_PI = (1<<(AW-1))-1;
    localparam HALF_PI = (1<<(AW-2))-1;

    generate
        if (CORDIC_MODE == "NCO") begin
            always @(posedge clk ) begin
                if (rst==1'b1) begin
                    po_info <= 'd0;
                    po_x <= 'd0;
                    po_y <= 'd0;
                    po_z <= 'd0;
                end else if (pi_dv == 1'b1) begin
                    po_x <= pi_x;
                    po_y <= 'd0;
                    po_dv <= 1'b1;
                    case (pi_z[AW-1:AW-2])
                        // if the angle is 0~π/2, first quadrant
                        2'b00: begin
                            po_info[AW+2-1: AW+2-2] <= 2'b00;
                            po_info[AW-1:0] <= pi_z;
                        end
                        // if the angle is π/2~π, second quarant
                        2'b01: begin
                            po_info[AW+2-1: AW+2-2] <= 2'b10;
                            po_info[AW-1:0] <= ONE_PI - pi_z;
                        end
                        // if the angle is π~3π/2, third quarant
                        2'b10: begin
                            po_info[AW+2-1: AW+2-2] <= 2'b11;
                            po_info[AW-1:0] <= pi_z - ONE_PI;
                        end
                        // if the angle is 3π/2~2π, fourth quarant
                        2'b11: begin
                            po_info[AW+2-1: AW+2-2] <= 2'b01;
                            po_info[AW-1:0] <= TWO_PI-1 - pi_z;
                        end
                    endcase
                end else begin
                    po_dv <= 1'b0;
                end
            end
        end else if(CORDIC_MODE == "ANGLE")begin
            always @(posedge clk ) begin
                if (rst==1'b1) begin
                    po_info <= 'd0;
                    po_x <= 'd0;
                    po_y <= 'd0;
                    po_z <= 'd0;
                end else if (pi_dv == 1'b1) begin
                    po_dv <= 1'b1;
                    case ({pi_x[IDW - 1],pi_y[IDW - 1]})
                        // first quarant
                        2'b00 : begin
                            po_info[AW+2-1: AW+2-2] <= 2'b00;
                            po_x <= {{(ODW-IDW){1'b0}}, pi_x};
                            po_y <= {{(ODW-IDW){1'b0}}, pi_y};
                        end
                        // fourth quarant
                        2'b01 : begin
                            po_info[AW+2-1: AW+2-2] <= 2'b01;
                            po_x <= {{(ODW-IDW){1'b0}}, pi_x};
                            po_y <= {{(ODW-IDW){1'b0}}, (~pi_y+1'b1)};
                        end
                        // seconf quarant
                        2'b10 : begin
                            po_info[AW+2-1: AW+2-2] <= 2'b10;
                            po_x <= {{(ODW-IDW){1'b0}}, (~pi_x+1'b1)};
                            po_y <= {{(ODW-IDW){1'b0}}, pi_y};
                        end
                        // third quarant
                        2'b11 : begin
                            po_info[AW+2-1: AW+2-2] <= 2'b11;
                            po_x <= {{(ODW-IDW){1'b0}}, (~pi_x+1'b1)};
                            po_y <= {{(ODW-IDW){1'b0}}, (~pi_y+1'b1)};
                        end
                    endcase
                end else begin
                    po_dv <= 1'b0;
                end
            end
            
        end else begin
            always @(posedge clk ) begin
                if (rst==1'b1) begin
                    po_info <= 'd0;
                    po_x <= 'd0;
                    po_y <= 'd0;
                    po_z <= 'd0;
                    po_dv <= 1'b0;
                end begin
                    po_info <= 'd0;
                    po_x <= 'd0;
                    po_y <= 'd0;
                    po_z <= 'd0;
                    po_dv <= 1'b0;
                end 
            end
        end
    endgenerate

    
endmodule