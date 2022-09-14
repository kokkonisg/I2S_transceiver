`include "I2S_top.sv"
`default_nettype none

import ctrl_pkg::*;

module tb_I2S_top;
logic pclk, penable, pwrite;
logic preset, temp_sclk;
logic [31:0] paddr, pwdata, prdata;
wire sclk, mclk, ws, sd;
OP_t OPtx ='{default: 0, standard: MSB, mode: MT, word_size: w16bits, frame_size: f32bits, stereo: 1'b1};
OP_t OPrx ='{default: 0, standard: MSB, mode: SR, word_size: w16bits, frame_size: f32bits, stereo: 1'b1};
OP_t OPmstr = '{default: 0, standard: MSB, mode: MT, word_size: w16bits, frame_size: f32bits, stereo: 1'b1};

I2S_top #(.ADR_OFFSET(0)) Utr(.*, .prdata());
I2S_top #(.ADR_OFFSET(32'h10)) Urc(.*);

assign sclk = temp_sclk;
localparam CLK_PERIOD = 6;
always #(CLK_PERIOD/2) pclk=~pclk;


// assign sd = $urandom(i);
//clk_div Udiv(.sclk, .pclk, .rst_(preset), .mclk, .OP(OPmstr));
//ws_gen Usmth(.clk(sclk), .rst_(preset), .OP(OPmstr), .ws, .Tx_empty(1'b0), .Rx_full(1'b0));

// logic [31:0] datain [12] = '{dafault: $urandom};
// logic [31:0] dataout [12];
initial begin
    temp_sclk <= 1'b0;
    preset<=1'bx;pclk<=1'b0;
    #(CLK_PERIOD*3) preset<=0;
    #(CLK_PERIOD*3) preset<=1;
    @(posedge pclk) penable<=1'b1;pwrite<=1'b1;paddr<=32'h0;pwdata<=OPtx;
    @(posedge pclk);
    @(posedge pclk) paddr<=32'h4;pwdata<=$urandom;temp_sclk <= 1'bZ;
    repeat (20) @(posedge pclk) pwdata<=$urandom($stime); 
    paddr<=32'h10; pwdata<=OPrx; OPtx.tran_en <= 1'b1;
    @(posedge pclk);
    paddr<=32'h0;pwdata<=OPtx;
    @(posedge pclk); 
    repeat (38) @(posedge sclk) paddr<=32'h18;pwrite<=1'b0;
    repeat (166) @(posedge sclk); 
    // @(posedge pclk) pwrite<=1'b1;paddr<=32'h4;pwdata<=$urandom($stime);
    // @(posedge pclk) pwrite<=1'b1;paddr<=32'h4;pwdata<=$urandom($stime);
    // @(posedge pclk) pwrite<=1'b1;paddr<=32'h4;pwdata<=$urandom($stime);
    // repeat (38) @(posedge sclk) paddr<=32'h18;pwrite<=1'b0;
    
    //pwrite<=1'b1;paddr<=32'h4;pwdata<=$urandom(1);

    
    
end

endmodule
`default_nettype wire