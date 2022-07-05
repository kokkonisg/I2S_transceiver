`include "package.sv"
import ctrl_pkg::*;

module clk_div(pclk, sclk);
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