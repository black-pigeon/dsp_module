`default_nettype	none

module	generic_fir #(
		parameter		NTAPS=43, IW=12, TW=IW, OW=2*IW+7,
		parameter [0:0]		FIXED_TAPS=1
	) (
		input	wire			i_clk, i_reset,

		input	wire			i_tap_wr,	// Ignored if FIXED_TAPS
		input	wire	[(TW-1):0]	i_tap,		// Ignored if FIXED_TAPS

		input	wire			i_ce,
		input	wire	[(IW-1):0]	i_sample,
		output	wire	[(OW-1):0]	o_result
		
	);

	// Local declarations

	reg 	[(TW-1):0] tap		[NTAPS:0];
	wire	[(TW-1):0] tapout	[NTAPS:0];
	wire	[(IW-1):0] sample	[NTAPS:0];
	wire	[(OW-1):0] result	[NTAPS:0];
	wire		tap_wr;

	genvar	k;
	

	// The first sample in our sample chain is the sample we are given
	assign	sample[0]	= i_sample;
	// Initialize the partial summing accumulator with zero
	assign	result[0]	= 0;

	// Initialize filter memory

	generate
	if(FIXED_TAPS)
	begin
		initial $readmemh("taps.txt", tap);

		assign	tap_wr = 1'b0;
	end else begin
		assign	tap_wr = i_tap_wr;
        always @(*) begin
            tap[0] = i_tap;
        end
	end
	

	for(k=0; k<NTAPS; k=k+1)
	begin: FILTER

		fir_tap #(
			.FIXED_TAPS(FIXED_TAPS),
			.IW(IW), .OW(OW), .TW(TW),
			.INITIAL_VALUE(0)
		) tapk(
			i_clk, i_reset,
			// Tap update circuitry
			tap_wr, tap[k], tapout[k],
			// Sample delay line
			i_ce, sample[k], sample[k+1],
			// The output accumulator
			result[k], result[k+1]
		);

		if (!FIXED_TAPS)
            always @(*) begin
                tap[NTAPS-1-k] = tapout[k+1];
            end

		// Make verilator happy

		// verilator lint_off UNUSED
		wire	[(TW-1):0]	unused_tap;
		if (FIXED_TAPS)
			assign	unused_tap    = tapout[k];
		// verilator lint_on UNUSED
		
	end endgenerate

	assign	o_result = result[NTAPS];

	// Make verilator happy

	// verilator lint_off UNUSED
	wire	[(TW):0]	unused;
	assign	unused = { i_tap_wr, i_tap };
	// verilator lint_on UNUSED
	
endmodule