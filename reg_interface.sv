module reg_interface (
    input logic reg_wen, reg_ren,
    input logic pclk, preset, penable, pwrite, 
    input logic [3:0] flags,
    input logic [31:0] addr, pwdata, Rx_data,

    output logic [31:0] prdata, Tx_data, controls);

    logic [31:0] registers [3];

    assign controls = registers[0][12:0];
    assign Tx_data = registers[1];
    assign registers[2] = Rx_data;

    always_ff @(posedge pclk) begin
        if (!preset) registers[0:1] <= '{default: 0};
        else if (penable) 
            case (addr)
                32'h0: if (pwrite) registers[0] <= pwdata;
                        else if (!pwrite) prdata <= {flags, controls};
                32'h4: if (pwrite && reg_wen) registers[1] <= pwdata;
                32'h8: if (!pwrite && reg_ren) prdata <= registers[2];
            endcase
    end
endmodule

module reg_control (
    input logic pclk, preset, penable, pwrite, [31:0] addr,
    logic Rx_empty, Tx_full,
    output logic Tx_wen, Rx_ren, reg_wen, reg_ren);

    logic occTx, occRx;
    always_ff @(negedge pclk, negedge preset) begin: proc_reg_fifo_dataex
        if (!preset) begin
            {Tx_wen, Rx_ren, reg_wen, reg_ren, occTx, occRx} <= 0;
        end else begin
            if (!Tx_full && occTx) begin: wr_TxFIFO
                Tx_wen <= 1'b1;
                occTx <= 1'b0;
            end
            else Tx_wen <= 1'b0;

            if (penable && pwrite && addr==32'h4 && !occTx) begin: wr_TxReg
                reg_wen <= 1'b1;
                occTx <= 1'b1;
            end
            else reg_wen <= 1'b0;

            if (!Rx_empty && !occRx) begin: rd_RxFIFO
                Rx_ren <= 1'b1;
                occRx <= 1'b1;
            end
            else Rx_ren <= 1'b0;

            if (penable && !pwrite && addr==32'h8 && occRx) begin: rd_RxReg
                reg_ren <= 1'b1;
                occRx <= 1'b0;
            end
            else reg_ren <= 1'b0;
        end
    end
endmodule