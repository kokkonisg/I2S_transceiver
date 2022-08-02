`include "I2S_top.sv"
`default_nettype none

import ctrl_pkg::*;

module tb_I2S_top;
logic pclk, penable, pwrite;
logic preset;
logic [31:0] paddr, pwdata, prdata;
wire sclk, mclk, ws, sd;
OP_t OPp='{default: 0, standard: I2S, mode: MR, frame_size: f16bits};

I2S_top U(.*);

localparam CLK_PERIOD = 12;
always #(CLK_PERIOD/2) pclk=~pclk;

assign sd = 1'b1;
// assign ws = (OP.mode inside {MR, MT}) ? 1'bZ : 1'b0;

// initial begin
//     $dumpfile("tb_I2S_top.vcd");
//     $dumpvars(0, tb_I2S_top);
// end

initial begin
    preset<=1'bx;pclk<=1'b0;
    #(CLK_PERIOD*3) preset<=0;
    #(CLK_PERIOD*3) preset<=1;
    @(posedge pclk) penable<=1'b1;pwrite<=1'b1;paddr<=32'h4;pwdata<=OPp;

    @(posedge pclk) paddr<=32'h0;pwdata<=$urandom;
    repeat (5) @(posedge pclk); OPp.tran_en <= 1'b1;
    @(posedge pclk) paddr<=32'h4;pwdata<=OPp;

    // repeat(200) @(posedge pclk);
    //     foreach (U.Utx.FIFO[i]) $display("TxFIFO[%0d]: %32b",i,U.Utx.FIFO[i]);
    //     foreach (U.Ureg.registers[i]) $display("reg[%0d]: %32b",i,U.Ureg.registers[i]);

    
end

endmodule
`default_nettype wire