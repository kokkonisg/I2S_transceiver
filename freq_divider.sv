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
	logic ev_clk; 
	logic div1,div2;

	assign sclk = (!N[0]) ? ev_clk : div1^div2;

	always_ff @(posedge pclk, negedge rst_) begin
		if (!rst_) begin
			{counter, ev_clk} <= 0;
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
	input logic clk, rst_,
	OP_t OP,
	output logic ws
	);

	logic [4:0] cnt;
	
	typedef enum {IDLE, L, R} state_t; state_t state, nextstate;
	always_ff @(negedge clk, negedge rst_) begin
		if (!rst_) {state, cnt} <= {IDLE ,5'hff};
		else {state, cnt} <= {nextstate, (OP.tran_en) ? cnt+1'b1 : cnt};
	end

	always_comb 
		case (state)
			IDLE: if (OP.tran_en) nextstate <= L;
				  else nextstate <= IDLE;

			L: if ((OP.frame_size==f32bits && cnt==5'h1f) || 
				   (OP.frame_size==f16bits && cnt[3:0]==4'hf))
					nextstate <= R;

			R: if ((OP.frame_size==f32bits && cnt==5'h1f) || 
				   (OP.frame_size==f16bits && cnt[3:0]==4'hf))
					nextstate <= (OP.tran_en) ? L : IDLE;	
		endcase 		
	

	always_comb 
		case (state)
			IDLE: ws <= (OP.standard==I2S) ? 1'b1 : 1'b0;
			L: ws <= (OP.standard==I2S) ? 1'b0 : 1'b1;
			R: ws <= (OP.standard==I2S) ? 1'b1 : 1'b0;
		endcase

endmodule

module ws_tracker(
	input logic clk, rst_, ws, OP_t OP,
	output ws_state_t state);

logic ws_old, ws_change;
assign ws_change = ws ^ ws_old;

logic [4:0] cnt; logic cnt_en;

always_ff @(negedge clk, negedge rst_) begin
	if (!rst_) cnt <= 5'h0;
	else begin
	ws_old <= ws;
	if (cnt_en) cnt <= cnt+1'b1;
	end
end

let cntZ = ((OP.frame_size==f32bits && cnt==5'h0) || (OP.frame_size==f16bits && cnt[3:0]==4'h0));
let RtoL = (OP.standard==I2S) ? (ws_old && !ws) : (!ws_old && ws);
let LtoR = (OP.standard==I2S) ? (!ws_old && ws) : (ws_old && !ws);
let RtoIDL = (OP.standard==I2S) ? (ws_old && ws && cntZ) : (!ws_old && !ws && cntZ);
let LtoIDL = (OP.standard==I2S) ? (!ws_old && !ws && cntZ) : (ws_old && ws && cntZ);


always_comb begin
	if (!rst_) state = IDLE;
	else
	    if (RtoL) {state, cnt_en} = {L, 1'b1};
		else if (LtoIDL) {state, cnt_en} = {IDLE, 1'b0};
		else if (LtoR) {state, cnt_en} = {R, 1'b1};
		else if (RtoIDL) {state, cnt_en} = {IDLE,1'b0};
	    
end

endmodule

module tbench;
logic clk=0;
logic rst_=1;
OP_t OP = '{default: 0, frame_size: f32bits, standard: MSB};
logic ws;
ws_state_t state;

ws_gen u1(.*);

ws_tracker u2(clk, rst_, ws, OP, state);

always forever #1 clk <= ~clk;

initial begin
@(posedge clk) rst_<=0;
@(posedge clk) rst_<=1;
repeat(2) @(posedge clk);
OP.tran_en<=1;
repeat(50) @(posedge clk);
@(u1.cnt==5'hff) OP.tran_en<=0;
repeat(25) @(posedge clk);
OP.tran_en<=1;
end
endmodule