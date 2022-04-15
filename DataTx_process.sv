module DataTx_process (
    input logic [31:0] din,
    output logic [31:0] dout,

    input logic [1:0] standard, word_size,
    input logic frame_size
);

always_comb
    if (frame_size==1'b0)  //16-bit frame and word
        case (standard)
            2'b00, 2'b01, 2'b10: dout = {{16{1'b0}}, din[15:0]};
            default: dout = 16'bx; //NOT ALLOWED
        endcase

    else  //32-bit frame
        if (word_size==2'b00) //16-bit word
            case (standard)
                2'b00, 2'b10: dout = {din[15:0], {16{1'b0}}};
                2'b01: dout = {{16{1'b0}}, din[15:0]};
                default: dout = 32'bx; //NOT ALLOWED
            endcase

        else if (word_size==2'b01) //24-bit word
            case (standard)
                2'b00, 2'b10: dout = {din[23:0], {8{1'b0}}};
                2'b01: dout = {{8{1'b0}}, din[23:0]};
                default: dout = 32'bx; //NOT ALLOWED
            endcase
            
        else if (word_size==2'b10) //32-bit word
            case (standard)
                2'b00, 2'b01, 2'b10: dout = din;
                default: dout = 32'bx; //NOT ALLOWED
            endcase

        else
            dout = 32'bx;//NOT ALLOWED
    
endmodule