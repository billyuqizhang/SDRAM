//-----------------------------------------------------------------------------  
// Module Information  
//-----------------------------------------------------------------------------
// Copyright  1994-2010 Landwind International Medical Science PTE.LTD., 2010.  
// All rights reserved.  
//-----------------------------------------------------------------------------  
// Module Information  
//-----------------------------------------------------------------------------  
// Module      : tb_1101_AD_interface  
// File        : tb_1101_AD_interface.v  
// Library     :   
// top level   : tb_1101_AD_interface.v 
// Simulator   : Modelsim 6.5c
// Synthesizer : Synplify E-2010.09  
// DEPARTMENT  : Ultrasound Dept.  
// Designer    : Zhang Yuqi (yuqi.zhang@landwind.com)  
// Description : It is the sim test bench for 1101 ADC.
// Date		   : 2011.06.26
//------------------------------------------------------------------------------
//--================================================================--

//  --================================================================--
`include "../src/defination.v"

module fifo_sim;
//input
  reg																	clk_100;
  reg																	rd_en;
  reg																	wr_en;
  reg		[ `SDRM_BUS-1: 0] 						data_in;

	wire																almost_empty;
	wire																almost_full;
	wire																empty;
	wire																full;
	wire	[ 35: 0]											data_out;
  wire	[3:0]													usedw;
  sdrm_fifo 		sdram_fifo_inst
    (
      .clock         (clk_100),
      .rdreq         (rd_en),
      .wrreq         (wr_en),
      .data      		 ({3'd0,data_in}),
                    
      .almost_empty  (almost_empty),
      .almost_full   (almost_full),
      .empty         (empty),
      .full          (full),
      .q      			 (data_out),
     	.usedw				 (usedw)			
	);
integer i;
 
initial begin                                      
	// Initialize Inputs                             
 	wr_en = 0;
	rd_en = 0; 		   
                              
	#1000;                                           
 	
 	wr_en = 1;
 	#10;
 	data_in = 34;
	for (i = 1; i <= 8; i=i+1) begin
	#10;
 		data_in = data_in + 3;		
 	end
	
	#100;
	wr_en = 0;
	rd_en = 1;
	#1000;
end
    
 parameter CLK_PERIOD_100M = 5;	//100MHz
                
   initial begin
      clk_100 = 1'b0;
      #CLK_PERIOD_100M;
      forever   
         #CLK_PERIOD_100M	 clk_100 = ~clk_100;
   end     
   
endmodule    