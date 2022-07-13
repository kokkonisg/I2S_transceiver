`include "package.sv"
`include "FIFOs.sv"
`include "Reg_Interface.sv"
`include "freq_divider.sv"

import ctrl_pkg::*;

module I2S_top(
    input pclk, penable, preset, pwrite,
    input [31:0] paddr, pwdata,
    output [31:0] prdata,
    
    output sclk, mclk, ws, sd); 


function logic [31:0] preprocess;
    input logic [31:0] din;
    input logic [1:0] standard, word_size;
    input logic frame_size;
    logic [31:0] dout;

    if (frame_size==1'b0)  //16-bit frame and word
        if (standard inside {2'b00, 2'b01, 2'b10})
            dout = {{16{1'b0}}, din[15:0]};   
        else dout = 32'bx;

    else if (frame_size==1'b1)//32-bit frame
        if (word_size==2'b00) //16-bit word
            case (standard)
                2'b00, 2'b10: dout = {din[15:0], {16{1'b0}}};
                2'b01: dout = {{16{1'b0}}, din[15:0]};
                default: dout = 32'bx; //NOT ALLOWED
            endcase

        else if (word_size==2'b01) //24-bit word
            case (standard)
                2'b00, 2'b10: dout = {din[23:0], {8{1'b0}}};
                2'b01: dout = {{8{1'b0}}, din[23:0]};
                default: dout = 32'bx; //NOT ALLOWED
            endcase
            
        else if (word_size==2'b10) //32-bit word
            case (standard)
                2'b00, 2'b01, 2'b10: dout = din;
                default: dout = 32'bx; //NOT ALLOWED
            endcase

        else
            dout = 32'bx;//NOT ALLOWED

    preprocess = dout;
endfunction

function logic [31:0] postprocess;
    input logic [31:0] din;
    input logic [1:0] standard, word_size;
    input logic frame_size;
    logic [31:0] dout;

    if (frame_size==1'b1 && word_size==2'b00 && standard inside {2'b00, 2'b10})
        dout = {16'b0,din[31:16]};
    else dout = din;

    postprocess = dout;
endfunction

sample_rate_enum sample_rate;
word_size_enum word_size;
frame_size_enum frame_size;
standard_enum standard;
mode_enum mode;
logic stereo, mclk_en, mute, stop;

logic rst, Tx_wen, Tx_ren, Rx_ren, Rx_wen, reg_wen, reg_ren;
logic Tx_full, Tx_empty, Rx_full, Rx_empty;
logic [31:0] Tx_data, Rx_data, controls;
logic occRx, occTx;

assign rst = controls[0];
assign stop = controls[1];
assign mute = controls[2];
assign mode = ctrl_pkg::mode_enum'(controls[4:3]);
assign standard = ctrl_pkg::standard_enum'(controls[6:5]);
assign mclk_en = controls[7];
assign frame_size = ctrl_pkg::frame_size_enum'(controls[8]);
assign word_size = ctrl_pkg::word_size_enum'(controls[10:9]);
assign sample_rate = ctrl_pkg::sample_rate_enum'(controls[11]);
assign stereo = controls[12];

logic sd_in, mclk_in, sclk_in;
//SR=2'b00, MR=2'b10, ST=2'b01, MT=2'b11
assign sd = mode[0] ? sd_in : 1'bZ;

assign sclk = mode[1] ? sclk_in : 1'bZ;

assign mclk = mclk_en ? mclk_in : 1'bZ;
// ----------**SCLK BIDIRECTIONAL TODO RETHINK?**---------------

Reg_Interface Ureg(.*, .Rx_data(postprocess(Rx_data, standard, word_size, frame_size)));

clk_div Udiv(.sclk(sclk_in), .pclk);

TxFIFO Utx(
    .wclk(pclk),
    .rclk(sclk),
    .wen(Tx_wen),
    .rst(rst),
    .stereo,
    .frame_size,
    .standard,
    .mode,
    .din(preprocess(Tx_data, standard, word_size, frame_size)),
    .dout(sd_in),
    .ws,
    .full(Tx_full),
    .empty(Tx_empty)
);

RxFIFO Urx(
    .rclk(pclk),
    .wclk(sclk),
    .ren(Rx_ren),
    .rst(rst),
    .din(sd),
    .ws,
    .stereo,
    .frame_size,
    .standard,
    .mode,
    .dout(Rx_data),
    .full(Rx_full),
    .empty(Rx_empty)
);


always_ff @(negedge pclk) begin
	if (preset) begin
        Tx_wen<=1'b0;
        Rx_ren<=1'b0;
        reg_wen<=1'b0;
        reg_ren<=1'b0;
        occRx<=1'b0;
        occTx<=1'b0;
    end
    
    if (!Tx_full && occTx) begin
        Tx_wen <= 1'b1;
        occTx <= 1'b0;
    end
    else Tx_wen <= 1'b0;

    if (penable && pwrite && paddr==32'h0 && !occTx) begin
        reg_wen <= 1'b1;
        occTx <= 1'b1;
    end
    else reg_wen <= 1'b0;

    if (!Rx_empty && !occRx) begin
        Rx_ren <= 1'b1;
        occRx <= 1'b1;
    end
    else Rx_ren <= 1'b0;

    if (penable && !pwrite && paddr==32'h8 && occRx) begin
        reg_ren <= 1'b1;
        occRx <= 1'b0;
    end
    else reg_ren <= 1'b0;
end

endmodule