library IEEE;
use IEEE.Std_Logic_1164.all;
library STD;
use ieee.numeric_std.all;

package VDP_PKG is 

	type Slot_t is (
		ST_HSCROLL,
		ST_BGAMAP,
		ST_BGACHAR,
		ST_BGBMAP,
		ST_BGBCHAR,
		ST_SPRMAP,
		ST_SPRCHAR,
		ST_EXT,
		ST_REFRESH
	);
	type SlotPipe_t is array(0 to 2) of Slot_t;

	type BGTileInfo_r is record
		DATA 	: std_logic_vector(31 downto 0);
		PAL 	: std_logic_vector(1 downto 0);
		PRIO 	: std_logic;
		WIN 	: std_logic;
		VGRID : std_logic;
	end record;
	type BGTileInfoBuf_t is array(0 to 1) of BGTileInfo_r;
	type BGTileRender_t is array(0 to 3) of BGTileInfo_r;
	type BGPatterNameInfo_t is array(0 to 1) of std_logic_vector(15 downto 0);
	
	type BGPixInfo_r is record
		COLOR : std_logic_vector(3 downto 0);
		PAL 	: std_logic_vector(1 downto 0);
		PRIO 	: std_logic;
		VGRID : std_logic;
	end record;
	
	type BGPixInfo_t is array(0 to 31) of BGPixInfo_r;
	
	function FlipPixels(b: std_logic_vector(7 downto 0); flip: std_logic) return std_logic_vector;
	
	type ObjRenderInfo_r is record
		XPOS 	: std_logic_vector(8 downto 0);
		DATA 	: std_logic_vector(31 downto 0);
		PAL	: std_logic_vector(1 downto 0);
		PRIO 	: std_logic;
		EN 	: std_logic;
		BORD	: std_logic_vector(2 downto 0);
	end record;
	type ObjRenderInfo_t is array(0 to 6) of ObjRenderInfo_r;
	
	type Regs_t is array(0 to 23) of std_logic_vector(7 downto 0);
	
	type Fifo_r is record
		ADDR 	: std_logic_vector(16 downto 0);
		DATA 	: std_logic_vector(15 downto 0);
		CODE	: std_logic_vector(3 downto 0);
	end record;
	
	type Fifo_t is array(0 to 3) of Fifo_r;
	
	type ColorArray_t is array(0 to 3) of std_logic_vector(3 downto 0);

end VDP_PKG;

package body VDP_PKG is

	function FlipPixels(b: std_logic_vector(31 downto 0); flip: std_logic) return std_logic_vector is
		variable res: std_logic_vector(31 downto 0); 
	begin
		if flip = '1' then
			res := b(3 downto 0) & b(7 downto 4) & b(11 downto 8) & b(15 downto 12) & b(19 downto 16) & b(23 downto 20) & b(27 downto 24) & b(31 downto 28);
		else
			res := b;
		end if;
		return res;
	end function;


end package body VDP_PKG;
