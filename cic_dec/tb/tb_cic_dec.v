`timescale  1ns / 1ps

module tb_cic_dec;

    function integer clogb2;
    input integer depth;
    for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
    endfunction

// fir_with_mult_ip Parameters

    parameter R     = 16;           // Decimation factor
    parameter M     = 1 ;           // Differential delay 1
    parameter N     = 3 ;           // Number of stages
    parameter BIN   = 12;           // Input data width
    parameter BOUT=(BIN + N*$clog2(R));
    parameter PERIOD = 10;

    parameter   SIGNAL_SOURCE_LEN = 200;

    // fir_with_mult_ip Inputs
    reg   clk                                  = 0 ;
    reg   rst                                  = 1 ;
    reg   [BIN-1:0]  i_sample                   = 0 ;
    reg   i_sample_valid                       = 0 ;

    reg     [11:0]  simu_lut    [SIGNAL_SOURCE_LEN-1:0];

    // fir_with_mult_ip Outputs
    wire  [BOUT-1:0]  o_sample                   ;
    wire  o_sample_valid                       ;

    integer i;


    initial
    begin
        forever #(PERIOD/2)  clk=~clk;
    end

    initial
    begin
        #(PERIOD*2) rst  =  0;
    end

        cic_dec_filter#(
            .R          ( R ),
            .M          ( M ),
            .N          ( N ),
            .BIN        ( BIN ),
            .BOUT       ( BOUT )
        )u_cic_dec_filter(
            .clk        ( clk        ),
            .rst        ( rst        ),
            .din        ( i_sample        ),
            .din_valid  ( i_sample_valid  ),
            .dout       ( o_sample       ),
            .dout_valid  ( o_sample_valid  )
        );



    initial begin
        $readmemh("./signal_source.txt", simu_lut) ;
        i = 0 ;
        i_sample_valid = 0 ;
        i_sample = 0 ;
        # 200 ;
        forever begin
            @(posedge clk) begin
                i_sample_valid          = 1'b1 ;
                i_sample         = simu_lut[i] ;
                if (i == SIGNAL_SOURCE_LEN-1) begin
                    i = 0 ;
                end else begin
                    i = i + 1 ;
                end
            end
        end
    end

endmodule