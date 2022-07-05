`include "package.sv"

import ctrl_pkg::*;

module TxFIFO(
    input logic wclk, rclk, rst_, write, read,
    [31:0] logic din,
    OP_t OP,
    output logic full, empty, dout,
    inout logic ws
    );

    logic [31:0] FIFO [7:0];
    logic [3:0] r_ptr_par;
    logic [4:0] r_ptr_ser;
    logic [3:0] w_ptr;

    assign full = ({!w_ptr[3],w_ptr[2:0]} == r_ptr_par);
    assign empty = (w_ptr == r_ptr_par);

    always_ff @(posedge wclk, negedge rst_) begin: wrt_data
        if(!rst_) begin
            FIFO <= '{default: 0};
            w_ptr <= 4'b0;
        end else if (write && !full) begin
            FIFO[w_ptr[2:0]] <= din;
            w_ptr <= w_ptr + 1'b1;
        end
    end

    always_ff @(negedge rclk, negedge rst_) begin: rd_data //aka data to be transmitted
        if(!rst_) begin
            r_ptr_par <= 4'b0;
            unique if (OP.frame_size == f16bits) r_ptr_ser <= 5'd15;
            else if (OP.frame_size == f31bits) r_ptr_ser <= 5'd31;
        end else if (read && !empty) begin
            dout <= FIFO[r_ptr_par[2:0]][r_ptr_ser];

            if (r_ptr_ser > 0) r_ptr_ser <= r_ptr_ser - 1'b1;
            else begin
                r_ptr_par <= r_ptr_par + 1'b1;
                unique if (OP.frame_size == f16bits) r_ptr_ser <= 5'd15;
                else if (OP.frame_size == f31bits) r_ptr_ser <= 5'd31;
            end
        end
    end

endmodule

module RxFIFO(
    input logic wclk, rclk, rst_, write, read, din,
    OP_t OP,
    output logic full, empty,
    logic [31:0] dout,
    inout logic ws
    );

    logic [31:0] FIFO [7:0];
    logic [3:0] w_ptr_par;
    logic [4:0] w_ptr_ser;
    logic [3:0] r_ptr;

    assign full = ({!w_ptr_par[3],w_ptr_par[2:0]} == r_ptr);
    assign empty = (w_ptr_par == r_ptr);

    always_ff @(negedge rclk, negedge rst_) begin: rd_data
        if(!rst_)
            r_ptr <= 4'b0;
        else if (read && !empty) begin
            dout <= FIFO[r_ptr_par[2:0]];
            r_ptr <= r_ptr + 1'b1;
        end
    end

    always_ff @(posedge wclk, negedge rst_) begin: wrt_data //aka recieved data
        if(!rst_) begin
            FIFO <= '{default: 0};
            w_ptr_par <= 4'b0;
            unique if (OP.frame_size == f16bits) w_ptr_ser <= 5'd15;
            else if (OP.frame_size == f31bits) w_ptr_ser <= 5'd31;
        end else if (write && !full) begin
            FIFO[w_ptr[2:0]][w_ptr_ser] <= din;

            if (w_ptr_ser > 0) w_ptr_ser <= w_ptr_ser - 1'b1;
            else begin
                w_ptr_par <= w_ptr_par + 1'b1;
                unique if (OP.frame_size == f16bits) w_ptr_ser <= 5'd15;
                else if (OP.frame_size == f31bits) w_ptr_ser <= 5'd31;
            end
        end
    end

endmodule