`include "package.sv"
`include "freq_divider.sv"

import ctrl_pkg::*;

// module TxFIFO(
//     input logic wclk, rclk, rst_, write, read, ws,
//     logic [31:0] din,
//     OP_t OP,
//     output logic full, empty, dout
//     );

//     logic [31:0] FIFO [7:0];
//     logic [3:0] r_ptr_par;
//     logic [4:0] r_ptr_ser;
//     logic [3:0] w_ptr;
//     logic full_act, empty_act;

//     assign full_act = ({!w_ptr[3],w_ptr[2:0]} == r_ptr_par);
//     synch full_synch (wclk, full_act, rst_, full);
//     assign empty_act = (w_ptr == r_ptr_par);
//     synch empty_synch (rclk, empty_act, rst_, empty);

//     always_ff @(posedge wclk, negedge rst_) begin: wrt_data
//         if(!rst_) begin
//             FIFO <= '{default: 0};
//             w_ptr <= 4'b0;
//         end else if (write && !full) begin
//             FIFO[w_ptr[2:0]] <= din;
//             w_ptr <= w_ptr + 1'b1;
//         end
//     end

//     always_ff @(negedge rclk, negedge rst_) begin: rd_data //aka data to be transmitted
//         if(!rst_) begin
//             r_ptr_par <= 4'b0;
//             unique if (OP.frame_size == f16bits) r_ptr_ser <= 5'd15;
//             else if (OP.frame_size == f32bits) r_ptr_ser <= 5'd31;
//         end else if (read && !empty) begin
//             dout <= FIFO[r_ptr_par[2:0]][r_ptr_ser];

//             if (r_ptr_ser > 0) r_ptr_ser <= r_ptr_ser - 1'b1;
//             else begin
//                 r_ptr_par <= r_ptr_par + 1'b1;
//                 unique if (OP.frame_size == f16bits) r_ptr_ser <= 5'd15;
//                 else if (OP.frame_size == f32bits) r_ptr_ser <= 5'd31;
//             end
//         end
//     end

// endmodule

// module RxFIFO(
//     input logic wclk, rclk, rst_, write, read, ws, din,
//     OP_t OP,
//     output logic full, empty,
//     logic [31:0] dout
//     );

//     logic [31:0] FIFO [7:0];
//     logic [3:0] w_ptr_par;
//     logic [4:0] w_ptr_ser;
//     logic [3:0] r_ptr;
//     logic full_act, empty_act;

//     assign full_act = ({!w_ptr_par[3],w_ptr_par[2:0]} == r_ptr);
//     synch full_synch (wclk, full_act, rst_, full);
//     assign empty_act = (w_ptr_par == r_ptr);
//     synch empty_synch (rclk, empty_act, rst_, empty);



//     always_ff @(negedge rclk, negedge rst_) begin: rd_data
//         if(!rst_)
//             r_ptr <= 4'b0;
//         else if (read && !empty) begin
//             dout <= FIFO[r_ptr[2:0]];
//             r_ptr <= r_ptr + 1'b1;
//         end
//     end

//     always_ff @(posedge wclk, negedge rst_) begin: wrt_data //aka recieved data
//         if(!rst_) begin
//             FIFO <= '{default: 0};
//             w_ptr_par <= 4'b0;
//             unique if (OP.frame_size == f16bits) w_ptr_ser <= 5'd15;
//             else if (OP.frame_size == f32bits) w_ptr_ser <= 5'd31;
//         end else if (write && !full) begin
//             FIFO[w_ptr_par[2:0]][w_ptr_ser] <= din;

//             if (w_ptr_ser > 0) w_ptr_ser <= w_ptr_ser - 1'b1;
//             else begin
//                 w_ptr_par <= w_ptr_par + 1'b1;
//                 unique if (OP.frame_size == f16bits) w_ptr_ser <= 5'd15;
//                 else if (OP.frame_size == f32bits) w_ptr_ser <= 5'd31;
//             end
//         end
//     end

// endmodule

// module synch(
// 	input logic clk, act, rst_,
// 	output logic f);

// 	logic d, q;
// 	assign f = act || d || q;
// 	always @(posedge clk, negedge rst_)
//         if (!rst_) {d, q} <= 0;
//         else begin
//             q<=act;
//             d<=q;
//         end
// endmodule


module TxFIFO #(WIDTH = 32, ADDR = 3) (
    input logic wclk, rclk, rst_, wr_en, rd_en,
    logic [WIDTH-1:0] din,
    OP_t OP,
    output logic dout);

    logic [WIDTH-1:0] FIFO [(1<<ADDR)-1:0];
    logic [ADDR-1:0] wadr, radr;
    int sptr;
    logic sdone, empty, full;
    let maxp = (OP.frame_size==f16bits) ? 15 : 31;
    assign sdone = (sptr == 0);

    always_ff @(posedge wclk, negedge rst_) begin : proc_write
        if(~rst_) begin
            FIFO <= '{default: 0};
        end else if (wr_en && !full) begin
            FIFO[wadr] <= din;
        end
    end

    always_ff @(negedge rclk) begin : proc_read
        if (~rst_) sptr <= maxp;
        else if (rd_en && !empty) begin
            dout <= FIFO[radr][sptr];
            sptr <= (sptr>0) ? sptr-1 : maxp;
        end
    end

    //-----------------------------------------------
    logic [ADDR:0] rbin,  wbin, rbinnext, wbinnext, rgray, wgray, rgraynext, wgraynext;
    logic [ADDR:0] r2wsynch1, r2wsynch2;
    logic [ADDR-1:0] w2rsynch1, w2rsynch2;
    
    always_ff @(posedge wclk, negedge rst_) begin
        if (!rst_) {r2wsynch1, r2wsynch2} <= 0;
        else {r2wsynch2, r2wsynch1} <= {r2wsynch1, rgray};
    end

    always_ff @(posedge rclk, negedge rst_) begin
        if (!rst_) {w2rsynch1, w2rsynch2} <= 0;
        else {w2rsynch2, w2rsynch1} <= {w2rsynch1, wgray};
    end

    //------------------------------------------------

    always @(posedge rclk, negedge rst_) begin
        if (!rst_) {rbin, rgray} <= 0;
        else {rbin, rgray} <= {rbinnext, rgraynext};
    end
    assign radr = rbin[ADDR-1:0];
    assign rbinnext = rbin + (rd_en & sdone & !empty);
    assign rgraynext = (rbinnext>>1) ^ rbinnext;

    assign empty_val = (rgraynext == w2rsynch2);
    always @(posedge rclk, negedge rst_) begin
        if (!rst_) empty <= 1'b1;
        else empty <= empty_val; 
    end 


    always @(posedge wclk, negedge rst_) begin
        if (!rst_) {wbin, wgray} <= 0;
        else {wbin, wgray} <= {wbinnext, wgraynext};
    end
    assign wadr = wbin[ADDR-1:0];
    assign wbinnext = wbin + (wr_en & !full);
    assign wgraynext = (wbinnext>>1) ^ wbinnext;

    assign full_val = (wgraynext == {~r2wsynch2[ADDR:ADDR-1], r2wsynch2[ADDR-2:0]});
    always @(posedge wclk, negedge rst_) begin
        if (!rst_) full <= 1'b0;
        else full <= full_val; 
    end 

    //-----------------------------------------------
endmodule

module RxFIFO #(WIDTH = 32, ADDR = 3) (
    input logic wclk, rclk, rst_, wr_en, rd_en,
    logic din,
    OP_t OP,
    output logic [WIDTH-1:0] dout);

    logic [WIDTH-1:0] FIFO [(1<<ADDR)-1:0];
    logic [ADDR-1:0] wadr, radr;
    int sptr;
    logic sdone, empty, full;
    let maxp = (OP.frame_size==f16bits) ? 15 : 31;
    assign sdone = (sptr == 0);

    always_ff @(posedge wclk, negedge rst_) begin : proc_write
        if(~rst_) begin
            FIFO <= '{default: 0};
            sptr <= maxp;
        end else if (wr_en && !full) begin
            FIFO[wadr][sptr] <= din;
            sptr <= (sptr>0) ? sptr-1 : maxp;
        end
    end

    always_ff @(posedge rclk) begin : proc_read
        if (rd_en && !empty) begin
            dout <= FIFO[radr];
        end
    end

    //-----------------------------------------------
    logic [ADDR:0] rbin,  wbin, rbinnext, wbinnext, rgray, wgray, rgraynext, wgraynext;
    logic [ADDR:0] r2wsynch1, r2wsynch2;
    logic [ADDR-1:0] w2rsynch1, w2rsynch2;
    
    always_ff @(posedge wclk, negedge rst_) begin
        if (!rst_) {r2wsynch1, r2wsynch2} <= 0;
        else {r2wsynch2, r2wsynch1} <= {r2wsynch1, rgray};
    end

    always_ff @(posedge rclk, negedge rst_) begin
        if (!rst_) {w2rsynch1, w2rsynch2} <= 0;
        else {w2rsynch2, w2rsynch1} <= {w2rsynch1, wgray};
    end

    //------------------------------------------------

    always @(posedge rclk, negedge rst_) begin
        if (!rst_) {rbin, rgray} <= 0;
        else {rbin, rgray} <= {rbinnext, rgraynext};
    end
    assign radr = rbin[ADDR-1:0];
    assign rbinnext = rbin + (rd_en & sdone & !empty);
    assign rgraynext = (rbinnext>>1) ^ rbinnext;

    assign empty_val = (rgraynext == w2rsynch2);
    always @(posedge rclk, negedge rst_) begin
        if (!rst_) empty <= 1'b1;
        else empty <= empty_val; 
    end 


    always @(posedge wclk, negedge rst_) begin
        if (!rst_) {wbin, wgray} <= 0;
        else {wbin, wgray} <= {wbinnext, wgraynext};
    end
    assign wadr = wbin[ADDR-1:0];
    assign wbinnext = wbin + (wr_en & !full);
    assign wgraynext = (wbinnext>>1) ^ wbinnext;

    assign full_val = (wgraynext == {~r2wsynch2[ADDR:ADDR-1], r2wsynch2[ADDR-2:0]});
    always @(posedge wclk, negedge rst_) begin
        if (!rst_) full <= 1'b0;
        else full <= full_val; 
    end 

    //-----------------------------------------------
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