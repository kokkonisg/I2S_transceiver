
import ctrl_pkg::*;

module RxFIFO(
    input logic rclk, ren, rst,
	input logic wclk, din,
    input logic stereo, frame_size,
	input logic [1:0] standard, mode, 
    
    output logic [31:0] dout,
    output logic full, empty,
    inout ws);

    // logic full, empty;
	logic [31:0] FIFO [7:0];
	logic [3:0] wCnt_p = 4'b0; //parallel write counter
	logic [4:0] wCnt_s = (frame_size==1'b0)? 5'd15 : 5'd31; //serial write counter
    logic [3:0] rCnt = 4'b0; //read counter
    logic ws_temp, wen;

    assign full = ({!wCnt_p[3],wCnt_p[2:0]} == rCnt);
    assign empty = (wCnt_p == rCnt);
    assign ws = (mode[1]) ? ws_temp : 1'bZ;

	//**Reading data from FIFO**
	always_ff @(posedge rclk) begin
		if (rst) rCnt <= 4'b0;
		
        if (ren && !empty) begin
            dout <= FIFO[rCnt[2:0]];
            rCnt <= rCnt+1;          
        end
    end

    always_latch begin: output_enable
        if (rst) 
            wen = 1'b0;
        else
            unique case (mode)
                MR: wen = !full ? 1'b1 : 1'b0;
                SR: wen = (!full && !ws) ? 1'b1 : 
                            (full) ? 1'b0 : wen;
                default: wen = 1'b0;
            endcase
    end

    always_ff @(posedge wclk) begin
    	if (rst) begin
            foreach (FIFO[i]) FIFO[i]<=32'b0;
            wCnt_s <= (frame_size==1'b0)? 5'd15 : 5'd31;
            wCnt_p <= 4'd0;
        end
        
        if (wen) begin
            if (stereo)
                if (!(ws ^ wCnt_p[2:0]%2))
                    FIFO[wCnt_p[2:0]][wCnt_s] <= din;  
                else if (standard==2'b00 && wCnt_s==0)
                    FIFO[wCnt_p[2:0]][wCnt_s] <= din;
                else 
                    $display("--UNEXPECTED--");
            else
                FIFO[wCnt_p[2:0]][wCnt_s] <= din;


            if (wCnt_s>0) wCnt_s<=wCnt_s-1;
            else if (frame_size==1'b0) wCnt_s <= 5'd15;
            else if (frame_size==1'b1) wCnt_s <= 5'd31;
            wCnt_p <= (wCnt_s>0) ? wCnt_p : wCnt_p+1;
        end
    end

    always_ff @(negedge wclk) begin: ws_generator
        if (mode == MR)
            if (wen)
                if (stereo)
                    if (standard == I2S && wCnt_s==0)
                        ws_temp <= !(wCnt_p[2:0]%2);              
                    else
                        ws_temp <= (wCnt_p[2:0]%2);
                else  
                    ws_temp <= 1'b0;
            else 
                ws_temp <= 1'bx;
    end

        

	// //**Writing data to FIFO**
	// always_ff @(posedge wclk) begin
    //   if (ws || !ws)  
    //     if (wen && !full) begin
    //         //FIFO[wCnt_p[2:0]][wCnt_s] <= din;
    //         //The bellow is pretty much this ^ with extra checking

    //         if (stereo) 
    //             if (!(ws ^ wCnt_p[2:0]%2))
    //                 FIFO[wCnt_p[2:0]][wCnt_s] <= din;  
    //             else if (standard==2'b00 && wCnt_s==0)
    //                 FIFO[wCnt_p[2:0]][wCnt_s] <= din;
    //             else 
    //                 $display("--UNEXPECTED--");
    //         else   
    //             FIFO[wCnt_p[2:0]][wCnt_s] <= din;

    //         FIFO[wCnt_p[2:0]][wCnt_s] <= din;

    //         if (mode[1]==1'b1)  //IF MASTER
    //             if (stereo)
    //                 if (standard == 2'b00 && wCnt_s==0)
    //                     ws_temp <= !(wCnt_p[2:0]%2);              
    //                 else
    //                     ws_temp <= (wCnt_p[2:0]%2);
    //             else  
    //                 ws_temp <= 1'b0;

    //         if (wCnt_s>0) wCnt_s<=wCnt_s-1;
    //         else if (frame_size==1'b0) wCnt_s <= 5'd15;
    //         else wCnt_s <= 5'd31;

    //         wCnt_p <= (wCnt_s>0) ? wCnt_p : wCnt_p+1;
    //     end
    //     else if (full) 
    //         ws_temp <= 1'bx;
        
    // end

    
endmodule