//`include "C:/Users/G/Documents/University/I2S/I2S_transceiver/package.sv"
`include "C:/Users/G/Documents/University/I2S/I2S_transceiver/FIFOs.sv"
`include "C:/Users/G/Documents/University/I2S/I2S_transceiver/reg_interface.sv"
`include "C:/Users/G/Documents/University/I2S/I2S_transceiver/freq_divider.sv"

import ctrl_pkg::*;

module I2S_top #(parameter ADR_OFFSET = 0)(
    input logic pclk, penable, preset, pwrite,
    input logic [31:0] paddr, pwdata,
    output logic mclk,
    output logic [31:0] prdata,
    
    inout sclk, ws, sd); 


OP_t OP;
FL_t FL;
logic Tx_wen, Tx_ren, Rx_ren, Rx_wen, reg_wen, reg_ren;
logic Tx_full, Tx_empty, Rx_full, Rx_empty;
logic [31:0] Tx_data, Rx_data;
logic [14:0] controls;
logic [9:0] flags;
logic [31:0] addr; 
logic del_Tx_ren, del_Rx_wen; //delayed enables

assign addr = paddr - ADR_OFFSET; 

assign FL = {
    Uwsc.ws_state == IDLE, //Inteface idle / standing by
    (!OP.stereo) ? 1'b0 : 
        (OP.mode inside {MT, ST}) ? Utx.radr%2 : Urx.wadr%2, //Channel being transmitted 
    Tx_full, //full
    Tx_empty, //empty
    Utx.Al_full, //Almost full
    Utx.Al_empty, //Almost empty
    Rx_full, //full
    Rx_empty, //empty
    Urx.Al_full, //Almost full
    Urx.Al_empty //Almost empty
};

assign flags = FL;
assign OP = controls;

//tri-state buffers for inout ports
logic sd_gen, sclk_gen, ws_gen;
assign sd = (OP.mode inside {MT,ST}) ? sd_gen : 1'bZ;

assign ws = (OP.mode inside {MT,MR}) ? ws_gen : 1'bZ;

assign sclk = (OP.mode inside {MT,MR}) ? sclk_gen : 1'bZ;


//module definitions
reg_interface Ureg(
    .pclk,
    .preset,
    .penable,
    .pwrite,
    .addr,
    .pwdata,
    .prdata,
    .reg_wen,
    .reg_ren,
    .Rx_data(postprocess(Rx_data, OP)),
    .Tx_data,
    .controls,
    .flags
);

reg_control Uregc(
    .pclk,
    .penable,
    .preset,
    .pwrite,
    .addr,
    .Rx_empty,
    .Tx_full,
    .Tx_wen,
    .Rx_ren,
    .reg_wen,
    .reg_ren
);

clk_div Udiv(
    .sclk(sclk_gen),
    .pclk,
    .mclk,
    .rst_(preset & OP.rst),
    .OP
);

// ws_gen Uwsg (
//     .clk(sclk),
//     .rst_(preset & OP.rst),
//     .OP,
//     .ws(ws_gen),
//     .state(ws_gen_state),
//     .Tx_empty,
//     .Rx_full
// );

ws_control Uwsc (
    .sclk,
    .rst_(preset & OP.rst),
    .ws,
    .ws_gen,
    .OP,
    .Tx_empty,
    .Rx_full,
    .Tx_ren,
    .Rx_wen,
    .del_Tx_ren,
    .del_Rx_wen
);

TxFIFO Utx(
    .wclk(pclk),
    .rclk(sclk),
    .wr_en(Tx_wen),
    .rd_en(OP.standard==I2S ? del_Tx_ren : Tx_ren),
    .rst_(preset & OP.rst),
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
    .wr_en(OP.standard==I2S ? del_Rx_wen : Rx_wen),
    .rst_(preset & OP.rst),
    .OP,
    .dout(Rx_data),
    .din(sd),
    .full(Rx_full),
    .empty(Rx_empty)
);
endmodule

//a function that transforms the input data from PCM encoder to the desired format 
//(ex. a word encoded in 16bits -> 32bit frame with LSB standard, meaning zero-fill 16 MSBs)
function logic [31:0] preprocess;
    input logic [31:0] din;
    input OP_t OP;
    logic [31:0] dout;

    case (OP.frame_size)
        f16bits: dout = {{16'b0}, din[15:0]};
        f32bits: 
            case (OP.word_size)
                w16bits: case (OP.standard)
                    I2S, MSB: dout = {din[15:0], {16'b0}};
                    LSB: dout = {{16'b0}, din[15:0]};
                    default: dout = din;
                endcase
                w24bits: case (OP.standard)
                    I2S, MSB: dout = {din[23:0], {8'b0}};
                    LSB: dout = {{8'b0}, din[23:0]};
                    default: dout = din;
                endcase
                w32bits: dout = din;
                default: dout = din;
            endcase
    endcase

    preprocess = dout;
endfunction


//the reverse of the above function
//ex. for a 32bit frame with LSB standard containing a 16bit word -> the 16 LSBs are real data
function logic [31:0] postprocess;
    input logic [31:0] din;
    input OP_t OP;
    logic [31:0] dout;

    case (OP.frame_size)
        f16bits: dout = {{16'b0}, din[15:0]};
        f32bits: 
            case (OP.word_size)
                w16bits: case (OP.standard)
                    I2S, MSB: dout = {{16'b0}, din[31:16]};
                    LSB: dout = {{16'b0}, din[15:0]};
                    default: dout = din;
                endcase
                w24bits: case (OP.standard)
                    I2S, MSB: dout = {{8'b0}, din[31:8]};
                    LSB: dout = {{8'b0}, din[23:0]};
                    default: dout = din;
                endcase
                w32bits: dout = din;
                default: dout = din;
            endcase
    endcase

    postprocess = dout;
endfunction