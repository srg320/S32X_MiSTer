// Copyright (c) 2010 Gregory Estrade (greg@torlus.com)
// Copyright (c) 2018 Sorgelig
//
// All rights reserved
//
// Redistribution and use in source and synthezised forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// Redistributions in synthesized form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.
//
// Neither the name of the author nor the names of other contributors may
// be used to endorse or promote products derived from this software without
// specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
// Please report bugs to the author, but before you do so, please
// make sure that this is not a derivative work and that
// you have the latest version of this file.

module gen
(
	input         RESET_N,
	input         MCLK,
	
	output [23:1] VA,
	input  [15:0] VDI,
	output [15:0] VDO,
	output        RNW,
	output        LDS_N,
	output        UDS_N,
	output        AS_N,
	input         DTACK_N,
	output        ASEL_N,
	output        VCLK_CE,
	output        CE0_N,
	output        LWR_N,
	output        UWR_N,
	output        CAS0_N,
	output        RAS2_N,
	output        CAS2_N,
	output        ROM_N,
	output        FDC_N,
	input         CART_N,
	input         DISK_N,
	output        TIME_N,
	
	input  [15:0] EXT_SL,
	input  [15:0] EXT_SR,

	input   [1:0] LPF_MODE,
	input         EN_GEN_FM,
	input         EN_GEN_PSG,
	input         EN_32X_PWM,
	output [15:0] DAC_LDATA,
	output [15:0] DAC_RDATA,

	input         LOADING,
	input         PAL,
	input         EXPORT,

	input         EN_HIFI_PCM,
	input         LADDER,
	input         OBJ_LIMIT_HIGH,
	input         FMBUSY_QUIRK,

	output  [3:0] RED,
	output  [3:0] GREEN,
	output  [3:0] BLUE,
	output        YS_N,
	output        EDCLK,
	output        VS,
	output        HS,
	output        HBL,
	output        VBL,
	output        CE_PIX,
	input         BORDER,

	output        INTERLACE,
	output        FIELD,
	output  [1:0] RESOLUTION,

	input         J3BUT,
	input  [11:0] JOY_1,
	input  [11:0] JOY_2,
	input  [11:0] JOY_3,
	input  [11:0] JOY_4,
	input  [11:0] JOY_5,
	input   [2:0] MULTITAP,

	input  [24:0] MOUSE,
	input   [2:0] MOUSE_OPT,
	
	input         GUN_OPT,
	input         GUN_TYPE,
	input         GUN_SENSOR,
	input         GUN_A,
	input         GUN_B,
	input         GUN_C,
	input         GUN_START,

	input   [7:0] SERJOYSTICK_IN,
	output  [7:0] SERJOYSTICK_OUT,
	input   [1:0] SER_OPT,

	output        RAM_CE_N,
	input         RAM_RDY,

	output        RFS,
	input         RFS_RDY,

	input         GG_RESET,
	input         GG_EN,
	input [128:0] GG_CODE,
	output        GG_AVAILABLE,
	
	input         PAUSE_EN,
	input         BGA_EN,
	input         BGB_EN,
	input         SPR_EN,
	input   [1:0] BG_GRID_EN,
	input         SPR_GRID_EN,

	output [23:0] DBG_M68K_A,
	output [23:0] DBG_MBUS_A,
	output [15:0] DBG_HOOK,
	output [7:0] DBG_HOOK2
);

reg reset;
always @(posedge MCLK) if(M68K_CLKENn) begin
	reset <= ~RESET_N | LOADING;
end


//--------------------------------------------------------------
// CLOCK ENABLERS
//--------------------------------------------------------------
wire M68K_CLKEN = M68K_CLKENp;
reg  M68K_CLKENp, M68K_CLKENn;
reg  Z80_CLKENp, Z80_CLKENn;

always @(negedge MCLK) begin
	reg [3:0] VCLKCNT = 0;
	reg [3:0] ZCLKCNT = 0;

	if(~RESET_N | LOADING) begin
		VCLKCNT <= 0;
		ZCLKCNT = 0;
		Z80_CLKENp <= 0;
		Z80_CLKENn <= 0;
		M68K_CLKENp <= 0;
		M68K_CLKENn <= 1;
	end
	else begin
		M68K_CLKENp <= 0;
		VCLKCNT <= VCLKCNT + 1'b1;
		if (VCLKCNT == 4'd6) begin
			VCLKCNT <= 0;
			M68K_CLKENp <= 1;
		end

		M68K_CLKENn <= 0;
		if (VCLKCNT == 4'd3) begin
			M68K_CLKENn <= 1;
		end
		
		Z80_CLKENn <= 0;
		ZCLKCNT <= ZCLKCNT + 1'b1;
		if (ZCLKCNT == 14) begin
			ZCLKCNT <= 0;
			Z80_CLKENn <= 1;
		end
		
		Z80_CLKENp <= 0;
		if (ZCLKCNT == 7) begin
			Z80_CLKENp <= 1;
		end

	end
end

reg [16:1] ram_rst_a;
always @(posedge MCLK) ram_rst_a <= ram_rst_a + LOADING;

//--------------------------------------------------------------
// CPU 68000
//--------------------------------------------------------------
wire [23:1] M68K_A;
wire [15:0] M68K_DO;
wire        M68K_AS_N;
wire        M68K_UDS_N;
wire        M68K_LDS_N;
wire        M68K_RNW;
wire  [2:0] M68K_FC;
wire        M68K_BG_N;
wire        M68K_BR_N;
wire        M68K_BGACK_N;
reg   [2:0] M68K_IPL_N;


assign M68K_BR_N = VBUS_BR_N & Z80_BR_N;
assign M68K_BGACK_N = VBUS_BGACK_N & Z80_BGACK_N;

fx68k M68K
(
	.clk(MCLK),
	.extReset(reset),
	.pwrUp(reset),
	.enPhi1(M68K_CLKENp),
	.enPhi2(M68K_CLKENn),

	.eRWn(M68K_RNW),
	.ASn(M68K_AS_N),
	.UDSn(M68K_UDS_N),
	.LDSn(M68K_LDS_N),

	.FC0(M68K_FC[0]),
	.FC1(M68K_FC[1]),
	.FC2(M68K_FC[2]),

	.BGn(M68K_BG_N),
	.BRn(M68K_BR_N),
	.BGACKn(M68K_BGACK_N),
	.HALTn(1),

	.DTACKn(M68K_MBUS_DTACK_N /*& DTACK_N*/),
	.VPAn(~M68K_INTACK),
	.BERRn(1),
	.IPL0n(1),
	.IPL1n(M68K_IPL_N[1]),
	.IPL2n(M68K_IPL_N[2]),
	.iEdb(/*genie_ovr ? genie_data : */MBUS_DI),
	.oEdb(M68K_DO),
	.eab(M68K_A)
);

wire M68K_INTACK = &M68K_FC & ~M68K_AS_N;

/*wire genie_ovr;
wire [15:0] genie_data;

CODES #(.ADDR_WIDTH(24), .DATA_WIDTH(16)) codes (
	.clk(MCLK),
	.reset(GG_RESET),
	.enable(~GG_EN),
	.addr_in({M68K_A[23:1], 1'b0}),
	.data_in(MBUS_DI),
	.code(GG_CODE),
	.available(GG_AVAILABLE),
	.genie_ovr(genie_ovr),
	.genie_data(genie_data)
);*/


//-----------------------------------------------------------------------
// 68K RAM
//-----------------------------------------------------------------------
dpram #(15) ram68k_u
(
	.clock(MCLK),
	.address_a(MBUS_A[15:1]),
	.data_a(MBUS_DO[15:8]),
	.wren_a(RAM_SEL & ~MBUS_RNW & ~MBUS_UDS_N),
	.q_a(ram68k_q[15:8]),

	.address_b(ram_rst_a[15:1]),
	.wren_b(LOADING)
);

dpram #(15) ram68k_l
(
	.clock(MCLK),
	.address_a(MBUS_A[15:1]),
	.data_a(MBUS_DO[7:0]),
	.wren_a(RAM_SEL & ~MBUS_RNW & ~MBUS_LDS_N),
	.q_a(ram68k_q[7:0]),

	.address_b(ram_rst_a[15:1]),
	.wren_b(LOADING)
);
wire [15:0] ram68k_q;

//--------------------------------------------------------------
// VDP + PSG
//--------------------------------------------------------------
reg         VDP_SEL;
wire [15:0] VDP_DO;
wire        VDP_DTACK_N;

wire [23:1] VBUS_A;
wire        VBUS_SEL;
wire        VBUS_BR_N;
wire        VBUS_BGACK_N;

wire        M68K_EXINT;
wire        M68K_HINT;
wire        M68K_VINT;

wire        Z80_INT_N;
wire        VRAM_RFRS;

wire [15:0] vram_a;
wire  [7:0] vram_d;
wire  [7:0] vram_q;
wire        vram_we;

vdp2 vdp
(
	.RST_n(~reset),
	.CLK(MCLK),
	.ENABLE(1),

	.VCLK_ENp(M68K_CLKENp),
	.VCLK_ENn(M68K_CLKENn),
	.SEL(VDP_SEL),
	.A(MBUS_A[4:1]),
	.RNW(MBUS_RNW),
	.AS_N(M68K_AS_N),
	.DI(MBUS_DO),
	.DO(VDP_DO),
	.DTACK_N(VDP_DTACK_N),

	.VRAM_A(vram_a),
	.VRAM_D(vram_d),
	.VRAM_Q(vram_q),
	.VRAM_WE(vram_we),
	
	.HL(HL),
	.HINT(M68K_HINT),
	.VINT(M68K_VINT),
	.IPL_N(M68K_IPL_N[2:1]),
	.INTACK(M68K_INTACK),
	.Z80_INT_N(Z80_INT_N),
	
	.REFRESH(VRAM_RFRS),

	.VBUS_ADDR(VBUS_A),
	.VBUS_DATA(MBUS_DI),
	.VBUS_SEL(VBUS_SEL),
	.VBUS_DTACK_N(VDP_MBUS_DTACK_N),

	.BG_N(M68K_BG_N),
	.BR_N(VBUS_BR_N),
	.BGACK_N(VBUS_BGACK_N),

	.FIELD_OUT(FIELD),
	.INTERLACE(INTERLACE),
	.RESOLUTION(RESOLUTION),

	.PAL(PAL),
	.R(RED),
	.G(GREEN),
	.B(BLUE),
	.YS_N(YS_N),
	.EDCLK(EDCLK),
	.HS_N(HS),
	.VS_N(VS),
	.CE_PIX(CE_PIX),
	.HBL(HBL),
	.VBL(VBL),
	
	.BORDER_EN(BORDER),
	.VSCROLL_BUG(0),
	
	.BGA_EN(BGA_EN),
	.BGB_EN(BGB_EN),
	.SPR_EN(SPR_EN),
	.BG_GRID_EN(BG_GRID_EN),
	.SPR_GRID_EN(SPR_GRID_EN)
);

dpram #(16,8) vram
(
	.clock(MCLK),
	.address_a(vram_a),
	.data_a(vram_d),
	.wren_a(vram_we),
	.q_a(vram_q),

	.address_b(ram_rst_a[16:1]),
	.wren_b(LOADING)
);


// PSG 0x10-0x17 in VDP space
wire signed [10:0] PSG_SND;
jt89 psg
(
	.rst(reset),
	.clk(MCLK),
	.clk_en(Z80_CLKENn),

	.wr_n(MBUS_RNW | ~VDP_SEL | ~MBUS_A[4] | MBUS_A[3]),
	.din(MBUS_DO[15:8]),

	.sound(PSG_SND)
);


//--------------------------------------------------------------
// Gamepads
//--------------------------------------------------------------
reg         IO_SEL;
wire  [7:0] IO_DO;
wire        IO_DTACK_N;

multitap multitap
(
	.RESET(reset),
	.CLK(MCLK),
	.CE(M68K_CLKEN),

	.J3BUT(J3BUT),

	.P1_UP(~JOY_1[3]),
	.P1_DOWN(~JOY_1[2]),
	.P1_LEFT(~JOY_1[1]),
	.P1_RIGHT(~JOY_1[0]),
	.P1_A(~JOY_1[4]),
	.P1_B(~JOY_1[5]),
	.P1_C(~JOY_1[6]),
	.P1_START(~JOY_1[7]),
	.P1_MODE(~JOY_1[8]),
	.P1_X(~JOY_1[9]),
	.P1_Y(~JOY_1[10]),
	.P1_Z(~JOY_1[11]),

	.P2_UP(~JOY_2[3]),
	.P2_DOWN(~JOY_2[2]),
	.P2_LEFT(~JOY_2[1]),
	.P2_RIGHT(~JOY_2[0]),
	.P2_A(~JOY_2[4]),
	.P2_B(~JOY_2[5]),
	.P2_C(~JOY_2[6]),
	.P2_START(~JOY_2[7]),
	.P2_MODE(~JOY_2[8]),
	.P2_X(~JOY_2[9]),
	.P2_Y(~JOY_2[10]),
	.P2_Z(~JOY_2[11]),

	.P3_UP(~JOY_3[3]),
	.P3_DOWN(~JOY_3[2]),
	.P3_LEFT(~JOY_3[1]),
	.P3_RIGHT(~JOY_3[0]),
	.P3_A(~JOY_3[4]),
	.P3_B(~JOY_3[5]),
	.P3_C(~JOY_3[6]),
	.P3_START(~JOY_3[7]),
	.P3_MODE(~JOY_3[8]),
	.P3_X(~JOY_3[9]),
	.P3_Y(~JOY_3[10]),
	.P3_Z(~JOY_3[11]),

	.P4_UP(~JOY_4[3]),
	.P4_DOWN(~JOY_4[2]),
	.P4_LEFT(~JOY_4[1]),
	.P4_RIGHT(~JOY_4[0]),
	.P4_A(~JOY_4[4]),
	.P4_B(~JOY_4[5]),
	.P4_C(~JOY_4[6]),
	.P4_START(~JOY_4[7]),
	.P4_MODE(~JOY_4[8]),
	.P4_X(~JOY_4[9]),
	.P4_Y(~JOY_4[10]),
	.P4_Z(~JOY_4[11]),
	
	.P5_UP(~JOY_5[3]),
	.P5_DOWN(~JOY_5[2]),
	.P5_LEFT(~JOY_5[1]),
	.P5_RIGHT(~JOY_5[0]),
	.P5_A(~JOY_5[4]),
	.P5_B(~JOY_5[5]),
	.P5_C(~JOY_5[6]),
	.P5_START(~JOY_5[7]),
	.P5_MODE(~JOY_5[8]),
	.P5_X(~JOY_5[9]),
	.P5_Y(~JOY_5[10]),
	.P5_Z(~JOY_5[11]),

	.DISK(~DISK_N),

	.FOURWAY_EN(MULTITAP == 1),
	.TEAMPLAYER_EN({MULTITAP == 3,MULTITAP == 2}),

	.MOUSE(MOUSE),
	.MOUSE_OPT(MOUSE_OPT),
	
	.GUN_OPT(GUN_OPT),
	.GUN_TYPE(GUN_TYPE),
	.GUN_SENSOR(GUN_SENSOR),
	.GUN_A(GUN_A),
	.GUN_B(GUN_B),
	.GUN_C(GUN_C),
	.GUN_START(GUN_START),

	.SERJOYSTICK_IN(SERJOYSTICK_IN),
	.SERJOYSTICK_OUT(SERJOYSTICK_OUT),
	.SER_OPT(SER_OPT),

	.PAL(PAL),
	.EXPORT(EXPORT),

	.SEL(IO_SEL),
	.A(MBUS_A[4:1]),
	.RNW(MBUS_RNW),
	.DI(MBUS_DO[7:0]),
	.DO(IO_DO),
	.DTACK_N(IO_DTACK_N),
	.HL(HL)
);

//-----------------------------------------------------------------------
// MBUS Handling
//-----------------------------------------------------------------------
reg         M68K_MBUS_DTACK_N;
reg         Z80_MBUS_DTACK_N;
reg         VDP_MBUS_DTACK_N;

reg  [15:0] M68K_MBUS_D;
reg  [15:0] VDP_MBUS_D;

reg  [23:1] MBUS_A;
reg  [15:0] MBUS_DO;

reg         MBUS_RNW;
reg         MBUS_AS_N;
reg         MBUS_UDS_N;
reg         MBUS_LDS_N;
wire [15:0] MBUS_DI;
reg         MBUS_ASEL_N;

reg  [15:0] OPEN_BUS;

reg         ROM_SEL;
reg         RAM_SEL;
reg         FDC_SEL;
reg         TIME_SEL;

reg   [3:0] mstate;
reg   [1:0] msrc;

localparam	MSRC_NONE = 0,
				MSRC_M68K = 1,
				MSRC_Z80  = 2,
				MSRC_VDP  = 3;

localparam 	MBUS_IDLE         = 0,
				MBUS_SELECT       = 1,
				MBUS_RAM_WAIT     = 2,
				MBUS_RAM_READ     = 3,
				MBUS_RAM_WRITE    = 4,
				MBUS_ROM_READ     = 5,
				MBUS_VDP_READ     = 6,
				MBUS_IO_READ      = 7,
				MBUS_ROM_WAIT     = 8,
				MBUS_ZBUS_READ    = 9,
				MBUS_FDC_READ     = 10,
				MBUS_TIME_READ    = 11,
				MBUS_NOT_USED     = 12,
				MBUS_ROM_REFRESH  = 13,
				MBUS_RAM_REFRESH  = 14,
				MBUS_FINISH       = 15; 

always @(posedge MCLK) begin
	reg [9:0] refresh_timer, refresh_timer2;
	reg rfs_ram_pend, rfs_rom_pend;
	reg [1:0] rfs_wait;
	reg [1:0] cycle_cnt;

	reg RAM_RDY_OLD;
	
	if (reset) begin
		M68K_MBUS_DTACK_N <= 1;
		Z80_MBUS_DTACK_N  <= 1;
		VDP_MBUS_DTACK_N  <= 1;
		MBUS_UDS_N <= 1;
		MBUS_LDS_N <= 1;
		MBUS_RNW <= 1;
		MBUS_AS_N <= 1;
		ROM_SEL <= 0;
		RAM_SEL <= 0;
		VDP_SEL <= 0;
		IO_SEL <= 0;
		CTRL_SEL <= 0;
		ZBUS_SEL <= 0;
		FDC_SEL <= 0;
		mstate <= MBUS_IDLE;
		OPEN_BUS <= 'h4E71;
		TIME_SEL <= 0;

		RFS <= 0;
		DBG_HOOK <= 0;
		DBG_HOOK2 <= 0;
	end
	else begin
		if (M68K_CLKENp) begin
			refresh_timer <= refresh_timer + 1'd1;
			if (VRAM_RFRS) begin
				refresh_timer <= 0;
				rfs_rom_pend <= 0;
			end
			else if (refresh_timer == 'd119) begin
				refresh_timer <= 0;
				//rfs_rom_pend <= 1;
			end
			
			refresh_timer2 <= refresh_timer2 + 1'd1;
			if (VRAM_RFRS) begin
				refresh_timer2 <= 0;
				rfs_ram_pend <= 0;
			end
			else if (refresh_timer2 == 'd119) begin
				refresh_timer2 <= 0;
				//rfs_ram_pend <= 1;
			end
			
			if (cycle_cnt) cycle_cnt = cycle_cnt - 1'd1;
		end

		RAM_RDY_OLD <= RAM_RDY;
		case(mstate)
		MBUS_IDLE:
			begin
				if (!PAUSE_EN) begin
				msrc <= MSRC_NONE;
				if (!M68K_AS_N && (!M68K_LDS_N || !M68K_UDS_N) && M68K_MBUS_DTACK_N && !M68K_INTACK) begin
					msrc <= MSRC_M68K;
					MBUS_A <= M68K_A[23:1];
					MBUS_DO <= M68K_DO;
					MBUS_AS_N <= 0;
					MBUS_UDS_N <= M68K_UDS_N;
					MBUS_LDS_N <= M68K_LDS_N;
					MBUS_RNW <= M68K_RNW;
					MBUS_ASEL_N <= M68K_A[23];
					
					case (M68K_A[23:20])
						//ROM: 000000-3FFFFF
						4'h0,4'h1,4'h2,4'h3: begin
							ROM_SEL <= 1;
							mstate <= MBUS_ROM_WAIT;
							cycle_cnt <= rfs_rom_pend ? 2'd2 : 2'd0;
						end
						
						//400000-7FFFFF
						4'h4,4'h5,4'h6,4'h7: begin
							M68K_MBUS_DTACK_N <= 0;
							mstate <= MBUS_FINISH;
						end
						
						//32X: 800000-9FFFFF (DTACK area)
						4'h8,4'h9: begin
							mstate <= MBUS_NOT_USED;
						end
						
						//A00000-BFFFFF
						4'hA,4'hB: begin
							//ZBUS: A00000-A07FFF/A08000-A0FFFF
							if (M68K_A[23:16] == 'hA0) begin
								if (!Z80_BUSRQ_N) begin
									ZBUS_SEL <= 1;
									mstate <= MBUS_ZBUS_READ;
								end else begin
									M68K_MBUS_DTACK_N <= 0;
									mstate <= MBUS_FINISH;
								end
							end
						
							//I/O: A10000-A1001F (+mirrors)
							else if (M68K_A[23:8] == 16'hA100) begin
								if (M68K_A[7:5] == 3'b000) begin
									IO_SEL <= 1;
									mstate <= MBUS_IO_READ;
								end else begin	//Ballz 3D
									M68K_MBUS_DTACK_N <= 0;
									mstate <= MBUS_FINISH;
								end
							end
			
							//Memory mode: A11000
							else if (M68K_A[23:8] == 16'hA110) begin
								M68K_MBUS_DTACK_N <= 0;
								mstate <= MBUS_FINISH;
							end
			
							//CTRL: A11100, A11200
							else if (M68K_A[23:8] == 16'hA111 || M68K_A[23:8] == 16'hA112) begin
								CTRL_SEL <= 1;
								M68K_MBUS_DTACK_N <= 0;
								mstate <= MBUS_FINISH;
							end
			
							//Unknown: A11300
							else if (M68K_A[23:8] == 16'hA113) begin
								M68K_MBUS_DTACK_N <= 0;
								mstate <= MBUS_FINISH;
							end
			
							//FDC: A120XX
							else if (M68K_A[23:8] == 16'hA120) begin
								FDC_SEL <= 1;
								mstate <= MBUS_FDC_READ;
							end
			
							//TIME: A130XX
							else if (M68K_A[23:8] == 16'hA130) begin
								TIME_SEL <= 1;
								mstate <= MBUS_TIME_READ;
							end
						
							//TMSS: A140XX
							else if (M68K_A[23:8] == 16'hA140) begin
								M68K_MBUS_DTACK_N <= 0;
								mstate <= MBUS_FINISH;
							end
							
							else begin
								mstate <= MBUS_NOT_USED;
							end
						end
						
						//C00000-DFFFFF
						4'hC,4'hD: begin
							//VDP: C00000-C0001F (+mirrors)
							if (M68K_A[23:21] == 3'b110 && !M68K_A[18:16] && !M68K_A[7:5]) begin
								VDP_SEL <= 1;
								if (rfs_rom_pend && !M68K_RNW) rfs_rom_pend <= 0;
								if (rfs_ram_pend && !M68K_RNW) rfs_ram_pend <= 0;
								mstate <= MBUS_VDP_READ;
							end
							
							else begin
								mstate <= MBUS_NOT_USED;
							end
						end
						
						//RAM: E00000-FFFFFF
						4'hE,4'hF: begin
							RAM_SEL <= 1;
							mstate <= MBUS_RAM_WAIT;
							cycle_cnt <= rfs_ram_pend ? 2'd3 : 2'd0;
						end
						
						default:;
					endcase
					
//					if (M68K_A[23:22] == 2'b00) begin
//						ROM_SEL <= 1;
//						mstate <= MBUS_ROM_WAIT;
//						cycle_cnt <= rfs_rom_pend ? 2'd2 : 2'd0;
//					end
//						
//					//400000-7FFFFF
//					else if (M68K_A[23:22] == 2'b01) begin
//						M68K_MBUS_DTACK_N <= 0;
//						mstate <= MBUS_FINISH;
//					end
//						
//					//DTACK area
//					//32X: 800000-9FFFFF
//					else if (M68K_A[23:21] == 3'b100) begin
//						mstate <= MBUS_NOT_USED;
//					end
//					
//					//A00000-BFFFFF
//					else if (M68K_A[23:21] == 3'b101) begin
//						//ZBUS: A00000-A07FFF/A08000-A0FFFF
//						if (M68K_A[23:16] == 'hA0) begin
//							if (!Z80_BUSRQ_N) begin
//								ZBUS_SEL <= 1;
//								mstate <= MBUS_ZBUS_READ;
//							end else begin
//								M68K_MBUS_DTACK_N <= 0;
//								mstate <= MBUS_FINISH;
//							end
//						end
//					
//						//I/O: A10000-A1001F (+mirrors)
//						else if (M68K_A[23:8] == 16'hA100) begin
//							if (M68K_A[7:5] == 3'b000) begin
//								IO_SEL <= 1;
//								mstate <= MBUS_IO_READ;
//							end else begin	//Ballz 3D
//								M68K_MBUS_DTACK_N <= 0;
//								mstate <= MBUS_FINISH;
//							end
//						end
//		
//						//Memory mode: A11000
//						else if (M68K_A[23:8] == 16'hA110) begin
//							M68K_MBUS_DTACK_N <= 0;
//							mstate <= MBUS_FINISH;
//						end
//		
//						//CTRL: A11100, A11200
//						else if (M68K_A[23:8] == 16'hA111 || M68K_A[23:8] == 16'hA112) begin
//							CTRL_SEL <= 1;
//							M68K_MBUS_DTACK_N <= 0;
//							mstate <= MBUS_FINISH;
//						end
//		
//						//Unknown: A11300
//						else if (M68K_A[23:8] == 16'hA113) begin
//							M68K_MBUS_DTACK_N <= 0;
//							mstate <= MBUS_FINISH;
//						end
//		
//						//FDC: A120XX
//						else if (M68K_A[23:8] == 16'hA120) begin
//							FDC_SEL <= 1;
//							mstate <= MBUS_FDC_READ;
//						end
//		
//						//TIME: A130XX
//						else if (M68K_A[23:8] == 16'hA130) begin
//							TIME_SEL <= 1;
//							mstate <= MBUS_TIME_READ;
//						end
//					
//						//TMSS: A140XX
//						else if (M68K_A[23:8] == 16'hA140) begin
//							M68K_MBUS_DTACK_N <= 0;
//							mstate <= MBUS_FINISH;
//						end
//						
//						else begin
//							mstate <= MBUS_NOT_USED;
//						end
//					end
//	
//					//VDP: C00000-C0001F (+mirrors)
//					else if (M68K_A[23:21] == 3'b110 && !M68K_A[18:16] && !M68K_A[7:5]) begin
//						VDP_SEL <= 1;
//						if (rfs_rom_pend && !M68K_RNW) rfs_rom_pend <= 0;
//						if (rfs_ram_pend && !M68K_RNW) rfs_ram_pend <= 0;
//						mstate <= MBUS_VDP_READ;
//					end
//	
//					//RAM: E00000-FFFFFF
//					else if (&M68K_A[23:21]) begin
//						RAM_SEL <= 1;
//						mstate <= MBUS_RAM_WAIT;
//						cycle_cnt <= rfs_ram_pend ? 2'd3 : 2'd0;
//					end
//					
//					else  begin
//						M68K_MBUS_DTACK_N <= 0;
//						mstate <= MBUS_FINISH;
//					end
				end
				else if (VBUS_SEL && VDP_MBUS_DTACK_N) begin
					msrc <= MSRC_VDP;
					MBUS_A <= VBUS_A;
					//MBUS_DO <= 0;
					MBUS_AS_N <= 0;
					MBUS_UDS_N <= 0;
					MBUS_LDS_N <= 0;
					MBUS_RNW <= 1;
					MBUS_ASEL_N <= VBUS_A[23];
					
					case (VBUS_A[23:20])
						//ROM: 000000-3FFFFF
						4'h0,4'h1,4'h2,4'h3: begin
							ROM_SEL <= 1;
							mstate <= MBUS_ROM_WAIT;
							cycle_cnt <= rfs_rom_pend ? 2'd2 : 2'd0;
						end
						
						//400000-7FFFFF
						4'h4,4'h5,4'h6,4'h7: begin
							VDP_MBUS_DTACK_N <= 0;
							mstate <= MBUS_FINISH;
						end
						
						//32X: 800000-9FFFFF (DTACK area)
						4'h8,4'h9: begin
							mstate <= MBUS_NOT_USED;
						end
						
						//A00000-DFFFFF
						4'hA,4'hB,4'hC,4'hD: begin
							VDP_MBUS_DTACK_N <= 0;
							mstate <= MBUS_FINISH;
						end
						
						//RAM: E00000-FFFFFF
						4'hE,4'hF: begin
							RAM_SEL <= 1;
							mstate <= MBUS_RAM_WAIT;
						end
						
						default:;
					endcase
					
//					//ROM: 000000-3FFFFF
//					if (!VBUS_A[23:22]) begin
//						ROM_SEL <= 1;
//						mstate <= MBUS_ROM_READ;
//					end
//						
//					//400000-7FFFFF
//					else if (VBUS_A[23:22] == 2'b01) begin
//						VDP_MBUS_DTACK_N <= 0;
//						mstate <= MBUS_FINISH;
//					end
//						
//					//DTACK area
//					//32X: 800000-9FFFFF
//					else if (VBUS_A[23:21] == 3'b100) begin
//						mstate <= MBUS_NOT_USED;
//					end
//
//					//RAM: E00000-FFFFFF
//					else if (&VBUS_A[23:21]) begin
//						RAM_SEL <= 1;
//						mstate <= MBUS_RAM_WAIT;
//					end
//					
//					else  begin
//						VDP_MBUS_DTACK_N <= 0;
//						mstate <= MBUS_FINISH;
//					end
				end
				else if (Z80_IO && !Z80_ZBUS && Z80_MBUS_DTACK_N && !Z80_BGACK_N && Z80_BR_N) begin
					msrc <= MSRC_Z80;
					MBUS_A <= Z80_A[15] ? {BAR[23:15],Z80_A[14:1]} : {16'hC000, Z80_A[7:1]};
					MBUS_DO <= {Z80_DO,Z80_DO};
					MBUS_AS_N <= 0;
					MBUS_UDS_N <= Z80_A[0];
					MBUS_LDS_N <= ~Z80_A[0];
					MBUS_RNW <= Z80_WR_N;
					MBUS_ASEL_N <= Z80_A[15] ? BAR[23] : 1'b1;
					
					if (Z80_A[15]) begin
						case (BAR[23:20])
							//ROM: 000000-3FFFFF
							4'h0,4'h1,4'h2,4'h3: begin
								ROM_SEL <= 1;
								mstate <= /*rfs_rom_pend ? MBUS_ROM_REFRESH :*/ MBUS_ROM_READ;
								rfs_rom_pend <= 0;
								cycle_cnt <= rfs_rom_pend ? 2'd2 : 2'd0;
							end
							
							//400000-7FFFFF
							4'h4,4'h5,4'h6,4'h7: begin
								Z80_MBUS_DTACK_N <= 0;
								mstate <= MBUS_FINISH;
							end
							
							//32X: 800000-9FFFFF (DTACK area)
							4'h8,4'h9: begin
								mstate <= MBUS_NOT_USED;
							end
							
							//A00000-BFFFFF
							4'hA,4'hB: begin
								mstate <= MBUS_NOT_USED;
							end
							
							//C00000-DFFFFF
							4'hC,4'hD: begin
								//VDP: C00000-C0001F (+mirrors)
								if (BAR[23:21] == 3'b110 && !BAR[18:16] && !Z80_A[7:5]) begin
									VDP_SEL <= 1;
									if (rfs_rom_pend && !Z80_WR_N) rfs_rom_pend <= 0;
									if (rfs_ram_pend && !Z80_WR_N) rfs_ram_pend <= 0;
									mstate <= MBUS_VDP_READ;
								end
								
								else begin
									mstate <= MBUS_NOT_USED;
								end
							end
							
							//RAM: E00000-FFFFFF
							4'hE,4'hF: begin
								RAM_SEL <= 1;
								mstate <= /*rfs_ram_pend ? MBUS_RAM_REFRESH :*/ MBUS_RAM_WAIT;
								rfs_ram_pend <= 0;
								cycle_cnt <= rfs_ram_pend ? 2'd3 : 2'd0;
							end
							
							default:;
						endcase
					end 
					
					//VDP: C00000-C000FF (+mirrors)
					else if (Z80_A[15:8] == 8'h7F /*&& !Z80_A[7:5]*/) begin
						VDP_SEL <= 1;
						if (rfs_rom_pend && !Z80_WR_N) rfs_rom_pend <= 0;
						if (rfs_ram_pend && !Z80_WR_N) rfs_ram_pend <= 0;
						mstate <= MBUS_VDP_READ;
					end
					
//					//ROM: 000000-3FFFFF
//					if (BAR[23:22] == 2'b00 && Z80_A[15]) begin
//						ROM_SEL <= 1;
//						mstate <= /*rfs_rom_pend ? MBUS_ROM_REFRESH :*/ MBUS_ROM_READ;
//						rfs_rom_pend <= 0;
//						cycle_cnt <= rfs_rom_pend ? 2'd2 : 2'd0;
//					end
//						
//					//400000-7FFFFF
//					else if (BAR[23:22] == 2'b01 && Z80_A[15]) begin
//						Z80_MBUS_DTACK_N <= 0;
//						mstate <= MBUS_FINISH;
//					end
//						
//					//DTACK area
//					//32X: 800000-9FFFFF
//					else if (BAR[23:21] == 3'b100 && Z80_A[15]) begin
//						mstate <= MBUS_NOT_USED;
//					end
//					
//					//A00000-BFFFFF
//					else if (BAR[23:21] == 3'b101 && Z80_A[15]) begin
//						mstate <= MBUS_NOT_USED;
//					end
//	
//					//VDP: C00000-C0001F (+mirrors)
//					else if ((BAR[23:21] == 3'b110 && !BAR[18:16] && Z80_A[15] && !Z80_A[7:5]) || (Z80_A[15:8] == 8'h7F && !Z80_A[7:5])) begin
//						VDP_SEL <= 1;
//						if (rfs_rom_pend && !Z80_WR_N) rfs_rom_pend <= 0;
//						if (rfs_ram_pend && !Z80_WR_N) rfs_ram_pend <= 0;
//						mstate <= MBUS_VDP_READ;
//					end
//	
//					//RAM: E00000-FFFFFF
//					else if (&BAR[23:21] && Z80_A[15]) begin
//						RAM_SEL <= 1;
//						mstate <= /*rfs_ram_pend ? MBUS_RAM_REFRESH :*/ MBUS_RAM_WAIT;
//						rfs_ram_pend <= 0;
//						cycle_cnt <= rfs_ram_pend ? 2'd3 : 2'd0;
//					end
//					
//					else  begin
//						Z80_MBUS_DTACK_N <= 0;
//						mstate <= MBUS_FINISH;
//					end
				end
				end
			end

		MBUS_ZBUS_READ:
			if (!MBUS_ZBUS_DTACK_N) begin
				M68K_MBUS_DTACK_N <= ~(msrc == MSRC_M68K);
				VDP_MBUS_DTACK_N <= ~(msrc == MSRC_VDP);
				mstate <= MBUS_FINISH;
			end
		
		MBUS_RAM_WAIT: begin
				mstate <= rfs_ram_pend ? MBUS_RAM_REFRESH : MBUS_RAM_READ;
				if (rfs_ram_pend) rfs_ram_pend <= 0;
			end

		MBUS_RAM_REFRESH: begin
				if (!cycle_cnt && M68K_CLKENp) begin
					mstate <= MBUS_RAM_READ;
				end
			end
			
		MBUS_RAM_READ: begin
				M68K_MBUS_DTACK_N <= ~(msrc == MSRC_M68K);
				VDP_MBUS_DTACK_N <= ~(msrc == MSRC_VDP);
				Z80_MBUS_DTACK_N <= ~(msrc == MSRC_Z80);
				if (msrc == MSRC_M68K && MBUS_RNW) OPEN_BUS <= ram68k_q;
				mstate <= MBUS_FINISH;
				if (MBUS_A == 24'hFFE03C>>1 && !MBUS_RNW) DBG_HOOK <= MBUS_DO;
			end

//		MBUS_RAM_WRITE: begin
//				M68K_MBUS_DTACK_N <= ~(msrc == MSRC_M68K);
//				VDP_MBUS_DTACK_N <= ~(msrc == MSRC_VDP);
//				Z80_MBUS_DTACK_N <= ~(msrc == MSRC_Z80);
//				mstate <= MBUS_FINISH;
//				if (MBUS_A == 24'hFFE03C>>1) DBG_HOOK <= MBUS_DO;
//			end
			
		MBUS_ROM_WAIT: begin
//			if (!RAM_RDY || !DTACK_N) begin
				mstate <= rfs_rom_pend ? MBUS_ROM_REFRESH : MBUS_ROM_READ;
				if (rfs_rom_pend) rfs_rom_pend <= 0;
//			end
		end
		
		MBUS_ROM_REFRESH: begin
			if (!cycle_cnt && M68K_CLKENp) begin
				mstate <= MBUS_ROM_READ;
			end
		end
		
		MBUS_ROM_READ: begin
			if (RAM_RDY || !DTACK_N) begin
				M68K_MBUS_DTACK_N <= ~(msrc == MSRC_M68K);
				VDP_MBUS_DTACK_N <= ~(msrc == MSRC_VDP);
				Z80_MBUS_DTACK_N <= ~(msrc == MSRC_Z80);
				mstate <= MBUS_FINISH;
			end
		end
			
		MBUS_VDP_READ:
			if (!VDP_DTACK_N) begin
				M68K_MBUS_DTACK_N <= ~(msrc == MSRC_M68K);
				Z80_MBUS_DTACK_N <= ~(msrc == MSRC_Z80);
				mstate <= MBUS_FINISH;
			end

		MBUS_IO_READ:
			if (!IO_DTACK_N) begin
				M68K_MBUS_DTACK_N <= ~(msrc == MSRC_M68K);
				Z80_MBUS_DTACK_N <= ~(msrc == MSRC_Z80);
				mstate <= MBUS_FINISH;
			end
			
		MBUS_FDC_READ:
			begin
				M68K_MBUS_DTACK_N <= ~(msrc == MSRC_M68K);
				VDP_MBUS_DTACK_N <= ~(msrc == MSRC_VDP);
				Z80_MBUS_DTACK_N <= ~(msrc == MSRC_Z80);
				mstate <= MBUS_FINISH;
			end
			
		MBUS_TIME_READ:
			begin
				M68K_MBUS_DTACK_N <= ~(msrc == MSRC_M68K);
				VDP_MBUS_DTACK_N <= ~(msrc == MSRC_VDP);
				Z80_MBUS_DTACK_N <= ~(msrc == MSRC_Z80);
				mstate <= MBUS_FINISH;
			end

		MBUS_NOT_USED: begin
				if (!DTACK_N) begin
					M68K_MBUS_DTACK_N <= ~(msrc == MSRC_M68K);
					VDP_MBUS_DTACK_N <= ~(msrc == MSRC_VDP);
					Z80_MBUS_DTACK_N <= ~(msrc == MSRC_Z80);
					mstate <= MBUS_FINISH;
				end
				DBG_HOOK2 <= DBG_HOOK2 + 8'd1;
			end
			
		MBUS_FINISH:
			begin
				if ((M68K_AS_N && !M68K_MBUS_DTACK_N && msrc == MSRC_M68K) ||
					 (!Z80_IO && !Z80_MBUS_DTACK_N && msrc == MSRC_Z80) ||
					 (!VBUS_SEL && !VDP_MBUS_DTACK_N && msrc == MSRC_VDP)) begin
					 if (msrc == MSRC_VDP) MBUS_DO <= MBUS_DI;
					M68K_MBUS_DTACK_N <= 1;
					VDP_MBUS_DTACK_N <= 1;
					Z80_MBUS_DTACK_N <= 1;
					MBUS_AS_N <= 1;
					MBUS_UDS_N <= 1;
					MBUS_LDS_N <= 1;
					MBUS_RNW <= 1;
					MBUS_ASEL_N <= 1;
					ROM_SEL <= 0;
					RAM_SEL <= 0;
					VDP_SEL <= 0;
					ZBUS_SEL <= 0;
					CTRL_SEL <= 0;
					IO_SEL <= 0;
					FDC_SEL <= 0;
					TIME_SEL <= 0;
					mstate <= MBUS_IDLE;
					if (msrc == MSRC_M68K) begin
						OPEN_BUS <= MBUS_DI;
					end
					DBG_HOOK2 <= '0;
				end
			end
		endcase;
	end
end

assign MBUS_DI = ROM_SEL ? VDI :
					  RAM_SEL ? ram68k_q :
					  VDP_SEL ? (MBUS_A[4:2] == 1 ? {OPEN_BUS[15:10],VDP_DO[9:0]} : VDP_DO) :
					  ZBUS_SEL ? (!Z80_BUSRQ_N ? {MBUS_ZBUS_D, MBUS_ZBUS_D} : OPEN_BUS) :
					  CTRL_SEL ? CTRL_DO :
					  IO_SEL ? {IO_DO, IO_DO} :
					  VDI;

assign VA = MBUS_A;
assign VDO = MBUS_DO;
assign RNW = MBUS_RNW;
assign LDS_N = MBUS_LDS_N;
assign UDS_N = MBUS_UDS_N;
assign AS_N = MBUS_AS_N;
assign ASEL_N = MBUS_ASEL_N;										//000000-7FFFFF 68K/VDP/Z80
assign TIME_N = ~TIME_SEL;											//A13000-A130FF
assign FDC_N =  ~FDC_SEL;											//A12000-A120FF 
assign VCLK_CE = M68K_CLKENn;

assign CE0_N  = ~(MBUS_A[23:22] == {1'b0, CART_N     }) | MBUS_ASEL_N;	//000000-3FFFFF /CART=0 or 400000-7FFFFF /CART=1
assign ROM_N  = ~(MBUS_A[23:21] == {1'b0,~CART_N,1'b0}) | MBUS_ASEL_N;	//400000-5FFFFF /CART=0 or 000000-1FFFFF /CART=1
assign RAS2_N = ~(MBUS_A[23:21] == {1'b0,~CART_N,1'b1}) | MBUS_ASEL_N;	//600000-7FFFFF /CART=0 or 200000-3FFFFF /CART=1 (pulse in real)
assign CAS2_N = ~MBUS_RNW | MBUS_AS_N;							//000000-FFFFFF 
assign CAS0_N = ~MBUS_RNW | MBUS_AS_N;							//000000-FFFFFF 
assign LWR_N  =  MBUS_RNW | MBUS_LDS_N;						//000000-FFFFFF 
assign UWR_N  =  MBUS_RNW | MBUS_UDS_N;						//000000-FFFFFF 

assign RAM_CE_N = ~RAM_SEL;

assign DBG_MBUS_A = {MBUS_A,1'b0};
assign DBG_M68K_A = {M68K_A,1'b0};


//--------------------------------------------------------------
// CPU Z80
//--------------------------------------------------------------
reg         Z80_RESET_N;
reg         Z80_BUSRQ_N;
wire        Z80_BUSAK_N;
wire        Z80_MREQ_N;
wire        Z80_IORQ_N;
wire        Z80_RFSH_N;
reg         Z80_WAIT_N;
wire        Z80_RD_N;
wire        Z80_WR_N;
wire [15:0] Z80_A;
wire  [7:0] Z80_DO;
wire        Z80_IO = ~Z80_MREQ_N & (~Z80_RD_N | ~Z80_WR_N);
//wire        Z80_IO_PRE = ~Z80_MREQ_N & Z80_RFSH_N;
wire  [7:0] Z80_MBUS_D = Z80_A[0] ? MBUS_DI[7:0] : MBUS_DI[15:8];

T80s #(.T2Write(1)) Z80
//T80pa Z80
(
	.RESET_n(Z80_RESET_N),
	.CLK(MCLK),
//	.CEN_p(Z80_CLKENp),
//	.CEN_n(Z80_CLKENn),
	.CEN(Z80_CLKENn),
	.BUSRQ_n(Z80_BUSRQ_N),
	.BUSAK_n(Z80_BUSAK_N),
	.RFSH_n(Z80_RFSH_N),
	.WAIT_n(~Z80_MBUS_DTACK_N | ~Z80_ZBUS_DTACK_N | ~Z80_IO),//Z80_WAIT_N
	.INT_n(Z80_INT_N),
	.MREQ_n(Z80_MREQ_N),
	.IORQ_n(Z80_IORQ_N),
	.RD_n(Z80_RD_N),
	.WR_n(Z80_WR_N),
	.A(Z80_A),
	.DI(!Z80_ZBUS_DTACK_N ? Z80_ZBUS_D : Z80_MBUS_D),
	.DO(Z80_DO)
);

//always @(posedge MCLK) begin
//	if (reset) begin
//		Z80_WAIT_N <= 1;
//	end
//	else begin
//		if (Z80_WAIT_N && !Z80_MREQ_N && Z80_RFSH_N && !Z80_ZBUS && Z80_MBUS_DTACK_N)
//			Z80_WAIT_N <= 0;
//		else if (!Z80_WAIT_N && !Z80_MBUS_DTACK_N && M68K_CLKENp)
//			Z80_WAIT_N <= 1;
//	end
//end

wire        CTRL_F  = (MBUS_A[11:8] == 1) ? Z80_BUSAK_N : (MBUS_A[11:8] == 2) ? Z80_RESET_N : OPEN_BUS[8];
wire [15:0] CTRL_DO = {OPEN_BUS[15:9], CTRL_F, OPEN_BUS[7:0]};
reg         CTRL_SEL;
always @(posedge MCLK) begin
	if (reset) begin
		Z80_BUSRQ_N <= 1;
		Z80_RESET_N <= 0;
	end
	else if(CTRL_SEL & ~MBUS_RNW & ~MBUS_UDS_N) begin
		if (MBUS_A[11:8] == 1) Z80_BUSRQ_N <= ~MBUS_DO[8];
		if (MBUS_A[11:8] == 2) Z80_RESET_N <=  MBUS_DO[8];
	end
end

//-----------------------------------------------------------------------
// ZBUS Handling
//-----------------------------------------------------------------------
// Z80:   0000-7EFF
// 68000: A00000-A07FFF (A08000-A0FFFF)

wire       Z80_ZBUS  = ~Z80_A[15] && ~&Z80_A[14:8];

wire       ZBUS_NO_BUSY = ZBUS_A[14] && ~|ZBUS_A[13:2] && |ZBUS_A[1:0] && FMBUSY_QUIRK;

reg        ZBUS_SEL;
reg [14:0] ZBUS_A;
reg        ZBUS_WE;
reg  [7:0] ZBUS_DO;
wire [7:0] ZBUS_DI = ZRAM_SEL ? ZRAM_DO : (FM_SEL ? (ZBUS_NO_BUSY ? {1'b0, FM_DO[6:0]} : FM_DO) : 8'hFF);

reg  [7:0] MBUS_ZBUS_D;
reg  [7:0] Z80_ZBUS_D;

reg        MBUS_ZBUS_DTACK_N;
reg        Z80_ZBUS_DTACK_N;

reg        Z80_BR_N;
reg        Z80_BGACK_N;

wire       Z80_ZBUS_SEL = Z80_ZBUS & Z80_IO;
wire       ZBUS_FREE = ~Z80_BUSRQ_N & Z80_RESET_N;

wire       Z80_MBUS_SEL = Z80_IO & ~Z80_ZBUS;

// RAM 0000-1FFF (2000-3FFF)
wire ZRAM_SEL = ~ZBUS_A[14];

wire  [7:0] ZRAM_DO;
dpram #(13) ramZ80
(
	.clock(MCLK),
	.address_a(ZBUS_A[12:0]),
	.data_a(ZBUS_DO),
	.wren_a(ZBUS_WE & ZRAM_SEL),
	.q_a(ZRAM_DO)
);

always @(posedge MCLK) begin
	reg [1:0] zstate;
	reg [1:0] zsrc;
	reg Z80_BGACK_DIS, Z80_BGACK_DIS2;

	localparam 	ZSRC_MBUS = 0,
					ZSRC_Z80  = 1;

	localparam	ZBUS_IDLE   = 0,
					ZBUS_READ   = 1,
					ZBUS_FINISH = 2;

	ZBUS_WE <= 0;
	
	if (reset) begin
		MBUS_ZBUS_DTACK_N <= 1;
		Z80_ZBUS_DTACK_N  <= 1;
		zstate <= ZBUS_IDLE;
		
		Z80_BR_N <= 1;
		Z80_BGACK_N <= 1;
		Z80_BGACK_DIS <= 0;
		Z80_BGACK_DIS2 <= 0;
	end
	else begin
		if (~ZBUS_SEL)     MBUS_ZBUS_DTACK_N <= 1;
		if (~Z80_ZBUS_SEL) Z80_ZBUS_DTACK_N  <= 1;

		case (zstate)
		ZBUS_IDLE:
			if (ZBUS_SEL & MBUS_ZBUS_DTACK_N) begin
				ZBUS_A <= {MBUS_A[14:1], MBUS_UDS_N};
				ZBUS_DO <= (~MBUS_UDS_N) ? MBUS_DO[15:8] : MBUS_DO[7:0];
				ZBUS_WE <= ~MBUS_RNW & ZBUS_FREE;
				zsrc <= ZSRC_MBUS;
				zstate <= ZBUS_READ;
			end
			else if (Z80_ZBUS_SEL & Z80_ZBUS_DTACK_N) begin
				ZBUS_A <= Z80_A[14:0];
				ZBUS_DO <= Z80_DO;
				ZBUS_WE <= ~Z80_WR_N;
				zsrc <= ZSRC_Z80;
				zstate <= ZBUS_READ;
			end

		ZBUS_READ:
			zstate <= ZBUS_FINISH;

		ZBUS_FINISH:
			begin
				case(zsrc)
				ZSRC_MBUS:
					begin
						MBUS_ZBUS_D <= ZBUS_FREE ? ZBUS_DI : 8'hFF;
						MBUS_ZBUS_DTACK_N <= 0;
					end

				ZSRC_Z80:
					begin
						Z80_ZBUS_D <= ZBUS_DI;
						Z80_ZBUS_DTACK_N <= 0;
					end
				endcase
				zstate <= ZBUS_IDLE;
			end
		endcase
		
		
		if (Z80_MBUS_SEL && Z80_BR_N && Z80_BGACK_N && VBUS_BR_N && VBUS_BGACK_N && M68K_CLKENp) begin
			Z80_BR_N <= 0;
		end
		else if (!Z80_BR_N && !M68K_BG_N && VBUS_BR_N && VBUS_BGACK_N && M68K_AS_N && M68K_CLKENn) begin
			Z80_BGACK_N <= 0;
		end
		else if (!Z80_BGACK_N && !Z80_BR_N && !M68K_BG_N && M68K_CLKENp) begin
			Z80_BR_N <= 1;
		end
		else if (!Z80_BGACK_DIS2 && !Z80_BGACK_N && Z80_BR_N && !Z80_MBUS_SEL && M68K_CLKENn) begin
			Z80_BGACK_DIS <= 1;
			Z80_BGACK_DIS2 <= Z80_BGACK_DIS;
		end
		else if (!Z80_BGACK_N && Z80_BGACK_DIS2 && M68K_CLKENn) begin
			Z80_BGACK_N <= 1;
			Z80_BGACK_DIS <= 0;
			Z80_BGACK_DIS2 <= 0;
		end
	end
end


//-----------------------------------------------------------------------
// Z80 BANK REGISTER
//-----------------------------------------------------------------------
// 6000-60FF

wire BANK_SEL = ZBUS_A[14:8] == 7'h60;
reg [23:15] BAR;

always @(posedge MCLK) begin
	if (reset) BAR <= 0;
	else if (BANK_SEL & ZBUS_WE) BAR <= {ZBUS_DO[0], BAR[23:16]};
end


//--------------------------------------------------------------
// YM2612
//--------------------------------------------------------------
// 4000-4003 (4000-5FFF)

wire        FM_SEL = ZBUS_A[14:13] == 2'b10;
wire  [7:0] FM_DO;
wire signed [15:0] FM_right;
wire signed [15:0] FM_left;
wire signed [15:0] FM_LPF_right;
wire signed [15:0] FM_LPF_left;
wire [15:0] SL;
wire [15:0] SR;
wire signed [15:0] PRE_LPF_L;
wire signed [15:0] PRE_LPF_R;

jt12 fm
(
	.rst(~Z80_RESET_N),
	.clk(MCLK),
	.cen(M68K_CLKENp),

	.cs_n(0),
	.addr(ZBUS_A[1:0]),
	.wr_n(~(FM_SEL & ZBUS_WE)),
	.din(ZBUS_DO),
	.dout(FM_DO),
	.en_hifi_pcm( EN_HIFI_PCM ),
	.ladder(LADDER),
	.snd_left(FM_left),
	.snd_right(FM_right)
);

wire signed [15:0] fm_adjust_l = (FM_left << 4) + (FM_left << 2) + (FM_left << 1) + (FM_left >>> 2);
wire signed [15:0] fm_adjust_r = (FM_right << 4) + (FM_right << 2) + (FM_right << 1) + (FM_right >>> 2);

genesis_fm_lpf fm_lpf_l
(
	.clk(MCLK),
	.reset(reset),
	.in(fm_adjust_l),
	.out(FM_LPF_left)
);

genesis_fm_lpf fm_lpf_r
(
	.clk(MCLK),
	.reset(reset),
	.in(fm_adjust_r),
	.out(FM_LPF_right)
);

wire signed [15:0] fm_select_l = ((LPF_MODE == 2'b01) ? FM_LPF_left : fm_adjust_l);
wire signed [15:0] fm_select_r = ((LPF_MODE == 2'b01) ? FM_LPF_right : fm_adjust_r);

wire signed [10:0] psg_adjust = PSG_SND - (PSG_SND >>> 5);

jt12_genmix genmix
(
	.rst(reset),
	.clk(MCLK),
	.fm_left(fm_select_l),
	.fm_right(fm_select_r),
	.psg_snd(psg_adjust),
	.fm_en(EN_GEN_FM),
	.psg_en(EN_GEN_PSG),
	.snd_left(SL),
	.snd_right(SR)
);

SND_MIX mix
(
	.CH0_R(SR),
	.CH0_L(SL),
	.CH0_EN(1),
	
	.CH1_R(EXT_SR),
	.CH1_L(EXT_SL),
	.CH1_EN(EN_32X_PWM),
	
	.OUT_R(PRE_LPF_R),
	.OUT_L(PRE_LPF_L)
);

genesis_lpf lpf_right
(
	.clk(MCLK),
	.reset(reset),
	.lpf_mode(LPF_MODE[1:0]),
	.in(PRE_LPF_R),
	.out(DAC_RDATA)
);

genesis_lpf lpf_left
(
	.clk(MCLK),
	.reset(reset),
	.lpf_mode(LPF_MODE[1:0]),
	.in(PRE_LPF_L),
	.out(DAC_LDATA)
);

endmodule
