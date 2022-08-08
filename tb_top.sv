`include "I2S_top.sv"
`default_nettype none

import ctrl_pkg::*;

module tb_I2S_top;
logic pclk, penable, pwrite;
logic preset, temp_sclk;
logic [31:0] paddr, pwdata, prdata;
wire sclk, mclk, ws, sd;
OP_t OPtx ='{default: 0, standard: MSB, mode: MT, frame_size: f16bits, stereo: 1'b1};
OP_t OPrx ='{default: 0, standard: MSB, mode: SR, frame_size: f16bits, stereo: 1'b1};

I2S_top #(.OFFSET(0)) Utr(.*, .prdata());
I2S_top #(.OFFSET(32'h10)) Urc(.*);

assign sclk = temp_sclk;
localparam CLK_PERIOD = 6;
always #(CLK_PERIOD/2) pclk=~pclk;

int i=0;

// assign sd = $urandom(i);
// clk_div Udiv(.sclk, .pclk, .rst_(preset), .mclk, .OP(OPpp));
// ws_gen Usmth(.clk(sclk), .rst_(preset), .OP(OPpp), .ws, .Tx_empty(1'b0), .Rx_full(1'b0));

logic [31:0] datain;
always @(negedge pclk) datain <= $urandom(i++);
initial begin
    temp_sclk <= 1'b0;
    preset<=1'bx;pclk<=1'b0;
    #(CLK_PERIOD*3) preset<=0;
    #(CLK_PERIOD*3) preset<=1;
    @(posedge pclk) penable<=1'b1;pwrite<=1'b1;paddr<=32'h0;pwdata<=OPtx;

    @(posedge pclk) paddr<=32'h4;pwdata<=datain;temp_sclk <= 1'bZ;
    repeat (20) @(posedge pclk) pwdata<=datain; paddr<=32'h0+32'h10;pwdata<=OPrx;
    OPtx.tran_en <= 1'b1;
    repeat (20) @(posedge pclk);
    paddr<=32'h0;pwdata<=OPtx;
    @(posedge pclk); paddr<=32'h8+32'h10;pwrite<=1'b0;
    repeat (166) @(posedge sclk); 
    OPtx.tran_en <= 1'b0;
    repeat (10) @(posedge sclk); 
    paddr<=32'h0;pwdata<=OPtx;
    //pwrite<=1'b1;paddr<=32'h4;pwdata<=$urandom(1);


    // repeat(200) @(posedge pclk);
    //     foreach (U.Utx.FIFO[i]) $display("TxFIFO[%0d]: %32b",i,U.Utx.FIFO[i]);
    //     foreach (U.Ureg.registers[i]) $display("reg[%0d]: %32b",i,U.Ureg.registers[i]);

    
end

endmodule
`default_nettype wire