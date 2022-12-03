// -----------------------------------------------------------------------------
// Copyright (c) 2019-2022 All rights reserved
// -----------------------------------------------------------------------------
// Author 	 : WCC 1530604142@qq.com
// File   	 : cic_filter
// Create 	 : 2022-12-02
// Revise 	 : 2022-
// Editor 	 : Vscode, tab size (4)
// Version	 : v1.0  
// Functions : 
// 			   
// -----------------------------------------------------------------------------
module cic_dec_filter #(
    parameter R     = 32,           // Decimation factor
    parameter M     = 1 ,           // Differential delay 1 or 2
    parameter N     = 3 ,           // Number of stages
    parameter BIN   = 12,           // Input data width
    parameter BOUT  = 24            // BOUT=(BIN + N*$clog2((R*M))), 
) (
    input   wire                clk         ,
    input   wire                rst         ,
    
    input   wire    [BIN-1:0]   din         ,
    input   wire                din_valid   ,

    output  wire    [BOUT-1:0]  dout        ,
    output  wire                dout_valid  
);

    //====================================================
    // integerator
    // y(n) = y(n-1) + x(n)
    //====================================================
    generate    
        genvar i;
        for ( i=0 ; i<N ; i=i+1 ) begin :LOOP
            reg  [BOUT-1:0]acc;
            wire [BOUT-1:0]sum;
            if ( i == 0 ) begin
                assign sum = acc + {{(BOUT-BIN){din[BIN-1]}},din};
            end else begin
                assign sum = acc + ( LOOP[i-1].sum );
            end
            always@(posedge clk)begin
                if (rst==1'b1)begin
                    acc <= {(BOUT){1'd0}};
                end else if (din_valid == 1'b1) begin
                    acc <= sum;
                end   
            end    
        end
    endgenerate
    wire [BOUT-1:0]acc_out;
    assign acc_out=LOOP[N-1].sum;


    //====================================================
    // decimation
    // 
    //====================================================
    reg [$clog2(R)-1:0]cnt0;
    reg [BOUT-1:0]dec_out;
    assign dval = (cnt0==(R-1));
    always@(posedge clk)begin
        if (rst==1'b1) begin
            cnt0    <=  'd0;
            dec_out <=  'd0;
        end else if(din_valid == 1'b1)begin
            cnt0    <=  dval?'d0        :cnt0 + 1'd1;
            dec_out <=  dval?acc_out   :dec_out;
        end
    end


    //====================================================
    //comb
    //y(n) = x(n) - y(n-1)
    //====================================================
    generate
        genvar j;
        for ( j=0 ; j<N ; j=j+1 ) begin :LOOP2
            reg  [BOUT-1:0]comb[0:M-1];
            wire [BOUT-1:0]sub;   
            integer k;
            if ( j == 0 ) begin
                if (M==1) begin
                    assign sub = dec_out - comb[0];
                    always@(posedge clk )begin
                        if (rst==1'b1)begin
                            comb[0] <= {(BOUT){1'd0}};
                        end else begin
                            comb[0] <= (dval) ? dec_out : comb[0];
                        end
                    end  
                end else begin
                    assign sub = dec_out - comb[M-1];
                    always@(posedge clk )begin
                        if (rst==1'b1)begin
                            for (k = 0; k<M; k=k+1) begin
                                comb[k] <= {(BOUT){1'd0}};
                            end
                        end else if (dval) begin
                            comb[0] <= dec_out;
                            for (k = 1; k<M; k=k+1) begin
                                comb[k] <= comb[k-1];
                            end
                        end 
                    end  
                end
            end else begin
                if (M==1) begin
                    assign sub = LOOP2[j-1].sub - comb[0];
                    always@(posedge clk )begin
                        if (rst==1'b1)begin
                            comb[0] <= {(BOUT){1'd0}};
                        end else begin
                            comb[0] <= (dval) ? LOOP2[j-1].sub : comb[0];
                        end
                    end  
                end else begin
                    assign sub = LOOP2[j-1].sub - comb[M-1];
                    always@(posedge clk )begin
                        if (rst==1'b1)begin
                            for (k = 0; k<M; k=k+1) begin
                                comb[k] <= {(BOUT){1'd0}};
                            end
                        end else if(dval)begin
                            comb[0] <=  LOOP2[j-1].sub;
                            for (k = 1; k<M; k=k+1) begin
                                comb[k] <= comb[k-1];
                            end
                        end
                    end 
                end
                
            end
        end
        endgenerate
        assign dout = LOOP2[N-1].sub;


        reg comb_valid;
        always @(posedge clk ) begin
            if (rst==1'b1) begin
                comb_valid <= 1'b0;
            end else begin
                comb_valid <= dval;
            end
        end
        assign dout_valid = comb_valid;

endmodule