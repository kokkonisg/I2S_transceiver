`include "package.sv"
`include "FIFOs.sv"
`include "Reg_Interface.sv"
`include "freq_divider.sv"

import ctrl_pkg::*;

module I2S_top(
    input pclk, penable, preset, pwrite,
    input [31:0] paddr, pwdata,
    output [31:0] prdata,
    
    inout sclk, mclk, ws, sd); 


function logic [31:0] preprocess;
    input logic [31:0] din;
    input OP_t OP;
    logic [31:0] dout;

    if (OP.frame_size==f16bits)  //16-bit frame and word
        dout = {{16{1'b0}}, din[15:0]};   

    else if (OP.frame_size==f32bits)//32-bit frame
        if (OP.word_size==w16bits) //16-bit word
            case (OP.standard)
                I2S, MSB: dout = {din[15:0], {16{1'b0}}};
                LSB: dout = {{16{1'b0}}, din[15:0]};
            endcase

        else if (OP.word_size==w24bits) //24-bit word
            case (OP.standard)
                I2S, MSB: dout = {din[23:0], {8{1'b0}}};
                LSB: dout = {{8{1'b0}}, din[23:0]};
            endcase
            
        else dout = din;

    preprocess = dout;
endfunction

function logic [31:0] postprocess;
    input logic [31:0] din;
    input OP_t OP;
    logic [31:0] dout;

    if (OP.frame_size==f32bits && OP.standard inside {I2S, MSB})
        case (OP.word_size)
            w32bits: dout = {16'b0, din[31:16]};
            w24bits: dout = {8'b0, din[31:8]};
            default: dout = din;
        endcase
    else dout = din;

    postprocess = dout;
endfunction

OP_t OP;

logic rst, Tx_wen, Tx_ren, Rx_ren, Rx_wen, reg_wen, reg_ren;
logic Tx_full, Tx_empty, Rx_full, Rx_empty;
logic [31:0] Tx_data, Rx_data, controls;
logic occRx, occTx;
logic ws_change;

assign OP = controls;

logic sd_gen, mclk_gen, sclk_gen, ws_gen;
//SR=2'b00, MR=2'b10, ST=2'b01, MT=2'b11
assign sd = (OP.mode inside {MT,ST}) ? sd_gen : 1'bZ;

assign ws = (OP.mode inside {MT,MR}) ? ws_gen : 1'bZ;

assign sclk = (OP.mode inside {MT,MR}) ? sclk_gen : 1'bZ;

assign mclk = OP.mclk_en ? mclk_gen : 1'bZ; //Only outputting mclk so no need for tristate
// ----------**SCLK BIDIRECTIONAL TODO RETHINK?**---------------

Reg_Interface Ureg(.*, .Rx_data(postprocess(Rx_data, OP)));

clk_div Udiv(.sclk(sclk_gen), .pclk, .rst_(preset), .N(6'd3));

ws_gen Uwsg (.clk(sclk), .rst_(preset), .OP, .ws(ws_gen));

ws_state_t ws_state;
ws_tracker Uwtr (.clk(sclk), .rst_(preset), .OP, .ws, .state(ws_state));

TxFIFO Utx(
    .wclk(pclk),
    .rclk(sclk),
    .wr_en(Tx_wen),
    .rd_en(Tx_ren & !OP.stop),
    .rst_(preset),
    .OP,
    .din(preprocess(Tx_data, OP)),
    .dout(sd_gen),
    .full(Tx_full),
    .empty(Tx_empty)
);

RxFIFO Urx(
    .rclk(pclk),
    .wclk(sclk),
    .rd_en(Rx_ren),
    .wr_en(Rx_wen & !OP.stop),
    .rst_(preset),
    .OP,
    .dout(Rx_data),
    .din(sd),
    .full(Rx_full),
    .empty(Rx_empty)
);


always_ff @(negedge pclk) begin: proc_reg_fifo_dataex
	if (!preset) begin
        {Tx_wen, Rx_ren, reg_wen, reg_ren, occTx, occRx} <= 0;
    end else begin
        if (!Tx_full && occTx) begin: wr_TxFIFO
            Tx_wen <= 1'b1;
            occTx <= 1'b0;
        end
        else Tx_wen <= 1'b0;

        if (penable && pwrite && paddr==32'h0 && !occTx) begin: wr_TxReg
            reg_wen <= 1'b1;
            occTx <= 1'b1;
        end
        else reg_wen <= 1'b0;

        if (!Rx_empty && !occRx) begin: rd_RxFIFO
            Rx_ren <= 1'b1;
            occRx <= 1'b1;
        end
        else Rx_ren <= 1'b0;

        if (penable && !pwrite && paddr==32'h8 && occRx) begin: rd_RxReg
            reg_ren <= 1'b1;
            occRx <= 1'b0;
        end
        else reg_ren <= 1'b0;
    end
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