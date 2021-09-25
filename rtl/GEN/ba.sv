module BA 
(
	input             CLK,
	input             RST_N,
	input             ENABLE,
	
	input             VCLK_ENp,
	input             VCLK_ENn,
	input      [23:1] VA,
	input      [15:0] VDI,
	output     [15:0] VDO,
	input             RNW,
	input             LDS_N,
	input             UDS_N,
	input             AS_N,
	output            DTACK_N,
	output            BR_N,
	input             BG_N,
	output            BGACK_N,
	
	input             ZCLK_ENp,
	input             ZCLK_ENn,
	input      [15:0] ZA,
	input       [7:0] ZDI,
	output      [7:0] ZDO,
	input             ZWR_N,
	input             ZRD_N,
	input             MREQ_N,
	input             M1_N,
	output            WAIT_N,
	output            ZBR_N,
	output            ZBAK_N,
	output            ZRAM_N
	
	
);



endmodule
