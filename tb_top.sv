`include "I2S_top.sv"
`default_nettype none

import ctrl_pkg::*;

module tb_I2S_top;
logic pclk, penable, pwrite;
logic preset;
logic [31:0] paddr, pwdata, prdata;
wire sclk, mclk, ws, sd;

I2S_top U(.*);

localparam CLK_PERIOD = 10;
always #(CLK_PERIOD/2) pclk=~pclk;

logic rst=1'b0;
sample_rate_enum sample_rate = hz44;
word_size_enum word_size = w16bits;
frame_size_enum frame_size = f16bits;
standard_enum standard = I2S;
mode_enum mode = MT;
logic [31:0] contrl;
assign contrl = {1'b1, sample_rate, word_size, frame_size, 1'b0, standard, mode, 1'b0, 1'b0, rst};

assign sd = (!mode[0]) ? 1'b1 : 1'bZ;
assign ws = (mode inside {MR, MT}) ? 1'bZ : 1'b0;

initial begin
    $dumpfile("tb_I2S_top.vcd");
    $dumpvars(0, tb_I2S_top);
end

initial begin
    preset<=1'bx;pclk<=1'b0;
    #(CLK_PERIOD*3) preset<=1;
    #(CLK_PERIOD*3) preset<=0;
    @(posedge pclk) penable<=1'b1;pwrite<=1'b1;paddr<=32'h4;pwdata<=contrl;
    @(posedge pclk) pwdata<= {contrl[31:1], 1'b1};
    @(posedge pclk) pwdata<= {contrl[31:1], 1'b0};
    

    @(posedge pclk) paddr<=32'h0;pwdata<=$urandom;
    repeat (5) @(posedge pclk); penable <= 1'b0;
        foreach (U.Ureg.registers[i]) $display("reg[%0d]: %32b",i,U.Ureg.registers[i]);
    
    
    repeat(200) @(posedge pclk);
        foreach (U.Utx.FIFO[i]) $display("TxFIFO[%0d]: %32b",i,U.Utx.FIFO[i]);
        foreach (U.Ureg.registers[i]) $display("reg[%0d]: %32b",i,U.Ureg.registers[i]);

    
end

endmodule
`default_nettype wire