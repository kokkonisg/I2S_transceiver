`default_nettype none

module tb_I2S_top;

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

logic pclk, penable, pwrite;
logic preset, temp_sclk;
logic [31:0] paddr, pwdata, prdata;
logic [12:0] flags;
wire sclk, mclk, ws, sd;
OP_t OPtx ='{default: 0, sys_freq: k32, standard: MSB, mode: ST, sample_rate: hz44, word_size: w32bits, frame_size: f32bits, stereo: 1'b1, stop: 1'b1, rst:1'b1};
OP_t OPrx ='{default: 0, sys_freq: k32, standard: MSB, mode: MR, sample_rate: hz44, word_size: w32bits, frame_size: f32bits, stereo: 1'b1, stop: 1'b1, rst:1'b1};
OP_t OPmstr = '{default: 0, sys_freq: k32, standard: MSB, mode: MT, sample_rate: hz44, word_size: w32bits, frame_size: f32bits, stereo: 1'b1};


//Two of the same modules used, one is transmitting data while the other recieves it
I2S_top #(.ADR_OFFSET(0)) Utr(.*, .prdata());
I2S_top #(.ADR_OFFSET(32'h20)) Urc(.*);

assign sclk = temp_sclk; //keeps sclk from being undefined at start
localparam CLK_PERIOD = 6;
always #(CLK_PERIOD/2) pclk=~pclk;


//------------------------------------------------------------------
/*The following impliments a way to automatically check wether 
the data are correctly transmitted through the BUS without any losses.
Two queues are used, the INPUT_DATA one is for data to-be transmitted and
the OUTPUT_DATA one for the data recieved. 

A messege is printed in the Transcript/Terminal where the current recieved
data is displayed as well as a Pass or Fail statement, if the two data slices 
(of input and output) are matching or not */

logic [31:0] INPUT_DATA [$]; //actually could be a static array
logic [31:0] OUTPUT_DATA [$];
int num_of_words = 256;

initial begin
    for (int i=0; i<num_of_words; i++) begin
        if (OPtx.word_size==w16bits) begin
            INPUT_DATA.push_front($urandom(i)>>16);
        end else if (OPtx.word_size==w24bits) begin
            INPUT_DATA.push_front($urandom(i)>>8);
        end else begin
            INPUT_DATA.push_front($urandom(i));
        end
    end
end

int j = num_of_words-1;
always @(negedge pclk) begin    
    if (!Utr.Uregc.occTx && penable && pwrite && paddr==32'h08) begin
        pwdata<=INPUT_DATA[j];
        if (j >= 0) begin
            j <= j-1;
        end
    end

    if ($past(Urc.Uregc.reg_ren && paddr==32'h32)) begin
        OUTPUT_DATA.push_front(prdata);
    end
end

//just a help function to return the pass or fail
function string check_data (logic [31:0] qIN [$],logic [31:0] qOUT [$], OP_t OP);
    automatic int size = qIN.size() < qOUT.size() ? qIN.size() : qOUT.size();
    automatic logic check = 1'b1;
    for (int k=0; k<size; k++) begin
        check = check & (OP.frame_size == f32bits ? (qIN[$-k]==qOUT[$-k]) : (qIN[$-k][15:0]==qOUT[$-k][15:0]));
        // $display("IN:%h OUT:%h -- %b -- %0b",qIN[$-k],qOUT[$-k],(OP.frame_size == f32bits ? (qIN[$-k]==qOUT[$-k]) : (qIN[$-k][15:0]==qOUT[$-k][15:0])),OP.frame_size); //BUG CHECK
    end
    return (check) ? "PASS" : "FAIL";
endfunction

always @(posedge pclk) begin
    if (OUTPUT_DATA.size() != $past(OUTPUT_DATA.size())) begin
        $displayh("@%0t -- %s", $stime, check_data(INPUT_DATA,OUTPUT_DATA, OPtx));
    end
end
//-------------------------------------------------------------------------

//First the control bits are defined using OP
//Then some data is loaded to-be transmitted
//the transaction is enabled
//some data is being recieved and read
//then a loop occures where data is inputted and outputted so the FIFOs dont empty/fill
//in the end the transmission is stopped

int loop=0;
localparam num_of_loops=9; //just some help vars for the looping

initial begin
    // $displayh("initial IN: %p", INPUT_DATA);
    // $displayh("initial OUT: %p", OUTPUT_DATA);


    temp_sclk <= 1'b0;
    preset<=1'bx;pclk<=1'bx;
    #(CLK_PERIOD) pclk<=1'b0;
    #(CLK_PERIOD*3) preset<=1'b0;
    #(CLK_PERIOD*3) preset<=1'b1;

    //parsing control bits
    @(posedge pclk); penable<=1'b1; pwrite<=1'b1; paddr<=32'h00; pwdata<=OPtx;
    @(posedge pclk); penable<=1'b1; pwrite<=1'b1; paddr<=32'h20; pwdata<=OPrx;

    //first load of data in TxFIFO
    @(posedge pclk); paddr<=32'h08; temp_sclk <= 1'bZ;
    repeat (15) @(posedge pclk); 

    //starting data transmission
    OPrx.stop <= 1'b0;
    @(posedge pclk); paddr<=32'h20; pwdata<=OPrx;
    @(posedge pclk);

    
    //reading data being recieved first
    @(posedge pclk); paddr<=32'h32; pwrite<=1'b0;
    repeat (38) @(posedge sclk)

    //loop to write & read data
    while (loop < num_of_loops/3) begin 
        @(posedge pclk) paddr<=32'h08; pwrite<=1'b1;
        repeat (20) @(posedge pclk);
        @(posedge pclk) paddr<=32'h32; pwrite<=1'b0;
        repeat (150) @(posedge sclk);
        $display("\nloop no%0d\n",loop+1);
        loop++;
    end

    @(posedge pclk); penable<=1'b1; pwrite<=1'b0; paddr<=32'h24; flags<=prdata;

    //loop to read data
    while (loop < 2*num_of_loops/3) begin 
        @(posedge pclk) paddr<=32'h08; pwrite<=1'b1;
        repeat (20) @(posedge pclk);
        @(posedge pclk) paddr<=32'h32; pwrite<=1'b0;
        repeat (150) @(posedge sclk);
        $display("\nloop no%0d\n",loop+1);
        loop++;
    end

    // OPrx.stop<=1'b1;OPtx.frame_size <= f16bits; OPrx.frame_size <= f16bits; OPtx.sample_rate <= hz48; OPrx.sample_rate <= hz48;
    // @(posedge pclk) pwrite<=1'b1; paddr<=32'h0; pwdata<=OPtx;
    // @(posedge pclk); pwrite<=1'b1; paddr<=32'h20; pwdata<=OPrx;

    // OPtx.rst <= 1'b0; OPrx.rst <= 1'b0; 
    // //parsing control bits
    // @(posedge pclk); pwrite<=1'b1; paddr<=32'h00; pwdata<=OPtx;
    // @(posedge pclk); pwrite<=1'b1; paddr<=32'h20; pwdata<=OPrx;
    
    // OPtx.rst <= 1'b1; OPrx.rst <= 1'b1;
    // //parsing control bits
    // @(posedge pclk); pwrite<=1'b1; paddr<=32'h00; pwdata<=OPtx;
    // @(posedge pclk); pwrite<=1'b1; paddr<=32'h20; pwdata<=OPrx;
    
    // //first load of data in TxFIFO
    // @(posedge pclk) paddr<=32'h08;
    // repeat (15) @(posedge pclk); 

    // OPrx.stop<=1'b0;
    // @(posedge pclk) pwrite<=1'b1; paddr<=32'h20; pwdata<=OPrx;

    //loop to read data
    while (loop < num_of_loops) begin 
        @(posedge pclk) paddr<=32'h08; pwrite<=1'b1;
        repeat (20) @(posedge pclk);
        @(posedge pclk) paddr<=32'h32; pwrite<=1'b0;
        repeat (120) @(posedge sclk);
        $display("\nloop no%0d\n",loop+1);
        loop++;
    end

    //end of transmission
    OPrx.stop<=1'b1;
    @(posedge pclk) pwrite<=1'b1; paddr<=32'h20; pwdata<=OPrx;
    $display("%0t NO MORE INPUT IN TxFIFO ENDING TRANSMISSION",$stime);

    //reading the last frame being transmitted 
    @(posedge pclk) paddr<=32'h32;pwrite<=1'b0;
    $finish;
    
end

endmodule
`default_nettype wire
