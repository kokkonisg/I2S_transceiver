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
        end else if (rd_en && !empty /*&& !OP.stop*/) begin
            sptr <= (sptr>0) ? sptr-1 : maxp;
        end
    end

    //-----------Pointer Synchronizers-----------
    logic [ADDR:0] rbin,  wbin, rbinnext, wbinnext, rgray, wgray, rgraynext, wgraynext;
    logic [ADDR:0] r2wsynch1, r2wsynch2;
    logic [ADDR:0] w2rsynch1, w2rsynch2;
    
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

    //------------Empty & Full logic-------------
    always_ff @(negedge rclk, negedge rst_) begin
        if (!rst_) begin
            {rbin, rgray} <= 0;
        end else begin
            {rbin, rgray} <= {rbinnext, rgraynext};
        end    
    end

    assign radr = rbin[ADDR-1:0];
    assign rbinnext = rbin + (rd_en & sdone & ~empty);
    assign rgraynext = (rbinnext>>1) ^ rbinnext;

    assign empty_val = (rgraynext == w2rsynch2);
    always_ff @(negedge rclk, negedge rst_) begin
        if (!rst_) begin 
            empty <= 1'b1;
        end else begin 
            empty <= empty_val; 
        end
    end 


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
endmodule

module RxFIFO #(WIDTH = 32, ADDR = 3) (
    input logic wclk, rclk, rst_, wr_en, rd_en,
    logic din,
    OP_t OP,
    output logic [WIDTH-1:0] dout, logic full, empty);

    logic [WIDTH-1:0] FIFO [(1<<ADDR)-1:0];
    logic [ADDR-1:0] wadr, radr;
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

    //------------Empty & Full logic-------------
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
endmodule


module f_tbench;
    logic pclk, sclk, rst_, read, write, ws;
    logic [31:0] din={$urandom,1'b1}; logic dout;
    OP_t OP = '{default: 0, frame_size: f16bits};

    initial begin
        pclk<=0;
        forever #2 pclk <= ~pclk;
    end

    clk_div div(.*,.N(6'h2));
    TxFIFO fifo(.wclk(pclk),.rclk(sclk),.wr_en(write),.rd_en(read),.*);
    // ws_gen wsg(.*,.clk(sclk));
    // ws_tracker wst(.*,.clk(sclk),.ws_change(read));

    always begin
        rst_ <= 1; {read, write} <= 0;
        @(posedge pclk) rst_ <=0;
        @(posedge pclk) rst_<=1;
        @(posedge pclk) write<=1;
        repeat (5) @(posedge pclk); write<=0;
        @(posedge pclk) read<=1;
        repeat (500) @(posedge pclk);
    end
endmodule