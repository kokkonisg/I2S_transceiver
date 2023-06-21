clear -all


analyze -sv09 -f filelist.f

elaborate -top I2S_top -bbox_mul 48

clock clk
reset ~resetn

check_superlint -extract

check_superlint -prove
