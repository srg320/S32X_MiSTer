//
// ddram.v
// Copyright (c) 2020 Sorgelig
//
//
// This source file is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version. 
//
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License 
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
// ------------------------------------------
//


module ddram
(
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,
	
	input         clk,

	input  [27:1] mem_addr,
	output [31:0] mem_dout,
	input  [31:0] mem_din,
	input         mem_rd,
	input   [3:0] mem_wr,
	input   [1:0] mem_chan,
	input         mem_16b,
	output        mem_busy
);



reg   [7:0] ram_burst;
reg  [63:0] ram_din;
reg  [27:1] ram_address;
(* ramstyle = "logic" *) reg  [27:1] cache_addr[4] = '{4{27'h7FFFFFF}};
(* ramstyle = "logic" *) reg [127:0] cache_data[4];
reg   [1:0] cache_chan;
reg   [7:0] ram_ba;
reg         ram_word;
reg         ram_read = 0;
reg         ram_write = 0;

reg  [27:1] addr;
reg  [31:0] din;
reg   [3:0] wr;
reg   [1:0] chan;
reg         word;

reg [1:0]  state = 0;
reg        read_busy = 0;
reg        write_busy = 0;

always @(posedge clk) begin
	reg old_rd, old_we;

	old_rd <= mem_rd;
	old_we <= |mem_wr;
	if (mem_rd && !old_rd) begin
		if (cache_addr[mem_chan][27:4] == mem_addr[27:4]) begin
			cache_addr[mem_chan][3:1] <= mem_addr[3:1];
			cache_chan <= mem_chan;
			ram_word <= mem_16b;
		end else
			read_busy <= 1;
	end
	if (|mem_wr && !old_we) begin
		if (cache_addr[mem_chan][27:4] == mem_addr[27:4]) begin
			if (mem_16b) 
				case (mem_addr[3:1])
					3'b000: begin
						if (mem_wr[1]) cache_data[mem_chan][127:120] <= mem_din[15:8];
						if (mem_wr[0]) cache_data[mem_chan][119:112] <= mem_din[7:0];
					end
					3'b001: begin
						if (mem_wr[1]) cache_data[mem_chan][111:104] <= mem_din[15:8];
						if (mem_wr[0]) cache_data[mem_chan][103:096] <= mem_din[7:0];
					end
					3'b010: begin
						if (mem_wr[1]) cache_data[mem_chan][095:088] <= mem_din[15:8];
						if (mem_wr[0]) cache_data[mem_chan][087:080] <= mem_din[7:0];
					end
					3'b011: begin
						if (mem_wr[1]) cache_data[mem_chan][079:072] <= mem_din[15:8];
						if (mem_wr[0]) cache_data[mem_chan][071:064] <= mem_din[7:0];
					end
					3'b100: begin
						if (mem_wr[1]) cache_data[mem_chan][063:056] <= mem_din[15:8];
						if (mem_wr[0]) cache_data[mem_chan][055:048] <= mem_din[7:0];
					end
					3'b101: begin
						if (mem_wr[1]) cache_data[mem_chan][047:040] <= mem_din[15:8];
						if (mem_wr[0]) cache_data[mem_chan][039:032] <= mem_din[7:0];
					end
					3'b110: begin
						if (mem_wr[1]) cache_data[mem_chan][031:024] <= mem_din[15:8];
						if (mem_wr[0]) cache_data[mem_chan][023:016] <= mem_din[7:0];
					end
					3'b111: begin
						if (mem_wr[1]) cache_data[mem_chan][015:008] <= mem_din[15:8];
						if (mem_wr[0]) cache_data[mem_chan][007:000] <= mem_din[7:0];
					end
				endcase
			else
				case (mem_addr[3:2])
					2'b00: begin
						if (mem_wr[3]) cache_data[mem_chan][127:120] <= mem_din[31:24];
						if (mem_wr[2]) cache_data[mem_chan][119:112] <= mem_din[23:16];
						if (mem_wr[1]) cache_data[mem_chan][111:104] <= mem_din[15:8];
						if (mem_wr[0]) cache_data[mem_chan][103:096] <= mem_din[7:0];
					end
					2'b01: begin
						if (mem_wr[3]) cache_data[mem_chan][095:088] <= mem_din[31:24];
						if (mem_wr[2]) cache_data[mem_chan][087:080] <= mem_din[23:16];
						if (mem_wr[1]) cache_data[mem_chan][079:072] <= mem_din[15:8];
						if (mem_wr[0]) cache_data[mem_chan][071:064] <= mem_din[7:0];
					end
					2'b10: begin
						if (mem_wr[3]) cache_data[mem_chan][063:056] <= mem_din[31:24];
						if (mem_wr[2]) cache_data[mem_chan][055:048] <= mem_din[23:16];
						if (mem_wr[1]) cache_data[mem_chan][047:040] <= mem_din[15:8];
						if (mem_wr[0]) cache_data[mem_chan][039:032] <= mem_din[7:0];
					end
					2'b11: begin
						if (mem_wr[3]) cache_data[mem_chan][031:024] <= mem_din[31:24];
						if (mem_wr[2]) cache_data[mem_chan][023:016] <= mem_din[23:16];
						if (mem_wr[1]) cache_data[mem_chan][015:008] <= mem_din[15:8];
						if (mem_wr[0]) cache_data[mem_chan][007:000] <= mem_din[7:0];
					end
				endcase
		end
		write_busy <= 1;
	end

	if(!DDRAM_BUSY) begin
		ram_write <= 0;
		ram_read  <= 0;

		case(state)
			0: if (write_busy) begin
					ram_din		<= mem_16b ? {4{mem_din[15:0]}} : {2{mem_din}};
					ram_address <= mem_addr;
					if (mem_16b) 
						case (mem_addr[2:1])
							2'b00: ram_ba <= {mem_wr[1:0],6'b000000};
							2'b01: ram_ba <= {2'b00,mem_wr[1:0],4'b0000};
							2'b10: ram_ba <= {4'b0000,mem_wr[1:0],2'b00};
							2'b11: ram_ba <= {6'b000000,mem_wr[1:0]};
						endcase
					else
						case (mem_addr[2])
							1'b0: ram_ba <= {mem_wr,4'b0000};
							1'b1: ram_ba <= {4'b0000,mem_wr};
						endcase
					ram_write 	<= 1;
					ram_burst   <= 1;
					state       <= 1;
				end
				else if(read_busy) begin
					ram_address          <= {mem_addr[27:4],3'b000};
					cache_addr[mem_chan] <= mem_addr;
					cache_chan           <= mem_chan;
					ram_word 	         <= mem_16b;
					ram_ba               <= 8'hFF;
					ram_read             <= 1;
					ram_burst            <= 2;
					state                <= 2;
				end

			1: begin
					write_busy <= 0;
					state  <= 0;
				end
		
			2: if (DDRAM_DOUT_READY) begin
					cache_data[cache_chan][127:64] <= DDRAM_DOUT;
					state <= 3;
				end

			3: if (DDRAM_DOUT_READY) begin
					cache_data[cache_chan][63:0] <= DDRAM_DOUT;
					read_busy <= 0;
					state <= 0;
				end
		endcase
	end
end

always_comb begin
	if (ram_word) 
		case (cache_addr[cache_chan][3:1])
			3'b000: mem_dout = {16'h0000,cache_data[cache_chan][127:112]};
			3'b001: mem_dout = {16'h0000,cache_data[cache_chan][111:096]};
			3'b010: mem_dout = {16'h0000,cache_data[cache_chan][095:080]};
			3'b011: mem_dout = {16'h0000,cache_data[cache_chan][079:064]};
			3'b100: mem_dout = {16'h0000,cache_data[cache_chan][063:048]};
			3'b101: mem_dout = {16'h0000,cache_data[cache_chan][047:032]};
			3'b110: mem_dout = {16'h0000,cache_data[cache_chan][031:016]};
			3'b111: mem_dout = {16'h0000,cache_data[cache_chan][015:000]};
		endcase
	else
		case (cache_addr[cache_chan][3:2])
			2'b00: mem_dout = cache_data[cache_chan][127:096];
			2'b01: mem_dout = cache_data[cache_chan][095:064];
			2'b10: mem_dout = cache_data[cache_chan][063:032];
			2'b11: mem_dout = cache_data[cache_chan][031:000];
		endcase
end
//assign mem_dout = cache_data[cache_chan];
assign mem_busy = read_busy | write_busy;


assign DDRAM_CLK      = clk;
assign DDRAM_BURSTCNT = ram_burst;
assign DDRAM_BE       = ram_ba;
assign DDRAM_ADDR     = {4'b0011, ram_address[27:3]}; // RAM at 0x30000000
assign DDRAM_RD       = ram_read;
assign DDRAM_DIN      = ram_din;
assign DDRAM_WE       = ram_write;

endmodule
