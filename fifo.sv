
    module FIFOtrans(wclk, rclk, dataIn, RD, WR, EN, dataOut, Rst, EMPTY, FULL); 

    input logic wclk, rclk, RD, WR, EN, Rst;
    output logic EMPTY, FULL;

    input logic [31:0] dataIn;
    output logic [31:0] dataOut; 

    logic [2:0]  Count = 0; 
    logic [31:0] FIFO [0:7]; 
    logic [2:0]  readCounter[1:0] = {0,0};
    logic writeCounter = 0; 

    assign EMPTY = (Count==0)? 1'b1:1'b0; 
    assign FULL = (Count==8)? 1'b1:1'b0; 

    always_ff @ (posedge rclk) 
        if (EN && RD ==1'b1 && Count!=0) begin 
            dataOut <= FIFO[readCounter[0]]; 
            readCounter[0] <= (readCounter[0]==31) ? 0 : readCounter[0] + 1; 
            readCounter[1] <= (readCounter[0]!=31) ? readCounter[1] : 
                              (readCounter[1]==7)  ? 0 : readCounter[1]+1;
        end  

    always_ff @ (posedge wclk)
        if (EN && WR==1'b1 && Count<8) begin
            FIFO[writeCounter] <= dataIn; 
            writeCounter <= (writeCounter==7) ? 0 : writeCounter + 1; 
        end 

    always begin 
        if (En && Rst) begin 
            readCounter[0] <= 0; 
            readCounter[1] <= 0; 
            writeCounter <= 0; 
        end  

        if (readCounter[1] > writeCounter) 
            Count<=readCounter[1]-writeCounter;  
        else if (writeCounter > readCounter[1]) 
            Count<=writeCounter-readCounter[1]; 
        else;
    end 
endmodule


