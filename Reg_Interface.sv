module Reg_Interface (
    input logic reg_wen, reg_ren,
    input logic pclk, preset, penable, pwrite, 
    input logic [31:0] paddr, pwdata, Rx_data,

    output logic [31:0] prdata, Tx_data, controls);

    logic [31:0] registers [3];

    assign Tx_data = registers[0];
    assign controls = registers[1];
    assign registers[2] = Rx_data;

    always_ff @(posedge pclk) begin
        if (!preset) begin registers[0]=32'h0; registers[1]=32'h0; 
        end else if (penable) 
            case (paddr)
                32'h0: if (pwrite && reg_wen) registers[0] <= pwdata;
                32'h4: if (pwrite) registers[1] <= pwdata;
                        else if (~pwrite) prdata <= registers[1];
                32'h8: if (~pwrite && reg_ren) prdata <= registers[2];
            endcase
    end
endmodule