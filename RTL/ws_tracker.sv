//when I2S operates in slave mode the ws signal is being tracked with
//the help of a delayed ws signal (ws_old) and the state of the signal 
//is then outputed to be used bu ws_control (states: L,R channel or IDLE)
module ws_tracker(
    input logic clk, rst_, ws, OP_t OP,
    output ws_state_t state
    );

logic ws_old;
logic [4:0] cnt; 
logic cnt_en;

logic cntZ, RtoL, LtoR, RtoIDL, LtoIDL;

always_ff @(negedge clk, negedge rst_) begin
    if (!rst_) begin
        cnt <= 5'h1f;
    end else begin
        ws_old <= ws;
        if (OP.mode inside {ST, SR} && cnt_en) begin
            cnt <= cnt+1'b1;
        end    
    end
end

//for when the counter is truely zero (deppending in frame size)
assign cntZ = ((OP.frame_size==f32bits && cnt==5'h0) || (OP.frame_size==f16bits && cnt[3:0]==4'h0));

//for when the ws channel changes from R to L (or channel 1 to channel 2 it isnt necessarily L and R)
assign RtoL = (OP.standard==I2S) ? (ws_old && !ws) : (!ws_old && ws); //same as IDLEtoL

//for when the ws channel changes from L to R
assign LtoR = OP.stereo & ((OP.standard==I2S) ? (!ws_old && ws) : (ws_old && !ws));

//for when the ws channel changes from R to idle 
assign RtoIDL = OP.stereo & ((OP.standard==I2S) ? (ws_old && ws && cntZ) : (!ws_old && !ws && cntZ));

//for when the ws channel changes from L to idle, should only happen in mono mode and not in stereo 
assign LtoIDL = OP.stereo ? 
              ((OP.standard==I2S) ? (!ws_old && !ws && cntZ) : (ws_old && ws && cntZ)) :
              ((OP.standard==I2S) ? (!ws_old && ws) : (ws_old && !ws));


always_latch begin
    if (!rst_) begin
        {state} = {IDLE};
    end else begin
        if (RtoL) begin
            {state, cnt_en} = {L, 1'b1}; 
        end else if (LtoIDL) begin
            {state, cnt_en} = {IDLE, 1'b0};
        end else if (LtoR) begin
            {state, cnt_en} = {R, 1'b1};
        end else if (RtoIDL) begin
            {state, cnt_en} = {IDLE,1'b0};
        end 
    end   
end


endmodule
