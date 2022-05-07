`include "Rx_FIFO.sv"
`include "Tx_FIFO.sv"
`include "Reg_Interface.sv"

module I2S_top(
    input pclk, penable, preset, pwrite,
    input [31:0] paddr, pwdata,
    output [31:0] prdata); 

typedef struct packed{
        logic stereo;
        typedef enum {44, 48} sample_rate;
        typedef enum [1:0] {16b, 24b, 32b} word_size;
        typedef enum {16b, 32b} frame_size;
        logic mclk_en;
        typedef enum [1:0] {I2S, MSB, LSB} standard;
        typedef enum [1:0] {SR, MR, SR, MT} mode; 
        logic mute, stop, reset;
} ctrl_pack;

logic wen, ren, full, empty;
logic [31:0] Tx_data, Rx_data;
ctrl_pack ctrls;

Reg_Interface U0(.*);
//clk_div U(.*);
logic sclk;
Tx_FIFO U1(
    .wclk(pclk),
    .rclk(sclk),
);
Rx_FIFO U2();
endmodule