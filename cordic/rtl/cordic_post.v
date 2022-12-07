// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// Author 	 : WCC 1530604142@qq.com
// File   	 : cordic_post
// Create 	 : 2022-12-06
// Revise 	 : 2022-
// Editor 	 : Vscode, tab size (4)
// Version	 : v1.0  
// Functions : calculate the final result of cordic, this module needs to 
//             correct the amp by 0.60725 
//             0.60725 ≌ (1/2 + 1/8 - 1/64 - 1/512) - ((1/2 + 1/8 - 1/64 - 1/512)/4096)   
// License	 : License: LGPL-3.0-or-later
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
module cordic_post #(
    parameter CORDIC_MODE = "NCO",
    parameter DW = 20,
    parameter AW = 20
    
) (
    input   wire                clk     ,
    input   wire                rst     ,
    input   wire                pi_dv   ,
    input   wire    [AW+2-1:0]  pi_info ,
    input   wire    [DW-1:0]    pi_x    ,
    input   wire    [DW-1:0]    pi_y    ,
    input   wire    [AW-1:0]    pi_z    ,

    output  reg                 po_dv   ,
    output  reg     [DW-1:0]    po_x    ,// NCO mode output
    output  reg     [DW-1:0]    po_y    ,

    output  wire    [AW-1:0]    po_angle   ,// angle mode output
    output  wire    [DW-1:0]    po_amp
);

    //====================================================
    //parameter define
    //====================================================
    localparam TWO_PI = 1<<AW;
    localparam ONE_PI = TWO_PI >>1;
    localparam HALF_PI = ONE_PI >>1;

    //==========================================
    //amp correction
    //5个clk
    //==========================================

    //----------------data shift------------------
    //1 clk
    reg 	[DW-1:0]	x_gain_tmp_r0		;// >> 1
    reg 	[DW-1:0]	x_gain_tmp_r1		;// >> 3
    reg 	[DW-1:0]	x_gain_tmp_r2		;// >> 6
    reg 	[DW-1:0]	x_gain_tmp_r3		;// >> 9

    reg 	[DW-1:0]	y_gain_tmp_r0		;// >> 1
    reg 	[DW-1:0]	y_gain_tmp_r1		;// >> 3
    reg 	[DW-1:0]	y_gain_tmp_r2		;// >> 6
    reg 	[DW-1:0]	y_gain_tmp_r3		;// >> 9

    reg                 dv_int1             ;
    reg     [AW+2-1:0]  info_int1           ;
    
    always @(posedge clk) begin
        if (rst==1'b1) begin
            x_gain_tmp_r0 <= 'd0;
            x_gain_tmp_r1 <= 'd0;
            x_gain_tmp_r2 <= 'd0;
            x_gain_tmp_r3 <= 'd0;
            y_gain_tmp_r0 <= 'd0;
            y_gain_tmp_r1 <= 'd0;
            y_gain_tmp_r2 <= 'd0;
            y_gain_tmp_r3 <= 'd0;
            dv_int1 <= 1'b0;
            info_int1 <= 'd0;
        end else if(pi_dv == 1'b1)begin
            x_gain_tmp_r0 <= pi_x >>> 1;
            x_gain_tmp_r1 <= pi_x >>> 3;
            x_gain_tmp_r2 <= pi_x >>> 6;
            x_gain_tmp_r3 <= pi_x >>> 9;
            y_gain_tmp_r0 <= pi_y >>> 1;
            y_gain_tmp_r1 <= pi_y >>> 3;
            y_gain_tmp_r2 <= pi_y >>> 6;
            y_gain_tmp_r3 <= pi_y >>> 9;
            dv_int1 <= 1'b1;
            info_int1 <= pi_info;
        end else begin
            dv_int1 <= 1'b0;
        end
    end
    
    // tmp_r0 + tmp_r1;
    // tmp_r2 + tmp_r3;
    // 1 clk
    reg 	[DW-1:0] 	x_add_gain_r0		;// gain_tmp_r0 + gain_tmp_r1
    reg 	[DW-1:0]	x_add_gain_r1		;// gain_tmp_r1 + gain_tmp_r2
    reg 	[DW-1:0] 	y_add_gain_r0		;// gain_tmp_r0 + gain_tmp_r1
    reg 	[DW-1:0]	y_add_gain_r1		;// gain_tmp_r1 + gain_tmp_r2
    reg                 dv_int2             ;
    reg     [AW+2-1:0]  info_int2           ;
    always @(posedge clk) begin
        if (rst==1'b1) begin
            x_add_gain_r0 <= 'd0;
            x_add_gain_r1 <= 'd0;
            y_add_gain_r0 <= 'd0;
            y_add_gain_r1 <= 'd0;
            dv_int2 <= 1'b0;
            info_int2 <= 'd0;
        end else if(dv_int1 == 1'b1)begin
            x_add_gain_r0 <= x_gain_tmp_r0 + x_gain_tmp_r1;
            x_add_gain_r1 <= x_gain_tmp_r2 + x_gain_tmp_r3;	
            y_add_gain_r0 <= y_gain_tmp_r0 + y_gain_tmp_r1;
            y_add_gain_r1 <= y_gain_tmp_r2 + y_gain_tmp_r3;	
            dv_int2 <= 1'b1;
            info_int2 <= info_int1;
        end else begin
            dv_int2 <= 1'b0;
        end
    end
    
    //----------------sub------------------
    // add_gain_r0 - add_gain_r1
    // 1 clk
    reg 	[DW-1:0]	x_diff_gain_r0	; // add_gain_r0 - add_gain_r1
    reg 	[DW-1:0]	x_diff_gain_r0_dd	;
    reg 	[DW-1:0]	y_diff_gain_r0	; // add_gain_r0 - add_gain_r1
    reg 	[DW-1:0]	y_diff_gain_r0_dd	;
    reg                 dv_int3         ;
    reg     [AW+2-1:0]  info_int3           ;
    always @(posedge clk) begin
        if (rst==1'b1) begin
            x_diff_gain_r0 <= 'd0;	
            y_diff_gain_r0 <= 'd0;	
            dv_int3 <= 1'b0;
            info_int3 <= 'd0;
        end else if(dv_int2 == 1'b1)begin
            x_diff_gain_r0 <= x_add_gain_r0 - x_add_gain_r1;
            y_diff_gain_r0 <= y_add_gain_r0 - y_add_gain_r1;
            dv_int3 <= 1'b1;
            info_int3 <= info_int2;
        end else begin
            dv_int3 <= 1'b0;
        end
    end

    always @(posedge clk ) begin
        if (rst==1'b1) begin
            x_diff_gain_r0_dd <= 'd0;
            y_diff_gain_r0_dd <= 'd0;
        end else begin
            x_diff_gain_r0_dd <=  x_diff_gain_r0;
            y_diff_gain_r0_dd <= y_diff_gain_r0;
        end
    end
    
    //----------------shift 12bit /4096------------------
    // diff_gain_r0 >> 12
    //1 clk
    reg 	[DW-1:0]	x_gain_tmp_r4		;// >> 12
    reg 	[DW-1:0]	y_gain_tmp_r4		;// >> 12
    reg                 dv_int4;
    reg     [AW+2-1:0]  info_int4           ;
    always @(posedge clk) begin
        if (rst==1'b1) begin
            x_gain_tmp_r4 <= 'd0;
            y_gain_tmp_r4 <= 'd0;
            dv_int4 <= 1'b0;
            info_int4 <= 'd0;
        end else if(dv_int3 == 1'b1) begin
            x_gain_tmp_r4 <= x_diff_gain_r0 >>> 12;
            y_gain_tmp_r4 <= y_diff_gain_r0 >>> 12;
            dv_int4 <= 1'b1;
            info_int4 <= info_int3;
        end else begin
            dv_int4 <= 1'b0;
        end
    end
    
    // 1 clk
    reg 	[DW-1:0]	x_diff_gain_r1	;
    reg 	[DW-1:0]	y_diff_gain_r1	;
    reg                 dv_int5;
    reg     [AW+2-1:0]  info_int5           ;
    always @(posedge clk) begin
        if (rst==1'b1) begin
            x_diff_gain_r1 <= 'd0;
            y_diff_gain_r1 <= 'd0;
            dv_int5 <= 1'b0;
            info_int5 <= 'd0;
        end else if(dv_int4 == 1'b1)begin
            x_diff_gain_r1 <= x_diff_gain_r0_dd - x_gain_tmp_r4;
            y_diff_gain_r1 <= y_diff_gain_r0_dd - y_gain_tmp_r4;
            dv_int5 <= 1'b1;
            info_int5 <= info_int4;
        end else begin
            dv_int5 <= 1'b0;
        end
    end

    always @(posedge clk ) begin
        if (rst==1'b1) begin
            po_dv <= 1'b0;
            po_x <= 'd0;
            po_y <= 'd0;
        end else if (dv_int5 == 1'b1) begin
            po_dv <= 1'b1;
            case (info_int5[AW+2-1 -:2])
                2'b00 : begin
                    po_x <= x_diff_gain_r1;
                    po_y <= y_diff_gain_r1;
                end

                2'b01 : begin
                    po_x <= x_diff_gain_r1;
                    po_y <= ~y_diff_gain_r1 + 1'b1;
                end

                2'b10 : begin
                    po_x <= ~x_diff_gain_r1 + 1'b1;
                    po_y <= y_diff_gain_r1 ;
                end

                2'b11 : begin
                    po_x <= ~x_diff_gain_r1 + 1'b1;
                    po_y <= ~y_diff_gain_r1 + 1'b1;
                end
            endcase
        end else begin
            po_dv <=  1'b0;
        end
    end
    
    //====================================================
    //Restore the angle, restore the original angle 
    //according to the obtained quadrant information
    //====================================================
    // 1 clk
    reg 	[AW-1:0]	angle_abs 	;
    reg 	[1:0]	data_info_dd0   ;
    reg                 angle_dv1   ;
    always @(posedge clk) begin
        if (rst==1'b1) begin
            angle_abs <= 'd0;
            data_info_dd0 <= 'd0;
            angle_dv1 <= 1'b0;
        end else if (pi_dv) begin
            angle_dv1 <= 1'b1;
            if (pi_z[AW-1] == 1'b1) begin
                angle_abs <= ~pi_z + 1'b1;
                data_info_dd0 <= pi_info[AW+2-1:AW+2-2];
            end
            else begin
                angle_abs <= pi_z;
                data_info_dd0 <= pi_info[AW+2-1:AW+2-2];
            end
        end else begin
            angle_dv1 <= 1'b0;
        end
    end
    
    //1 clk
    reg 	[19:0]	angle_tmp;
    reg             angle_dv2;
    always @(posedge clk) begin
        if (rst==1'b1) begin
            angle_tmp <= 'd0;
            angle_dv2 <= 1'b0;
        end
        else if(angle_dv1 == 1'b1)begin
            angle_dv2 <= 1'b1;
            case(data_info_dd0)
                // first quarant
                2'b00 : begin
                    angle_tmp <= angle_abs;
                end
                // fourth quarant
                2'b01 : begin
                    angle_tmp <= TWO_PI - angle_abs;
                end
                // second quarant 
                2'b10 : begin
                    angle_tmp <= ONE_PI - angle_abs;
                end
                // third quarant 
                2'b11 : begin
                    angle_tmp <= ONE_PI + angle_abs;
                end
            endcase
        end else begin
            angle_dv2 <= 1'b0;
        end
    end
    
    //----------------po_dv_r, po_angle_r------------------
    reg 	[AW*4-1:0]	po_angle_r ;
    always @(posedge clk) begin
        if (rst==1'b1) begin
            po_angle_r <= 'd0;
        end
        else begin
            po_angle_r <= {po_angle_r[AW*3-1:0],angle_tmp};		
        end
    end
    // assign po_dv = dv_int5;
    assign po_angle = po_angle_r[AW*4-1 -: AW];
    assign po_amp = po_x[DW-1]? (~po_x + 1) : po_x;
    // assign po_x = x_diff_gain_r1;
    // assign po_y = y_diff_gain_r1;
    

endmodule