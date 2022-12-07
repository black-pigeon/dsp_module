`timescale  1ns / 1ps

module tb_fir_with_mult_ip;

    function integer clogb2;
    input integer depth;
    for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
    endfunction

// fir_with_mult_ip Parameters
parameter PERIOD = 10                ;
parameter IW     = 12                ;
parameter TW     = 12                ;
parameter NTAPS  = 85                ;
parameter OW     = IW+TW+7;

parameter   SIGNAL_SOURCE_LEN = 200;

// fir_with_mult_ip Inputs
reg   clk                                  = 0 ;
reg   rst                                  = 1 ;
reg   [IW-1:0]  i_sample                   = 0 ;
reg   i_sample_valid                       = 0 ;

reg     [11:0]  simu_lut    [SIGNAL_SOURCE_LEN-1:0];

// fir_with_mult_ip Outputs
wire  [OW-1:0]  o_sample                   ;
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

    generic_fir #(
        .NTAPS(NTAPS ),
        .IW(IW ),
        .TW(TW ),
        .OW(OW ),
        .FIXED_TAPS (1'b1 )
    ) generic_fir_dut (
        .i_clk (clk ),
        .i_reset (rst ),
        .i_tap_wr (1'b0 ),
        .i_tap ('d0 ),
        .i_ce (i_sample_valid ),
        .i_sample (i_sample ),
        .o_result  ( o_sample)
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
            end
            else begin
                i = i + 1 ;
            end
        end
    end
end

endmodule