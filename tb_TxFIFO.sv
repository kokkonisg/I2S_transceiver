`include "TxFIFO.sv"
`default_nettype none

module tb_TxFIFO;
reg wclk=1;
reg rclk=1;
reg rst;
reg [31:0] din;
reg [31:0] FIFO [9] = {{32{1'b1}},{32{1'b0}},{32{1'b1}},{32{1'b0}},{32{1'b1}},{32{1'b0}},{32{1'b1}},{32{1'b0}},{32{1'b0}}};

wire dout;
wire ws;

int i=0;

assign din = FIFO[i];

TxFIFO U0
(
    .rst (rst),
    .wclk (wclk),
    .rclk (rclk),
    .en (1'b1),
    .stereo (1'b1),
    .standard (2'b00),
    .dinL (din),
    .dinR (din),
    .dout (dout),
    .ws (ws),
    .word_size (2'b11)
);

localparam rCLK_PERIOD = 10;
localparam wCLK_PERIOD = 6;
always #(rCLK_PERIOD/2) rclk = ~rclk;
always #(wCLK_PERIOD/2) wclk = ~wclk;


initial begin
    $dumpfile("tb_TxFIFO.vcd");
    $dumpvars(0, tb_TxFIFO);
end

initial begin
    #1 rst<=1'bx;
    #(wCLK_PERIOD) rst<=1;
    #(wCLK_PERIOD) rst<=0;
    // din=FIFO[0];
    foreach (U0.FIFO[i]) $display("FIFO[%0d]: %32b",i,U0.FIFO[i]);

    repeat(10) begin
        @(posedge wclk);
        // din=FIFO[i];
        if (i<8) i++;
    end

    // repeat(60) @(posedge rclk);
    // rst<=1;

    // repeat(1) @(posedge wclk);
    // rst<=0;

    #900 foreach (U0.FIFO[i]) $display("@%0t: FIFO[%0d]: %32b",$time,i,U0.FIFO[i]);

    //$finish(2);
end

endmodule
`default_nettype wire