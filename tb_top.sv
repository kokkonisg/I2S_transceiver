`include "I2S_top.sv"
`default_nettype none

import ctrl_pkg::*;

module tb_I2S_top;
logic pclk, penable, pwrite;
logic preset;
logic [31:0] paddr, pwdata, prdata;
wire sclk, mclk, ws, sd;
OP_t OPp='{default: 0, standard: MSB, mode: SR, frame_size: f16bits, stereo: 1'b0};
OP_t OPpp = OPp;
I2S_top U(.*);

localparam CLK_PERIOD = 12;
always #(CLK_PERIOD/2) pclk=~pclk;

int i=0;
assign sd = $urandom(i);
clk_div Udiv(.sclk, .pclk, .rst_(preset), .N(6'd3));
ws_gen Usmth(.clk(sclk), .rst_(preset), .OP(OPpp), .ws, .Tx_empty(1'b0), .Rx_full(1'b0));
// assign ws = (OP.mode inside {MR, MT}) ? 1'bZ : 1'b0;

// initial begin
//     $dumpfile("tb_I2S_top.vcd");
//     $dumpvars(0, tb_I2S_top);
// end

always @(posedge sclk) i++;
initial begin
    OPpp.mode = MT;
    preset<=1'bx;pclk<=1'b0;
    #(CLK_PERIOD*3) preset<=0;
    #(CLK_PERIOD*3) preset<=1;
    @(posedge pclk) penable<=1'b1;pwrite<=1'b1;paddr<=32'h0;pwdata<=OPp;

    @(posedge pclk) paddr<=32'h4;pwdata<=$urandom;
    repeat (5) @(posedge pclk); OPpp.tran_en <= 1'b1;
    @(posedge pclk) paddr<=32'h0;pwdata<=OPp;
    @(posedge pclk);
    repeat (66) @(posedge sclk); 
    @(posedge pclk) paddr<=32'h8;pwrite<=1'b0;
    repeat (10) @(posedge sclk); OPpp.tran_en <= 1'b0;
    //pwrite<=1'b1;paddr<=32'h4;pwdata<=$urandom(1);


    // repeat(200) @(posedge pclk);
    //     foreach (U.Utx.FIFO[i]) $display("TxFIFO[%0d]: %32b",i,U.Utx.FIFO[i]);
    //     foreach (U.Ureg.registers[i]) $display("reg[%0d]: %32b",i,U.Ureg.registers[i]);

    
end

endmodule
`default_nettype wire