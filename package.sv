package ctrl_pkg;
	typedef enum logic {hz44=1'b0, hz48=1'b1} sample_rate_t;
        typedef enum logic [1:0] {w16bits=2'b00, w24bits=2'b01, w32bits=2'b10} word_size_t;
        typedef enum logic {f16bits=1'b0, f32bits=1'b1} frame_size_t;
        typedef enum logic [1:0] {I2S=2'b00, MSB=2'b01, LSB=2'b10} standard_t;
        typedef enum logic [1:0] {SR=2'b00, MR=2'b10, ST=2'b01, MT=2'b11} mode_t;  

    typedef struct packed {
	sample_rate_t sample_rate;
	word_size_t word_size;
	frame_size_t frame_size;
	mode_t mode;
	standard_t standard;
	logic rst, stop, mute, mclk_en, stereo;
        }OP_t; OP_t OP;
endpackage