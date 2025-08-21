//-------------------------------------------------------------------------------------------------
module mist
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock,
	input  wire       cep1x,
	input  wire       cep2x,

	input  wire       hsync,
	input  wire       vsync,
	input  wire[ 5:0] r,
	input  wire[ 5:0] g,
	input  wire[ 5:0] b,

	output wire[ 1:0] sync,
	output wire[17:0] rgb,

	output wire[ 7:0] joy1,
	output wire[ 7:0] joy2,

	output wire       ps2kCk,
	output wire       ps2kD,

	input  wire       sdcCs,
	input  wire       sdcCk,
	input  wire       sdcMosi,
	output wire       sdcMiso,

	output wire       romE,
	output wire       dckE,
	output wire       tzxE,
	output wire[26:0] dioA,
	output wire[ 7:0] dioD,
	output wire[31:0] dioS,
	output wire       dioW,

	input  wire       spiCk,
	input  wire       spiSs1,
	input  wire       spiSs2,
	input  wire       spiSs3,
	input  wire       spiMosi,
	output wire       spiMiso,

	output wire[63:0] status
);
//-------------------------------------------------------------------------------------------------

localparam CONF_STR =
{
	"TS2068;;",
	"F1,ROM,Load ROM;",
	"F2,DCK,Load DCK;",
	"F3,TZX,Load TZX;",
	"S0,VHD,Mount SD;",
	"-;",
	"O3,Model,PAL,NTSC;",
	"O4,DivMMC,Off,On;",
	"-;",
	"T1,Reset;",
	"T2,NMI;",
	"T5,Remove DCK;",
	"V,V2.0,2025.08.10;",
};

//-------------------------------------------------------------------------------------------------

wire novga;

wire[ 8:0] mouse_x;
wire[ 8:0] mouse_y;
wire[ 7:0] mouse_flags;
wire       mouse_strobe;

wire[31:0] joystick_1;
wire[31:0] joystick_2;

wire       sdRd;
wire       sdWr;
wire       sdAck;
wire[31:0] sdLba;
wire       sdBusy;
wire       sdConf;
wire       sdSdhc;
wire       sdAckCf;
wire[ 8:0] sdBuffA;
wire[ 7:0] sdBuffD;
wire[ 7:0] sdBuffQ;
wire       sdBuffW;
wire       imgMntd;
wire[63:0] imgSize;

user_io #(.STRLEN(159), .SD_IMAGES(1), .FEATURES(32'h2000)) user_io
(
	.conf_str      (CONF_STR),
	.conf_addr     (        ),
	.conf_chr      (8'd0    ),

	.clk_sys       (clock  ),
	.clk_sd        (clock  ),

	.SPI_CLK       (spiCk  ),
	.SPI_SS_IO     (spiSs1 ),
	.SPI_MOSI      (spiMosi),
	.SPI_MISO      (spiMiso),

	.ps2_kbd_clk   (ps2kCk ),
	.ps2_kbd_data  (ps2kD  ),
	.ps2_kbd_clk_i (1'b0   ),
	.ps2_kbd_data_i(1'b0   ),

	.mouse_x       (mouse_x),
	.mouse_y       (mouse_y),
	.mouse_z       (),
	.mouse_idx     (),
	.mouse_flags   (mouse_flags),
	.mouse_strobe  (mouse_strobe),

	.joystick_0    (joystick_2),
	.joystick_1    (joystick_1),
	.joystick_2    (),
	.joystick_3    (),
	.joystick_4    (),
	.joystick_analog_0(),
	.joystick_analog_1(),

	.ypbpr         (),
	.status        (status),
	.buttons       (),
	.switches      (),
	.no_csync      (),
	.core_mod      (),
	.scandoubler_disable(novga),

	.sd_rd         (sdRd   ),
	.sd_wr         (sdWr   ),
	.sd_ack        (sdAck  ),
	.sd_lba        (sdLba  ),
	.sd_conf       (sdConf ),
	.sd_sdhc       (sdSdhc ),
	.sd_ack_x      (),
	.sd_ack_conf   (sdAckCf),
	.sd_buff_addr  (sdBuffA),
	.sd_din        (sdBuffD),
	.sd_dout       (sdBuffQ),
	.sd_dout_strobe(sdBuffW),
	.sd_din_strobe (),
	.img_size      (imgSize),
	.img_mounted   (imgMntd),

	.rtc           (),

	.leds          (8'd0),
	.key_code      (),
	.key_strobe    (),
	.key_pressed   (),
	.key_extended  (),
	.kbd_out_data  (8'd0),
	.kbd_out_strobe(1'b0),

	.ps2_mouse_clk (),
	.ps2_mouse_data(),
	.ps2_mouse_clk_i(1'b0),
	.ps2_mouse_data_i(1'b0),

	.i2c_start     (),
	.i2c_read      (),
	.i2c_addr      (),
	.i2c_subaddr   (),
	.i2c_dout      (),
	.i2c_din       (8'hFF),
	.i2c_ack       (1'b1),
	.i2c_end       (1'b1),

	.serial_data   (8'd0),
	.serial_strobe (1'd0)
);

wire      dioE;
wire[7:0] dioI;

data_io data_io
(
	.clk_sys       (clock  ),
	.clkref_n      (1'b0   ),
	.SPI_SCK       (spiCk  ),
	.SPI_SS2       (spiSs2 ),
	.SPI_SS4       (1'b1   ),
	.SPI_DI        (spiMosi),
	.SPI_DO        (spiMiso),
	.ioctl_download(dioE   ),
	.ioctl_upload  (       ),
	.ioctl_index   (dioI   ),
	.ioctl_addr    (dioA   ),
	.ioctl_din     (8'hFF  ),
	.ioctl_dout    (dioD   ),
	.ioctl_wr      (dioW   ),
	.ioctl_fileext (       ),
	.ioctl_filesize(dioS   ),
	.QCSn          (1'b1),
	.QSCK          (1'b1),
	.QDAT          (4'd0),
	.hdd_clk       (1'b0),
	.hdd_cmd_req   (1'b0),
	.hdd_cdda_req  (1'b0),
	.hdd_dat_req   (1'b0),
	.hdd_cdda_wr   (),
	.hdd_status_wr (),
	.hdd_addr      (),
	.hdd_wr        (),
	.hdd_data_out  (),
	.hdd_data_in   (16'd0),
	.hdd_data_rd   (),
	.hdd_data_wr   (),
	.hdd0_ena      (),
	.hdd1_ena      ()
);

sd_card sd_card
(
	.clk_sys     (clock  ),
	.sd_rd       (sdRd   ),
	.sd_wr       (sdWr   ),
	.sd_ack      (sdAck  ),
	.sd_lba      (sdLba  ),
	.sd_conf     (sdConf ),
	.sd_sdhc     (sdSdhc ),
	.sd_ack_conf (sdAckCf),
	.sd_buff_addr(sdBuffA),
	.sd_buff_din (sdBuffD),
	.sd_buff_dout(sdBuffQ),
	.sd_buff_wr  (sdBuffW),
	.img_size    (imgSize),
	.img_mounted (imgMntd),
	.allow_sdhc  (1'b1   ),
	.sd_busy     (sdBusy ),
	.sd_cs       (sdcCs  ),
	.sd_sck      (sdcCk  ),
	.sd_sdi      (sdcMosi),
	.sd_sdo      (sdcMiso)
);

wire[5:0] ro, go, bo;

osd #(.OSD_AUTO_CE(1'b1), .BIG_OSD(1'b1)) osd
(
	.clk_sys(clock  ),
	.ce     (1'b0   ),
	.SPI_SCK(spiCk  ),
	.SPI_SS3(spiSs3 ),
	.SPI_DI (spiMosi),
	.rotate (2'd0   ),
	.HBlank (1'b0   ),
	.VBlank (1'b0   ),
	.HSync  (hsync  ),
	.VSync  (vsync  ),
	.R_in   (r      ),
	.G_in   (g      ),
	.B_in   (b      ),
	.R_out  (ro     ),
	.G_out  (go     ),
	.B_out  (bo     )
);

scandoubler #(.HCW(10)) scandoubler
(
	.clock   (clock  ),
	.novga   (novga  ),
	.ice     (cep1x  ),
	.isync   ({  vsync,  hsync }),
	.irgb    ({ ro, go, bo }),
	.oce     (cep2x  ),
	.osync   (sync   ),
	.orgb    (rgb    )
);

//-------------------------------------------------------------------------------------------------

assign joy1 = joystick_1[7:0];
assign joy2 = joystick_2[7:0];

assign romE = dioE && dioI == 1;
assign dckE = dioE && dioI == 2;
assign tzxE = dioE && dioI == 3;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
