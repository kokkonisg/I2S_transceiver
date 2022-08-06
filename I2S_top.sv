`include "package.sv"
`include "FIFOs.sv"
`include "reg_interface.sv"
`include "freq_divider.sv"

import ctrl_pkg::*;

module I2S_top(
    input logic pclk, penable, preset, pwrite,
    input logic [31:0] paddr, pwdata,
    output logic [31:0] prdata,
    
    inout sclk, mclk, ws, sd); 


OP_t OP;
ws_state_t ws_gen_state;
logic Tx_wen, Tx_ren, Rx_ren, Rx_wen, reg_wen, reg_ren;
logic Tx_full, Tx_empty, Rx_full, Rx_empty;
logic [31:0] Tx_data, Rx_data, controls;
logic del_Tx_ren, del_Rx_wen; //delayed enables
logic [3:0] flags;

assign flags = {Tx_full, Tx_empty, Rx_full, Rx_empty};
assign OP = controls;

logic sd_gen, mclk_gen, sclk_gen, ws_gen;
assign sd = (OP.mode inside {MT,ST}) ? sd_gen : 1'bZ;

assign ws = (OP.mode inside {MT,MR}) ? ws_gen : 1'bZ;

assign sclk = (OP.mode inside {MT,MR}) ? sclk_gen : 1'bZ;

//Only outputting mclk so no need for tristate
assign mclk = OP.mclk_en ? mclk_gen : 1'bZ; 

reg_interface Ureg(.*, .Rx_data(postprocess(Rx_data, OP)));
reg_control Uregc(.*);

clk_div Udiv(.sclk(sclk_gen), .pclk, .mclk, .rst_(preset), .OP);

ws_gen Uwsg (.clk(sclk), .rst_(preset), .OP, .ws(ws_gen), .state(ws_gen_state), .*);
ws_control Uwsc (.*);

TxFIFO Utx(
    .wclk(pclk),
    .rclk(sclk),
    .wr_en(Tx_wen),
    .rd_en((OP.standard==I2S ? del_Tx_ren : Tx_ren) & !OP.stop),
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
    .wr_en((OP.standard==I2S ? del_Rx_wen : Rx_wen)  & !OP.stop),
    .rst_(preset),
    .OP,
    .dout(Rx_data),
    .din(sd),
    .full(Rx_full),
    .empty(Rx_empty)
);
endmodule

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