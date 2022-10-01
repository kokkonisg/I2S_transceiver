`include "I2S_top.sv"
`default_nettype none

import ctrl_pkg::*;

module tb_I2S_top;
logic pclk, penable, pwrite;
logic preset, temp_sclk;
logic [31:0] paddr, pwdata, prdata;
wire sclk, mclk, ws, sd;
OP_t OPtx ='{default: 0, standard: MSB, mode: MT, word_size: w32bits, frame_size: f32bits, stereo: 1'b1};
OP_t OPrx ='{default: 0, standard: MSB, mode: SR, word_size: w32bits, frame_size: f32bits, stereo: 1'b1};
OP_t OPmstr = '{default: 0, standard: MSB, mode: MT, word_size: w32bits, frame_size: f32bits, stereo: 1'b1};


//Two of the same modules used, one is transmitting data while the other recieves it
I2S_top #(.ADR_OFFSET(0)) Utr(.*, .prdata());
I2S_top #(.ADR_OFFSET(32'h10)) Urc(.*);

assign sclk = temp_sclk; //keeps sclk from being undefined at start
localparam CLK_PERIOD = 6;
always #(CLK_PERIOD/2) pclk=~pclk;


//------------------------------------------------------------------
/*The following impliments a way to automatically check wether 
the data are correctly transmitted through the BUS without any losses.
Two queues are used, the INPUT_DATA one is for data to-be transmitted and
the OUTPUT_DATA one for the data recieved. 

A messege is printed in the Transcript/Terminal where the current recieved
data is displayed as well as a Pass or Fail statement, if the two data slices 
(of input and output) are matching or not */

logic [31:0] INPUT_DATA [$]; //actually could be a static array
logic [31:0] OUTPUT_DATA [$];
initial begin
    for (int i=0;i<256;i++) begin
        if (OPtx.word_size==w16bits) begin
            INPUT_DATA.push_front($urandom(i)>>16);
        end else if (OPtx.word_size==w24bits) begin
            INPUT_DATA.push_front($urandom(i)>>8);
        end else begin
            INPUT_DATA.push_front($urandom(i));
        end
    end
    $displayh("initial IN: %p", INPUT_DATA[$-10:$]);
    $displayh("initial OUT: %p", OUTPUT_DATA);
end

int i=255;
always @(negedge pclk) begin    
    if (!Utr.Uregc.occTx && penable && pwrite && paddr==32'h4) begin
        pwdata<=INPUT_DATA[i];
        i<=i-1;
    end

    if ($past(Urc.Uregc.reg_ren && paddr==32'h18)) begin
        OUTPUT_DATA.push_front(prdata);
    end
end

//just a help function to return the pass or fail
function string check_data (logic [31:0] q1 [$],logic [31:0] q2 [$]);
    automatic int size = q1.size() < q2.size() ? q1.size() : q2.size();
    automatic logic check = 1'b1;
    for (int i=0; i<size; i++) begin
        check = check & (q1[$-i]==q2[$-i]);
        //$display("IN:%h OUT:%h -- %b",q1[$-i],q2[$-i],q1[$-i]==q2[$-i]); //BUG CHECK
    end
    return (check) ? "PASS" : "FAIL";
endfunction

always @(posedge pclk) begin
    if (OUTPUT_DATA.size() != $past(OUTPUT_DATA.size())) begin
        $displayh("@%0t -- OUT: %p -- %b", $stime, OUTPUT_DATA[0:9], check_data(INPUT_DATA,OUTPUT_DATA));
    end
end
//-------------------------------------------------------------------------


//First the control bits are defined using OP
//Then some data is loaded to-be transmitted
//the transaction is enabled
//some data is being recieved and read
//then a loop occures where data is inputed and outputed so the FIFOs dont empty/fill
//in the end the transmission is stopped
initial begin
    temp_sclk <= 1'b0;
    preset<=1'bx;pclk<=1'b0;
    #(CLK_PERIOD*3) preset<=0;
    #(CLK_PERIOD*3) preset<=1;
    @(posedge pclk) penable<=1'b1;pwrite<=1'b1;paddr<=32'h0;pwdata<=OPtx;
    @(posedge pclk);
    @(posedge pclk) paddr<=32'h4;temp_sclk <= 1'bZ;
    repeat (5) @(posedge pclk);
    repeat (15) @(posedge pclk); 
    paddr<=32'h10; pwdata<=OPrx; OPtx.tran_en <= 1'b1;
    @(posedge pclk);
    paddr<=32'h0;pwdata<=OPtx;
    @(posedge pclk); 
    repeat (38) @(posedge sclk) paddr<=32'h18;pwrite<=1'b0;
    repeat (30) @(posedge sclk);
    repeat (10) begin
        @(posedge pclk) paddr<=32'h4;pwrite<=1'b1;
        repeat (20) @(posedge pclk);
        @(posedge pclk) paddr<=32'h18;pwrite<=1'b0;
        repeat (150) @(posedge sclk);
    end    
    $display("%0t NO MORE INPUT IN TxFIFO ENDING TRANSMISSION",$stime);
    OPtx.tran_en<=1'b0;
    @(posedge pclk)
      pwrite<=1'b1;paddr<=32'h0;pwdata<=OPtx;
    @(posedge pclk) paddr<=32'h18;pwrite<=1'b0;
    // @(posedge pclk) pwrite<=1'b1;paddr<=32'h4;pwdata<=$urandom($stime);
    // @(posedge pclk) pwrite<=1'b1;paddr<=32'h4;pwdata<=$urandom($stime);
    // @(posedge pclk) pwrite<=1'b1;paddr<=32'h4;pwdata<=$urandom($stime);
    // repeat (38) @(posedge sclk) paddr<=32'h18;pwrite<=1'b0;
    
    //pwrite<=1'b1;paddr<=32'h4;pwdata<=$urandom(1);

    
    
end

endmodule
`default_nettype wire