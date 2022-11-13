`include "package.sv"
import ctrl_pkg::*;


//when I2S operates in master mode the ws signal is generated using an fsm 
//and starts/stops using the OP.tran_en (transcaction enable) control bit
module ws_gen(
    input logic clk, rst_, Tx_empty, Rx_full,
    OP_t OP,
    output logic ws, ws_state_t state
    );

    logic [4:0] cnt;
    logic enable;
    ws_state_t nextstate;
    always_ff @(negedge clk, negedge rst_) begin
        if (!rst_) begin
            {state, cnt} <= {IDLE, 5'hff};
        end else begin
            {state, cnt} <= {nextstate, (enable) ? cnt+1'b1 : cnt};
        end
    end

    //latch to send the whole frame if transaction is disabled midway 
    always_latch if((OP.frame_size==f32bits && cnt==5'h1f) || (OP.frame_size==f16bits && cnt[3:0]==4'hf)) begin  
        enable = !OP.stop & ((OP.mode==MT & !Tx_empty) | (OP.mode==MR & !Rx_full));
    end

    always_comb begin
        case (state)
            IDLE: if (enable) begin
                    nextstate <= L;
                end else begin
                    nextstate <= IDLE;
                end 

            L: if ((OP.frame_size==f32bits && cnt==5'h1f) 
                  || (OP.frame_size==f16bits && cnt[3:0]==4'hf)) begin
                    nextstate <= (OP.stereo) ? ((enable) ? R : IDLE) : ((enable) ? L : IDLE);
                end

            R: if ((OP.frame_size==f32bits && cnt==5'h1f) 
                  || (OP.frame_size==f16bits && cnt[3:0]==4'hf)) begin
                    nextstate <= (enable) ? L : IDLE;   
                end
            default: nextstate <= IDLE;
        endcase 
    end        
    

    always_comb begin
        case (state)
            IDLE: ws <= (OP.standard==I2S) ? 1'b1 : 1'b0;
            L: ws <= (OP.standard==I2S) ? 1'b0 : 1'b1;
            R: ws <= (OP.standard==I2S) ? 1'b1 : 1'b0;
        endcase
    end
endmodule

//when I2S operates in slave mode the ws signal is being tracked with
//the help of a delayed ws signal (ws_old) and the state of the signal 
//is then outputed to be used bu ws_control (states: L,R channel or IDLE)
module ws_tracker(
    input logic clk, rst_, ws, OP_t OP,
    output ws_state_t state);

logic ws_old;
logic [4:0] cnt; 
logic cnt_en;

always_ff @(negedge clk, negedge rst_) begin
    if (!rst_) begin
        cnt <= 5'h0;
    end else begin
        ws_old <= ws;
        if (OP.mode inside {ST, SR} && cnt_en /*&& !OP.stop*/) begin
            cnt <= cnt+1'b1;
        end    
    end
end

//for when the counter is truely zero (deppending in frame size)
let cntZ = ((OP.frame_size==f32bits && cnt==5'h0) || (OP.frame_size==f16bits && cnt[3:0]==4'h0));

//for when the ws channel changes from R to L (or channel 1 to channel 2 it isnt necessarily L and R)
let RtoL = (OP.standard==I2S) ? (ws_old && !ws) : (!ws_old && ws); //same as IDLEtoL

//for when the ws channel changes from L to R
let LtoR = OP.stereo & ((OP.standard==I2S) ? (!ws_old && ws) : (ws_old && !ws));

//for when the ws channel changes from R to idle 
let RtoIDL = OP.stereo & ((OP.standard==I2S) ? (ws_old && ws && cntZ) : (!ws_old && !ws && cntZ));

//for when the ws channel changes from L to idle, should only happen in mono mode and not in stereo 
let LtoIDL = OP.stereo ? 
              ((OP.standard==I2S) ? (!ws_old && !ws && cntZ) : (ws_old && ws && cntZ)) :
              ((OP.standard==I2S) ? (!ws_old && ws) : (ws_old && !ws));


always_comb begin
    if (!rst_) begin
        state = IDLE;
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

module ws_control(
    input logic sclk, preset, ws, 
    OP_t OP, ws_state_t ws_gen_state,
    output logic Tx_ren, Rx_wen, del_Tx_ren, del_Rx_wen
    );

    ws_state_t ws_state, ws_tr_state;
    ws_tracker Uwst(.clk(sclk), .rst_(preset), .OP, .ws, .state(ws_tr_state));

    //depending on the peripheral's mode, 
    //only one of the above modules needs to run
    assign ws_state = (OP.mode inside {MT, MR}) ? ws_gen_state : ws_tr_state;

    //dellayed enables are used for I2S Phillips standard which requires a 1 clok cycle dellay
    always_ff @(negedge sclk or negedge preset) begin : proc_del_en
        if (!preset) begin
            {del_Tx_ren, del_Rx_wen} <= 0;
        end else begin
            {del_Tx_ren, del_Rx_wen} <= {Tx_ren, Rx_wen};
        end    
    end

    //controls when the Transmitting (Recieving) FIFO starts sending (accepting) bits based on ws state
    always_comb begin : proc_ws_fifo_synch
        if (ws_state inside {L,R}) begin
            {Tx_ren, Rx_wen} = 2'b0;
            case (OP.mode)
                MT, ST: Tx_ren = 1'b1;
                MR, SR: Rx_wen = 1'b1;
            endcase
        end else if (ws_state == IDLE) begin
            {Tx_ren, Rx_wen} = 2'b0;
        end
    end

endmodule

// module ws_tbench;
//     logic clk=0;
//     logic rst_=1;
//     OP_t OP = '{default: 0, frame_size: f32bits, standard: MSB};
//     logic ws;
//     ws_state_t state;

//     ws_gen u1(.clk, .rst_, .Tx_empty(), .Rx_full(), .OP, .ws, .state);

//     ws_tracker u2(.clk, .rst_, .ws, .OP, .state);

//     always forever #1 clk <= ~clk;

//     initial begin
//     @(posedge clk) rst_<=0;
//     @(posedge clk) rst_<=1;
//     repeat(2) @(posedge clk);
//     OP.tran_en<=1;
//     repeat(50) @(posedge clk);
//     @(u1.cnt==5'hff) OP.tran_en<=0;
//     repeat(25) @(posedge clk);
//     OP.tran_en<=1;
//     end
// endmodule