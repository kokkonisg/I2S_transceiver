`include "package.sv"

import ctrl_pkg::*;

//Heavily based on the design shown on Cliff Cummings' paper
//"Simulation and Synthesis Techniques for Asynchronous FIFO Design", 2005

module TxFIFO #(WIDTH = 32, ADDR = 3) (
    input logic wclk, rclk, rst_, wr_en, rd_en,
    logic [WIDTH-1:0] din,
    OP_t OP,
    output logic dout, full, empty);

    logic [WIDTH-1:0] FIFO [(1<<ADDR)-1:0];
    logic [ADDR-1:0] wadr, radr;
    logic Al_full, Al_empty;
    int sptr;
    logic sdone;
    let maxp = (OP.frame_size==f16bits) ? 15 : 31;
    assign sdone = (sptr == 0);

    //basic FIFO mem logic for parallel input and serial output.
    always_ff @(posedge wclk) begin : proc_write
        if (wr_en && !full) begin
            FIFO[wadr] <= din;
        end
    end

    assign dout = (OP.mute /*|| OP.stop*/) ? 1'b0 : FIFO[radr][sptr];

    always_ff @(negedge rclk, negedge rst_) begin : proc_read
        if (!rd_en) begin
            sptr <= maxp;
        end else if (rd_en /*&& !OP.stop*/) begin
            sptr <= (sptr>0) ? sptr-1 : maxp;
        end
    end

    //-----------Pointer Synchronizers-----------
    logic [ADDR:0] rbin,  wbin, rbinnext, wbinnext, rgray, wgray, rgraynext, wgraynext;
    logic [ADDR:0] r2wsynch1, r2wsynch2; 
    logic [ADDR:0] w2rsynch1, w2rsynch2;
    logic [ADDR:0] r2wsynch2_bin, w2rsynch2_bin;

    always_ff @(posedge wclk, negedge rst_) begin
        if (!rst_) begin
            {r2wsynch1, r2wsynch2} <= 0;
        end else begin
            {r2wsynch2, r2wsynch1} <= {r2wsynch1, rgray};
        end
    end

    always_ff @(posedge rclk, negedge rst_) begin
        if (!rst_) begin
            {w2rsynch1, w2rsynch2} <= 0;
        end else begin
            {w2rsynch2, w2rsynch1} <= {w2rsynch1, wgray};
        end    
    end

    //------------Empty logic-------------
    always_ff @(posedge rclk, negedge rst_) begin
        if (!rst_) begin
            {rbin, rgray} <= 0;
        end else begin
            {rbin, rgray} <= {rbinnext, rgraynext};
        end    
    end

    assign radr = rbin[ADDR-1:0];
    assign rbinnext = rbin + (rd_en & sdone & !empty);
    assign rgraynext = (rbinnext>>1) ^ rbinnext;

    assign empty_val = (rgraynext == w2rsynch2);
    always_ff @(posedge rclk, negedge rst_) begin
        if (!rst_) begin 
            empty <= 1'b1;
        end else begin 
            empty <= empty_val; 
        end
    end 
    
    //------------Almost Empty logic-------------
    gray2bin Ug0(.binary_out(w2rsynch2_bin), .gray_in(w2rsynch2));
    assign Al_empty_val = (int'(3'(rbin[ADDR-1:0]+3'd4)) - int'(w2rsynch2_bin[ADDR-1:0]) < 4) && (int'(3'(rbin[ADDR-1:0]+3'd4)) - int'(w2rsynch2_bin[ADDR-1:0]) > 0);
    always_ff @(posedge rclk, negedge rst_) begin
        if (!rst_) begin 
            Al_empty <= 1'b1;
        end else begin 
            Al_empty <= Al_empty_val | empty_val; 
        end
    end 

    //------------Full logic-------------
    always_ff @(posedge wclk, negedge rst_) begin
        if (!rst_) begin 
            {wbin, wgray} <= 0;
        end else begin
            {wbin, wgray} <= {wbinnext, wgraynext};
        end
    end

    assign wadr = wbin[ADDR-1:0];
    assign wbinnext = wbin + (wr_en & !full);
    assign wgraynext = (wbinnext>>1) ^ wbinnext;

    assign full_val = (wgraynext == {~r2wsynch2[ADDR:ADDR-1], r2wsynch2[ADDR-2:0]});
    always_ff @(posedge wclk, negedge rst_) begin
        if (!rst_) begin 
            full <= 1'b0;
        end else begin
            full <= full_val; 
        end
    end 

    //------------Almost Full logic-------------
    gray2bin Ug1(.binary_out(r2wsynch2_bin), .gray_in(r2wsynch2));
    assign Al_full_val = (int'(3'(wbin[ADDR-1:0]+3'd4)) - int'(r2wsynch2_bin[ADDR-1:0]) < 4) && (int'(3'(wbin[ADDR-1:0]+3'd4)) - int'(r2wsynch2_bin[ADDR-1:0]) > 0);
    always_ff @(posedge wclk, negedge rst_) begin
        if (!rst_) begin 
            Al_full <= 1'b0;
        end else begin 
            Al_full <= Al_full_val | full_val; 
        end
    end 

endmodule


module RxFIFO #(WIDTH = 32, ADDR = 3) (
    input logic wclk, rclk, rst_, wr_en, rd_en,
    logic din,
    OP_t OP,
    output logic [WIDTH-1:0] dout, logic full, empty);

    logic [WIDTH-1:0] FIFO [(1<<ADDR)-1:0];
    logic [ADDR-1:0] wadr, radr;
    logic Al_full, Al_empty;
    int sptr;
    logic sdone;
    let maxp = (OP.frame_size==f16bits) ? 15 : 31;
    assign sdone = (sptr == 0);

    //basic FIFO mem logic for serial input and parallel output
    always_ff @(posedge wclk) begin : proc_write
        if (!wr_en) begin
            sptr <= maxp;
        end else if (wr_en && !full /*&& !OP.stop*/) begin
            FIFO[wadr][sptr] <= din;
            sptr <= (sptr>0) ? sptr-1 : maxp;
        end
    end

    always_ff @(posedge rclk) begin : proc_read
        if (rd_en && !empty) begin
            dout <= FIFO[radr];
        end
    end

    //-----------Pointer Synchronizers-----------
    logic [ADDR:0] rbin,  wbin, rbinnext, wbinnext, rgray, wgray, rgraynext, wgraynext;
    logic [ADDR:0] r2wsynch1, r2wsynch2;
    logic [ADDR:0] w2rsynch1, w2rsynch2;
    logic [ADDR:0] r2wsynch2_bin, w2rsynch2_bin;
    
    always_ff @(posedge wclk, negedge rst_) begin
        if (!rst_) begin 
            {r2wsynch1, r2wsynch2} <= 0;
        end else begin
            {r2wsynch2, r2wsynch1} <= {r2wsynch1, rgray};
        end
    end

    always_ff @(posedge rclk, negedge rst_) begin
        if (!rst_) begin 
            {w2rsynch1, w2rsynch2} <= 0;
        end else begin
            {w2rsynch2, w2rsynch1} <= {w2rsynch1, wgray};
        end
    end

    //------------Empty logic-------------
    always_ff @(posedge rclk, negedge rst_) begin
        if (!rst_) begin 
            {rbin, rgray} <= 0;
        end else begin
            {rbin, rgray} <= {rbinnext, rgraynext};
        end
    end

    assign radr = rbin[ADDR-1:0];
    assign rbinnext = rbin + (rd_en & !empty);
    assign rgraynext = (rbinnext>>1) ^ rbinnext;

    assign empty_val = (rgraynext == w2rsynch2);
    always_ff @(posedge rclk, negedge rst_) begin
        if (!rst_) begin
            empty <= 1'b1;
        end else begin
            empty <= empty_val; 
        end    
    end 

    //------------Almost Empty logic-------------
    gray2bin Ug0(.binary_out(w2rsynch2_bin), .gray_in(w2rsynch2));
    assign Al_empty_val = (int'(3'(rbin[ADDR-1:0]+3'd4)) - int'(w2rsynch2_bin[ADDR-1:0]) < 4) && (int'(3'(rbin[ADDR-1:0]+3'd4)) - int'(w2rsynch2_bin[ADDR-1:0]) > 0);
    always_ff @(posedge rclk, negedge rst_) begin
        if (!rst_) begin 
            Al_empty <= 1'b1;
        end else begin 
            Al_empty <= Al_empty_val | empty_val; 
        end
    end

    //------------Full logic-------------
    always_ff @(posedge wclk, negedge rst_) begin
        if (!rst_) begin {wbin, wgray} <= 0;
        end else begin 
            {wbin, wgray} <= {wbinnext, wgraynext};
        end    
    end

    assign wadr = wbin[ADDR-1:0];
    assign wbinnext = wbin + (wr_en & sdone & !full);
    assign wgraynext = (wbinnext>>1) ^ wbinnext;

    assign full_val = (wgraynext == {~r2wsynch2[ADDR:ADDR-1], r2wsynch2[ADDR-2:0]});
    always_ff @(posedge wclk, negedge rst_) begin
        if (!rst_) begin
            full <= 1'b0;
        end else begin
            full <= full_val; 
        end
    end  

    //------------Almost Full logic-------------
    gray2bin Ug1(.binary_out(r2wsynch2_bin), .gray_in(r2wsynch2));
    assign Al_full_val = (int'(3'(wbin[ADDR-1:0]+3'd4)) - int'(r2wsynch2_bin[ADDR-1:0]) < 4) && (int'(3'(wbin[ADDR-1:0]+3'd4)) - int'(r2wsynch2_bin[ADDR-1:0]) > 0);
    always_ff @(posedge wclk, negedge rst_) begin
        if (!rst_) begin 
            Al_full <= 1'b0;
        end else begin 
            Al_full <= Al_full_val | full_val; 
        end
    end 
endmodule

module gray2bin #(
      //=============
      // Parameters
      //=============
      parameter DATA_WIDTH = 4
   ) (
      //============
      // I/O Ports
      //============
      input  [DATA_WIDTH-1:0] gray_in,
      output [DATA_WIDTH-1:0] binary_out
   );
   
   // gen vars
   genvar i;

   //=====================
   // Generate: gray2bin
   //=====================
   generate 
      for (i=0; i<DATA_WIDTH; i=i+1)
      begin
         assign binary_out[i] = ^ gray_in[DATA_WIDTH-1:i];
      end
   endgenerate
endmodule

module f_tbench;
    logic pclk, sclk, rst_, read, write, ws, full, empty, Al_full, Al_empty;
    logic [31:0] din; logic dout;
    OP_t OP ='{default: 0, standard: MSB, mode: MT, word_size: w32bits, frame_size: f32bits, sys_freq: k32,stereo: 1'b1, stop: 1'b1, rst:1'b1};
    

    initial begin
        pclk<=0;sclk<=0;
        forever #2 pclk <= !pclk;
    end
    initial 
        forever #3 sclk <= !sclk;

    RxFIFO fifo(.wclk(sclk),.rclk(pclk),.wr_en(write),.rd_en(read),.*);
    


    always begin
        rst_ <= 1; {read, write} <= 0;
        @(posedge pclk) rst_ <=0; din=$urandom($stime);
        @(posedge pclk) rst_<=1;
        @(posedge pclk) write<=1;
        @(posedge pclk); write<=0;
        repeat (20) @(posedge pclk);
        @(posedge pclk) write<=1;
        @(posedge pclk); write<=0;
        repeat (20) @(posedge pclk);
        @(posedge pclk) write<=1;
        @(posedge pclk); write<=0;
        repeat (20) @(posedge pclk);
        @(posedge pclk) write<=1;
        @(posedge pclk); write<=0;
        repeat (20) @(posedge pclk);
        @(posedge pclk) write<=1;
        @(posedge pclk); write<=0;
        repeat (20) @(posedge pclk);
        @(posedge pclk) write<=1;
        @(posedge pclk); write<=0;
        repeat (20) @(posedge pclk);
        @(posedge pclk) write<=1;
        @(posedge pclk); write<=0;
        repeat (20) @(posedge pclk);
        @(posedge pclk) write<=1;
        @(posedge pclk); write<=0;
        repeat (40) @(posedge pclk);


        @(posedge sclk) read<=1;
        @(posedge sclk); read<=0;
        repeat (20) @(posedge sclk);
        @(posedge sclk) read<=1;
        @(posedge sclk); read<=0;
        repeat (20) @(posedge sclk);
        @(posedge sclk) read<=1;
        @(posedge sclk); read<=0;
        repeat (20) @(posedge sclk);
        @(posedge sclk) read<=1;
        @(posedge sclk); read<=0;
        repeat (20) @(posedge sclk);
        @(posedge sclk) read<=1;
        @(posedge sclk); read<=0;
        repeat (20) @(posedge sclk);
        @(posedge sclk) read<=1;
        @(posedge sclk); read<=0;
        repeat (20) @(posedge sclk);
        @(posedge sclk) read<=1;
        @(posedge sclk); read<=0;
        repeat (20) @(posedge sclk);
        @(posedge sclk) read<=1;
        @(posedge sclk); read<=0;
        repeat (20) @(posedge sclk);
        @(posedge sclk) read<=1;
        @(posedge sclk); read<=0;
        repeat (20) @(posedge sclk);
        @(posedge sclk) read<=1;
        @(posedge sclk); read<=0;
        repeat (20) @(posedge sclk);
        @(posedge sclk) read<=1;
        @(posedge sclk); read<=0;
        repeat (20) @(posedge sclk);

        repeat (140) @(posedge pclk);
    end

endmodule