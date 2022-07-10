`include "package.sv"
import ctrl_pkg::*;

module test_clk_div(pclk, sclk);
	input	wire	pclk;
	output	reg		sclk;

  reg	[31:0]	counter=0;
  	

	always @(posedge pclk)
	if (counter == 0)
		counter <= 2;
	else
		counter <= counter - 1;

	always @(posedge pclk)
   		sclk <= (counter == 1);
        
endmodule

module clk_div(
	input logic pclk, rst_,
	logic [5:0] N,
	output logic sclk
);
	logic [5:0] counter;
	logic tff1, tff2;
	logic ev_clk;

	assign sclk = (N%2) ? ev_clk : div1^div2;

	always_ff @(posedge pclk, negedge rst_) begin
		if (!rst_) begin
			{counter, tff1, tff2, ev_clk} <= 9'b0;
			{div1, div2} <= 2'b11;
		end else begin
			counter <= (counter>=N-1) ? 6'b0 : counter + 1;
		end
	end

	always_ff @(posedge pclk)
		case (N%2)
			1'b0: 
				if (counter==(N/2-1)) begin
					counter <= 0;
					ev_clk <= ~ev_clk;
				end
			1'b1: begin
				if (counter==0) div1 <= ~div1;
			end
		endcase

	always @(negedge pclk)
		if (N%2==1'b1 && counter==(N+1)/2) div2 <= ~div2;	

endmodule	

module ws_gen(
	input logic clk, rst_, en,
	OP_t OP,
	output logic ws, ws_old
	);

	logic [4:0] cnt;
	logic b = (OP.frame_size==f16bits) ? 1'b0 : 1'b1;
	
	always_ff @(posedge clk, negedge rst_) begin
		if (!rst_) {ws, cnt} <= 0;
		else if (en) begin
			if (cnt=={b,4'hf}) ws <= ~ws;
			cnt <= cnt + 1;
		end
	end
endmodule

module ws_tracker(
	input logic ws,
	OP_t OP,
	output logic ws_change
);

logic [4:0] cnt;
logic b = (OP.frame_size==f16bits) ? 1'b0 : 1'b1;
assign ws_change = ws ^ ws_old;

always_ff @(posedge clk, negedge rst_) begin
		if (!rst_) cnt <= 0;
		else begin
			if (cnt=={b,4'hf}) ws_old <= ws;
			cnt <= cnt + 1;
		end
	end
endmodule