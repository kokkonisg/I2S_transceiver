module reg_interface (
    input logic reg_wen, reg_ren,
    input logic pclk, preset, penable, pwrite,
    input logic [31:0] addr, pwdata, Rx_data,
    logic [9:0] flags,

    output logic [31:0] prdata, Tx_data,
    output logic [14:0] controls);

    logic [31:0] registers [4];

    assign controls = registers[0][14:0];
    assign Tx_data = registers[1];
    assign registers[2] = Rx_data;
    assign registers[3] = {22'b0, flags};

    always_ff @(posedge pclk, negedge preset) begin
        if (!preset) begin
            registers[0] <= 32'b001111011010101; //change reset values
            registers[1] <= 32'b0;
        end else if (penable) begin 
            case (addr)
                32'h0: if (pwrite) registers[0] <= pwdata; //write & read
                        else if (!pwrite) prdata <= registers[0];
                32'h4: if (pwrite && reg_wen) registers[1] <= pwdata; //write only
                32'h8: if (!pwrite && reg_ren) prdata <= registers[2]; //read only
                32'h12: if (!pwrite) prdata <= registers[3]; //read only
            endcase
        end
    end
endmodule

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

            if (penable && pwrite && addr==32'h4 && !occTx) begin: wr_TxReg
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

            if (penable && !pwrite && addr==32'h8 && occRx) begin: rd_RxReg
                reg_ren <= 1'b1;
                occRx <= 1'b0;
            end else begin
                reg_ren <= 1'b0;
            end
        end
    end
endmodule