`include "package.sv"
import ctrl_pkg::*;

module ws_gen(
	input logic clk, rst_, Tx_empty, Rx_full,
	OP_t OP,
	output logic ws, ws_state_t state
	);

	logic [4:0] cnt;
	logic enable;
	ws_state_t nextstate;
	always_ff @(negedge clk, negedge rst_) begin
		if (!rst_) {state, cnt} <= {IDLE ,5'hff};
		else {state, cnt} <= {nextstate, (enable) ? cnt+1'b1 : cnt};
	end

	always_latch if((OP.stereo && cnt==5'h1f) || (!OP.stereo && cnt[3:0]==4'hf))	 
		enable = OP.tran_en & ((OP.mode==MT & !Tx_empty) | (OP.mode==MR & !Rx_full));

	always_comb 
		case (state)
			IDLE: if (enable) nextstate <= L;
				  else nextstate <= IDLE;

			L: if ((OP.frame_size==f32bits && cnt==5'h1f) || 
				   (OP.frame_size==f16bits && cnt[3:0]==4'hf))
					nextstate <= (OP.stereo) ? R : 
								  (enable) ? L : IDLE;

			R: if ((OP.frame_size==f32bits && cnt==5'h1f) || 
				   (OP.frame_size==f16bits && cnt[3:0]==4'hf))
					nextstate <= (enable) ? L : IDLE;	
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

logic ws_old;
logic [4:0] cnt; logic cnt_en;

always_ff @(negedge clk, negedge rst_) begin
	if (!rst_) cnt <= 5'h0;
	else begin
	ws_old <= ws;
	if (OP.mode inside {ST, SR} && cnt_en) cnt <= cnt+1'b1;
	end
end

let cntZ = ((OP.frame_size==f32bits && cnt==5'h0) || (OP.frame_size==f16bits && cnt[3:0]==4'h0));
let RtoL = (OP.standard==I2S) ? (ws_old && !ws) : (!ws_old && ws); //same as IDLEtoL
let LtoR = OP.stereo & ((OP.standard==I2S) ? (!ws_old && ws) : (ws_old && !ws));
let RtoIDL = OP.stereo & ((OP.standard==I2S) ? (ws_old && ws && cntZ) : (!ws_old && !ws && cntZ));
let LtoIDL = OP.stereo ? 
			  ((OP.standard==I2S) ? (!ws_old && !ws && cntZ) : (ws_old && ws && cntZ)) :
		      ((OP.standard==I2S) ? (!ws_old && ws) : (ws_old && !ws));


always_comb begin
	if (!rst_) state = IDLE;
	else
	    if (RtoL) {state, cnt_en} = {L, 1'b1}; 
		else if (LtoIDL) {state, cnt_en} = {IDLE, 1'b0};
		else if (LtoR) {state, cnt_en} = {R, 1'b1};
		else if (RtoIDL) {state, cnt_en} = {IDLE,1'b0};
	    
end

endmodule

module ws_control(
	input logic sclk, preset, ws, 
	OP_t OP, ws_state_t ws_gen_state,
	output logic Tx_ren, Rx_wen, del_Tx_ren, del_Rx_wen
	);

	ws_state_t ws_state, ws_tr_state;
	ws_tracker Uwst(.clk(sclk), .rst_(preset), .OP, .ws, .state(ws_tr_state));
	assign ws_state = (OP.mode inside {MT, MR}) ? ws_gen_state : ws_tr_state;


	always_ff @(negedge sclk or negedge preset) begin : proc_del_en
    if(!preset)
        {del_Tx_ren, del_Rx_wen} <= 0;
    else
        {del_Tx_ren, del_Rx_wen} <= {Tx_ren, Rx_wen};
end

always_comb begin : proc_ws_fifo_synch
    if (ws_state inside {L,R}) begin
        {Tx_ren, Rx_wen} = 2'b0;
        case (OP.mode)
            MT, ST: Tx_ren = 1'b1;
            MR, SR: Rx_wen = 1'b1;
        endcase
    end
    else if (ws_state == IDLE)
        {Tx_ren, Rx_wen} = 2'b0;
    
end
endmodule

module ws_tbench;
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