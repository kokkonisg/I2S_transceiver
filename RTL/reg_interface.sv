module reg_interface (
    input logic reg_wen, reg_ren, Tx_wen, Rx_ren,
    input logic pclk, preset, penable, pwrite,
    input logic [31:0] addr, pwdata, Rx_data,
    input logic [12:0] flags,

    output logic [31:0] prdata, Tx_data,
    output logic [14:0] controls);

    logic [31:0] registers [4];

    assign controls = registers[0][14:0];
    assign registers[1] = {19'b0, flags};
    assign Tx_data = registers[2];

    always_ff @(posedge pclk, negedge preset) begin
        if (!preset) begin
            registers[0] <= 32'b000011011010101; //change reset values
            //registers[1] contains flags so on reset, the reset values of the contained vars are set 
            registers[2] <= 32'b0;
            registers[3] <= 32'b0;
        end else if (penable) begin
            if (Rx_ren) begin
                registers[3] <= Rx_data;
            end
            case (addr)
                32'h0: if (pwrite) registers[0] <= pwdata; //write & read
                        else if (!pwrite) prdata <= registers[0];
                32'h4: if (!pwrite) prdata <= registers[1]; //read only
                32'h8: if (pwrite && reg_wen) registers[2] <= pwdata; //write only
                32'h12: if (!pwrite && reg_ren) prdata <= registers[3]; //read only
            endcase
        end
    end
endmodule