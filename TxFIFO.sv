module TxFIFO(
    input logic wclk, rclk, ren, wen, rst,
	input logic stereo, 
	input logic [1:0] standard, word_size,
    input logic [31:0] dinL, dinR,

    output logic full ,empty,
	output logic dout, ws);
    
	logic [31:0] FIFO [7:0];
	logic [3:0] rCnt_p = 4'b0; //parallel read counter
	logic [4:0] rCnt_s = (word_size==2'b00)? 5'd15 : 5'd31; //serial read counter
    logic [3:0] wCnt = 4'b0; //write counter
    
    assign full = ({~wCnt[3],wCnt[2:0]} == rCnt_p);
    assign empty = (wCnt == rCnt_p);

	//**Writing data**
	always_ff @(posedge wclk) begin
        if (wen && !full) begin
            FIFO[wCnt[2:0]] <= (wCnt[2:0]%2==0)? dinL : dinR;
            wCnt <= wCnt+1;
        end
    end


	//**Reading data**
	always_ff @(negedge rclk) begin      
	    if (ren && !empty) begin
            $display("%0t: rCnt_s:%0d",$time,rCnt_s);
            $display("%0t: rCnt_p:%6d",$time,rCnt_p[2:0]);
			dout <= FIFO[rCnt_p[2:0]][rCnt_s];

			if (stereo) begin
              if (standard == 2'b00 && rCnt_s==0) begin
                ws <= ~(rCnt_p[2:0]%2);
              end
              else if (standard != 2'b00 && rCnt_s==((word_size==2'b00)? 5'd15 : 5'd31))
                ws <= (rCnt_p[2:0]%2);
			end
			
			if (rCnt_s>0) rCnt_s<=rCnt_s-1;
            else if (word_size==2'b00) rCnt_s <= 5'd15;
            else rCnt_s <= 5'd31;

        
			rCnt_p <= (rCnt_s>0) ? rCnt_p : rCnt_p+1;
		end
	end


    always_ff @(posedge wclk)
        if (rst) begin
            ws <= 1'b0;
            foreach (FIFO[i]) FIFO[i]=32'b0;
            rCnt_s <= (word_size==2'b00)? 5'd15 : 5'd31;
            rCnt_p <= 4'd0;
            wCnt <= 4'd0;
        end
endmodule