/*
 * File Name:  sdram_interface.v
 * Version:  2.1
 * Date:  Sept 22, 2013
 * Description:  SDRAM driver top module
 *
 * WalkEEG www.walkeeg.com
 * Copyright (C) 2013 BralSen www.bralsen.com
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

`include "../src/defination.v"

module sdram_interface (
			// inputs:
		input   wire		         							clk						,
		input   wire		         							reset_n				,
		input   wire		         							az_cs					,
		input   wire		         							az_rd_n				,
		input   wire		         							az_wr_n				,
		input   wire		[ `SDRM_ADDR-1: 0] 		az_addr				,
		input		wire		[ `SDRM_BANK-1: 0] 		az_ba					,
		input   wire		[ `SDRM_DQM -1: 0] 		az_dqm				,
		input   wire		[ `SDRM_DATA-1: 0] 		az_data				,
      // outputs:            		
		output  wire								          zs_cs_n				, 
		output  wire     											zs_ras_n			, 		      
		output           											zs_cas_n			, 
		output  wire									        zs_we_n		    ,
		output           											zs_cke				,      
		output  				[ `SDRM_ADDR-1: 0] 		zs_addr				,       
		inout   				[ `SDRM_DATA-1: 0] 		zs_dq					,
		output  				[ `SDRM_BANK-1: 0] 		zs_ba					,
		output  wire		[ `SDRM_DQM -1: 0] 		zs_dqm				, 				
//		output           						za_valid				,      
//		output           						za_waitrequest	,	
		output  				[ `SDRM_DATA-1: 0] 		za_data				  					       
);


//  wire    [ 23: 0] CODE;
  reg              						ack_refresh_request;
	//ACTIVE   
  reg     [ `SDRM_ADDR-1: 0] 	active_addr;
  reg	    [ `SDRM_BANK-1: 0] 	active_bank;
  reg              						active_cs_n;
  reg     [ `SDRM_DATA-1: 0] 	active_data;
  reg     [ `SDRM_DQM -1: 0]  active_dqm	;
  reg              						active_rnw;
  //FIFO
  wire             						almost_empty;
  wire             						almost_full;
  wire    [ `SDRM_ADDR-1: 0] 	f_addr;
  wire    [ `SDRM_BANK-1: 0] 	f_bank;
  wire             						f_cs_n;
  wire    [ `SDRM_DATA-1: 0]	f_data;
  wire    [ `SDRM_DQM -1: 0] 	f_dqm;
  wire             						f_empty;
  reg              						f_pop;
  wire             						f_rnw;
  wire             						f_select;

  
  wire    [ `SDRM_ADDR-1: 0] 	cas_addr;
  wire             						clk_en;
  wire    [  3: 0] 						cmd_all;
  wire    [  2: 0] 						cmd_code;
  wire             						cs_n;
  wire             						csn_decode;
  wire             						csn_match;

  wire    [ `SDRM_BUS-1: 0] 	fifo_read_data;
  reg     [ `SDRM_ADDR-1: 0] 	i_addr;
  reg     [  3: 0] i_cmd;
  reg     [  3: 0] i_count;
  reg     [  2: 0] i_next;
  reg     [  2: 0] i_refs;
  reg     [  2: 0] i_state;
  reg              init_done;
  reg     [ `SDRM_ADDR-1: 0] m_addr /* synthesis ALTERA_ATTRIBUTE = "FAST_OUTPUT_REGISTER=ON"  */;
  reg     [ `SDRM_BANK-1: 0] m_bank /* synthesis ALTERA_ATTRIBUTE = "FAST_OUTPUT_REGISTER=ON"  */;
  reg     [  3: 0] m_cmd /* synthesis ALTERA_ATTRIBUTE = "FAST_OUTPUT_REGISTER=ON"  */;
  reg     [  3: 0] m_count;
  reg     [ `SDRM_DATA-1: 0] m_data /* synthesis ALTERA_ATTRIBUTE = "FAST_OUTPUT_REGISTER=ON ; FAST_OUTPUT_ENABLE_REGISTER=ON"  */;
  reg     [  3: 0] m_dqm /* synthesis ALTERA_ATTRIBUTE = "FAST_OUTPUT_REGISTER=ON"  */;
  reg     [  8: 0] m_next;
  reg     [  8: 0] m_state;
  reg              oe /* synthesis ALTERA_ATTRIBUTE = "FAST_OUTPUT_ENABLE_REGISTER=ON"  */;
  wire             pending;
  wire             rd_strobe;
  reg     [  2: 0] rd_valid;
  reg     [ `SDRM_ADDR: 0] refresh_counter;
  reg              refresh_request;
  
  wire             bank_match;
  wire             rnw_match;
  wire             row_match;
  wire    [ 23: 0] txt_code;
  
//  reg              						za_cannotrefresh;
  reg     [ `SDRM_DATA-1: 0] 	za_data /* synthesis ALTERA_ATTRIBUTE = "FAST_INPUT_REGISTER=ON"  */;
//  reg              za_valid;
  wire             						za_waitrequest;
  wire    [ `SDRM_ADDR-1: 0] 	zs_addr;
  wire    [ `SDRM_BANK-1: 0] 	zs_ba;
  wire             						zs_cas_n;
  wire             						zs_cke;
  wire    [ `SDRM_DATA-1: 0] 	zs_dq;
  wire             						zs_ras_n;
  wire             						zs_we_n;

  //combination logic

  //fifo 
  assign f_select = f_pop & pending;											//fifo read enable										
  assign f_cs_n = 1'b0;																		//FIFO always chip select effective
  assign cs_n = f_select ? f_cs_n : active_cs_n;					
  assign csn_decode = cs_n;
  assign {f_rnw, f_bank[`SDRM_BANK-1: 0], f_addr[`SDRM_ADDR-1: 0], f_dqm[`SDRM_DQM-1:0], f_data[`SDRM_DATA-1:0]} = fifo_read_data;
  
  sdram_fifo 		sdram_fifo_inst
    (
      .clock        (clk),
      .rdreq        (f_select),
      .wrreq        ((~az_wr_n | ~az_rd_n) & !za_waitrequest),
      .data      		(3'b0, {az_wr_n,az_ba[`SDRM_BANK-1:0],az_addr[`SDRM_ADDR-1:0],(az_wr_n?{`SDRM_DQM{1'b0}}:az_dqm[`SDRM_DQM-1:0]),az_data[`SDRM_DATA-1:0]}),

      .almost_empty (almost_empty),
      .almost_full  (almost_full),
      .empty        (f_empty),
      .full         (za_waitrequest),
      .q      			(fifo_read_data),
      .usedw				()
     );
	
  // Refresh/init counter.
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          refresh_counter <= 12000;
      else if (refresh_counter == 0)
          refresh_counter <= 1874;
      else 
        refresh_counter <= refresh_counter - 1'b1;
    end

  // Refresh request signal.
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          refresh_request <= 0;
      else if (1)
          refresh_request <= ((refresh_counter == 0) | refresh_request) & ~ack_refresh_request & init_done;
    end

//  // Generate an Interrupt if two ref_reqs occur before one ack_refresh_request
//  always @(posedge clk or negedge reset_n)
//    begin
//      if (reset_n == 0)
//          za_cannotrefresh <= 0;
//      else if (1)
//          za_cannotrefresh <= (refresh_counter == 0) & refresh_request;
//    end


  // **** Init FSM ****
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
        begin
          i_state <= 3'b000;
          i_next <= 3'b000;
          i_cmd <= 4'b1111;
          i_addr <= {`SDRM_ADDR{1'b1}};
          i_count <= {4{1'b0}};
        end
      else 
        begin
          i_addr <= {`SDRM_ADDR{1'b1}};
          case (i_state) // synthesis parallel_case full_case
          
              3'b000: begin
                  i_cmd <= 4'b1111;								//Command suspend
                  i_refs <= 3'b0;
                  //Wait for refresh count-down after reset
                  if (refresh_counter == 0)
                      i_state <= 3'b001;
              end // 3'b000 
          
              3'b001: begin
                  i_state <= 3'b011;
                  i_cmd <= {{1{1'b0}},3'h2};			//Precharge all banks
                  i_count <= 2;
                  i_next <= 3'b010;
              end // 3'b001 
          
              3'b010: begin
                  i_cmd <= {{1{1'b0}},3'h1};			//Auto refresh
                  i_refs <= i_refs + 1'b1;
                  i_state <= 3'b011;
                  i_count <= 8;										//wait until tRP(166MHz=>15ns) pass
                  // Count up init_refresh_commands
                  if (i_refs == 3'h1)							//auto refresh twice
                      i_next <= 3'b111;						
                  else 
                    i_next <= 3'b010;
              end // 3'b010 
          
              3'b011: begin
                  i_cmd <= {{1{1'b0}},3'h7};			//No operation
                  //WAIT til safe to Proceed...
                  if (i_count > 1)
                      i_count <= i_count - 1'b1;	//delay
                  else 
                    i_state <= i_next;
              end // 3'b011 
          
              3'b101: begin
                  i_state <= 3'b101;
              end // 3'b101 
          
              3'b111: begin												//mode register update
                  i_state <= 3'b011;
                  i_cmd <= {{1{1'b0}},3'h0};			//Mode register write
                  i_addr <= {{3{1'b0}},1'b0,2'b00,3'h3,4'h0};
                  										//OP_code		//CAS latency=3		//burst length=0
                  i_count <= 4;										//wait 4 clock
                  i_next <= 3'b101;
              end // 3'b111 
          
              default: begin
                  i_state <= 3'b000;
              end // default
          
          endcase // i_state
        end
    end

  // Initialization-done flag.
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          init_done <= 0;
      else if (1)
          init_done <= init_done | (i_state == 3'b101);
    end
        
  assign csn_match = active_cs_n == f_cs_n;
  assign rnw_match = active_rnw == f_rnw;
  assign bank_match = active_bank == f_bank;
  assign row_match = {active_addr[22 : 10]} == {f_addr[22 : 10]};
  assign pending = csn_match && rnw_match && bank_match && row_match && !f_empty;	//fifo not empty, 
  
  assign cas_addr = f_select ? f_addr : active_addr ;
  // **** Main FSM ****
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
        begin
          m_state <= 9'b000000001;
          m_next 	<= 9'b000000001;
          m_cmd 	<= 4'b1111;
          m_bank 	<= 2'b00;
          m_addr 	<= {`SDRM_ADDR{1'b0}};
          m_data 	<= 32'b00000000000000000000000000000000;
          m_dqm 	<= 4'b0000;
          m_count <= 4'b0000;
          ack_refresh_request <= 1'b0;
          f_pop 	<= 1'b0;
          oe 			<= 1'b0;
        end
      else 
        begin
          f_pop <= 1'b0;
          oe 		<= 1'b0;
          case (m_state) // synthesis parallel_case full_case
          
              9'b000000001: begin
                  //Wait for init-fsm to be done...
                  if (init_done)
                    begin
                      //Hold bus if another cycle ended to arf.
                      if (refresh_request)
                          m_cmd <= {{1{1'b0}},3'h7};		//cs_n
                      else 
                        	m_cmd <= 4'b1111;
                      ack_refresh_request <= 1'b0;
                      //Wait for a read/write request.
                      if (refresh_request)							//ack refresh request
                        begin
                          m_state <= 9'b001000000;
                          m_next 	<= 9'b010000000;
                          m_count <= 2;
                          active_cs_n <= 1'b1;
                        end
                      else if (!f_empty)								//when fifo is not empty
                        begin
                          f_pop <= 1'b1;								//
                          active_cs_n <= f_cs_n;
                          active_rnw 	<= f_rnw;
                          active_addr <= f_addr;
                          active_bank <= f_bank;
                          active_data <= f_data;
                          active_dqm 	<= f_dqm;
                          m_state 		<= 9'b000000010;
                        end
                    end
                  else 
                    begin
                      m_addr 	<= i_addr;
                      m_state <= 9'b000000001;
                      m_next 	<= 9'b000000001;
                      m_cmd 	<= i_cmd;
                    end
              end // 9'b000000001 
          
              9'b000000010: begin
                  m_state <= 9'b000000100;
                  m_cmd <= {csn_decode,3'h3};
                  m_bank <= active_bank;
                  m_addr <= active_addr[22 : 10];
                  m_data <= active_data;
                  m_dqm <= active_dqm;
                  m_count <= 3;
                  m_next <= active_rnw ? 9'b000001000 : 9'b000010000;
              end // 9'b000000010 
          
              9'b000000100: begin
                  // precharge all if arf, else precharge csn_decode
                  if (m_next == 9'b010000000)
                      m_cmd <= {{1{1'b0}},3'h7};
                  else 
                    	m_cmd <= {csn_decode,3'h7};
                  //Count down til safe to Proceed...
                  if (m_count > 1)
                      m_count <= m_count - 1'b1;
                  else 
                    m_state <= m_next;
              end // 9'b000000100 
          
              9'b000001000: begin
                  m_cmd <= {csn_decode,3'h5};
                  m_bank <= f_select ? f_bank : active_bank;
                  m_dqm <= f_select ? f_dqm  : active_dqm;
                  m_addr <= cas_addr;
                  //Do we have a transaction pending?
                  if (pending)
                    begin
                      //if we need to ARF, bail, else spin
                      if (refresh_request)
                        begin
                          m_state <= 9'b000000100;
                          m_next <= 9'b000000001;
                          m_count <= 2;
                        end
                      else 
                        begin
                          f_pop <= 1'b1;
                          active_cs_n <= f_cs_n;
                          active_rnw <= f_rnw;
                          active_addr <= f_addr;
                          active_data <= f_data;
                          active_dqm <= f_dqm;
                        end
                    end
                  else 
                    begin
                      //correctly end RD spin cycle if fifo mt
                      if (~pending & f_pop)
                          m_cmd <= {csn_decode,3'h7};
                      m_state <= 9'b100000000;
                    end
              end // 9'b000001000 
          
              9'b000010000: begin
                  m_cmd <= {csn_decode,3'h4};
                  oe <= 1'b1;
                  m_data <= f_select ? f_data : active_data;
                  m_dqm <= f_select ? f_dqm  : active_dqm;
                  m_bank <= f_select ? f_bank : active_bank;
                  m_addr <= cas_addr;
                  //Do we have a transaction pending?
                  if (pending)
                    begin
                      //if we need to ARF, bail, else spin
                      if (refresh_request)
                        begin
                          m_state <= 9'b000000100;
                          m_next <= 9'b000000001;
                          m_count <= 2;
                        end
                      else 
                        begin
                          f_pop <= 1'b1;
                          active_cs_n <= f_cs_n;
                          active_rnw <= f_rnw;
                          active_addr <= f_addr;
                          active_data <= f_data;
                          active_dqm <= f_dqm;
                        end
                    end
                  else 
                    begin
                      //correctly end WR spin cycle if fifo empty
                      if (~pending & f_pop)
                        begin
                          m_cmd <= {csn_decode,3'h7};
                          oe <= 1'b0;
                        end
                      m_state <= 9'b100000000;
                    end
              end // 9'b000010000 
          
              9'b000100000: begin
                  m_cmd <= {csn_decode,3'h7};
                  //Count down til safe to Proceed...
                  if (m_count > 1)
                      m_count <= m_count - 1'b1;
                  else 
                    begin
                      m_state <= 9'b001000000;
                      m_count <= 2;
                    end
              end // 9'b000100000 
          
              9'b001000000: begin				//refresh
                  m_state <= 9'b000000100;
                  m_addr <= {`SDRM_ADDR{1'b1}};
                  // precharge all if arf, else precharge csn_decode
                  if (refresh_request)
                      m_cmd <= {{1{1'b0}},3'h2};	//cs_n=0,ras_n=0,cas_n=1,we_n=0; Precharge all Banks
                  else 
                    	m_cmd <= {csn_decode,3'h2};
              	end // 9'b001000000 
          
              9'b010000000: begin
                  ack_refresh_request <= 1'b1;
                  m_state <= 9'b000000100;
                  m_cmd <= {{1{1'b0}},3'h1};
                  m_count <= 8;
                  m_next <= 9'b000000001;
              end // 9'b010000000 
          
              9'b100000000: begin
                  m_cmd <= {csn_decode,3'h7};
                  //if we need to ARF, bail, else spin
                  if (refresh_request)
                    begin
                      m_state <= 9'b000000100;
                      m_next <= 9'b000000001;
                      m_count <= 1;
                    end
                  else //wait for fifo to have contents
                  if (!f_empty)
                      //Are we 'pending' yet?
                      if (csn_match && rnw_match && bank_match && row_match)
                        begin
                          m_state <= f_rnw ? 9'b000001000 : 9'b000010000;
                          f_pop <= 1'b1;
                          active_cs_n <= f_cs_n;
                          active_rnw <= f_rnw;
                          active_addr <= f_addr;
                          active_data <= f_data;
                          active_dqm <= f_dqm;
                        end
                      else 
                        begin
                          m_state <= 9'b000100000;
                          m_next <= 9'b000000001;
                          m_count <= 1;
                        end
              end // 9'b100000000 
          
              // synthesis translate_off
          
              default: begin
                  m_state <= m_state;
                  m_cmd <= 4'b1111;
                  f_pop <= 1'b0;
                  oe <= 1'b0;
              end // default
          
              // synthesis translate_on
          endcase // m_state
        end
    end


  assign rd_strobe = m_cmd[2 : 0] == 3'h5;
  //Track RD Req's based on cas_latency w/shift reg
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          rd_valid <= {3{1'b0}};
      else 
        rd_valid <= (rd_valid << 1) | { {2{1'b0}}, rd_strobe };
    end


  // Register dq data.
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          za_data <= 0;
      else 
        	za_data <= zs_dq;
    end

  //before output
  assign {zs_cs_n, zs_ras_n, zs_cas_n, zs_we_n} = m_cmd;	//Command 
  assign zs_addr = m_addr;																//Address
  assign clk_en = 1;			assign zs_cke = clk_en;					//clock allways enable
  assign zs_dq = oe?m_data:{`SDRM_DATA{1'bz}};						//Data
  assign zs_dqm = m_dqm;																	//Data mask
  assign zs_ba = m_bank;																	//Bank
  
//  // Delay za_valid to match registered data.
//  always @(posedge clk or negedge reset_n)
//    begin
//      if (reset_n == 0)
//          za_valid <= 0;
//      else if (1)
//          za_valid <= rd_valid[2];
//    end

//	For simulation
//  assign cmd_code = m_cmd[2 : 0];
//  assign cmd_all = m_cmd;
//
////synthesis translate_off
////////////////// SIMULATION-ONLY CONTENTS
//  assign txt_code = (cmd_code == 3'h0)? 24'h4c4d52 :
//    (cmd_code == 3'h1)? 24'h415246 :
//    (cmd_code == 3'h2)? 24'h505245 :
//    (cmd_code == 3'h3)? 24'h414354 :
//    (cmd_code == 3'h4)? 24'h205752 :
//    (cmd_code == 3'h5)? 24'h205244 :
//    (cmd_code == 3'h6)? 24'h425354 :
//    (cmd_code == 3'h7)? 24'h4e4f50 :
//    24'h424144;
//
//  assign CODE = &(cmd_all|4'h7) ? 24'h494e48 : txt_code;

//////////////// END SIMULATION-ONLY CONTENTS

//synthesis translate_on

endmodule

