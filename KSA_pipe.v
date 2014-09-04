
module KSA (s, a, b, c);
  // BITS specifies how many bits should be in the adder
  parameter BITS = 64;
  // LEVELS shows how many levels are there in the adder.
  // *IMPORTANT*:
  // !!!    LEVELS = floor(log2(BITS))   !!!
  parameter LEVELS = 6;

  // IO's
  input [BITS-1:0]  a;
  input [BITS-1:0]  b;
  input             c;      // Carry in => set to 0 at input

  output [BITS:0]   s;      // Sum output

  // PG wires:
  wire [BITS-1:0]   Plvl[LEVELS:0], Glvl[LEVELS:0];

  // level 0 - Create PG-generators (red):
  assign Plvl[0][BITS-1:0] = a^b;
  assign Glvl[0][BITS-1:0] = a&b;

  // level 1 - END:
  genvar lvl;
  generate
    for (lvl = 1; lvl <= LEVELS; lvl = lvl + 1) begin
      // Create buffers (green)
      assign Plvl[lvl][2**(lvl-1)-1:0] = Plvl[lvl-1][2**(lvl-1)-1:0];
      assign Glvl[lvl][2**(lvl-1)-1:0] = Glvl[lvl-1][2**(lvl-1)-1:0];
      // Create PG calculators (yellow)
      assign Plvl[lvl][BITS-1:2**(lvl-1)] = Plvl[lvl-1][BITS-1:2**(lvl-1)] & Plvl[lvl-1][BITS-1 - 2**(lvl-1):0];
      assign Glvl[lvl][BITS-1:2**(lvl-1)] = (Plvl[lvl-1][BITS-1:2**(lvl-1)] & Glvl[lvl-1][BITS-1 - 2**(lvl-1):0]) | Glvl[lvl-1][BITS-1:2**(lvl-1)];
    end
  endgenerate
  // At this point all the carries are stored in the Glvl[LEVELS][BITS-1:0]

  // Calculate sum by shifting the carries left by 1 bit:
  assign s = {1'b0, Plvl[0]}^{Glvl[LEVELS], c};
endmodule


module KSA_pipe(s, a, b, c, clk);
	parameter BITS = 64;
	parameter LEVELS = 6;

	// IO's
	input [BITS-1:0]	a;
	input [BITS-1:0]	b;
	input				c;

	input clk;

	output [BITS:0]		s;

	// Wires:
	wire [BITS-1:0]		aIn;
	wire [BITS-1:0]		bIn;
	wire				cIn;

	wire [BITS:0]		sOut;



	// Input Buffers:
	REGS #(.BITS(BITS)) inputBUF_A (aIn, a, clk);
	REGS #(.BITS(BITS)) inputBUF_B (bIn, b, clk);
	REG 				inputBUF_C (cIn, c, clk);

	// Adder:
	KSA #(.BITS(BITS), .LEVELS(LEVELS))adder4 (sOut, aIn, bIn, cIn);

	// Output Buffers:
	REGS #(.BITS(BITS+1)) outputBUF_S (s, sOut, clk);

endmodule

module REGS (Q, D, clk);
	parameter BITS = 64;
	input [BITS-1:0]	D;
	input				clk;
	output [BITS-1:0]	Q;

	genvar i;
	generate
		for (i = 0; i < BITS; i = i + 1) begin
			REG RR (Q[i], D[i], clk);
		end

	endgenerate

endmodule

module REG (Q, D, clk);
	input		D;
	input 		clk;
	output reg 	Q;

	always @ (posedge clk) begin
		Q <= D;
	end

endmodule
