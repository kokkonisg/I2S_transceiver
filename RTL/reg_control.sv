module reg_control (
    input logic pclk, preset, penable, pwrite, [31:0] addr,
    logic Rx_empty, Tx_full,
    output logic Tx_wen, Rx_ren, reg_wen, reg_ren);

    logic occTx, occRx;

    //To check wether the register is full or not
    //(meaning if the data has been accessed already or not)
    //the occ (occupied) bits are used being high for full, low for empty

    always_ff @(negedge pclk, negedge preset) begin: proc_reg_fifo_dataex
        if (!preset) begin
            {Tx_wen, Rx_ren, reg_wen, reg_ren, occTx, occRx} <= 0;
        end else begin
            if (!Tx_full && occTx) begin: wr_TxFIFO
                Tx_wen <= 1'b1;
                occTx <= 1'b0;
            end else begin
                Tx_wen <= 1'b0;
            end

            if (penable && pwrite && addr==32'h8 && !occTx) begin: wr_TxReg
                reg_wen <= 1'b1;
                occTx <= 1'b1;
            end else begin
                reg_wen <= 1'b0;
            end

            if (!Rx_empty && !occRx) begin: rd_RxFIFO
                Rx_ren <= 1'b1;
                occRx <= 1'b1;
            end else begin
                Rx_ren <= 1'b0;
            end

            if (penable && !pwrite && addr==32'h12 && occRx) begin: rd_RxReg
                reg_ren <= 1'b1;
                occRx <= 1'b0;
            end else begin
                reg_ren <= 1'b0;
            end
        end
    end
endmodule