`include "package.sv"
import ctrl_pkg::*;

module clk_tbench;
	logic pclk, rst_, sclk, mclk;
	OP_t OP = '{default: 0, mclk_en: 1'b1, mode: MT, stereo:1'b1};
	int cnt=0;
	always forever @(posedge pclk) if(rst_) cnt++;

	clk_div Udiv (.*);

	always forever #2 pclk <= !pclk;

	initial begin
		pclk <= 1'b0;
        rst_<=1'b0;
		@(posedge pclk) rst_<=1'b1;
	end
endmodule


module clk_div(
	input logic pclk, rst_,
	OP_t OP,
	output logic sclk, mclk
);
	logic [5:0] counter, N;
	logic ev_clk, clk25, f2, f4, f8, f16; 
	logic div1,div2,en,en25;

	div_calc Udc(.OP(OP),.en25(en25),.enN(en),.N);


	//Logic for division-by-N, where N is an odd or even number.
	//there is also a divide-by-2.5 divider as it was necessary
	//to achieve the desired clock frequency

	always_comb
		if (OP.mclk_en) begin
			mclk = (!en25) ? (!N[0] ? ev_clk : div1^div2) : clk25;

			if (!OP.stereo && OP.frame_size==f16bits) begin
				sclk = f16; 
			end else if (OP.stereo && OP.frame_size==f32bits) begin
				sclk = f4;
			end else begin //mono & 32bit frame OR stereo & 16bit frame
				sclk = f8;
			end
		end else begin
			sclk = (!en25) ? (!N[0] ? ev_clk : div1^div2) : clk25;
		end


//----Toggle FFs to create a 2^N divider----
//used to produce the sclk from mclk whenever mclk_en is high
	always_ff @(posedge mclk, negedge rst_) begin
		if (!rst_) begin
			f2 <= 1'b0;
		end	else begin 
			f2 <= !f2;
		end
	end

	always_ff @(posedge f2, negedge rst_) begin
		if (!rst_) begin 
			f4 <= 1'b0;
		end else begin 
			f4 <= !f4;
		end
	end

	always_ff @(posedge f4, negedge rst_) begin
		if (!rst_) begin 
			f8 <= 1'b0;
		end else begin 
			f8 <= !f8;
		end
	end

	always_ff @(posedge f8, negedge rst_) begin
		if (!rst_) begin 
			f16 <= 1'b0;
		end else begin 
			f16 <= !f16;
		end
	end
//------------------------------------------

//----Divider by N where N is either odd or even----
	always_ff @(posedge pclk, negedge rst_) begin
		if (!rst_) begin
			{counter, ev_clk} <= 0;
			{div1, div2} <= 2'b11;
		end else if (en) begin
			counter <= (counter>=N-1) ? 6'b0 : counter + 1;
		end
	end

	always_ff @(posedge pclk) begin
		if (en) begin
			case (N[0])
				1'b0: if (counter==(N/2-1)) begin
						{counter, ev_clk} <= {6'h0, ~ev_clk};
					end
				1'b1: if (counter==0) begin
						div1 <= ~div1;
					end
			endcase
		end
	end

	always_ff @(negedge pclk) begin
		if (en) begin
			if (N[0]==1'b1 && counter==(N+1)/2) begin
				div2 <= ~div2;	
			end
		end
	end
//--------------------------------------------------

//----Divider by 2.5----

	logic A, B, C, O;
	always_ff @(posedge pclk, negedge rst_) begin
		if (!rst_) begin
			{A,B,C} <= 1'b0;
		end else if (en25) begin
			A <= !A & !B & !C;
			B <= (A | B) & !C;
			C <= B;
		end
	end

	assign O = (!pclk & B & C) | (pclk & O);
	assign clk25 = A | O;
//----------------------
endmodule	


//look up table to calculate, depending on I2S options,
//the divisor of the freq divider 
module div_calc (
	input OP_t OP,
	output logic enN, en25, [5:0] N
);

	always_comb begin
		{enN, en25} = 1'b0;
		if (OP.mode inside {MT, MR}) begin
			case (OP.mclk_en)
			  1'b1: if (OP.sys_freq==k32) begin
			  			case (OP.sample_rate)
							hz44: {N, enN} = {6'd3, 1'b1};
							hz48: en25 = 1'b1;
						endcase
					end else begin
						{N, enN} = {6'd1, 1'b1}; //should never happen
					end
			  1'b0: case (OP.sys_freq)
					k8: case (OP.stereo)
						1'b1: case (OP.sample_rate)
							hz44: case (OP.frame_size)
								f16bits: {N, enN} = {6'd6,1'b1};
								f32bits: {N, enN} = {6'd3,1'b1};
							endcase
							hz48: case (OP.frame_size)
								f16bits: {N, enN} = {6'd5,1'b1};
								f32bits: en25 = 1'b1;
							endcase
						endcase
						1'b0: case (OP.sample_rate)
							hz44: case (OP.frame_size)
								f16bits: {N, enN} = {6'd11,1'b1};
								f32bits: {N, enN} = {6'd6,1'b1};
							endcase
							hz48: case (OP.frame_size)
								f16bits: {N, enN} = {6'd10,1'b1};
								f32bits: {N, enN} = {6'd5,1'b1};
							endcase
						endcase
					endcase
					k16: case (OP.stereo)
						1'b1: case (OP.sample_rate)
							hz44: case (OP.frame_size)
								f16bits: {N, enN} = {6'd11,1'b1};
								f32bits: {N, enN} = {6'd6,1'b1};
							endcase
							hz48: case (OP.frame_size)
								f16bits: {N, enN} = {6'd10,1'b1};
								f32bits: {N, enN} = {6'd5,1'b1};
							endcase
						endcase
						1'b0: case (OP.sample_rate)
							hz44: case (OP.frame_size)
								f16bits: {N, enN} = {6'd23,1'b1};
								f32bits: {N, enN} = {6'd11,1'b1};
							endcase
							hz48: case (OP.frame_size)
								f16bits: {N, enN} = {6'd21,1'b1};
								f32bits: {N, enN} = {6'd10,1'b1};
							endcase
						endcase
					endcase
					k32: case (OP.stereo)
						1'b1: case (OP.sample_rate)
							hz44: case (OP.frame_size)
								f16bits: {N, enN} = {6'd23,1'b1};
								f32bits: {N, enN} = {6'd11,1'b1};
							endcase
							hz48: case (OP.frame_size)
								f16bits: {N, enN} = {6'd21,1'b1};
								f32bits: {N, enN} = {6'd10,1'b1};
							endcase
						endcase
						1'b0: case (OP.sample_rate)
							hz44: case (OP.frame_size)
								f16bits: {N, enN} = {6'd45,1'b1};
								f32bits: {N, enN} = {6'd23,1'b1};
							endcase
							hz48: case (OP.frame_size)
								f16bits: {N, enN} = {6'd42,1'b1};
								f32bits: {N, enN} = {6'd21,1'b1};
							endcase
						endcase
					endcase
					default: {N, enN} = {6'd1, 1'b1}; //should never happen
				endcase 
			endcase 
		end
	end

endmodule : div_calc


