`include "package.sv"
import ctrl_pkg::*;

/*module test_clk_div(pclk, sclk);
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
        
endmodule*/

module clk_div(
	input logic pclk, rst_,
	logic [5:0] N,
	output logic sclk
);
	logic [5:0] counter;
	logic tff1, tff2;
	logic ev_clk; 
	logic div1,div2;

	assign sclk = (!N[0]) ? ev_clk : div1^div2;

	always_ff @(posedge pclk, negedge rst_) begin
		if (!rst_) begin
			{counter, tff1, tff2, ev_clk} <= 9'b0;
			{div1, div2} <= 2'b11;
		end else begin
			counter <= (counter>=N-1) ? 6'b0 : counter + 1;
		end
	end

	always_ff @(posedge pclk)
		case (N[0])
			1'b0: 
				if (counter==(N/2-1)) begin
					counter <= 0;
					ev_clk <= ~ev_clk;
				end
			1'b1: begin
				if (counter==0) div1 <= ~div1;
			end
		endcase

	always_ff @(negedge pclk)
		if (N[0]==1'b1 && counter==(N+1)/2) div2 <= ~div2;	

endmodule	

module ws_gen(
	input logic clk, rst_, en,
	OP_t OP,
	output logic ws
	);

	logic [4:0] cnt;
	
	always_ff @(posedge clk, negedge rst_) begin
		if (!rst_) {ws, cnt} <= {1'b1,5'b0};
		else if (en) begin
			if ((OP.frame_size==f32bits && cnt==5'h1f) || (OP.frame_size==f16bits && cnt[3:0]==4'hf)) ws <= ~ws;
			cnt <= cnt + 1;
		end
	end
endmodule

module ws_tracker(
	input logic clk, rst_, ws,
	OP_t OP,
	output logic ws_change
);

logic ws_old;
assign ws_change = ws ^ ws_old;

always_ff @(posedge clk) begin
		ws_old <= ws;
	end
endmodule


module tbench;
logic clk=0;
logic rst_=1;
OP_t OP = '{default: 0, frame_size: f32bits};
logic en =1'b1;
logic ws, ws_change;

ws_gen u1(.*);
ws_tracker u2(.*);

always forever #1 clk <= ~clk;

initial begin
@(negedge clk) rst_<=0;
@(posedge clk) rst_<=1;
end
endmodule