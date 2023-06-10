module ws_control(
    input logic sclk, rst_, ws, Tx_empty, Rx_full,
    input OP_t OP,
    output logic ws_gen, Tx_ren, Rx_wen, del_Tx_ren, del_Rx_wen
    );

    ws_state_t ws_state, ws_tr_state, ws_gen_state;
    ws_tracker Uwst(
        .clk(sclk),
        .rst_,
        .OP,
        .ws,
        .state(ws_tr_state)
    );

    ws_gen Uwsg (
        .clk(sclk),
        .rst_,
        .OP,
        .ws(ws_gen),
        .state(ws_gen_state),
        .Tx_empty,
        .Rx_full
    );

    //depending on the peripheral's mode, 
    //only one of the above modules needs to run
    assign ws_state = (OP.mode inside {MT, MR}) ? ws_gen_state : ws_tr_state;

    //dellayed enables are used for I2S Phillips standard which requires a 1 clok cycle dellay
    always_ff @(negedge sclk or negedge rst_) begin : proc_del_en
        if (!rst_) begin
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