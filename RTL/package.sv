package ctrl_pkg;
	typedef enum logic {hz44=1'b0, hz48=1'b1} sample_rate_t;
    typedef enum logic [1:0] {w16bits=2'b00, w24bits=2'b01, w32bits=2'b10} word_size_t;
    typedef enum logic {f16bits=1'b0, f32bits=1'b1} frame_size_t;
    typedef enum logic [1:0] {I2S=2'b00, MSB=2'b01, LSB=2'b10} standard_t;
    typedef enum logic [1:0] {SR=2'b00, MR=2'b10, ST=2'b01, MT=2'b11} mode_t;  
    typedef enum logic [1:0] {k32=2'b00, k16=2'b01, k8=2'b10} sys_freq_t;

    typedef enum logic {YES=1'b1, NO=1'b0} status_t;
    typedef enum logic {LEFT=1'b0, RIGHT=1'b1} channel_t;

    typedef enum {IDLE, L, R, ERR} ws_state_t;

    typedef struct packed {
        standard_t standard; //I2S standard to be used (Phillips, MSB or LSB justified)
        mode_t mode; //I2S mode, any combination of Master/Slave and Transmitter/Reciever
        sample_rate_t sample_rate; //sample rate of the PCM encoder (44.1kHz or 48kHz)
        word_size_t word_size; //no. of bits used by the PCM to encode each word (16, 24 or 32bits)
        frame_size_t frame_size; //no. of bits being sent/recieved during a data transaction (16 ot 32 bits)
        //NOTE: frame size has higher priority tha word size, meaning if word>frame then word's MSBs are automatically trimmed
        //      if frame>word the remaining bits are zero-filled (MSBs or LSBs depending on the standard)
        sys_freq_t sys_freq; //the systems main clock frequency
        logic stereo, mclk_en, stop, mute, rst; //misc. options
            //stop: while high stops the transmission (and reception) of data
            //mute: when high mutes (convert to 0) the data being recieved
            //mclk_en: when high master clock output is enabled
            //stereo: indicates whether 2 channels are used (when high=stereo mode) ot just 1 (when low=mono mode)
    } OP_t; OP_t OP;

    typedef struct packed {
        status_t TxReg_EMPTY;
        status_t RxReg_FULL;
        status_t IDLE;
        channel_t TxCH;
        channel_t RxCH;
        status_t TxFULL;
        status_t TxEMPTY;
        status_t TxAL_FULL;
        status_t TxAL_EMPTY;
        status_t RxFULL;
        status_t RxEMPTY;
        status_t RxAL_FULL;
        status_t RxAL_EMPTY;
    } FL_t; FL_t FL;
endpackage