module CART 
(
	input             CLK,
	input             RST_N,
	
	input             VCLK,
	input      [23:1] VA,
	input      [15:0] VDI,
	output     [15:0] VDO,
	input             AS_N,
	output            DTACK_N,
	input             LWR_N,
	input             UWR_N,
	input             CE0_N,
	input             CAS0_N,
	input             CAS2_N,
	input             ASEL_N,
	input             TIME_N,
	
	output     [23:1] MEM_A,
	input      [15:0] MEM_DI,
	output     [15:0] MEM_DO,
	output            MEM_RD,
	output            MEM_WRL,
	output            MEM_WRH,
	
	input      [23:0] rom_sz,
	input             eeprom_quirk,
	input             bank_eeprom_quirk,
	input             noram_quirk,
	input             schan_quirk,
	input             realtec_quirk,
	input             sfmap_quirk,
	input       [1:0] sfmap
);

	reg old_LWR_N, old_UWR_N, old_CAS0_N;
	always @(posedge CLK) begin
		old_LWR_N <= LWR_N;
		old_UWR_N <= UWR_N;
		old_CAS0_N <= CAS0_N;
	end
	
	reg         SRAM_BANK;
	reg         EEPROM_BANK;
	//reg   [7:0] BANK_DO;
	always @(posedge CLK) begin
		if (!RST_N) begin
			SRAM_BANK <= 0;
			EEPROM_BANK <= 0;
		end else begin
			if (!TIME_N) begin
				if (!LWR_N && old_LWR_N) begin
					SRAM_BANK <= VDI[0];
	//			end else if (!GEN_CAS0_N && old_CAS0_N) begin
	//				BANK_DO <= '0;
				end
			end
			
			if (bank_eeprom_quirk) begin
				if ({VA,1'b0} == 24'h200000 && !CE0_N && !LWR_N && old_LWR_N && !UWR_N && old_UWR_N) begin
					EEPROM_BANK <= ~VDI[0];
				end
			end
		end
	end
	wire SRAM_EN = ((SRAM_BANK || EEPROM_BANK || ({2'b00,VA[21:1]} >= rom_sz[23:1] && !noram_quirk)) && VA[21] && !CE0_N);
	
	//Realtec mapper
	reg [21:17] REALTEC_BANK;
	reg   [4:0] REALTEC_MASK;
	reg         REALTEC_BOOT;
	always @(posedge CLK) begin
		if (!RST_N) begin
			REALTEC_BANK <= '0;
			REALTEC_MASK <= '0;
			REALTEC_BOOT <= realtec_quirk;
		end else begin
			if (realtec_quirk) begin
				if (VA[23:16] == 8'h40 && !	VA[11:1] && !UWR_N && old_UWR_N) begin
					case (VA[15:12])
						4'h0: begin REALTEC_BANK[21:20] <= VDI[2:1]; REALTEC_BOOT <= ~VDI[0]; end
						4'h2: begin 
							case (VDI[5:0])
								6'd0,6'd1:                                      REALTEC_MASK <= 5'b00000;
								6'd2:                                           REALTEC_MASK <= 5'b00001;
								6'd3,6'd4:                                      REALTEC_MASK <= 5'b00011;
								6'd5,6'd6,6'd7,6'd8:                            REALTEC_MASK <= 5'b00111;
								6'd9,6'd10,6'd11,6'd12,6'd13,6'd14,6'd15,6'd16: REALTEC_MASK <= 5'b01111;
								default:                                        REALTEC_MASK <= 5'b11111;
							endcase
						end
						4'h4: begin REALTEC_BANK[19:17] <= VDI[2:0]; end
					endcase
				end
			end
		end
	end
	wire [21:1] REALTEC_A = REALTEC_BOOT ? {9'b000111111,VA[12:1]} : {(VA[21:17] & REALTEC_MASK) + REALTEC_BANK,VA[16:1]};
	
	//SF-001,SF-0012,SF-004 mappers
	reg   [7:0] SF001_BANK_REG;
	reg   [7:0] SF002_BANK_REG;
	reg         SF004_SRAM_EN;
	reg   [7:0] SF004_BANK_REG;
	reg   [2:0] SF004_FIRST_PAGE;
	always @(posedge CLK) begin
		if (!RST_N) begin
			SF001_BANK_REG <= 8'h00;
			SF002_BANK_REG <= 8'h00;
			SF004_SRAM_EN <= 0;
			SF004_BANK_REG <= 8'h80;
			SF004_FIRST_PAGE <= '0;
		end else begin
			if (sfmap_quirk && sfmap <= 2'd1) begin	//SF-001
				if (!SF001_BANK_REG[5] && VA[23:16] == 8'h00 && !LWR_N && old_LWR_N) begin
					case (VA[11:8])
						4'hE: SF001_BANK_REG <= VDI[7:0];
					endcase
				end
			end else if (sfmap_quirk && sfmap == 2'd2) begin	//SF-002
				if (VA[23:16] == 8'h00 && !LWR_N && old_LWR_N) begin
					SF002_BANK_REG <= VDI[7:0];
				end
			end else if (sfmap_quirk && sfmap == 2'd3) begin	//SF-004
				if (SF004_BANK_REG[7] && VA[23:16] == 8'h00 && !LWR_N && old_LWR_N) begin
					case (VA[11:8])
						4'hD: SF004_SRAM_EN <= VDI[7];
						4'hE: SF004_BANK_REG <= VDI[7:0];
						4'hF: SF004_FIRST_PAGE <= VDI[6:4];
					endcase
				end
			end
		end
	end
	wire [21:1] SF001_A = SF001_BANK_REG[7] && VA[21:18] == 4'b0000                  ? {4'b1110,VA[17:1]} : 
								 SF001_BANK_REG[7] && VA[21:18] == 4'b1111 && sfmap == 2'd1 ? {4'b0000,VA[17:1]} : 	//SRAM bank
								 VA[21:1];
	wire [21:1] SF002_A = VA[23:16] >= 8'h3C ? {5'b00000,VA[16:1]} :	//SRAM bank
								 VA[23:16] >= 8'h20 ? {~SF002_BANK_REG[7],VA[20:1]} : 
								 VA[21:1];
	wire [21:1] SF004_A = VA[23:21] == 3'b001 ? {4'b0000,VA[17:1]} : 	//SRAM bank
	                      VA[23:16] < 8'h14 && SF004_BANK_REG[6] ? {1'b0,SF004_FIRST_PAGE + VA[20:18],VA[17:1]} : 
								 {1'b0,SF004_FIRST_PAGE,VA[17:1]};
	wire SF_SRAM_EN = (VA[23:20] == 4'h4                           && sfmap == 2'd0) || 
							(VA[23:18] == 6'b001111 && SF001_BANK_REG[7] && sfmap == 2'd1) ||
							(VA[23:18] == 6'b001111                      && sfmap == 2'd2) || 
							(VA[23:21] == 3'b001    && SF004_SRAM_EN     && sfmap == 2'd3);
							  
	
	assign MEM_A = realtec_quirk                ? {1'b0,SRAM_EN,REALTEC_A} : 
					   sfmap_quirk && sfmap <= 2'd1 ? {1'b0,SF_SRAM_EN,SF001_A} : 
						sfmap_quirk && sfmap == 2'd2 ? {1'b0,SF_SRAM_EN,SF002_A} : 
						sfmap_quirk && sfmap == 2'd3 ? {1'b0,SF_SRAM_EN,SF004_A} : 
						{1'b0,SRAM_EN,VA[21:1]};
	assign MEM_DO = VDI;
	assign MEM_RD = !CE0_N && !CAS0_N;
	assign MEM_WRL = !CE0_N && !LWR_N && (SRAM_EN || schan_quirk);
	assign MEM_WRH = !CE0_N && !UWR_N && (SRAM_EN || schan_quirk);
	
	assign VDO = eeprom_quirk & {VA,1'b0} == 24'h200000 ? 16'h0000 : 
	             !TIME_N ? (sfmap_quirk && sfmap == 2'd3 ? {1'b0,SF004_FIRST_PAGE,4'b0000} : 16'h0000) :
					 CE0_N ? 16'h0000 : 
	             MEM_DI;


endmodule
