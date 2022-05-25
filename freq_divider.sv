module clk_div(pclk, sclk);
	input	wire	pclk;
	output	reg		sclk;

  reg	[31:0]	counter=0;
  	

	always @(posedge pclk)
	if (counter == 0)
		counter <= 2;
	else
		counter <= counter - 1;

	always @(posedge pclk)
   		sclk <= (counter == 1);
        
endmodule