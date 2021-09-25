library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library STD;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.VDP_PKG.all; 

entity VDP2 is
	port(
		RST_N       : in  std_logic;
		CLK         : in  std_logic;
		ENABLE      : in  std_logic;
		
		VCLK_ENp   	: in  std_logic;
		VCLK_ENn   	: in  std_logic;
		SEL         : in  std_logic;
		A           : in  std_logic_vector(4 downto 1);
		RNW         : in  std_logic;
		AS_N        : in  std_logic;
		DI          : in  std_logic_vector(15 downto 0);
		DO          : out std_logic_vector(15 downto 0);
		DTACK_N     : out std_logic;
		BR_N        : out std_logic;
		BG_N        : in  std_logic;
		BGACK_N     : out std_logic;
		IPL_N    	: out std_logic_vector(2 downto 1);

		VINT    		: out std_logic;
		HINT   		: out std_logic;
		INTACK      : in  std_logic;
		Z80_INT_N   : out std_logic;
		REFRESH   	: out std_logic;
		
		VBUS_ADDR   : out std_logic_vector(23 downto 1);
		VBUS_DATA   : in  std_logic_vector(15 downto 0);
		VBUS_SEL    : out std_logic;
		VBUS_DTACK_N: in  std_logic;
		
		PAL         : in  std_logic;
		HL          : in  std_logic;
	
		VRAM_A      : out std_logic_vector(15 downto 0);
		VRAM_D      : out std_logic_vector(7 downto 0);
		VRAM_Q      : in  std_logic_vector(7 downto 0);
		VRAM_WE     : out std_logic;

		CE_PIX      : buffer std_logic;
		FIELD_OUT   : out std_logic;
		INTERLACE   : out std_logic;
		RESOLUTION  : out std_logic_vector(1 downto 0);
		HBL         : out std_logic;
		VBL         : out std_logic;

		R           : out std_logic_vector(3 downto 0);
		G           : out std_logic_vector(3 downto 0);
		B           : out std_logic_vector(3 downto 0);
		YS_N        : out std_logic;
		EDCLK      	: out std_logic;
		HS_N       	: out std_logic;
		VS_N       	: out std_logic;
		
		BORDER_EN	: in  std_logic;
		VSCROLL_BUG	: in  std_logic := '1';
		
		BGA_EN		: in  std_logic;
		BGB_EN		: in  std_logic;
		SPR_EN		: in  std_logic;
		BG_GRID_EN  : in  std_logic_vector(1 downto 0);
		SPR_GRID_EN	: in  std_logic;
		
		DBG_OFFSET_X : out unsigned(9 downto 0);
		DBG_OFFSET_Y : out unsigned(10 downto 0);
--		DBG_CELL_X 	: out unsigned(5 downto 0);
--		DBG_CELL_Y 	: out unsigned(6 downto 0);
		DBG_WIN_HIT : out std_logic;
		DBG_FIFO_ADDR : out std_logic_vector(16 downto 0);
		DBG_FIFO_DATA : out std_logic_vector(15 downto 0);
		DBG_FIFO_CODE : out std_logic_vector(3 downto 0);
		DBG_FIFO_EMPTY       	: out std_logic;
		DBG_FIFO_FULL       	: out std_logic;
		DBG_MR1_DD	: out std_logic
	);
end VDP2;

architecture rtl of VDP2 is

	signal REGS 			: Regs_t;
	alias MR1_DD 			: std_logic is REGS(0)(0);
	alias MR1_M3 			: std_logic is REGS(0)(1);
	alias MR1_IE1 			: std_logic is REGS(0)(4);
	alias MR2_M5 			: std_logic is REGS(1)(2);
	alias MR2_M2 			: std_logic is REGS(1)(3);
	alias MR2_DMA 			: std_logic is REGS(1)(4);
	alias MR2_IE0 			: std_logic is REGS(1)(5);
	alias MR2_DISP 		: std_logic is REGS(1)(6);
	alias MR2_128K 		: std_logic is REGS(1)(7);
	alias NTA_SA 			: std_logic_vector(15 downto 13) is REGS(2)(5 downto 3);
	alias NTW_WD 			: std_logic_vector(15 downto 11) is REGS(3)(5 downto 1);
	alias NTB_SB 			: std_logic_vector(15 downto 13) is REGS(4)(2 downto 0);
	alias SAT_AT 			: std_logic_vector(16 downto 9) is REGS(5)(7 downto 0);
	alias MR3_HSCR 		: std_logic_vector(1 downto 0) is REGS(11)(1 downto 0);
	alias MR3_VSCR 		: std_logic is REGS(11)(2);
	alias MR4_RS1 			: std_logic is REGS(12)(0);
	alias MR4_LSM 			: std_logic_vector(1 downto 0) is REGS(12)(2 downto 1);
	alias MR4_STE 			: std_logic is REGS(12)(3);
	alias MR4_RS0 			: std_logic is REGS(12)(7);
	alias HSDT_HS 			: std_logic_vector(15 downto 10) is REGS(13)(5 downto 0);
	alias SS_HSZ 			: std_logic_vector(1 downto 0) is REGS(16)(1 downto 0);
	alias SS_VSZ 			: std_logic_vector(1 downto 0) is REGS(16)(5 downto 4);
	alias ADDR_INC 		: std_logic_vector(7 downto 0) is REGS(15);
	alias BGC_COL 			: std_logic_vector(3 downto 0) is REGS(7)(3 downto 0);
	alias BGC_PAL 			: std_logic_vector(1 downto 0) is REGS(7)(5 downto 4);
	alias WHP_WHP 			: std_logic_vector(5 downto 1) is REGS(17)(4 downto 0);
	alias WHP_RIGT 		: std_logic is REGS(17)(7);
	alias WVP_WVP 			: std_logic_vector(4 downto 0) is REGS(18)(4 downto 0);
	alias WVP_DOWN 		: std_logic is REGS(18)(7);
	alias HIR_HIT 			: std_logic_vector(7 downto 0) is REGS(10);
	signal DBG 				: std_logic_vector(15 downto 0);
	
	signal H40 				: std_logic;
	signal V30 				: std_logic;
	signal V30_LATCH 		: std_logic;
	signal VINT_FLAG 		: std_logic;
	signal HINT_FLAG 		: std_logic;
	signal Z80_INT_FLAG 	: std_logic;
	signal IN_DMA 			: std_logic;
	signal SOVR 			: std_logic;
	signal SCOL 			: std_logic;
	signal STATUS 			: std_logic_vector(15 downto 0);
	signal ODD 				: std_logic;
	signal FIELD_LATCH 	: std_logic;
	signal HV 				: std_logic_vector(15 downto 0);
	signal FF_DO 			: std_logic_vector(15 downto 0);
	signal INTACK_OLD 	: std_logic;
	signal Z80_INT_WAIT 	: unsigned(11 downto 0);
	signal HL_OLD 			: std_logic;
	signal HINT_COUNT 	: unsigned(7 downto 0);
	signal HINT_EN 		: std_logic;
	signal SOVR_CLR 		: std_logic;
	signal SCOL_CLR 		: std_logic;
	
	signal ADDR 			: std_logic_vector(16 downto 0);
	signal CODE 			: std_logic_vector(5 downto 0);
	signal PENDING 		: std_logic;
	signal FF_DTACK_N 	: std_logic;
	signal FIFO 			: Fifo_t;
	signal FIFO_WR_POS 	: unsigned(1 downto 0);
	signal FIFO_RD_POS 	: unsigned(1 downto 0);
	signal FIFO_QUEUE 	: unsigned(2 downto 0);
	signal FIFO_EMPTY 	: std_logic;
	signal FIFO_FULL		: std_logic;
	signal FIFO_ADDR 		: std_logic_vector(16 downto 0);
	signal FIFO_DATA 		: std_logic_vector(15 downto 0);
	signal FIFO_CODE 		: std_logic_vector(3 downto 0);
	signal IO_ADDR 		: std_logic_vector(16 downto 0);
	signal IO_DATA 		: std_logic_vector(15 downto 0);
	signal IO_BYTE 		: std_logic;
	signal IO_PORT_WE 	: std_logic;
	
	type dtc_t is (
		DTC_IDLE,
		DTC_FIFO_RD,
		DTC_FIFO_RD2,
		DTC_FIFO_RD3,
		DTC_FIFO_END,
		DTC_VRAM_WR,
		DTC_CRAM_WR,
		DTC_VSRAM_WR,
		DTC_PRE_RD,
		DTC_VRAM_RD,
		DTC_VRAM8_RD,
		DTC_CRAM_RD,
		DTC_VSRAM_RD
	);
	signal DTC 				: dtc_t;
	signal DT_RD_PEND 	: std_logic;
	signal DT_RD_EXEC 	: std_logic;
	signal DT_RD_CODE 	: std_logic_vector(3 downto 0);
	signal DT_RD_DATA 	: std_logic_vector(15 downto 0);
	
	type dmac_t is (
		DMA_IDLE,
		DMA_FILL_WR,
		DMA_FILL_WR2,
		DMA_COPY_RD,
		DMA_COPY_WR,
		DMA_VBUS_WAIT,
		DMA_VBUS_REFRESH,
		DMA_VBUS_SKIP,
		DMA_VBUS_RD,
		DMA_VBUS_WR,
		DMA_VBUS_END
	);
	signal DMAC 			: dmac_t;
	signal DMA_VBUS 		: std_logic;
	signal DMA_VBUS_WC 	: unsigned(1 downto 0);
	signal DMA_FILL 		: std_logic;
	signal DMA_FILL_START: std_logic;
	signal DMA_FILL_WE 	: std_logic;
	signal DMA_FILL_CODE : std_logic_vector(3 downto 0);
	signal DMA_COPY 		: std_logic;
	signal DMA_COPY_WE 	: std_logic;
	signal FF_VBUS_ADDR 	: std_logic_vector(23 downto 1);
	signal FF_VBUS_DATA 	: std_logic_vector(15 downto 0);
	signal FF_VBUS_SEL 	: std_logic;
	signal FF_BGACK_N 	: std_logic;
	signal FF_BR_N 		: std_logic;

	signal SCLK_DIV 		: unsigned(2 downto 0);
	signal EDCLK_DIV 		: unsigned(2 downto 0);
	signal EDCLK_DIV2 	: std_logic;
	signal DCLK_DIV 		: std_logic;
	signal DCLK_CE 		: std_logic;
	signal SCLK_CE 		: std_logic;
	signal EDCLK_CE 		: std_logic;
	signal SC_CE 			: std_logic;
	signal H_CNT 			: unsigned(8 downto 0);
	signal V_CNT 			: unsigned(8 downto 0);
	signal FIELD 			: std_logic;
	signal HBLANK 			: std_logic;
	signal VBLANK 			: std_logic;
	signal FF_HS 			: std_logic;
	signal FF_VS 			: std_logic;
	signal IN_VBL 			: std_logic;
	signal IN_HBL 			: std_logic;

	signal BG_X 			: unsigned(8 downto 0);
	signal BG_Y 			: unsigned(7 downto 0);
	signal SPR_Y 			: unsigned(8 downto 0);
	signal BG_PIX_X 		: unsigned(8 downto 0);
	signal DISP_OUT_EN 	: std_logic_vector(5 downto 0);
	signal COLOR 			: std_logic_vector(8 downto 0);
	signal COLOR2 			: std_logic_vector(8 downto 0);
	type BackColor_t is array(0 to 2) of std_logic;
	signal BK_COL 			: BackColor_t;
	signal DISP_GRID 		: std_logic;
	
	signal SLOTS 			: SlotPipe_t;
	signal SLOT 			: Slot_t;
	signal SLOT_CE 		: std_logic;
	signal REFRESH_WAIT 	: unsigned(4 downto 0);
	signal BG_VRAM_ADDR 	: std_logic_vector(15 downto 0);
	signal VRAM_SDATA_TEMP0 : std_logic_vector(7 downto 0);
	signal VRAM_SDATA_TEMP1 : std_logic_vector(7 downto 0);
	signal VRAM_SDATA_TEMP2 : std_logic_vector(7 downto 0);
	signal VRAM_SDATA 	: std_logic_vector(31 downto 0);
	signal BYTE_CNT 		: unsigned(1 downto 0);
	signal HSCRLA 			: std_logic_vector(9 downto 0);
	signal HSCRLB 			: std_logic_vector(9 downto 0);
	signal BG_VSRAM_ADDR : std_logic_vector(4 downto 0);
	signal VSCRLA 			: std_logic_vector(10 downto 0);
	signal VSCRLB 			: std_logic_vector(10 downto 0);
	signal VSCRLA_LAST 	: std_logic_vector(10 downto 0);
	signal VSCRLB_LAST 	: std_logic_vector(10 downto 0);
	signal WHP_LATCH 		: std_logic_vector(5 downto 1);
	signal WHP_RIGT_LATCH: std_logic;
	signal WVP_LATCH 		: std_logic_vector(4 downto 0);
	signal WVP_DOWN_LATCH: std_logic;
	signal PNI 				: BGPatterNameInfo_t;
	signal BGA_TILE_BUF 	: BGTileInfoBuf_t;
	signal BGB_TILE_BUF 	: BGTileInfoBuf_t;
	signal BGA_TILE 		: BGTileRender_t;
	signal BGB_TILE 		: BGTileRender_t;
	signal BGA_WIN_LAST 	: std_logic;
	
	signal CRAM_ADDR_A 	: std_logic_vector(5 downto 0);
	signal CRAM_ADDR_B 	: std_logic_vector(5 downto 0);
	signal CRAM_D 			: std_logic_vector(8 downto 0);
	signal CRAM_Q_A 		: std_logic_vector(8 downto 0);
	signal CRAM_Q_B 		: std_logic_vector(8 downto 0);
	signal CRAM_WE 		: std_logic;
	
	signal VSRAM_ADDR_A 	: std_logic_vector(4 downto 0);
	signal VSRAM_ADDR_B 	: std_logic_vector(5 downto 0);
	signal VSRAM_D 		: std_logic_vector(10 downto 0);
	signal VSRAM_WE 		: std_logic;
	signal VSRAM_Q_A 		: std_logic_vector(21 downto 0);
	signal VSRAM_Q_B 		: std_logic_vector(10 downto 0);
	
	signal SPR_VRAM_ADDR : std_logic_vector(15 downto 0);
	signal OBJ_N 			: std_logic_vector(6 downto 0);
	signal OBJ_FIND 		: std_logic;
	signal OBJ_FIND_DONE : std_logic;
	signal OBJ_VALID_X 	: std_logic;
	signal OBJ_MASKED 	: std_logic;
	signal OBJC_Y_OFS 	: std_logic_vector(5 downto 0);
	
	signal OBJC_ADDR_WR 	: std_logic_vector(6 downto 0);
	signal OBJC_ADDR_RD 	: std_logic_vector(6 downto 0);
	signal OBJC_D 			: std_logic_vector(31 downto 0);
	signal OBJC_WE 		: std_logic;
	signal OBJC_BE 		: std_logic_vector(3 downto 0);
	signal OBJC_Q 			: std_logic_vector(31 downto 0);
	signal OBJC_DATA_SAVE: std_logic_vector(9 downto 0);
	
	signal OBJVI_ADDR_WR : std_logic_vector(5 downto 0);
	signal OBJVI_ADDR_RD : std_logic_vector(5 downto 0);
	signal OBJVI_D 		: std_logic_vector(6 downto 0);
	signal OBJVI_Q 		: std_logic_vector(6 downto 0);
	signal OBJVI_WE 		: std_logic;
	
	signal OBJSI_ADDR_WR : std_logic_vector(5 downto 0);
	signal OBJSI_ADDR_RD : std_logic_vector(5 downto 0);
	signal OBJSI_D 		: std_logic_vector(34 downto 0);
	signal OBJSI_Q 		: std_logic_vector(34 downto 0);
	signal OBJSI_WE 		: std_logic;
	
	signal OBJCI_ADDR_A 	: std_logic_vector(8 downto 0);
	signal OBJCI_ADDR_B 	: std_logic_vector(8 downto 0);
	signal OBJCI_D_A 		: std_logic_vector(7 downto 0);
	signal OBJCI_WE_A 	: std_logic;
	signal OBJCI_WE_B 	: std_logic;
	signal OBJCI_Q_A 		: std_logic_vector(7 downto 0);
	signal OBJCI_Q_B 		: std_logic_vector(7 downto 0);
	
	signal OBJRI 			: ObjRenderInfo_t;
	signal OBJ_TILE_COLOR: std_logic_vector(3 downto 0);
	signal OBJ_TILE_N 	: unsigned(1 downto 0);
	signal OBJ_TILE_DATA : std_logic_vector(31 downto 0);
	signal OBJ_TILE_PRI 	: std_logic;
	signal OBJ_TILE_PAL 	: std_logic_vector(1 downto 0);
	signal OBJ_PIX 		: unsigned(4 downto 0);
	
	type PixMode_t is (
		PIX_SHADOW,
		PIX_NORMAL,
		PIX_HIGHLIGHT
	);
	type PixModePipe_t is array(0 to 2) of PixMode_t;
	signal PIX_MODE		: PixModePipe_t;


begin
	
	FIFO_EMPTY <= '1' when FIFO_QUEUE = 0 else '0';
	FIFO_FULL <= '1' when FIFO_QUEUE(2) = '1' else '0';
	
	FIFO_ADDR <= FIFO( to_integer(FIFO_RD_POS) ).ADDR;
	FIFO_DATA <= FIFO( to_integer(FIFO_RD_POS) ).DATA;
	FIFO_CODE <= FIFO( to_integer(FIFO_RD_POS) ).CODE;
	
	ODD <= FIELD when MR4_LSM(0) = '1' else '0';
	IN_DMA <= DMA_FILL or DMA_COPY or DMA_VBUS;
	STATUS <= "111111" & FIFO_EMPTY & FIFO_FULL & VINT_FLAG & SOVR & SCOL & ODD & (IN_VBL or not MR2_DISP) & IN_HBL & IN_DMA & PAL;
	
	process( RST_N, CLK )
	variable FIFO_QUEUE_INC, FIFO_QUEUE_DEC : std_logic;
	variable NEXT_DMA_SRC, NEXT_DMA_LEN : std_logic_vector(15 downto 0);
	begin
		if RST_N = '0' then
			REGS <= (others => (others => '0'));
			DBG <= (others => '0');
			CODE <= (others => '0');
			PENDING <= '0';
			ADDR <= (others => '0');
			FIFO <= (others => ((others => '0'),(others => '0'),(others => '0')));
			FIFO_RD_POS <= "00";
			FIFO_WR_POS <= "00";
			FIFO_QUEUE <= "000";
			DTC <= DTC_IDLE;
			DT_RD_PEND <= '0';
			DT_RD_EXEC <= '0';
			DT_RD_CODE <= (others => '0');
			DT_RD_DATA <= (others => '0');
			IO_PORT_WE <= '0';
			DMAC <= DMA_IDLE;
			DMA_FILL <= '0';
			DMA_FILL_START <= '0';
			DMA_COPY <= '0';
			DMA_VBUS <= '0';
			DMA_FILL_WE <= '0';
			DMA_COPY_WE <= '0';
			FF_VBUS_SEL <= '0';
			FF_DTACK_N <= '1';
			FF_BGACK_N <= '1';
			FF_BR_N <= '1';
			SOVR_CLR <= '0';
			SCOL_CLR <= '0';
		elsif rising_edge(CLK) then
			SOVR_CLR <= '0';
			SCOL_CLR <= '0';
		
			FIFO_QUEUE_INC := '0';
			FIFO_QUEUE_DEC := '0';
			if SEL = '0' and AS_N = '1' then
				FF_DTACK_N <= '1';
				if BG_N = '0' and FF_BR_N = '0' and FF_BGACK_N = '1' then
					FF_BGACK_N <= '0';
					FF_BR_N <= '1';
				end if;
			elsif SEL = '1' and FF_DTACK_N = '1' then
				if RNW = '0' then 									-- Write
					if A(4 downto 2) = "000" then					-- Data Port C00000-C00002
						PENDING <= '0';
	
						if FIFO_FULL = '0' then
							FIFO( to_integer(FIFO_WR_POS) ).ADDR <= ADDR;
							FIFO( to_integer(FIFO_WR_POS) ).DATA <= DI;
							FIFO( to_integer(FIFO_WR_POS) ).CODE <= CODE(3 downto 0);
							FIFO_WR_POS <= FIFO_WR_POS + 1;
							FIFO_QUEUE_INC := '1';
							ADDR <= std_logic_vector( unsigned(ADDR) + unsigned(ADDR_INC) );
							FF_DTACK_N <= '0';
						end if;
						
						if DMA_FILL = '1' then
							DMA_FILL_START <= '1';
							DMA_FILL_CODE <= CODE(3 downto 0);
						end if;
	
					elsif A(4 downto 2) = "001" then				-- Control Port C00004-C00006
						if FF_BR_N = '0' then
							
						elsif PENDING = '1' then
							if CODE(4 downto 0) /= DI(6 downto 4) & CODE(1 downto 0) or DMA_FILL = '0' then
							ADDR <= DI(2 downto 0) & ADDR(13 downto 0);
							end if;
							CODE(4 downto 0) <= DI(6 downto 4) & CODE(1 downto 0);
							if MR2_DMA = '1' then
								CODE(5) <= DI(7);
							end if;
							
							if MR2_DMA = '1' and DI(7) = '1' then
								if REGS(23)(7) = '0' then
									if VCLK_ENp = '1' then
										if DMA_VBUS = '0' then
											DMA_VBUS <= '1';
										else
											FF_BR_N <= '0';
											PENDING <= '0';
										end if;
									end if;
								else
									if REGS(23)(6) = '0' then
										DMA_FILL <= '1';
									else
										DMA_COPY <= '1';
									end if;
									FF_DTACK_N <= '0';
									PENDING <= '0';
								end if;
--							else
							elsif CODE(1 downto 0) = "00" and DI(7 downto 6) = "00" then
								DT_RD_PEND <= '1';
								DT_RD_CODE <= DI(5 downto 4) & CODE(1 downto 0);
								FF_DTACK_N <= '0';
								PENDING <= '0';
							else
								FF_DTACK_N <= '0';
								PENDING <= '0';
							end if;
						else
							CODE(1 downto 0) <= DI(15 downto 14);
							if DI(15 downto 14) = "10" then		-- Register Set
								if (MR2_M5 = '1' or unsigned(DI(12 downto 8)) <= 10) then
									-- mask registers above 10 in Mode4
									REGS( to_integer(unsigned(DI(12 downto 8))) ) <= DI(7 downto 0);
								end if;
							else											-- Address Set
								PENDING <= '1';
								ADDR(13 downto 0) <= DI(13 downto 0);
								CODE(5 downto 4) <= "00"; -- attempt to fix lotus i
							end if;
							FF_DTACK_N <= '0';
						end if;
					elsif A(4 downto 2) = "111" then
						DBG <= DI;
						FF_DTACK_N <= '0';
					elsif A(4 downto 3) = "10" then				-- PSG
						FF_DTACK_N <= '0';
					else													-- Unused (Lock-up)
						FF_DTACK_N <= '0';
					end if;
				
				else 														-- Read
					if A(4 downto 2) = "000" then					-- Data Port C00000-C00002 
						PENDING <= '0';
						
						if CODE = "001000" -- CRAM Read
						or CODE = "000100" -- VSRAM Read
						or CODE = "000000" -- VRAM Read
						or CODE = "001100" -- VRAM Read 8 bit
						then
							if DT_RD_EXEC = '0' and DT_RD_PEND = '0' then
								DT_RD_PEND <= '1';
								DT_RD_CODE <= CODE(3 downto 0);
								FF_DTACK_N <= '0';
							end if;
						else
							FF_DTACK_N <= '0';
						end if;
					elsif A(4 downto 2) = "001" then				-- Control Port C00004-C00006 (Read Status Register)
						PENDING <= '0';
						SOVR_CLR <= '1';
						SCOL_CLR <= '1';
						FF_DTACK_N <= '0';
					elsif A(4 downto 3) = "01" then				-- HV Counter C00008-C0000A
						FF_DTACK_N <= '0';
					elsif A(4) = '1' then							-- unused, PSG, DBG
						FF_DTACK_N <= '0';
					end if;
				end if;
			end if;
			
			case DTC is
				when DTC_IDLE =>
					if FIFO_EMPTY = '0' and SLOT_CE = '1' then
						DTC <= DTC_FIFO_RD2;
					elsif DT_RD_PEND = '1' and SLOT_CE = '1' then--
						DT_RD_PEND <= '0';
						DT_RD_EXEC <= '1';
						DTC <= DTC_PRE_RD;
					end if;
				
				when DTC_FIFO_RD2 =>
					if SLOT_CE = '1' then
						IO_ADDR <= FIFO_ADDR;
						IO_DATA <= FIFO_DATA;
						IO_BYTE <= FIFO_ADDR(0);
						IO_PORT_WE <= '1';
						DTC <= DTC_FIFO_RD;
					end if;
				
				when DTC_FIFO_RD =>
					case FIFO_CODE is
						when "0001" => -- VRAM Write
							if SLOT_CE = '1' and SLOT = ST_EXT then
								if IO_BYTE /= IO_ADDR(0) or MR2_128K = '1' then
									FIFO_RD_POS <= FIFO_RD_POS + 1;
									FIFO_QUEUE_DEC := '1';
									IO_PORT_WE <= '0';
									DTC <= DTC_FIFO_END;
								else
									IO_ADDR(0) <= not IO_ADDR(0);
									IO_DATA <= IO_DATA(7 downto 0) & IO_DATA(15 downto 8);
								end if;
							end if;
						when "0011" => -- CRAM Write
							if SLOT_CE = '1' and SLOT = ST_EXT then
								FIFO_RD_POS <= FIFO_RD_POS + 1;
								FIFO_QUEUE_DEC := '1';
								IO_PORT_WE <= '0';
								DTC <= DTC_FIFO_RD3;
							end if;
						when "0101" => -- VSRAM Write
							if SLOT_CE = '1' and SLOT = ST_EXT then
								FIFO_RD_POS <= FIFO_RD_POS + 1;
								FIFO_QUEUE_DEC := '1';
								IO_PORT_WE <= '0';
								DTC <= DTC_FIFO_RD3;
							end if;
						when others => --invalid target
							IO_PORT_WE <= '0';
							FIFO_RD_POS <= FIFO_RD_POS + 1;
							FIFO_QUEUE_DEC := '1';
							DTC <= DTC_FIFO_END;
					end case;
				
				when DTC_FIFO_RD3 =>
					IO_DATA <= FIFO_DATA;
					DTC <= DTC_FIFO_END;
				
				when DTC_FIFO_END =>
					if FIFO_EMPTY = '0' then
						IO_ADDR <= FIFO_ADDR;
						IO_DATA <= FIFO_DATA;
						IO_BYTE <= FIFO_ADDR(0);
						IO_PORT_WE <= '1';
						DTC <= DTC_FIFO_RD;
					else
						DTC <= DTC_IDLE;
					end if;
					
				when DTC_PRE_RD =>
					if SLOT_CE = '1' then
						IO_ADDR <= ADDR;
						IO_BYTE <= ADDR(0);
						DT_RD_DATA <= FIFO_DATA;
						ADDR <= std_logic_vector( unsigned(ADDR) + unsigned(ADDR_INC) );
						case DT_RD_CODE is
							when "1000" => -- CRAM Read
								DTC <= DTC_CRAM_RD;
							when "0100" => -- VSRAM Read
								DTC <= DTC_VSRAM_RD;
							when "0000" => -- VRAM Read
								DTC <= DTC_VRAM_RD;
							when others => -- VRAM Read 8 bit
								DTC <= DTC_VRAM8_RD;
						end case;
					end if;
					
				when DTC_VRAM_RD =>
					if SLOT_CE = '1' and SLOT = ST_EXT then
						IO_ADDR(0) <= not IO_ADDR(0);
						if IO_ADDR(0) = '0' then
							DT_RD_DATA(7 downto 0) <= VRAM_Q;
						else
							DT_RD_DATA(15 downto 8) <= VRAM_Q;
						end if;
						if IO_BYTE /= IO_ADDR(0) then
							DT_RD_EXEC <= '0';
							DTC <= DTC_IDLE;
						end if;
					end if;
				
				when DTC_VRAM8_RD =>
					if SLOT_CE = '1' and SLOT = ST_EXT then
						IO_ADDR(0) <= not IO_ADDR(0);
						DT_RD_DATA(7 downto 0) <= VRAM_Q;
						DT_RD_EXEC <= '0';
						DTC <= DTC_IDLE;
					end if;
					
				when DTC_CRAM_RD =>
					if SLOT_CE = '1' and SLOT = ST_EXT then
						DT_RD_DATA(11 downto 9) <= CRAM_Q_B(8 downto 6);
						DT_RD_DATA(7 downto 5) <= CRAM_Q_B(5 downto 3);
						DT_RD_DATA(3 downto 1) <= CRAM_Q_B(2 downto 0);
						DT_RD_EXEC <= '0';
						DTC <= DTC_IDLE;
					end if;
				
				when DTC_VSRAM_RD =>
					if SLOT_CE = '1' and SLOT = ST_EXT then
						if unsigned(IO_ADDR(6 downto 1)) < 40 then
							DT_RD_DATA(10 downto 0) <= VSRAM_Q_B(10 downto 0);
						else
							if IO_ADDR(1) = '0' then
								DT_RD_DATA(10 downto 0) <= VSRAM_Q_A(10 downto 0);
							else
								DT_RD_DATA(10 downto 0) <= VSRAM_Q_A(21 downto 11);
							end if;
						end if;
						DT_RD_EXEC <= '0';
						DTC <= DTC_IDLE;
					end if;
				
				when others => null;
			end case;
			
			case DMAC is
				when DMA_IDLE =>
					if DMA_VBUS = '1' then
						if BG_N = '0' and FF_BR_N = '0' and FF_DTACK_N = '1' then
							FF_DTACK_N <= '0';
							DMA_VBUS_WC <= "00";
							DMAC <= DMA_VBUS_WAIT;
						end if;
					elsif DMA_FILL_START = '1' and FIFO_EMPTY = '1' then
						DMA_FILL_WE <= '1';
						DMAC <= DMA_FILL_WR2;
					elsif DMA_COPY = '1' and FIFO_EMPTY = '1' and SLOT_CE = '1' then
						DMA_COPY_WE <= '0';
						IO_ADDR <= "0" & REGS(22) & REGS(21);
						DMAC <= DMA_COPY_RD;
					end if;
				
				when DMA_VBUS_WAIT =>
					if FF_BGACK_N = '0' and SLOT_CE = '1' then
						DMA_VBUS_WC <= DMA_VBUS_WC + 1;
						if DMA_VBUS_WC = 1 then
							FF_VBUS_SEL <= '1';
							DMAC <= DMA_VBUS_RD;
						end if;
					end if;
					
				when DMA_VBUS_RD =>
					if VBUS_DTACK_N = '0' and FIFO_FULL = '0' then
						FF_VBUS_DATA <= VBUS_DATA;
						FF_VBUS_SEL <= '0';
						if SLOT = ST_REFRESH then
							DMAC <= DMA_VBUS_REFRESH;
						else
							DMAC <= DMA_VBUS_WR;
						end if;
					end if;
				
				when DMA_VBUS_REFRESH =>
					if SLOT_CE = '1' then
						if CODE(3 downto 0) = "0001" then
							DMAC <= DMA_VBUS_WR;
						else
							DMAC <= DMA_VBUS_SKIP;
						end if;
					end if;
					
				when DMA_VBUS_SKIP =>
					if SLOT_CE = '1' then
						DMAC <= DMA_VBUS_WR;
					end if;
					
				when DMA_VBUS_WR =>
					if SLOT_CE = '1' then
						FIFO( to_integer(FIFO_WR_POS) ).ADDR <= ADDR;
						FIFO( to_integer(FIFO_WR_POS) ).DATA <= FF_VBUS_DATA;
						FIFO( to_integer(FIFO_WR_POS) ).CODE <= CODE(3 downto 0);
						FIFO_WR_POS <= FIFO_WR_POS + 1;
						FIFO_QUEUE_INC := '1';
						
						ADDR <= std_logic_vector( unsigned(ADDR) + unsigned(ADDR_INC) );
						NEXT_DMA_SRC := std_logic_vector( unsigned(REGS(22)) & unsigned(REGS(21)) + 1 );
						REGS(21) <= NEXT_DMA_SRC(7 downto 0);
						REGS(22) <= NEXT_DMA_SRC(15 downto 8);
						NEXT_DMA_LEN := std_logic_vector( unsigned(REGS(20)) & unsigned(REGS(19)) - 1 );
						REGS(19) <= NEXT_DMA_LEN(7 downto 0);
						REGS(20) <= NEXT_DMA_LEN(15 downto 8);
						if NEXT_DMA_LEN = x"0000" then
							DMAC <= DMA_VBUS_END;
						else
							FF_VBUS_SEL <= '1';
							DMAC <= DMA_VBUS_RD;
						end if;
					end if;
					
				when DMA_VBUS_END =>
					DMA_VBUS <= '0';
					FF_BGACK_N <= '1';
					DMAC <= DMA_IDLE;
					
				--fill
				when DMA_FILL_WR2 =>
--					if FIFO_EMPTY = '1' then
					IO_ADDR <= ADDR;
					DMAC <= DMA_FILL_WR;
--					end if;
					
				when DMA_FILL_WR =>
					if SLOT_CE = '1' and SLOT = ST_EXT then
						if FIFO_EMPTY = '1' then
							ADDR <= std_logic_vector( unsigned(ADDR) + unsigned(ADDR_INC) );
							NEXT_DMA_SRC := std_logic_vector( unsigned(REGS(22)) & unsigned(REGS(21)) + unsigned(ADDR_INC) );
							REGS(21) <= NEXT_DMA_SRC(7 downto 0);
							REGS(22) <= NEXT_DMA_SRC(15 downto 8);
							NEXT_DMA_LEN := std_logic_vector( unsigned(REGS(20)) & unsigned(REGS(19)) - 1 );
							REGS(19) <= NEXT_DMA_LEN(7 downto 0);
							REGS(20) <= NEXT_DMA_LEN(15 downto 8);
							if NEXT_DMA_LEN = x"0000" then
								DMA_FILL <= '0';
								DMA_FILL_START <= '0';
								DMA_FILL_WE <= '0';
								DMAC <= DMA_IDLE;
							else
								DMAC <= DMA_FILL_WR2;
							end if;
--						else
--							DMAC <= DMA_FILL_WR2;
						end if;
					end if;
				
				--copy
				when DMA_COPY_RD =>
					if SLOT_CE = '1' and SLOT = ST_EXT and FIFO_EMPTY = '1' then
						IO_ADDR <= ADDR;
						IO_DATA <= VRAM_Q & VRAM_Q;
						DMA_COPY_WE <= '1';
						DMAC <= DMA_COPY_WR;
					end if;
				
				when DMA_COPY_WR =>
					if SLOT_CE = '1' and SLOT = ST_EXT and FIFO_EMPTY = '1' then
						ADDR <= std_logic_vector( unsigned(ADDR) + unsigned(ADDR_INC) );
						NEXT_DMA_SRC := std_logic_vector( unsigned(REGS(22)) & unsigned(REGS(21)) + 1 );
						REGS(21) <= NEXT_DMA_SRC(7 downto 0);
						REGS(22) <= NEXT_DMA_SRC(15 downto 8);
						NEXT_DMA_LEN := std_logic_vector( unsigned(REGS(20)) & unsigned(REGS(19)) - 1 );
						REGS(19) <= NEXT_DMA_LEN(7 downto 0);
						REGS(20) <= NEXT_DMA_LEN(15 downto 8);
						if NEXT_DMA_LEN = x"0000" then
							DMA_COPY <= '0';
							DMAC <= DMA_IDLE;
						else
							DMAC <= DMA_COPY_RD;
						end if;
						
						IO_ADDR <= "0" & NEXT_DMA_SRC;
						DMA_COPY_WE <= '0';
					end if;
					
				when others => null;
			end case;
			
			if FIFO_QUEUE_INC = '1' and FIFO_QUEUE_DEC = '0' then
				FIFO_QUEUE <= FIFO_QUEUE + 1;
			elsif FIFO_QUEUE_DEC = '1' and FIFO_QUEUE_INC = '0' then
				FIFO_QUEUE <= FIFO_QUEUE - 1;
			end if;
		end if;
	end process;
	
	process( A, DT_RD_DATA, STATUS, HV )
	begin
		if A(4 downto 2) = "000" then					-- Data Port C00000-C00002 
			DO <= DT_RD_DATA;
		elsif A(4 downto 2) = "001" then				-- Control Port C00004-C00006 (Read Status Register)
			DO <= STATUS;
		elsif A(4 downto 3) = "01" then				-- HV Counter C00008-C0000A
			DO <= HV;
		else													-- unused, PSG, DBG
			DO <= x"FFFF";
		end if;
	end process;
	
	DTACK_N <= FF_DTACK_N;
	BGACK_N <= FF_BGACK_N;
	BR_N <= FF_BR_N;
	
	VBUS_ADDR <= REGS(23)(6 downto 0) & REGS(22) & REGS(21);
	VBUS_SEL <= FF_VBUS_SEL;
	
	--CRAM
	CRAM_ADDR_B <= IO_ADDR(6 downto 1);
	CRAM_D <= IO_DATA(11 downto 9) & IO_DATA(7 downto 5) & IO_DATA(3 downto 1);
	CRAM_WE <= '1' when ((IO_PORT_WE = '1' and FIFO_CODE = "0011") or (DMA_FILL_WE = '1' and DMA_FILL_CODE = "0011")) and SLOT = ST_EXT and SLOT_CE = '1' else '0';
	CRAM : entity work.dpram generic map(6,9)
	port map(
		clock			=> CLK,
		data_b		=> CRAM_D,
		address_a	=> CRAM_ADDR_A,
		address_b	=> CRAM_ADDR_B,
		wren_b		=> CRAM_WE,
		q_a			=> CRAM_Q_A,
		q_b			=> CRAM_Q_B
	);
	
	--VSRAM
	VSRAM_ADDR_A <= BG_VSRAM_ADDR;
	VSRAM_ADDR_B <= IO_ADDR(6 downto 1);
	VSRAM_D <= IO_DATA(10 downto 0);
	VSRAM_WE <= '1' when ((IO_PORT_WE = '1' and FIFO_CODE = "0101") or (DMA_FILL_WE = '1' and DMA_FILL_CODE = "0101")) and SLOT = ST_EXT and SLOT_CE = '1' else '0';
	VSRAM : entity work.dpram_dif generic map(5,22,6,11)
	port map(
		clock			=> CLK,
		data_b		=> VSRAM_D,
		address_a	=> VSRAM_ADDR_A,
		address_b	=> VSRAM_ADDR_B,
		wren_b		=> VSRAM_WE,
		q_a			=> VSRAM_Q_A,
		q_b			=> VSRAM_Q_B
	);
	
	--VRAM
	VRAM_A <= SPR_VRAM_ADDR when SLOT = ST_SPRMAP or SLOT = ST_SPRCHAR else 
				 BG_VRAM_ADDR when SLOT = ST_HSCROLL or SLOT = ST_BGAMAP or SLOT = ST_BGACHAR or SLOT = ST_BGBMAP or SLOT = ST_BGBCHAR else
				 IO_ADDR(15 downto 0) when MR2_128K = '0' else 
				 IO_ADDR(16 downto 11) & IO_ADDR(9 downto 2) & IO_ADDR(10) & IO_ADDR(1);
	VRAM_D <= IO_DATA(7 downto 0);
	VRAM_WE <= '1' when ((IO_PORT_WE = '1' and FIFO_CODE = "0001") or (DMA_FILL_WE = '1' and DMA_FILL_CODE = "0001") or DMA_COPY_WE = '1') and SLOT = ST_EXT and SLOT_CE = '1' else '0';
	
	--
	H40 <= MR4_RS1;
	V30 <= MR2_M2;
	
	process( RST_N, CLK )
	variable SCLK_CYCLES: unsigned(2 downto 0);
	begin
		if RST_N = '0' then
			SCLK_DIV <= (others => '0');
			SCLK_CE <= '0';
		elsif rising_edge(CLK) then
			if MR4_RS0 = '0' then
				SCLK_CYCLES := "101";
			else
				SCLK_CYCLES := "100";
			end if;
			SCLK_DIV <= SCLK_DIV + 1;
			if SCLK_DIV = SCLK_CYCLES-1  then
				SCLK_DIV <= (others => '0');
			end if;

			SCLK_CE <= '0';
			if SCLK_DIV = SCLK_CYCLES-1-1 and ENABLE = '1' then
				SCLK_CE <= '1';
			end if;
		end if;
	end process;
	
	process( RST_N, CLK )
	variable EDCLK_CYCLES: unsigned(2 downto 0);
	begin
		if RST_N = '0' then
			EDCLK_DIV <= (others => '0');
			EDCLK_DIV2 <= '0';
			EDCLK_CE <= '0';
		elsif rising_edge(CLK) then
			if MR4_RS0 = '0' then
				EDCLK_CYCLES := "100";
			elsif ((H_CNT&EDCLK_DIV2) >= "1110011010" and (H_CNT&EDCLK_DIV2) <= "1110101000") or 	--39A-3A8
					((H_CNT&EDCLK_DIV2) >= "1110101011" and (H_CNT&EDCLK_DIV2) <= "1110111001") or 	--3AB-3B9
					((H_CNT&EDCLK_DIV2) >= "1110111100" and (H_CNT&EDCLK_DIV2) <= "1111001010") or	--3BC-3CA
					((H_CNT&EDCLK_DIV2) >= "1111001101" and (H_CNT&EDCLK_DIV2) <= "1111011011") 		--3CD-3DB
			then
				EDCLK_CYCLES := "101";
			else
				EDCLK_CYCLES := "100";
			end if;
			
			EDCLK_DIV <= EDCLK_DIV + 1;
			if EDCLK_DIV = EDCLK_CYCLES-1  then
				EDCLK_DIV <= (others => '0');
				EDCLK_DIV2 <= not EDCLK_DIV2;
			end if;

			EDCLK_CE <= '0';
			if EDCLK_DIV = EDCLK_CYCLES-1-1 and ENABLE = '1' then
				EDCLK_CE <= '1';
			end if;
		end if;
	end process;
	
	SC_CE <= (SCLK_CE and not H40) or (EDCLK_CE and H40);
	
	process( RST_N, CLK )
	begin
		if RST_N = '0' then
			DCLK_DIV <= '0';
		elsif rising_edge(CLK) then
			if SC_CE = '1' then
				DCLK_DIV <= not DCLK_DIV;
			end if;
		end if;
	end process;
	
	DCLK_CE <= SC_CE and DCLK_DIV;

	
	process( RST_N, CLK )
	begin
		if RST_N = '0' then
			H_CNT <= (others => '0');
			V_CNT <= (others => '0');
			FIELD <= '0';
			IN_HBL <= '0';
			IN_VBL <= '0';
			FF_HS <= '0';
			FF_VS <= '0';
			FIELD_LATCH <= '0';
		elsif rising_edge(CLK) then
			if ENABLE = '1' and DCLK_CE = '1' then
				H_CNT <= H_CNT + 1;
				if H_CNT = "1"&x"27" and H40 = '0' then
					H_CNT <= "1"&x"D2";
				elsif H_CNT = "1"&x"6C" and H40 = '1' then
					H_CNT <= "1"&x"C9";
				end if;
				
				if (H_CNT = "1"&x"25" and H40 = '0') or (H_CNT = "1"&x"65" and H40 = '1') then
					IN_HBL <= '1';
				elsif (H_CNT = "0"&x"09" and H40 = '0') or (H_CNT = "0"&x"0B" and H40 = '1') then
					IN_HBL <= '0';
				end if;
				
				if (H_CNT = "1"&x"D8" and H40 = '0') or (H_CNT = "1"&x"CD" and H40 = '1') then
					FF_HS <= '1';
				elsif (H_CNT = "1"&x"F2" and H40 = '0') or (H_CNT = "1"&x"EC" and H40 = '1') then
					FF_HS <= '0';
				end if;
				
				if (H_CNT = "1"&x"09" and H40 = '0') or (H_CNT = "1"&x"49" and H40 = '1') then
					V_CNT <= V_CNT + 1;			
					if PAL = '0' and V30 = '0' then
						if V_CNT = "0"&x"EA" then
							V_CNT <= "1"&x"E5";
						end if;
					else
						if V_CNT = "1"&x"02" and V30 = '0' then
							V_CNT <= "1"&x"CA";
						elsif V_CNT = "1"&x"0A" and V30 = '1' then
							V_CNT <= "1"&x"D2";
						end if;
					end if;
					
					if (V_CNT = "0"&x"DF" and V30 = '0') or (V_CNT = "0"&x"EF" and V30 = '1') then
						IN_VBL <= '1';
					elsif V_CNT = "1"&x"FE" then
						IN_VBL <= '0';
					end if;
					
					if V_CNT = "1"&x"FF" then
						-- FIELD changes at VINT, but the HV_COUNTER reflects the current field from line 0-0
						FIELD_LATCH <= FIELD;
					end if;
				end if;
				
				if (H_CNT = "1"&x"13" and H40 = '0') or (H_CNT = "1"&x"53" and H40 = '1') then
					if (V_CNT = "1"&x"E5" and PAL = '0') or (V_CNT = "1"&x"CA" and PAL = '1' and V30 = '0') or (V_CNT = "1"&x"D2" and PAL = '1' and V30 = '1') then
						FF_VS <= '1';
						FIELD_OUT <= MR4_LSM(1) and MR4_LSM(0) and not FIELD_LATCH;
					elsif (V_CNT = "1"&x"E8" and PAL = '0') or (V_CNT = "1"&x"CD" and PAL = '1' and V30 = '0') or (V_CNT = "1"&x"D5" and PAL = '1' and V30 = '1') then
						FF_VS <= '0';
					end if;
				end if;
				
				if H_CNT = "0"&x"00" and ((V_CNT = "0"&x"E0" and V30 = '0') or (V_CNT = "0"&x"F0" and V30 = '1')) then
					FIELD <= not FIELD;
				end if;
			end if;
		end if;
	end process;
	
	-- VSync extension by half a line for interlace
	process( CLK )
	  -- 1710 = 1/2 * 3420 clock per line
	  variable VS_START_DELAY : integer range 0 to 1709;
	  variable VS_END_DELAY : integer range 0 to 1709;
	  variable VS_DELAY_ACTIVE: boolean;
	begin
	  if rising_edge( CLK ) then
		 if FF_VS = '1' then
			-- LSM(0) = 1 and FIELD = 0 right before vsync start -> start the delay
			if ((H_CNT = "1"&x"D2" and H40 = '0') or (H_CNT = "1"&x"D1" and H40 = '1')) and 
				((V_CNT = "1"&x"E5" and PAL = '0') or (V_CNT = "1"&x"CA" and PAL = '1' and V30 = '0') or (V_CNT = "1"&x"D2" and PAL = '1' and V30 = '1')) and 
				MR4_LSM(0) = '1' and FIELD = '0' then
			  VS_START_DELAY := 1709;
			  VS_DELAY_ACTIVE := true;
			end if;
	
			-- FF_VS already inactive, but end delay still != 0
			if VS_END_DELAY /= 0 then
			  VS_END_DELAY := VS_END_DELAY - 1;
			else
			  VS_N <= '0';
			end if;
			
		 else
			-- FF_VS = '0'
			if VS_DELAY_ACTIVE then
			  VS_END_DELAY := 1709;
			  VS_DELAY_ACTIVE := false;
			end if;
	
			-- FF_VS active, but start delay still != 0
			if VS_START_DELAY /= 0 then
			  VS_START_DELAY := VS_START_DELAY - 1;
			else
			  VS_N <= '1';
			end if;
		 end if;
		 HS_N <= not FF_HS;
	  end if;  
	end process;
	
	process( RST_N, CLK )
		variable V30prev : std_logic;
	begin
		if RST_N = '0' then
			V30_LATCH <= '0';
			HBLANK <= '0';
			VBLANK <= '0';
		elsif rising_edge(CLK) then
			if ENABLE = '1' and DCLK_CE = '1' then
				V30prev := V30prev and V30;
				if ((H_CNT = "1"&x"09" and H40 = '0') or (H_CNT = "1"&x"49" and H40 = '1')) and V_CNT = "1"&x"FF" then
					V30_LATCH <= V30prev;
					V30prev := '1';
				end if;
	
				if BORDER_EN = '0' then
					if (H_CNT = "1"&x"19" and H40 = '0') or (H_CNT = "1"&x"59" and H40 = '1') then
						HBLANK <= '1';
					elsif (H_CNT = "0"&x"19" and H40 = '0') or (H_CNT = "0"&x"19" and H40 = '1') then
						HBLANK <= '0';
					end if;
					
					if (H_CNT = "1"&x"09" and H40 = '0') or (H_CNT = "1"&x"49" and H40 = '1') then
						if (V_CNT = "0"&x"DF" and V30_LATCH = '0') or (V_CNT = "0"&x"EF" and V30_LATCH = '1') then
							VBLANK <= '1';
						elsif V_CNT = "1"&x"FF" then
							VBLANK <= '0';
						end if;
					end if;
				else
					if (H_CNT = "1"&x"25" and H40 = '0') or (H_CNT = "1"&x"65" and H40 = '1') then
						HBLANK <= '1';
					elsif (H_CNT = "0"&x"09" and H40 = '0') or (H_CNT = "0"&x"0B" and H40 = '1') then
						HBLANK <= '0';
					end if;
					
					if (H_CNT = "1"&x"09" and H40 = '0') or (H_CNT = "1"&x"49" and H40 = '1') then
						if (V_CNT = "0"&x"E7" and PAL = '0') or (V_CNT = "0"&x"FF" and PAL = '1' and V30_LATCH = '0') or (V_CNT = "1"&x"07" and PAL = '1' and V30_LATCH = '1') then
							VBLANK <= '1';
						elsif (V_CNT = "1"&x"F4" and PAL = '0') or (V_CNT = "1"&x"D9" and PAL = '1' and V30_LATCH = '0') or (V_CNT = "1"&x"E1" and PAL = '1' and V30_LATCH = '1') then
							VBLANK <= '0';
						end if;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	HBL <= HBLANK;
	VBL <= VBLANK;
	RESOLUTION <= V30&H40;
	INTERLACE <= MR4_LSM(1) and MR4_LSM(0);
	
	
	--Slots generation
	SLOT_CE <= DCLK_CE and H_CNT(0);
	
	process( RST_N, CLK, H_CNT, IN_VBL, MR2_DISP, H40 )
	begin
		if IN_VBL = '1' or MR2_DISP = '0' then
			if H_CNT(5 downto 1) = "11001" then
				SLOTS(0) <= ST_REFRESH;
			else
				SLOTS(0) <= ST_EXT;
			end if;
		elsif H_CNT(8 downto 1) = "11110011" then
			SLOTS(0) <= ST_HSCROLL;
		elsif H_CNT(8 downto 4) = "11111" then
			case H_CNT(3 downto 1) is 
				when "000" => 
					SLOTS(0) <= ST_BGAMAP;
				when "001" => 
					SLOTS(0) <= ST_SPRCHAR;
				when "010" => 
					SLOTS(0) <= ST_BGACHAR;
				when "011" => 
					SLOTS(0) <= ST_BGACHAR;
				when "100" => 
					SLOTS(0) <= ST_BGBMAP;
				when "101" => 
					SLOTS(0) <= ST_SPRCHAR;
				when "110" => 
					SLOTS(0) <= ST_BGBCHAR;
				when others => 
					SLOTS(0) <= ST_BGBCHAR;
			end case;
		elsif (H_CNT(8) = '0' and H40 = '0') or (H_CNT(8 downto 6) < "101" and H40 = '1') then
			case H_CNT(3 downto 1) is 
				when "000" => 
					SLOTS(0) <= ST_BGAMAP;
				when "001" => 
					if H_CNT(5 downto 4) = "11" then
						SLOTS(0) <= ST_REFRESH;
					else
						SLOTS(0) <= ST_EXT;
					end if;
				when "010" => 
					SLOTS(0) <= ST_BGACHAR;
				when "011" => 
					SLOTS(0) <= ST_BGACHAR;
				when "100" => 
					SLOTS(0) <= ST_BGBMAP;
				when "101" => 
					SLOTS(0) <= ST_SPRMAP;
				when "110" => 
					SLOTS(0) <= ST_BGBCHAR;
				when others => 
					SLOTS(0) <= ST_BGBCHAR;
			end case;
		elsif (H_CNT(8 downto 1) = "10000000" and H40 = '0') or (H_CNT(8 downto 1) = "10000001" and H40 = '0') or 
				(H_CNT(8 downto 1) = "10010000" and H40 = '0') or (H_CNT(8 downto 1) = "11110010" and H40 = '0') or
				(H_CNT(8 downto 1) = "10100000" and H40 = '1') or (H_CNT(8 downto 1) = "10100001" and H40 = '1') or 
				(H_CNT(8 downto 1) = "11100111" and H40 = '1') then
			SLOTS(0) <= ST_EXT;
		else
			SLOTS(0) <= ST_SPRCHAR;
		end if;
				
		if RST_N = '0' then
			SLOTS(1) <= ST_EXT;
			SLOTS(2) <= ST_EXT;
		elsif rising_edge(CLK) then
			if SLOT_CE = '1' then
				SLOTS(1) <= SLOTS(0);
				SLOTS(2) <= SLOTS(1);
			end if;
		end if;
	end process;
	
	SLOT <= SLOTS(2);
	
	REFRESH <= '1' when SLOT = ST_REFRESH and DMA_VBUS = '1' else '0';
		
	process( RST_N, CLK)
	begin
		if RST_N = '0' then
			VRAM_SDATA_TEMP0 <= (others => '0');
			VRAM_SDATA_TEMP1 <= (others => '0');
			VRAM_SDATA_TEMP2 <= (others => '0');
			BYTE_CNT <= (others => '0');
		elsif rising_edge(CLK) then
			if ENABLE = '1' then
				if SC_CE = '1' then
					case BYTE_CNT is
						when "00" =>
							VRAM_SDATA_TEMP0 <= VRAM_Q;
						when "01" =>
							VRAM_SDATA_TEMP1 <= VRAM_Q;
						when "10" =>
							VRAM_SDATA_TEMP2 <= VRAM_Q;
						when others => null;
					end case;
					BYTE_CNT <= BYTE_CNT + 1;
				end if;
				
				if SLOT_CE = '1' then
					BYTE_CNT <= (others => '0');
				end if;	
			end if;
		end if;
	end process;
	
	VRAM_SDATA <= VRAM_Q & VRAM_SDATA_TEMP2 & VRAM_SDATA_TEMP1 & VRAM_SDATA_TEMP0;
	
	
	BG_X <= H_CNT - 4;
	BG_Y <= V_CNT(7 downto 0);
	
	--Vertical scroll
	process( RST_N, CLK, MR3_VSCR, H_CNT )
	begin
		--scroll
		if MR3_VSCR = '0' then
			BG_VSRAM_ADDR <= "00000";
		else
			BG_VSRAM_ADDR <= std_logic_vector(H_CNT(8 downto 4));
		end if;
		
		if RST_N = '0' then
			VSCRLA <= (others => '0');
			VSCRLB <= (others => '0');
			VSCRLA_LAST <= (others => '0');
			VSCRLB_LAST <= (others => '0');
		elsif rising_edge(CLK) then
			if ENABLE = '1' then
				if SLOT_CE = '1' then
					if MR3_VSCR = '0' then
						if (H_CNT = "1"&x"09" and H40 = '0') or (H_CNT = "1"&x"49" and H40 = '1') then
							VSCRLA <= VSRAM_Q_A(10 downto 0);
							VSCRLA_LAST <= VSRAM_Q_A(10 downto 0);
							VSCRLB <= VSRAM_Q_A(21 downto 11);
							VSCRLB_LAST <= VSRAM_Q_A(21 downto 11);
						end if;
					else
						if H_CNT = "1"&x"F3" then
							if H40 = '0' then
								VSCRLA <= (others => '0');
								VSCRLB <= (others => '0');
							elsif VSCROLL_BUG = '1' then
								-- partial column gets the last read values AND'ed in H40 ("left column scroll bug")
								VSCRLA <= VSCRLA_LAST and VSCRLB_LAST;
								VSCRLB <= VSCRLA_LAST and VSCRLB_LAST;
							else
								-- using VSRAM sometimes looks better (Gynoug)
								VSCRLA <= VSRAM_Q_A(10 downto 0);
								VSCRLB <= VSRAM_Q_A(21 downto 11);
							end if;
						elsif H_CNT(3 downto 0) = x"3" and H_CNT(8 downto 6) <= "100" then
							VSCRLA <= VSRAM_Q_A(10 downto 0);
							VSCRLA_LAST <= VSRAM_Q_A(10 downto 0);
							VSCRLB <= VSRAM_Q_A(21 downto 11);
							VSCRLB_LAST <= VSRAM_Q_A(21 downto 11);
						end if;
					end if;
				end if;	
			end if;
		end if;
	end process;

	--Backgrounds
	
	process( RST_N, CLK, SLOT, PNI, MR4_LSM, H40, BYTE_CNT, SS_HSZ, SS_VSZ, HSDT_HS, MR3_HSCR, BG_X, BG_Y, FIELD, NTA_SA, NTB_SB, NTW_WD, 
	         HSCRLA, HSCRLB, VSCRLA, VSCRLB, WHP_LATCH, WVP_LATCH, WHP_RIGT_LATCH, WVP_DOWN_LATCH )
	variable OFFSET_X : unsigned(9 downto 0);
	variable OFFSET_Y : unsigned(10 downto 0);
	variable CELL_X : unsigned(5 downto 0);
	variable CELL_Y : unsigned(6 downto 0);
	variable PIX_Y : unsigned(3 downto 0);
	variable PIX_X : unsigned(1 downto 0);
	variable MAP_BASE : unsigned(15 downto 0);
	variable HSCRL : unsigned(9 downto 0);
	variable VSCRL : unsigned(10 downto 0);
	variable HSCRL_MASK : unsigned(7 downto 0);
	variable WIN_H, WIN_V, WIN_HIT : std_logic;
	variable PN : std_logic_vector(15 downto 0);
	variable N : integer;
	variable VG : std_logic;
	begin
		--scroll
		if SLOT = ST_BGAMAP or SLOT = ST_BGACHAR then
			HSCRL := unsigned(HSCRLA);
			VSCRL := unsigned(VSCRLA);
		else
			HSCRL := unsigned(HSCRLB);
			VSCRL := unsigned(VSCRLB);
		end if;
		
		--window
		if BG_X(8 downto 4) = "11111" then
			WIN_H := '0';
		elsif BG_X(8 downto 4) < unsigned(WHP_LATCH) then
			WIN_H := not WHP_RIGT_LATCH;
		else
			WIN_H := WHP_RIGT_LATCH;
		end if;
		
		if BG_Y(7 downto 3) < unsigned(WVP_LATCH) then
			WIN_V := not WVP_DOWN_LATCH;
		else
			WIN_V := WVP_DOWN_LATCH;
		end if;
		
		if SLOT = ST_BGAMAP or SLOT = ST_BGACHAR then
			WIN_HIT := WIN_H or WIN_V;
		else
			WIN_HIT := '0';
		end if;
		
		--planes
		if WIN_HIT = '1' then
			OFFSET_X := ("0" & BG_X);
			OFFSET_Y := ("00" & BG_Y & "0");
		else
			OFFSET_X := ((BG_X(8) and BG_X(7)) & BG_X) - (HSCRL(9 downto 4) & "0000");
			if MR4_LSM /= "11" then
				OFFSET_Y := ("00" & BG_Y & "0") + (VSCRL(9 downto 0) & "0");
			else
				OFFSET_Y := ("00" & BG_Y & FIELD) + VSCRL;
			end if;
		end if;
		
		VG := '0';
		if OFFSET_Y(3 downto 1) = 7 and OFFSET_Y(0) = (MR4_LSM(1) and MR4_LSM(0)) then
			VG := '1';
		end if;
				
		case SLOT is
			when ST_HSCROLL =>
				HSCRL_MASK := MR3_HSCR(1)&MR3_HSCR(1)&MR3_HSCR(1)&MR3_HSCR(1)&MR3_HSCR(1)&MR3_HSCR(0)&MR3_HSCR(0)&MR3_HSCR(0);
				BG_VRAM_ADDR <= HSDT_HS & std_logic_vector(BG_Y and HSCRL_MASK) & std_logic_vector(BYTE_CNT);
				
			when ST_BGAMAP | ST_BGBMAP =>			
				if SS_HSZ = "10" then
					-- illegal mode, 32x1
					CELL_Y := "0000000";
				elsif SS_HSZ = "11" then
					-- VSIZE is limited to 32 if HSIZE is 128
					CELL_Y := "00" & OFFSET_Y(8 downto 4);
				elsif SS_VSZ = "11" and SS_HSZ = "01" then
					-- VSIZE is limited to 64 if HSIZE is 64
					CELL_Y := "0" & OFFSET_Y(9 downto 4);
				else
					case SS_VSZ is
						when "00"|"10" => CELL_Y := "00" & OFFSET_Y(8 downto 4);	-- 32 cells
						when "01" =>      CELL_Y := "0" & OFFSET_Y(9 downto 4);	-- 64 cells
						when others =>    CELL_Y := OFFSET_Y(10 downto 4);			-- 128 cells
					end case;
				end if;
				
				CELL_X := OFFSET_X(9 downto 4);
				if WIN_HIT = '1' then
					if H40 = '0' then
						BG_VRAM_ADDR <= std_logic_vector( (unsigned(NTW_WD(15 downto 11)) & "00000000000") + ("000" & CELL_Y & CELL_X(3 downto 0) & BYTE_CNT) ); -- Window 32 cells
					else
						BG_VRAM_ADDR <= std_logic_vector( (unsigned(NTW_WD(15 downto 12)) & "000000000000") + ("00" & CELL_Y & CELL_X(4 downto 0) & BYTE_CNT) ); -- Window 64 cells
					end if;
				else
					if SLOT = ST_BGAMAP then
						MAP_BASE := unsigned(NTA_SA) & "0000000000000";
					else
						MAP_BASE := unsigned(NTB_SB) & "0000000000000";
					end if;
					case SS_HSZ is
						when "00"|"10" => BG_VRAM_ADDR <= std_logic_vector( MAP_BASE + ("000" & CELL_Y & CELL_X(3 downto 0) & BYTE_CNT) ); -- 32 cells
						when "01" =>      BG_VRAM_ADDR <= std_logic_vector( MAP_BASE + ("00"  & CELL_Y & CELL_X(4 downto 0) & BYTE_CNT) ); -- 64 cells
						when others =>    BG_VRAM_ADDR <= std_logic_vector( MAP_BASE + ("0"   & CELL_Y & CELL_X(5 downto 0) & BYTE_CNT) ); -- 128 cells
					end case;
				end if;
			
			when ST_BGACHAR | ST_BGBCHAR =>
				if PNI(0)(12) = '0' then
					PIX_Y := OFFSET_Y(3 downto 0);
				else
					PIX_Y := not OFFSET_Y(3 downto 0);
				end if;
				
				if MR4_LSM /= "11" then
					BG_VRAM_ADDR <= PNI(0)(10 downto 0) & std_logic_vector(PIX_Y(3 downto 1)) & std_logic_vector(BYTE_CNT);
				else
					BG_VRAM_ADDR <= PNI(0)(9 downto 0) & std_logic_vector(PIX_Y(3 downto 0)) & std_logic_vector(BYTE_CNT);
				end if;
			
			when others => null;
				BG_VRAM_ADDR <= (others => '0');
		end case;
		
		DBG_OFFSET_X <= OFFSET_X;
		DBG_OFFSET_Y <= OFFSET_Y;
--		DBG_CELL_X <= CELL_X;
--		DBG_CELL_Y <= CELL_Y;
		DBG_WIN_HIT <= WIN_HIT;
		
		if RST_N = '0' then
			HSCRLA <= (others => '0');
			HSCRLB <= (others => '0');
			PNI <= (others => (others => '0'));
			BGA_TILE_BUF <= (others => ((others => '0'),(others => '0'),'0','0','0'));
			BGB_TILE_BUF <= (others => ((others => '0'),(others => '0'),'0','0','0'));
		elsif rising_edge(CLK) then
			if ENABLE = '1' then
				if SLOT_CE = '1' then
					case SLOT is
						when ST_HSCROLL =>
							HSCRLA <= VRAM_SDATA(9 downto 0);
							HSCRLB <= VRAM_SDATA(25 downto 16);
							WHP_LATCH <= WHP_WHP;
							WVP_LATCH <= WVP_WVP;
							WHP_RIGT_LATCH <= WHP_RIGT;
							WVP_DOWN_LATCH <= WVP_DOWN;
							
						when ST_BGAMAP | ST_BGBMAP =>
							PNI(0) <= VRAM_SDATA(15 downto 0);
							PNI(1) <= VRAM_SDATA(31 downto 16);
						
						when ST_BGACHAR =>
							if PNI(0)(11) = '0' then
								BGA_TILE_BUF(0).DATA <= VRAM_SDATA(15 downto 0)&VRAM_SDATA(31 downto 16);
							else
								BGA_TILE_BUF(0).DATA <= VRAM_SDATA(19 downto 16)&VRAM_SDATA(23 downto 20)&VRAM_SDATA(27 downto 24)&VRAM_SDATA(31 downto 28)&
																VRAM_SDATA( 3 downto  0)&VRAM_SDATA( 7 downto  4)&VRAM_SDATA(11 downto  8)&VRAM_SDATA(15 downto 12);
							end if;	
							BGA_TILE_BUF(0).PAL <= PNI(0)(14 downto 13);
							BGA_TILE_BUF(0).PRIO <= PNI(0)(15);
							BGA_TILE_BUF(0).WIN <= WIN_HIT;
							BGA_TILE_BUF(0).VGRID <= VG;
							BGA_TILE_BUF(1) <= BGA_TILE_BUF(0);
							PNI(0) <= PNI(1);
							
						when ST_BGBCHAR =>
							if PNI(0)(11) = '0' then
								BGB_TILE_BUF(0).DATA <= VRAM_SDATA(15 downto 0)&VRAM_SDATA(31 downto 16);
							else
								BGB_TILE_BUF(0).DATA <= VRAM_SDATA(19 downto 16)&VRAM_SDATA(23 downto 20)&VRAM_SDATA(27 downto 24)&VRAM_SDATA(31 downto 28)&
																VRAM_SDATA( 3 downto  0)&VRAM_SDATA( 7 downto  4)&VRAM_SDATA(11 downto  8)&VRAM_SDATA(15 downto 12);
							end if;	
							BGB_TILE_BUF(0).PAL <= PNI(0)(14 downto 13);
							BGB_TILE_BUF(0).PRIO <= PNI(0)(15);
							BGB_TILE_BUF(0).WIN <= '0';
							BGB_TILE_BUF(0).VGRID <= VG;
							BGB_TILE_BUF(1) <= BGB_TILE_BUF(0);
							PNI(0) <= PNI(1);

						when others => null;
					end case;
				end if;	
			end if;
		end if;
	end process;
	
	--Sprites
	OBJC_ADDR_RD <= (OBJ_N(6) and H40) & OBJ_N(5 downto 0) when SLOT = ST_SPRCHAR else OBJVI_Q;
	OBJC_ADDR_WR <= (IO_ADDR(9) and H40) & IO_ADDR(8 downto 3);
	OBJC_D <= IO_DATA(7 downto 0) & IO_DATA(7 downto 0) & IO_DATA(7 downto 0) & IO_DATA(7 downto 0) when MR2_128K = '0' else
				 IO_DATA(15 downto 8) & IO_DATA(7 downto 0) & IO_DATA(15 downto 8) & IO_DATA(7 downto 0);
	OBJC_WE <= '1' when IO_ADDR(16 downto 10) = SAT_AT(16 downto 10) and (IO_ADDR(9) and not H40) = (SAT_AT(9) and not H40) and ((IO_PORT_WE = '1' and FIFO_CODE = "0001") or (DMA_FILL_WE = '1' and DMA_FILL_CODE = "0001") or DMA_COPY_WE = '1') and SLOT = ST_EXT and SLOT_CE = '1' else '0';
	OBJC_BE(3) <= not IO_ADDR(2) and     IO_ADDR(1) and (    IO_ADDR(0) or MR2_128K);
	OBJC_BE(2) <= not IO_ADDR(2) and     IO_ADDR(1) and (not IO_ADDR(0) or MR2_128K);
	OBJC_BE(1) <= not IO_ADDR(2) and not IO_ADDR(1) and (    IO_ADDR(0) or MR2_128K);
	OBJC_BE(0) <= not IO_ADDR(2) and not IO_ADDR(1) and (not IO_ADDR(0) or MR2_128K);
	OBJ_CACHE : entity work.obj_cache
	port map(
		clock       => CLK,
		wraddress   => OBJC_ADDR_WR,
		data        => OBJC_D,
		wren        => OBJC_WE,
		byteena_a   => OBJC_BE,
		rdaddress   => OBJC_ADDR_RD,
		q           => OBJC_Q
	);
	
	OBJVI_D <= OBJ_N;
	OBJVI_WE <= '1' when OBJ_FIND = '1' and ((unsigned(OBJVI_ADDR_WR) < 16 and H40 = '0') or (unsigned(OBJVI_ADDR_WR) < 20 and H40 = '1')) and SLOT = ST_SPRCHAR and DCLK_CE = '1' else '0';
	obj_visinfo : entity work.dpram generic map (6,7)
	port map(
		clock			=> CLK,
		address_a	=> OBJVI_ADDR_RD,
		q_a			=> OBJVI_Q,
		address_b	=> OBJVI_ADDR_WR,
		data_b		=> OBJVI_D,
		wren_b		=> OBJVI_WE
	);
	
	OBJSI_D <= VRAM_SDATA(24 downto 0) & OBJC_Q(27 downto 24) & OBJC_Y_OFS;
	OBJSI_WE <= '1' when unsigned(OBJVI_ADDR_RD) < unsigned(OBJVI_ADDR_WR) and SLOT = ST_SPRMAP and SLOT_CE = '1' else '0';
	obj_spinfo : entity work.dpram generic map (6,35)
	port map(
		clock			=> CLK,
		address_a	=> OBJSI_ADDR_RD,
		q_a			=> OBJSI_Q,
		address_b	=> OBJSI_ADDR_WR,
		data_b		=> OBJSI_D,
		wren_b		=> OBJSI_WE
	);
	
	process( RST_N, CLK, SLOT, SPR_Y, FIELD, H40, SAT_AT, OBJ_N, OBJ_TILE_N, OBJ_FIND_DONE, BYTE_CNT, OBJC_Q, OBJVI_Q, OBJSI_Q )
	variable OBJC_LINK : std_logic_vector(6 downto 0);
	variable OBJC_VS : std_logic_vector(1 downto 0);
	variable OBJC_Y : unsigned(9 downto 0);
	variable TEMP : unsigned(9 downto 0);
	variable OBJC_TILE_Y : unsigned(5 downto 0);
	variable OBJ_PAT : unsigned(10 downto 0);
	variable OBJ_VS : unsigned(1 downto 0);
	variable OBJ_HS : unsigned(1 downto 0);
	variable OBJ_X : unsigned(8 downto 0);
	variable OBJ_YOFS : unsigned(5 downto 0);
	variable OBJ_HF, OBJ_VF : std_logic;
	variable OBJ_PAL : std_logic_vector(1 downto 0);
	variable OBJ_PRI : std_logic;
	variable OBJ_TILE_X : unsigned(1 downto 0);
	variable OBJ_TILE_Y : unsigned(1 downto 0);
	variable OBJ_TILE_X_24 : unsigned(3 downto 0);
	variable OBJ_OFS_Y : unsigned(3 downto 0);
	variable OBJ_TILE_OFS : unsigned(7 downto 0);
	variable OBJ_POS : unsigned(8 downto 0);
	begin
		--part 1,2
		OBJC_VS := OBJC_Q(25 downto 24);
		OBJC_LINK := OBJC_Q(22 downto 16);
		OBJC_Y := unsigned(OBJC_Q(9 downto 0));
		
		if MR4_LSM = "11" then
			TEMP := "0100000000" + ("0" & SPR_Y(7 downto 0) & FIELD) - OBJC_Y(9 downto 0);
		else
			TEMP := "0100000000" + ("0" & SPR_Y(7 downto 0) & "0")   - (OBJC_Y(8 downto 0) & "0");
		end if;
		
		OBJC_TILE_Y := TEMP(9 downto 4);
		
		--save only the last 5(6 in doubleres) bits of the offset for part 3
		--Titan 2 textured cube (ab)uses this
		OBJC_Y_OFS <= std_logic_vector( TEMP(5 downto 0) );
				
		--part 3
		OBJ_YOFS := unsigned(OBJSI_Q(5 downto 0));
		OBJ_VS := unsigned(OBJSI_Q(7 downto 6));
		OBJ_HS := unsigned(OBJSI_Q(9 downto 8));
		OBJ_PAT := unsigned(OBJSI_Q(20 downto 10));
		OBJ_HF := OBJSI_Q(21);
		OBJ_VF := OBJSI_Q(22);
		OBJ_PAL := OBJSI_Q(24 downto 23);
		OBJ_PRI := OBJSI_Q(25);
		OBJ_X := unsigned(OBJSI_Q(34 downto 26));
		
		if OBJ_HF = '0' then
			OBJ_TILE_X :=          OBJ_TILE_N;
		else
			OBJ_TILE_X := OBJ_HS - OBJ_TILE_N;
		end if;
		
		if OBJ_VF = '0' then
			OBJ_TILE_Y :=          OBJ_YOFS(5 downto 4);
			OBJ_OFS_Y :=     OBJ_YOFS(3 downto 0);
		else
			OBJ_TILE_Y := OBJ_VS - OBJ_YOFS(5 downto 4);
			OBJ_OFS_Y := not OBJ_YOFS(3 downto 0);
		end if;
				
		OBJ_FIND <= '0';
		case SLOT is
			when ST_SPRMAP =>			
				--part 2
				if H40 = '0' then
					SPR_VRAM_ADDR <= SAT_AT(15 downto  9) & OBJVI_Q(5 downto 0) & "1" & std_logic_vector(BYTE_CNT);
				else
					SPR_VRAM_ADDR <= SAT_AT(15 downto 10) & OBJVI_Q(6 downto 0) & "1" & std_logic_vector(BYTE_CNT);
				end if;

			when ST_SPRCHAR =>
				--part 1
				if (OBJC_VS = "00" and OBJC_TILE_Y(5 downto 0) = "000000") or 												-- 8 pix
				   (OBJC_VS = "01" and OBJC_TILE_Y(5 downto 1) = "00000") or  												-- 16 pix
				   (OBJC_VS = "10" and OBJC_TILE_Y(5 downto 2) = "0000" and OBJC_TILE_Y(1 downto 0) /= "11") or	-- 24 pix
				   (OBJC_VS = "11" and OBJC_TILE_Y(5 downto 2) = "0000")  													-- 32 pix
				then
					OBJ_FIND <= not OBJ_FIND_DONE;
				end if;

				--part 3
				OBJ_TILE_X_24 := (OBJ_TILE_X(1) and OBJ_TILE_X(0)) & (OBJ_TILE_X(1) and not OBJ_TILE_X(0)) & (OBJ_TILE_X(1) xor OBJ_TILE_X(0)) & OBJ_TILE_X(0);
				case OBJ_VS is
					when "00" =>   OBJ_TILE_OFS := ("00" & OBJ_TILE_X &   "0000") + ("0000"                 & OBJ_OFS_Y);	-- 8 pixels
					when "01" =>   OBJ_TILE_OFS := ("0"  & OBJ_TILE_X &  "00000") + ("000"  & OBJ_TILE_Y(0) & OBJ_OFS_Y);	-- 16 pixels
					when "10" =>   OBJ_TILE_OFS := (    OBJ_TILE_X_24 &   "0000") + ("00"   & OBJ_TILE_Y    & OBJ_OFS_Y);	-- 24 pixels
					when others => OBJ_TILE_OFS := (       OBJ_TILE_X & "000000") + ("00"   & OBJ_TILE_Y    & OBJ_OFS_Y);	-- 32 pixels
				end case;
				
				if MR4_LSM = "11" then
					SPR_VRAM_ADDR <= std_logic_vector( (OBJ_PAT( 9 downto 0) & "000000") + ("000000"  & OBJ_TILE_OFS(7 downto 0) & BYTE_CNT) );
				else
					SPR_VRAM_ADDR <= std_logic_vector( (OBJ_PAT(10 downto 0) & "00000")  + ("0000000" & OBJ_TILE_OFS(7 downto 1) & BYTE_CNT) );
				end if;
				
			when others => null;
				SPR_VRAM_ADDR <= (others => '0');
		end case;
		
		OBJ_POS := OBJ_X + ("0000" & OBJ_TILE_N & "000") - "010000000";
		
		if RST_N = '0' then
			SPR_Y <= (others => '0');
			OBJ_N <= (others => '0');
			OBJ_TILE_N <= (others => '0');
			OBJ_VALID_X <= '0';
			OBJ_MASKED <= '0';
			OBJ_FIND_DONE <= '0';
			OBJVI_ADDR_WR <= (others => '0');
			OBJVI_ADDR_RD <= (others => '0');
			OBJSI_ADDR_WR <= (others => '0');
			OBJSI_ADDR_RD <= (others => '0');
		elsif rising_edge(CLK) then
			if ENABLE = '1' then
				if SLOT = ST_SPRCHAR and DCLK_CE = '1' then
					OBJ_N <= OBJC_LINK;
					if OBJC_LINK = "0000000" or ((OBJC_LINK(6) = '1' and H40 = '0') or (OBJC_LINK(6 downto 5) = "11" and H40 = '1')) then
						OBJ_FIND_DONE <= '1';
					end if;
					if OBJ_FIND = '1' and ((unsigned(OBJVI_ADDR_WR) < 16 and H40 = '0') or (unsigned(OBJVI_ADDR_WR) < 20 and H40 = '1')) then
						OBJVI_ADDR_WR <= std_logic_vector( unsigned(OBJVI_ADDR_WR) + 1 );
					end if;
				end if;
				
				if SLOT_CE = '1' then
					case SLOT is
						when ST_SPRMAP =>
							OBJVI_ADDR_RD <= std_logic_vector( unsigned(OBJVI_ADDR_RD) + 1 );
							if (unsigned(OBJVI_ADDR_RD) = 15 and H40 = '0') or (unsigned(OBJVI_ADDR_RD) = 19 and H40 = '1') then
								OBJVI_ADDR_RD <= (others => '0');
							end if;
							if unsigned(OBJVI_ADDR_RD) < unsigned(OBJVI_ADDR_WR) then
								OBJSI_ADDR_WR <= std_logic_vector( unsigned(OBJSI_ADDR_WR) + 1 );
							end if;
						
						when ST_SPRCHAR =>
							if unsigned(OBJSI_ADDR_RD) < unsigned(OBJSI_ADDR_WR) then
								OBJ_TILE_N <= OBJ_TILE_N + 1;
								if OBJ_TILE_N = OBJ_HS then
									OBJ_TILE_N <= (others => '0');
									OBJSI_ADDR_RD <= std_logic_vector( unsigned(OBJSI_ADDR_RD) + 1 );
								end if;
								OBJRI(0).XPOS <= std_logic_vector( OBJ_POS );
								if OBJ_HF = '0' then
									OBJRI(0).DATA <= VRAM_SDATA;
								else
									OBJRI(0).DATA <= VRAM_SDATA( 3 downto  0) & VRAM_SDATA( 7 downto  4) & VRAM_SDATA(11 downto  8) & VRAM_SDATA(15 downto 12) & 
														  VRAM_SDATA(19 downto 16) & VRAM_SDATA(23 downto 20) & VRAM_SDATA(27 downto 24) & VRAM_SDATA(31 downto 28);
								end if;
								OBJRI(0).PAL <= OBJ_PAL;
								OBJRI(0).PRIO <= OBJ_PRI;
								OBJRI(0).EN <= not OBJ_MASKED;
								OBJRI(0).BORD <= "000";
								if OBJ_TILE_N = 0 then
									OBJRI(0).BORD(0) <= SPR_GRID_EN;	--left border
								end if;
								if OBJ_TILE_N = OBJ_HS then
									OBJRI(0).BORD(1) <= SPR_GRID_EN;	--rigth border
								end if;
								if OBJ_YOFS = 0  or (OBJ_VS = OBJ_YOFS(5 downto 4) and OBJ_YOFS(3 downto 1) = "111") then	--top/bottom border
									OBJRI(0).BORD(2) <= SPR_GRID_EN;
								end if;
							else
								OBJRI(0).EN <= '0';
							end if;
							
							if OBJ_X /= "000000000" then
								OBJ_VALID_X <= '1';
							elsif OBJ_VALID_X = '1' then
								OBJ_MASKED <= '1';
							end if;
					
						when others => null;
					end case;
					
					if (H_CNT = "1"&x"03" and H40 = '0') or (H_CNT = "1"&x"43" and H40 = '1') then
						SPR_Y <= V_CNT + 2;
						OBJ_N <= (others => '0');
						OBJ_TILE_N <= (others => '0');
						OBJ_FIND_DONE <= '0';
						OBJVI_ADDR_WR <= (others => '0');
						OBJSI_ADDR_RD <= (others => '0');
					end if;
					
					if H_CNT = "0"&x"03" then
						if (unsigned(OBJVI_ADDR_WR) < 16 and H40 = '0') or (unsigned(OBJVI_ADDR_WR) < 20 and H40 = '1') then
							OBJVI_ADDR_RD <= OBJVI_ADDR_WR;
						else
							OBJVI_ADDR_RD <= (others => '0');
						end if;
						OBJSI_ADDR_WR <= (others => '0');
						OBJ_VALID_X <= '0';
						if unsigned(OBJSI_ADDR_RD) < unsigned(OBJSI_ADDR_WR) then
							OBJ_VALID_X <= '1';
						end if;
						OBJ_MASKED <= '0';
						OBJRI(0).EN <= '0';
					end if;
					
					OBJRI(1) <= OBJRI(0);
					OBJRI(2) <= OBJRI(1);
					OBJRI(3) <= OBJRI(2);
					OBJRI(4) <= OBJRI(3);
					OBJRI(5) <= OBJRI(4);
					OBJRI(6) <= OBJRI(5);
				end if;
			end if;
		end if;
	end process;
	
	process( RST_N, CLK, OBJRI, OBJ_PIX )
	begin
		case OBJ_PIX(3 downto 1) is
			when "100" =>  OBJCI_D_A <=  OBJRI(6).BORD(2)                      & OBJRI(6).PRIO & OBJRI(6).PAL & OBJRI(6).DATA(31 downto 28);
			when "101" =>  OBJCI_D_A <=  OBJRI(6).BORD(2)                      & OBJRI(6).PRIO & OBJRI(6).PAL & OBJRI(6).DATA(27 downto 24);
			when "110" =>  OBJCI_D_A <=  OBJRI(6).BORD(2)                      & OBJRI(6).PRIO & OBJRI(6).PAL & OBJRI(6).DATA(23 downto 20);
			when "111" =>  OBJCI_D_A <= (OBJRI(6).BORD(2) or OBJRI(6).BORD(1)) & OBJRI(6).PRIO & OBJRI(6).PAL & OBJRI(6).DATA(19 downto 16);
			when "000" =>  OBJCI_D_A <= (OBJRI(6).BORD(2) or OBJRI(6).BORD(0)) & OBJRI(6).PRIO & OBJRI(6).PAL & OBJRI(6).DATA(15 downto 12);
			when "001" =>  OBJCI_D_A <=  OBJRI(6).BORD(2)                      & OBJRI(6).PRIO & OBJRI(6).PAL & OBJRI(6).DATA(11 downto  8);
			when "010" =>  OBJCI_D_A <=  OBJRI(6).BORD(2)                      & OBJRI(6).PRIO & OBJRI(6).PAL & OBJRI(6).DATA( 7 downto  4);
			when others => OBJCI_D_A <=  OBJRI(6).BORD(2)                      & OBJRI(6).PRIO & OBJRI(6).PAL & OBJRI(6).DATA( 3 downto  0);
		end case;
		
		if RST_N = '0' then
			OBJ_PIX <= (others => '0');
			OBJCI_ADDR_A <= (others => '0');
		elsif rising_edge(CLK) then
			if ENABLE = '1' then
				if OBJRI(6).EN = '1' then
					if OBJ_PIX(0) = '1' then
						OBJCI_ADDR_A <= std_logic_vector( unsigned(OBJCI_ADDR_A) + 1 );
					end if;
					OBJ_PIX <= OBJ_PIX + 1;
				end if;
				
				if OBJRI(5).EN = '1' and SLOT_CE = '1' then
					OBJCI_ADDR_A <= OBJRI(5).XPOS;
					OBJ_PIX <= "00000";
				end if;
			end if;
		end if;
	end process;

	OBJCI_WE_A <= '1' when OBJRI(6).EN = '1' and OBJ_PIX(4) = '0' and OBJ_PIX(0) = '1' and OBJCI_Q_A(3 downto 0) = "0000" else '0';
	OBJCI_ADDR_B <= std_logic_vector( BG_PIX_X );
	OBJCI_WE_B <= DISP_OUT_EN(2) and DCLK_CE;
	obj_ci : entity work.dpram	generic map (9,8)
	port map(
		clock			=> CLK,
		address_a	=> OBJCI_ADDR_A,
		address_b	=> OBJCI_ADDR_B,
		data_a		=> OBJCI_D_A,
		data_b		=> (others => '0'),
		wren_a		=> OBJCI_WE_A,
		wren_b		=> OBJCI_WE_B,
		q_a			=> OBJCI_Q_A,
		q_b			=> OBJCI_Q_B
	);
		
	process( RST_N, CLK )
	begin
		if RST_N = '0' then
			SCOL <= '0';
			SOVR <= '0';
		elsif rising_edge(CLK) then
			if ENABLE = '1' then
				if OBJRI(6).EN = '1' and OBJ_PIX(4) = '0' and OBJ_PIX(0) = '1' and OBJCI_Q_A(3 downto 0) /= "0000" and OBJCI_D_A(3 downto 0) /= "0000" then
					SCOL <= '1';
				elsif SCOL_CLR = '1' then
					SCOL <= '0';
				end if;
				
				if H_CNT = "0"&x"03" and IN_VBL = '0' and unsigned(OBJSI_ADDR_RD) < unsigned(OBJSI_ADDR_WR) and SLOT_CE = '1' then
					SOVR <= '1';
				elsif SOVR_CLR = '1' then
					SOVR <= '0';
				end if;
			end if;
		end if;
	end process;

	process( RST_N, CLK )
	begin
		if RST_N = '0' then
			DISP_OUT_EN <= (others => '0');
		elsif rising_edge(CLK) then
			if ENABLE = '1' and DCLK_CE = '1' then
				if (H_CNT = "0"&x"13" and H40 = '0') or (H_CNT = "0"&x"13" and H40 = '1') then
					DISP_OUT_EN(0) <= MR2_DISP and not IN_VBL;
				elsif (H_CNT = "1"&x"13" and H40 = '0') or (H_CNT = "1"&x"53" and H40 = '1') then
					DISP_OUT_EN(0) <= '0';
				end if;
				DISP_OUT_EN(1) <= DISP_OUT_EN(0);
				DISP_OUT_EN(2) <= DISP_OUT_EN(1);
				DISP_OUT_EN(3) <= DISP_OUT_EN(2);
				DISP_OUT_EN(4) <= DISP_OUT_EN(3);
				DISP_OUT_EN(5) <= DISP_OUT_EN(4);
			end if;
		end if;
	end process;
	
	process( RST_N, CLK )
	variable XA, XB : unsigned(4 downto 0);
	variable PIXA, PIXB: integer range 0 to 7;
	variable CELLA, CELLB, CELLW: integer range 0 to 3;
	variable BGA_COL, BGB_COL, SPR_COL : std_logic_vector(3 downto 0);
	variable BGA_PAL, BGB_PAL, SPR_PAL : std_logic_vector(1 downto 0);
	variable BGA_PRIO, BGB_PRIO, SPR_PRIO : std_logic;
	variable PAL_COL, PAL_COL_DBG : std_logic_vector(5 downto 0);
	variable SPR_BORD : std_logic;
	variable PIX_MODE_TEMP : PixMode_t;
	begin
		if RST_N = '0' then
			BG_PIX_X <= (others => '0');
			BGA_TILE <= (others => ((others => '0'),(others => '0'),'0','0','0'));
			BGB_TILE <= (others => ((others => '0'),(others => '0'),'0','0','0'));
			BGA_WIN_LAST <= '0';
			COLOR <= (others => '0');
			B <= (others => '0');
			G <= (others => '0');
			R <= (others => '0');
			PIX_MODE <= (others => PIX_NORMAL);
			CE_PIX <= '0';
			DISP_GRID <= '0';
		elsif rising_edge(CLK) then
			CE_PIX <= '0';
			if ENABLE = '1' and DCLK_CE = '1' then
				if H_CNT(3 downto 0) = x"5" then
					BGA_TILE(0) <= BGA_TILE_BUF(1);
					BGA_TILE(1) <= BGA_TILE_BUF(0);
					if BGA_WIN_LAST = '0' then
						BGA_TILE(2) <= BGA_TILE(0);
						BGA_TILE(3) <= BGA_TILE(1);
					else
						BGA_TILE(2) <= BGA_TILE_BUF(1);
						BGA_TILE(3) <= BGA_TILE_BUF(0);
					end if;
					BGA_WIN_LAST <= BGA_TILE_BUF(1).WIN;
					
					BGB_TILE(0) <= BGB_TILE_BUF(1);
					BGB_TILE(1) <= BGB_TILE_BUF(0);
					BGB_TILE(2) <= BGB_TILE(0);
					BGB_TILE(3) <= BGB_TILE(1);
				end if;

				if DISP_OUT_EN(2) = '1' then
					CELLW := to_integer("0" & BG_PIX_X(3 downto 3));
					if BGA_TILE(CELLW).WIN = '1' then
						XA := "0" & BG_PIX_X(3 downto 0);
					else
						XA := ("0" & BG_PIX_X(3 downto 0)) - ("0" & unsigned(HSCRLA(3 downto 0)));
					end if;
					CELLA := to_integer(XA(4 downto 3));
					PIXA := to_integer(not XA(2 downto 0));
					BGA_COL := BGA_TILE(CELLA).DATA(PIXA*4 + 3) & BGA_TILE(CELLA).DATA(PIXA*4 + 2) & BGA_TILE(CELLA).DATA(PIXA*4 + 1) & BGA_TILE(CELLA).DATA(PIXA*4 + 0);
					BGA_PAL := BGA_TILE(CELLA).PAL;
					BGA_PRIO := BGA_TILE(CELLA).PRIO;
					
					XB := ("0" & BG_PIX_X(3 downto 0)) - ("0" & unsigned(HSCRLB(3 downto 0)));
					CELLB := to_integer(XB(4 downto 3));
					PIXB := to_integer(not XB(2 downto 0));
					BGB_COL := BGB_TILE(CELLB).DATA(PIXB*4 + 3) & BGB_TILE(CELLB).DATA(PIXB*4 + 2) & BGB_TILE(CELLB).DATA(PIXB*4 + 1) & BGB_TILE(CELLB).DATA(PIXB*4 + 0);
					BGB_PAL := BGB_TILE(CELLB).PAL;
					BGB_PRIO := BGB_TILE(CELLB).PRIO;
					
					SPR_COL := OBJCI_Q_B(3 downto 0);
					SPR_PAL := OBJCI_Q_B(5 downto 4);
					SPR_PRIO := OBJCI_Q_B(6);
					SPR_BORD := OBJCI_Q_B(7);
						
					BK_COL(0) <= '0';
					if SPR_COL /= "0000" and SPR_PRIO = '1' and (MR4_STE='0' or OBJCI_Q_B(5 downto 1) /= "11111") and SPR_EN = '1' then
						PAL_COL := SPR_PAL&SPR_COL;
					elsif BGA_COL /= "0000" and BGA_PRIO = '1' and BGA_EN = '1' then
						PAL_COL := BGA_PAL&BGA_COL;
					elsif BGB_COL /= "0000" and BGB_PRIO = '1' and BGB_EN = '1' then
						PAL_COL := BGB_PAL&BGB_COL;
					elsif SPR_COL /= "0000" and SPR_PRIO = '0' and (MR4_STE='0' or OBJCI_Q_B(5 downto 1) /= "11111") and SPR_EN = '1' then
						PAL_COL := SPR_PAL&SPR_COL;
					elsif BGA_COL /= "0000" and BGA_PRIO = '0' and BGA_EN = '1' then
						PAL_COL := BGA_PAL&BGA_COL;
					elsif BGB_COL /= "0000" and BGB_PRIO = '0' and BGB_EN = '1' then
						PAL_COL := BGB_PAL&BGB_COL;
					else
						PAL_COL := BGC_PAL&BGC_COL;
						BK_COL(0) <= '1';
					end if;
					
					if MR4_STE = '1' and BGA_PRIO = '0' and BGB_PRIO = '0' then
						--if all layers are normal priority, then shadowed
						PIX_MODE_TEMP := PIX_SHADOW;
					else
						PIX_MODE_TEMP := PIX_NORMAL;
					end if;
					
					PIX_MODE(0) <= PIX_MODE_TEMP;
					if MR4_STE = '1' and (SPR_PRIO = '1' or
						((BGA_PRIO = '0' or BGA_COL = "0000") and (BGB_PRIO = '0' or BGB_COL = "0000"))) then
						--sprite is visible
						if OBJCI_Q_B(5 downto 0) = "111110" then
							--if sprite is palette 3/color 14 increase intensity
							if PIX_MODE_TEMP = PIX_SHADOW then 
								PIX_MODE(0) <= PIX_NORMAL;
							else
								PIX_MODE(0) <= PIX_HIGHLIGHT;
							end if;
						elsif OBJCI_Q_B(5 downto 0) = "111111" then
							-- if sprite is visible and palette 3/color 15, decrease intensity
							PIX_MODE(0) <= PIX_SHADOW;
						elsif (SPR_PRIO = '1' and SPR_COL /= "0000") or SPR_COL = "1110" then
							--sprite color 14 or high prio always shows up normal
							PIX_MODE(0) <= PIX_NORMAL;
						end if;
					end if;
					
					case DBG(8 downto 7) is
						when "00" => PAL_COL_DBG := BGC_PAL&BGC_COL;
						when "01" => PAL_COL_DBG := SPR_PAL&SPR_COL;
						when "10" => PAL_COL_DBG := BGA_PAL&BGA_COL;
						when "11" => PAL_COL_DBG := BGB_PAL&BGB_COL;
						when others => null;
					end case;

					if DBG(6) = '1' then
						CRAM_ADDR_A <= PAL_COL_DBG;
					elsif DBG(8 downto 7) /= "00" then
						CRAM_ADDR_A <= PAL_COL and PAL_COL_DBG;
					else
						CRAM_ADDR_A <= PAL_COL;
					end if;
					
					DISP_GRID <= '0';
					if ((XA(2 downto 0) = 7 or BGA_TILE(CELLA).VGRID = '1') and BG_GRID_EN(0) = '1') or
						((XB(2 downto 0) = 7 or BGB_TILE(CELLB).VGRID = '1') and BG_GRID_EN(1) = '1') or 
						(SPR_BORD = '1' and SPR_GRID_EN = '1') then
						DISP_GRID <= '1';
					end if;
					
					BG_PIX_X <= BG_PIX_X + 1;
				else
					CRAM_ADDR_A <= BGC_PAL&BGC_COL;
					PIX_MODE(0) <= PIX_NORMAL;
					BG_PIX_X <= (others => '0');
					DISP_GRID <= '0';
				end if;
				
				if DISP_GRID = '1' then
					COLOR <= (others => '1');
					PIX_MODE(1) <= PIX_NORMAL;
					BK_COL(1) <= '0';
				else
					COLOR <= CRAM_Q_A;
					PIX_MODE(1) <= PIX_MODE(0);
					BK_COL(1) <= BK_COL(0);
				end if;
				
				COLOR2 <= COLOR;
				PIX_MODE(2) <= PIX_MODE(1);
				BK_COL(2) <= BK_COL(1);
				
				case PIX_MODE(2) is
				when PIX_SHADOW =>
					-- half brightness
					B <= '0' & COLOR2(8 downto 6);
					G <= '0' & COLOR2(5 downto 3);
					R <= '0' & COLOR2(2 downto 0);

				when PIX_NORMAL =>
					-- normal brightness
					B <= COLOR2(8 downto 6) & '0';
					G <= COLOR2(5 downto 3) & '0';
					R <= COLOR2(2 downto 0) & '0';
				
				when PIX_HIGHLIGHT =>
					-- increased brightness
					B <= std_logic_vector( unsigned('0' & COLOR2(8 downto 6)) + 7 );
					G <= std_logic_vector( unsigned('0' & COLOR2(5 downto 3)) + 7 );
					R <= std_logic_vector( unsigned('0' & COLOR2(2 downto 0)) + 7 );
				end case;
				YS_N <= not BK_COL(2);
				
				CE_PIX <= '1';
			end if;
		end if;
	end process;

	
	process( RST_N, CLK )
	begin
		if RST_N = '0' then
			HV <= (others => '0');
			HL_OLD <= '1';
		elsif rising_edge(CLK) then
			if ENABLE = '1' then
				HL_OLD <= HL;
				if MR1_M3 = '0' or (HL = '0' and HL_OLD = '1') then	
					HV(7 downto 0) <= std_logic_vector( H_CNT(8 downto 1) );
					case MR4_LSM is
						when "01" =>   HV(15 downto 8) <= std_logic_vector( V_CNT(7 downto 1)&V_CNT(8) );
						when "11" =>   HV(15 downto 8) <= std_logic_vector( V_CNT(6 downto 0)&V_CNT(7) );
						when others => HV(15 downto 8) <= std_logic_vector( V_CNT(7 downto 0) );
					end case;
					
--					EXINT_PENDING_SET <= '1';
				end if;
			end if;
		end if;
	end process;
	
	process( RST_N, CLK )
	begin
		if RST_N = '0' then
			VINT_FLAG <= '0';
			HINT_FLAG <= '0';
			HINT_COUNT <= (others => '0');
			Z80_INT_FLAG <= '0';
			Z80_INT_WAIT <= (others => '0');
			INTACK_OLD <= '0';
		elsif rising_edge(CLK) then
			if ENABLE = '1' then
				INTACK_OLD <= INTACK;
				if INTACK = '1' and INTACK_OLD = '0' then
					if VINT_FLAG = '1' and MR2_IE0 = '1' then--
						VINT_FLAG <= '0';
					elsif HINT_FLAG = '1' and MR1_IE1 = '1' then--
						HINT_FLAG <= '0';
--					elsif EXINT_FF = '1' then
--						EXINT_PENDING <= '0';
					end if;
				end if;

				if DCLK_CE = '1' then
					if H_CNT = "0"&x"00" and ((V_CNT = "0"&x"E0" and V30 = '0') or (V_CNT = "0"&x"F0" and V30 = '1')) then
						VINT_FLAG <= '1';
						Z80_INT_FLAG <= '1';
						Z80_INT_WAIT <= x"975";	--2422 MCLK
					end if;
					
					if (H_CNT = "1"&x"09" and H40 = '0') or (H_CNT = "1"&x"49" and H40 = '1') then
						if (V_CNT = "0"&x"DF" and V30 = '0') or (V_CNT = "0"&x"EF" and V30 = '1') then
							HINT_EN <= '0';
						elsif V_CNT = "1"&x"FE" then
							HINT_EN <= '1';
						end if;
					
--						if IN_VBL = '1' then 
						if HINT_EN = '0' then
							HINT_COUNT <= unsigned(HIR_HIT);
						else
							if HINT_COUNT = 0 then
								HINT_FLAG <= '1';
								HINT_COUNT <= unsigned(HIR_HIT);
							else
								HINT_COUNT <= HINT_COUNT - 1;
							end if;
						end if;
					end if;
				end if;
				
				if Z80_INT_WAIT = 0 then
					if Z80_INT_FLAG = '1' then
						Z80_INT_FLAG <= '0';
					end if;
				else
					Z80_INT_WAIT <= Z80_INT_WAIT - 1;
				end if;
			end if;
		end if;
	end process;
	
	EDCLK <= EDCLK_CE;
	VINT <= VINT_FLAG and MR2_IE0;
	HINT <= HINT_FLAG and MR1_IE1;
	
	process( RST_N, CLK )
	begin
		if RST_N = '0' then
			IPL_N <= "11";
		elsif rising_edge(CLK) then
			if ENABLE = '1' and VCLK_ENp = '1' then
				if AS_N = '1' then
					if VINT_FLAG = '1' and MR2_IE0 = '1' then
						IPL_N <= "00";
					elsif HINT_FLAG = '1' and MR1_IE1 = '1' then
						IPL_N <= "01";
--					elsif EXINT_FF = '1' then
--						IPL_N <= "10";
					else
						IPL_N <= "11";
					end if;
				end if;
			end if;
		end if;
	end process;
	
--	IPL_N <= "00" when VINT_FLAG = '1' and MR2_IE0 = '1' else
--				"01" when HINT_FLAG = '1' and MR1_IE1 = '1' else
----				"10" when EXINT_FF = '1' else
--				"11";
	
	Z80_INT_N <= not Z80_INT_FLAG;
	
	
	DBG_FIFO_ADDR <= FIFO_ADDR;
	DBG_FIFO_DATA <= FIFO_DATA;
	DBG_FIFO_CODE <= FIFO_CODE;
	DBG_FIFO_EMPTY <= FIFO_EMPTY;
	DBG_FIFO_FULL <= FIFO_FULL;
	DBG_MR1_DD <= MR1_DD;
	
end rtl;