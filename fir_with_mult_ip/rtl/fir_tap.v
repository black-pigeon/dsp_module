// -----------------------------------------------------------------------------
// Copyright (c) 2019-2022 All rights reserved
// -----------------------------------------------------------------------------
// Author 	 : WCC 1530604142@qq.com
// File   	 : fir_tap
// Create 	 : 2022-12-02
// Revise 	 : 2022-
// Editor 	 : Vscode, tab size (4)
// Version	 : v1.0  
// Functions : 
// 			   
// -----------------------------------------------------------------------------
module	fir_tap #(
    parameter		IW=16, TW=IW, OW=IW+TW+8,
    parameter [0:0]		FIXED_TAPS=0,
    parameter [(TW-1):0]	INITIAL_VALUE=0
) (

    input	wire			i_clk, i_reset,
    // Coefficient setting/handling
    
    input	wire			i_tap_wr,
    input	wire	[(TW-1):0]	i_tap,
    output	wire signed [(TW-1):0]	o_tap,

    // Data pipeline

    input	wire			i_ce,
    input	wire signed [(IW-1):0]	i_sample,
    output	reg	[(IW-1):0]	o_sample,

    // Output "results"

    input	wire	[(OW-1):0]	i_partial_acc,
    output	reg	[(OW-1):0]	o_acc


);

// Local declarations

reg		[(IW-1):0]	delayed_sample;
reg	signed	[(TW+IW-1):0]	product;


// Determine the tap we are using
generate
if (FIXED_TAPS != 0)
    // If our taps are fixed, the tap is given by the i_tap
    // external input.  This allows the parent module to be
    // able to use readmemh to set all of the taps in a filter
    assign	o_tap = i_tap;

else begin
    // If the taps are adjustable, then use the i_tap_wr signal
    // to know when to adjust the tap.  In this case, taps are
    // strung together through the filter structure--our output
    // tap becomes the input tap of the next tap module, and
    // i_tap_wr causes all of them to shift forward by one.
    reg	[(TW-1):0]	tap;

    initial	tap = INITIAL_VALUE;
    always @(posedge i_clk)
    if (i_tap_wr)
        tap <= i_tap;
    assign o_tap = tap;

end endgenerate

// o_sample, delayed_sample

// Forward the sample on down the line, to be the input sample for the
// next component
initial	o_sample = 0;
initial	delayed_sample = 0;
always @(posedge i_clk)
if (i_reset)
begin
    delayed_sample <= 0;
    o_sample <= 0;
end else if (i_ce)
begin
    // Note the two sample delay in this forwarding
    // structure.  This aligns the inputs up so that the
    // accumulator structure (below) works.
    delayed_sample <= i_sample;
    o_sample <= delayed_sample;
end


`ifndef	FORMAL
// Multiply the filter tap by the incoming sample
always @(posedge i_clk)
    if (i_reset)
        product <= 0;
    else if (i_ce)
        product <= o_tap * i_sample;
`else

wire	[(TW+IW-1):0]	w_pre_product;

abs_mpy #(.AW(TW), .BW(IW), .OPT_SIGNED(1'b1))
    abs_bypass(i_clk, i_reset, o_tap, i_sample, w_pre_product);

initial	product = 0;
always @(posedge i_clk)
if (i_reset)
    product <= 0;
else if (i_ce)
    product <= w_pre_product;

`endif

// Continue summing together the output components of the FIR filter
initial	o_acc = 0;
always @(posedge i_clk)
if (i_reset)
    o_acc <= 0;
else if (i_ce)
    o_acc <= i_partial_acc
        + { {(OW-(TW+IW)){product[(TW+IW-1)]}}, product };

// Make verilator happy

// verilate lint_on  UNUSED
wire	unused;
assign	unused = i_tap_wr;
// verilate lint_off UNUSED

endmodule