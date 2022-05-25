import ctrl_pkg::*;

module TxFIFO(
    input logic wclk, rclk, wen, rst, 
	input logic stereo, frame_size,
	input logic [1:0] standard, mode, 
    input logic [31:0] din,

	output logic dout, full, empty,
    inout ws);
    
    
	logic [31:0] FIFO [7:0];
	logic [3:0] rCnt_p = 4'b0; //parallel read counter
	logic [4:0] rCnt_s = (frame_size==1'b0)? 5'd15 : 5'd31; //serial read counter
    logic [3:0] wCnt = 4'b0; //write counter
    logic ws_temp, ren;

    assign full = ({!wCnt[3],wCnt[2:0]} == rCnt_p);
    assign empty = (wCnt == rCnt_p);
    assign ws = (mode == MT) ? ws_temp : 1'bZ;

	//**Writing data to FIFO**
	always_ff @(posedge wclk) begin: input_data
        if (wen && !full) begin
            FIFO[wCnt[2:0]] <= din;
            wCnt <= wCnt+1;
        end
    end

    always_latch begin: output_enable
        if (rst) 
            ren = 1'b0;
        else if (!rst)
            unique case (mode)
                MT: ren = !empty ? 1'b1 : 1'b0;
                ST: ren = (!empty && !ws) ? 1'b1 : 
                            (empty) ? 1'b0 : ren;
                default: ren = 1'b0;
            endcase
    end

    always_ff @(negedge rclk) begin: output_data      
        if (ren) begin
            if (stereo)
                // if (!(ws ^ rCnt_p[2:0]%2))
                //     dout <= FIFO[rCnt_p[2:0]][rCnt_s];  
                // else if (standard==2'b00 && rCnt_s==0)
                //     dout <= FIFO[rCnt_p[2:0]][rCnt_s];
                // else 
                //     $display("--UNEXPECTED--");
                dout <= FIFO[rCnt_p[2:0]][rCnt_s];
            else 
                dout <= FIFO[rCnt_p[2:0]][rCnt_s];
        

            if (rCnt_s>0) rCnt_s<=rCnt_s-1;
            else if (frame_size==1'b0) rCnt_s <= 5'd15;
            else if (frame_size==1'b1) rCnt_s <= 5'd31;
            rCnt_p <= (rCnt_s>0) ? rCnt_p : rCnt_p+1;
        end
        else dout <= 1'bx;
    end

    always_ff @(negedge rclk) begin: ws_generator
        if (mode == MT)
            if (ren)
                if (stereo)
                    // if (standard == I2S && rCnt_s==0)
                    //     ws_temp <= !(rCnt_p[2:0]%2);              
                    // else
                    //     ws_temp <= (rCnt_p[2:0]%2);
                    ws_temp <= (rCnt_p[2:0]%2);
                else  
                    ws_temp <= 1'b0;
            else 
                ws_temp <= 1'bx;
    end

    always_ff @(posedge wclk) begin: reset_behavior
        if (rst) begin
            foreach (FIFO[i]) FIFO[i]=32'b0;
            rCnt_s <= (frame_size==1'b0)? 5'd15 : 5'd31;
            rCnt_p <= 4'd0;
            wCnt <= 4'd0;
        end
    end

	// //**Reading data from FIFO**
	// always_ff @(negedge rclk) begin      
	//  // if (ws || !ws)  
    //     if (!empty) begin
	// 		//dout <= FIFO[rCnt_p[2:0]][rCnt_s]; 
    //         //The bellow is pretty much this ^ with extra checking

    //         if (ws || !ws) 
    //             if (stereo)
    //                 if (!(ws ^ rCnt_p[2:0]%2))
    //                     dout <= FIFO[rCnt_p[2:0]][rCnt_s];  
    //                 else if (standard==2'b00 && rCnt_s==0)
    //                     dout <= FIFO[rCnt_p[2:0]][rCnt_s];
    //                 else 
    //                     $display("--UNEXPECTED--");
    //             else 
    //                 dout <= FIFO[rCnt_p[2:0]][rCnt_s];    
            
	// 		if (mode[1]==1'b1)  //IF MASTER
    //             if (stereo)
    //                 if (standard == 2'b00 && rCnt_s==0)
    //                     ws_temp <= !(rCnt_p[2:0]%2);              
    //                 else
    //                     ws_temp <= (rCnt_p[2:0]%2);
    //             else  
    //                 ws_temp <= 1'b0;
			
			
	// 		if (rCnt_s>0) rCnt_s<=rCnt_s-1;
    //         else if (frame_size==1'b0) rCnt_s <= 5'd15;
    //         else if (frame_size==1'b1) rCnt_s <= 5'd31;

        
	// 		rCnt_p <= (rCnt_s>0) ? rCnt_p : rCnt_p+1;
	// 	end
    //     else if (empty) begin
    //         dout <= 1'bx;
    //         ws_temp <= 1'bx;
    //     end
	// end


endmodule