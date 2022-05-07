module RxFIFO(
    input logic wclk, rclk, wen, ren, rst,
	input logic din, ws,
	input logic stereo, 
	input logic [1:0] standard, word_size,
    
    output logic full ,empty,
    output logic [31:0] doutL, doutR);

    
	logic [31:0] FIFO [7:0];
	logic [3:0] wCnt_p = 4'b0; //parallel write counter
	logic [4:0] wCnt_s = (word_size==2'b00)? 5'd15 : 5'd31; //serial write counter
    logic [3:0] rCnt = 4'b0; //read counter
    
    assign full = ({~wCnt_p[3],wCnt_p[2:0]} == rCnt);
    assign empty = (wCnt_p == rCnt);

	//**Reading data**
	always_ff @(posedge wclk) begin
        if (ren && !empty) begin
            if (rCnt[2:0]%2 == 1'b0) doutL <= FIFO[rCnt[2:0]];
            else if (rCnt[2:0]%2 == 1'b1) doutR <= FIFO[rCnt[2:0]];
            rCnt <= rCnt+1;
        end
    end


	//**Writing data**
	always_ff @(posedge wclk) begin
        if (wen && !full) 
            if (stereo)
                if (~(ws ^ wCnt_p[2:0]%2))
                    FIFO[wCnt_p[2:0]][wCnt_s] <= din;  
                else if (standard==2'b00 && wCnt_s==0)
                    FIFO[wCnt_p[2:0]][wCnt_s] <= din;
                else begin
                    $display("--UNEXPECTED--");
                    //FIFO[wCnt_p[2:0]+1][wCnt_s] <= din;
                end
            else if (~ws)
                FIFO[wCnt_p[2:0]][wCnt_s] <= din;

            if (wCnt_s>0) wCnt_s<=wCnt_s-1;
            else if (word_size==2'b00) wCnt_s <= 5'd15;
            else wCnt_s <= 5'd31;

            wCnt_p <= (wCnt_s>0) ? wCnt_p : wCnt_p+1;
		end

    always_ff @(rst)
        if (rst) begin
            foreach (FIFO[i]) FIFO[i]=32'b0;
            wCnt_s <= (word_size==2'b00)? 5'd15 : 5'd31;
            wCnt_p <= 4'd0;
            rCnt <= 4'd0;
        end
endmodule