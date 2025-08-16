`default_nettype none
//-------------------------------------------------------------------------------------------------
module psd
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock50,

	output wire[ 1:0] sync,
	output wire[17:0] rgb,

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
	//output wire[ 1:0] dramDQM,
	//inout  wire[15:0] dramDQ,
	//output wire[ 1:0] dramBA,
	//output wire[12:0] dramA,

	input  wire       spiCk,
	input  wire       spiSs1,
	input  wire       spiSs2,
	input  wire       spiSs3,
	input  wire       spiMosi,
	inout  wire       spiMiso,

	output wire[ 2:0] led
);
//--- clock ---------------------------------------------------------------------------------------

	wire clock0, lock0;
	pll0 pll0(clock50, clock0, lock0); // 56.000 MHz

	wire clock1, lock1;
	pll1 pll1(clock50, clock1, lock1); // 56.488 MHz

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

	//assign sync = { 1'b1, ~(hsync^vsync) };
	//assign rgb = { {3{ r, r&i }}, {3{ g, g&i }}, {3{ b, b&i }} };

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
	wire[ 7:0] memQ;
	wire       memB;
	wire[ 7:0] memM;
	wire       memW;

	wire       mapped;
	wire       ramcs;
	wire[ 3:0] page;

	wire[7:0] homeQ;
	dprfm #(64, "../rom/tc2068-0.mif") home
	(
		clock,
		{ 2'b01, va },
		vd,
		clock,
		romE ? dioA[15:0] : memA,
		romE ? dioD : memD,
		homeQ,
		romE ? dioW : memW && memA[15:13] >= 2 && !memM[memA[15:13]]
	);

	wire[7:0] extdQ;
	romm #(8, "../rom/tc2068-1.mif") extd(clock, memA[12:0], extdQ);

	wire[7:0] dockQ;
	ram #(64) dock
	(
		clock,
		dckE ? dioA[15:0] : memA,
		dckE ? dioD : memD,
		dockQ,
		dioW
	);

	wire[7:0] dromQ;
	romm #(8, "../rom/esxdos.mif") drom(clock, memA[12:0], dromQ);

	wire[7:0] dramQ;
	ram #(128) dram(clock, { page, memA[12:0] }, memD, dramQ, memW && memA[15:13] == 1 && mapped);

	reg[7:0] dckS = 0;
	always @(posedge clock) if(dckE) dckS <= dioA[15:13];

	wire[7:0] memB0 = memA[15:13] <= dckS ? dockQ : 8'hFF;
	wire[7:0] memB1 = memA[15:13] <= 0 ? extdQ : 8'hFF;

	assign memQ 
		= memA[15:14] == 0 && mapped ? (ramcs ? dramQ : dromQ)
		: memM[memA[15:13]] ? (memB ? memB1 : memB0)
		: homeQ;

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

	mist mist
	(
		.clock  (clock  ),
		.cep1x  (ne14M  ),
		.cep2x  (ne28M  ),
		.hsync  (hsync  ),
		.vsync  (vsync  ),
		.r      ({3{ r, r&i }}),
		.g      ({3{ g, g&i }}),
		.b      ({3{ b, b&i }}),
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

//--- ts ------------------------------------------------------------------------------------------

	wire model = status[3];
	wire divmmc = status[4];

	wire reset = power && F9 && !romE && !dckE && !status[1];
	wire nmi = (F5 && !status[2]) || mapped;

	wire ear = tzxBusy ? tzxTape : ~tape;

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
		.nmi    (nmi    ),
		.va     (va     ),
		.vd     (vd     ),
		.memA   (memA   ),
		.memD   (memD   ),
		.memQ   (memQ   ),
		.memB   (memB   ),
		.memM   (memM   ),
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

	assign dramCk = 1'b0;
	assign dramCe = 1'b0;
	assign dramCs = 1'b1;
	assign dramWe = 1'b1;
	assign dramRas = 1'b1;
	assign dramCas = 1'b1;

	assign led = { sdcCs, ~ear, 1'b1};

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
