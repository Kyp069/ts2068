`default_nettype none
//-------------------------------------------------------------------------------------------------
module clp
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock12,

	output wire[ 1:0] sync,
	output wire[11:0] rgb,

	input  wire       tape,

	output wire       i2sCk,
	output wire       i2sWs,
	output wire       i2sD,

	output wire       dramCk,
	output wire       dramCe,
	output wire       dramCs,
	output wire       dramWe,
	output wire       dramRas,
	output wire       dramCas,
	output wire[ 1:0] dramDQM,
	inout  wire[15:0] dramDQ,
	output wire[ 1:0] dramBA,
	output wire[11:0] dramA,

	input  wire       spiCk,
	input  wire       spiSs1,
	input  wire       spiSs2,
	input  wire       spiSs3,
	input  wire       spiMosi,
	inout  wire       spiMiso,

	output wire[ 7:0] led
);
//--- clock ---------------------------------------------------------------------------------------

	wire clock0, lock0;
	pll0 pll0(clock12, clock0, lock0); // 56.000 MHz

	wire clock1, lock1;
	pll1 pll1(clock12, clock1, lock1); // 56.488 MHz

	wire clock = model ? clock1 : clock0;
	wire power = lock0 & lock1;

	reg[3:0] ce;
	always @(negedge clock) if(!power) ce <= 1'd0; else ce <= ce+1'd1;

	wire ne28M = ce[0:0] == 1;
	wire ne14M = ce[1:0] == 3;
	wire ne7M0 = ce[2:0] == 7;
	wire pe7M0 = ce[2:0] == 3;
	wire ne3M5 = ce[3:0] == 15;
	wire pe3M5 = ce[3:0] == 7;

//--- video ---------------------------------------------------------------------------------------

	wire hsync;
	wire vsync;
	wire r;
	wire g;
	wire b;
	wire i;

//--- sound ---------------------------------------------------------------------------------------

	wire[14:0] left;
	wire[14:0] right;

	i2s i2s(clock, { 1'd0,  left }, { 1'd0, right }, i2sCk, i2sWs, i2sD);

//--- keyboard ------------------------------------------------------------------------------------

	wire      strb;
	wire[7:0] code;

	ps2k ps2k(clock, ps2kCk, ps2kD, strb, code);

	wire[4:0] col;
	wire[7:0] row;
	wire play;
	wire stop;
	wire F5;
	wire F9;

	matrix matrix(clock, strb, code, row, col, play, stop, F5, F9);

//--- memory --------------------------------------------------------------------------------------

	wire[13:0] va;
	wire[ 7:0] vd;

	wire[15:0] memA;
	wire[ 7:0] memD;
	wire       memB;
	wire[ 7:0] memM;
	wire       memR;
	wire       memW;

	wire       mapped;
	wire       ramcs;
	wire[ 3:0] page;

	dprs #(16) dpr(clock, va, vd, clock, memA[13:0], memD, memW && memA[15:14] == 2'b01);

	wire extd = memM[memA[15:13]] &&  memB;
	wire dock = memM[memA[15:13]] && !memB;
	wire home = !memM[memA[15:13]];

	reg memRd = 0;
	always @(posedge clock) if(pe3M5) memRd <= memR;

	wire       ready;
	wire[21:0] sdrA = { 2'd0, romE ? { 3'd0, dioA[16:0] } : mapped && memA[15:14] == 0 ? (ramcs ? { 3'd4, page, memA[12:0] } : { 3'd0, 4'd3, memA[12:0] }) : extd ? { 3'd0, 4'd2, memA[12:0] } : { memA[15:14] ? 3'd1 : 4'd0, memA[15:0] } };
	wire[15:0] sdrD = {2{ romE ? dioD : memD }};
	wire[15:0] sdrQ ;
	wire       sdrR = memRd && (extd || home);
	wire       sdrW = romE ? dioW : memW && ((memA[15:14] && (extd || home)) || (memA[15:14] == 0 && mapped && ramcs));
	wire       rfsh ;

	sdram sdram
	(
		.clock  (clock  ),
		.ready  (ready  ),
		.rfsh   (rfsh   ),
		.a      (sdrA   ),
		.d      (sdrD   ),
		.q      (sdrQ   ),
		.rd     (sdrR   ),
		.wr     (sdrW   ),
		.dramCs (dramCs ),
		.dramWe (dramWe ),
		.dramRas(dramRas),
		.dramCas(dramCas),
		.dramDQM(dramDQM),
		.dramDQ (dramDQ ),
		.dramBA (dramBA ),
		.dramA  (dramA  )
	);

	assign dramCk = clock;
	assign dramCe = 1'b1;

	wire[ 7:0] memQ = extd || home ? sdrQ[7:0] : 8'hFF;

//--- mist ----------------------------------------------------------------------------------------

	wire[7:0] joy1;
	wire[7:0] joy2;

	wire ps2kCk;
	wire ps2kD;

	wire sdcCs;
	wire sdcCk;
	wire sdcMosi;
	wire sdcMiso;

	wire       romE;
	wire       dckE;
	wire       tzxE;
	wire[26:0] dioA;
	wire[ 7:0] dioD;
	wire[31:0] dioS;
	wire       dioW;

	wire[63:0] status;

	mist #(.RGBW(12)) mist
	(
		.clock  (clock  ),
		.cep1x  (ne14M  ),
		.cep2x  (ne28M  ),
		.hsync  (hsync  ),
		.vsync  (vsync  ),
		.r      ({2{ r, r&i }}),
		.g      ({2{ g, g&i }}),
		.b      ({2{ b, b&i }}),
		.sync   (sync   ),
		.rgb    (rgb    ),
		.joy1   (joy1   ),
		.joy2   (joy2   ),
		.ps2kCk (ps2kCk ),
		.ps2kD  (ps2kD  ),
		.sdcCs  (sdcCs  ),
		.sdcCk  (sdcCk  ),
		.sdcMosi(sdcMosi),
		.sdcMiso(sdcMiso),
		.romE   (romE   ),
		.dckE   (dckE   ),
		.tzxE   (tzxE   ),
		.dioA   (dioA   ),
		.dioD   (dioD   ),
		.dioS   (dioS   ),
		.dioW   (dioW   ),
		.spiCk  (spiCk  ),
		.spiSs1 (spiSs1 ),
		.spiSs3 (spiSs3 ),
		.spiSs2 (spiSs2 ),
		.spiMosi(spiMosi),
		.spiMiso(spiMiso),
		.status (status )
	);

//--- tzx -----------------------------------------------------------------------------------------
	/*
	reg[15:0] tzxSize;
	always @(posedge clock) if(tzxE) tzxSize <= dioS[15:0];

	wire[ 7:0] ramQ;
	ram #(256) ram(clock, tzxE ? dioA[17:0] : tzxA, dioD, ramQ, tzxE && dioW);

	wire[17:0] tzxA;
	wire tzxBusy;
	wire tzxTape;

	// MS parameter should be 56000 for PAL and 56488 for NTSC
	tzx #(56000) tzx
	(
		.clock  (clock  ),
		.ce     (1'b1   ),
		.a      (tzxA   ),
		.d      (ramQ   ),
		.play   (!play  ),
		.stop   (!stop  ),
		.busy   (tzxBusy),
		.size   (tzxSize),
		.tape   (tzxTape)
	);
	*/
//--- ts ------------------------------------------------------------------------------------------

	wire model = status[3];
	wire divmmc = status[4];

	wire reset = power && ready && F9 && !romE && !dckE && !status[1] && !status[5];
	wire nmi = (F5 && !status[2]) || mapped;

	//wire ear = tzxBusy ? tzxTape : ~tape;
	wire ear = ~tape;

	ts ts
	(
		.model  (model  ),
		.divmmc (divmmc ),
		.clock  (clock  ),
		.ne14M  (ne14M  ),
		.ne7M0  (ne7M0  ),
		.pe7M0  (pe7M0  ),
		.ne3M5  (ne3M5  ),
		.pe3M5  (pe3M5  ),
		.reset  (reset  ),
		.rfsh   (rfsh   ),
		.nmi    (nmi    ),
		.va     (va     ),
		.vd     (vd     ),
		.memA   (memA   ),
		.memD   (memD   ),
		.memQ   (memQ   ),
		.memB   (memB   ),
		.memM   (memM   ),
		.memR   (memR   ),
		.memW   (memW   ),
		.mapped (mapped ),
		.ramcs  (ramcs  ),
		.page   (page   ),
		.hsync  (hsync  ),
		.vsync  (vsync  ),
		.r      (r      ),
		.g      (g      ),
		.b      (b      ),
		.i      (i      ),
		.ear    (ear    ),
		.left   (left   ),
		.right  (right  ),
		.col    (col    ),
		.row    (row    ),
		.joy1   (joy1   ),
		.joy2   (joy2   ),
		.sdcCs  (sdcCs  ),
		.sdcCk  (sdcCk  ),
		.sdcMosi(sdcMosi),
		.sdcMiso(sdcMiso)
	);

//-------------------------------------------------------------------------------------------------

	assign led = { ~sdcCs, ear };

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
