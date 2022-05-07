package control_bits
    typedef struct packed{
        logic stereo;
        typedef enum {44, 48} sample_rate;
        typedef enum [1:0] {16b, 24b, 32b} word_size;
        typedef enum {16b, 32b} frame_size;
        logic mclk_en;
        typedef enum [1:0] {I2S, MSB, LSB} standard;
        typedef enum [1:0] {SR, MR, SR, MT} mode; 
        logic mute, stop, reset;
    } controls;
endpackage

module reg_interface (
    input logic pclk, preset, penable, pwrite, full, empty,
    input logic [31:0] paddr, pwdata, Rx_data,

    output logic [31:0] prdata, Tx_data);

logic wren, ren;
logic [31:0] registers [3];
controls [31:0] controls;

always_ff @(posedge pclk) begin
    if (preset) foreach (registers[i]) registers[i]=0;
    else if (penable &&  pwrite && ~full) registers[paddr>>5] <= pwdata;
    else if (penable && ~pwrite && ~empty) prdata <= registers[paddr>>5]; 
end

assign controls=registers[0];
assign Tx_data=registers[1];
assign registers[2]=Rx_data;

always_ff @(posedge pclk) begin
    wren <= penable && pwrite;
    ren <= penable && ~pwrite;
end


endmodule