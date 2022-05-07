`include "RxFIFO.sv"

module tb_RxFIFO;

logic wclk=1;
logic rclk=1;
logic rst,en;
logic ws; 
logic din;
logic [31:0] doutL,doutR;

localparam rCLK_PERIOD = 6;
localparam wCLK_PERIOD = 10;
always #(rCLK_PERIOD/2) rclk = ~rclk;
always #(wCLK_PERIOD/2) wclk = ~wclk;

logic [6*32-1:0] data_in = {$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom()};
int i=1;
logic [3:0] j=0;

RxFIFO U0
(
    .rst (rst),
    .wclk (wclk),
    .rclk (rclk),
    .wen (en),
    .ren (1'b1),
    .stereo (1'b1),
    .standard (2'b00),
    .doutL (doutL),
    .doutR (doutR),
    .din (din),
    .ws (ws),
    .word_size (2'b00)
);

initial begin
    din<=data_in[0];
    $dumpfile("tb_RxFIFO.vcd");
    $dumpvars(0, tb_RxFIFO);
end

always @(negedge wclk) begin
    if (en)begin
    din <= data_in[i];
    if (j==15)  ws<=~ws;        
    i<=i+1;
    j<=j+1;
    end
end

initial begin
    #1 rst<=1'bx;
    ws<=1'bx;
    #(wCLK_PERIOD) rst<=1;
    @(negedge wclk) rst<=0; ws<=0;en<=1;
    foreach (U0.FIFO[i]) $display("FIFO[%0d]: %32b",i,U0.FIFO[i]);

    repeat(2000) begin
        #1;
        if ($time==1465)
            foreach (U0.FIFO[i]) $display("FIFO[%0d]: %32b",i,U0.FIFO[i]);

        if ($time==1999)
            foreach (U0.FIFO[i]) $display("FIFO[%0d]: %32b",i,U0.FIFO[i]);
    end
end
endmodule