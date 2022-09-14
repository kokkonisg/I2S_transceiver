package ctrl_pkg;
	typedef enum logic {hz44=1'b0, hz48=1'b1} sample_rate_t;
    typedef enum logic [1:0] {w16bits=2'b00, w24bits=2'b01, w32bits=2'b10} word_size_t;
    typedef enum logic {f16bits=1'b0, f32bits=1'b1} frame_size_t;
    typedef enum logic [1:0] {I2S=2'b00, MSB=2'b01, LSB=2'b10} standard_t;
    typedef enum logic [1:0] {SR=2'b00, MR=2'b10, ST=2'b01, MT=2'b11} mode_t;  
    typedef enum logic [1:0] {k32=2'b00, k16=2'b01, k8=2'b10} sys_freq_t;

    typedef struct packed {
	sample_rate_t sample_rate; //sample rate of the PCM encoder
	word_size_t word_size; //no. of bits used to encode each word
	frame_size_t frame_size; //frame's size, if larger than word_size rest will be zero-filled
	mode_t mode; //I2S mode, any combination of Master/Slave and Transmitter/Reciever
	standard_t standard; //I2S standard to be used
	sys_freq_t sys_freq; //the systems main clock frequency
	logic stop, mute, mclk_en, stereo, tran_en; //misc. options
        //tran_en to be used from master to start the data transaction
        }OP_t; OP_t OP;
    typedef enum {IDLE, L, R, ERR} ws_state_t;
endpackage