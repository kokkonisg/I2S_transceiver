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