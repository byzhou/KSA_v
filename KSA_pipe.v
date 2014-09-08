
`timescale 1ns/1ns
//`define _DEBUG_stg1_s_Plvl_out_
//`define _DEBUG_s_Plvl_in_
//`define _DEBUG_INPUT_BUFF_A_

module KSA_stg1 (s_Plvl, s_Glvl, Plvl_0, a, b, c);
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

  output [BITS-1:0]   s_Plvl, s_Glvl, Plvl_0;      // Sum output

  // PG wires:
  wire [BITS-1:0]   Plvl[LEVELS / 2:0], Glvl[LEVELS / 2:0];

  assign s_Plvl = Plvl[LEVELS / 2];
  assign s_Glvl = Glvl[LEVELS / 2];
  assign Plvl_0 = Plvl[0];

  // level 0 - Create PG-generators (red):
  assign Plvl[0][BITS-1:0] = a^b;
  assign Glvl[0][BITS-1:0] = a&b;

  // level 1 - END:
  genvar lvl;
  generate
    for (lvl = 1; lvl <= LEVELS / 2; lvl = lvl + 1) begin :gen_KSA_1
      // Create buffers (green)
      assign Plvl[lvl][2**(lvl-1)-1:0] = Plvl[lvl-1][2**(lvl-1)-1:0];
      assign Glvl[lvl][2**(lvl-1)-1:0] = Glvl[lvl-1][2**(lvl-1)-1:0];
      // Create PG calculators (yellow)
      assign Plvl[lvl][BITS-1:2**(lvl-1)] = Plvl[lvl-1][BITS-1:2**(lvl-1)] & Plvl[lvl-1][BITS-1 - 2**(lvl-1):0];
      assign Glvl[lvl][BITS-1:2**(lvl-1)] = (Plvl[lvl-1][BITS-1:2**(lvl-1)] & Glvl[lvl-1][BITS-1 - 2**(lvl-1):0]) | Glvl[lvl-1][BITS-1:2**(lvl-1)];
    end
  endgenerate

endmodule

module KSA_stg2 (s, i_Plvl, i_Glvl, Plvl_0, c);
  // BITS specifies how many bits should be in the adder
  parameter BITS = 64;
  // LEVELS shows how many levels are there in the adder.
  // *IMPORTANT*:
  // !!!    LEVELS = floor(log2(BITS))   !!!
  parameter LEVELS = 6;

  output [BITS:0]   s;      // Sum output

  input [BITS-1:0] i_Plvl; //input
  input [BITS-1:0] i_Glvl;
  input [BITS-1:0] Plvl_0;
  input            c;

  // PG wires:
  wire [BITS-1:0]   Plvl[LEVELS:LEVELS/2], Glvl[LEVELS:LEVELS/2];

  assign Plvl[LEVELS/2] = i_Plvl;
  assign Glvl[LEVELS/2] = i_Glvl;

  // level 1 - END:
  genvar lvl;
  generate
    for (lvl = (LEVELS/2 + 1); lvl <= LEVELS; lvl = lvl + 1) begin :gen_KSA_2
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
  assign s = {1'b0, Plvl_0}^{Glvl[LEVELS], c};
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

    wire [BITS-1:0]     s_Plvl_out,s_Glvl_out,Plvl_0_out;
    wire [BITS-1:0]     s_Plvl_in,s_Glvl_in,Plvl_0_in;

	// Input Buffers:
	REGS #(.BITS(BITS)) inputBUF_A (aIn, a, clk);
	REGS #(.BITS(BITS)) inputBUF_B (bIn, b, clk);
	REG 				inputBUF_C (cIn, c, clk);

    `ifdef _DEBUG_INPUT_BUFF_A_
    always begin
        #5
        $display ("time: %d, BufA In: %h", $time, aIn);
    end
    `endif

    `ifdef _DEBUG_INPUT_BUFF_B_
    always begin
        #5
        $display ("time: %d, BufB Out: %d", $time, bIn);
    end
    `endif

    `ifdef _DEBUG_INPUT_BUFF_C_
    always begin
        #5
        $display ("time: %d, BufC Out: %d", $time, cIn);
    end
    `endif

	// stage1:
    KSA_stg1 #(.BITS(BITS), .LEVELS(LEVELS)) stg1(s_Plvl_out, s_Glvl_out, Plvl_0_out, aIn, bIn, cIn);

    `ifdef _DEBUG_stg1_s_Plvl_out_
    always begin
        #5
        $display ("time: %d, s_Plvl_out: %d", $time, s_Plvl_out);
    end
    `endif

    `ifdef _DEBUG_stg1_s_Glvl_out_
    always begin
        #5
        $display ("time: %d, s_Glvl_out: %d", $time, s_Glvl_out);
    end
    `endif

    `ifdef _DEBUG_stg1_Plvl_0_out_
    always begin
        #5
        $display ("time: %d, Plvl_0_out: %d", $time, Plvl_0_out);
    end
    `endif

    // mid stage buffer:
	REGS #(.BITS(BITS)) plvl (s_Plvl_in, s_Plvl_out, clk);
	REGS #(.BITS(BITS)) glvl (s_Glvl_in, s_Glvl_out, clk);
	REGS #(.BITS(BITS)) plvl_0 (Plvl_0_in, Plvl_0_out, clk);

    `ifdef _DEBUG_s_Plvl_in_
    always begin
        #5
        $display ("time: %d, s_Plvl_in: %d", $time, s_Plvl_in);
    end
    `endif

    `ifdef _DEBUG_s_Glvl_in_
    always begin
        #5
        $display ("time: %d, s_Glvl_in: %d", $time, s_Glvl_in);
    end
    `endif

    // stage2:
    KSA_stg2 #(.BITS(BITS), .LEVELS(LEVELS)) stg2(sOut, s_Plvl_in, s_Glvl_in, Plvl_0_in, cIn);

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
		for (i = 0; i < BITS; i = i + 1) begin : reg_gen
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
