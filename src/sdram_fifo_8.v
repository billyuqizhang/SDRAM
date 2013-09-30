/*
 * File Name:  sdram_fifo_8.v
 * Version:  2.1
 * Date:  Sept 22, 2013
 * Description:  SDRAM FIFO 8 depth
 * 							This design is based on Altera Qsys generator design
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
`include "../src/defination.v"

module sdram_fifo_8 (
  // inputs:
  input   wire	         					clk						,
  input   wire	         					reset_n				,
  input   wire	         					rd						,
  input   wire	         					wr						,
  input   wire	[ `SDRM_BUS-1: 0] wr_data				,
  // outputs:
  output  wire		         				almost_empty	,
  output  wire		         				almost_full		,
  output  wire		         				empty					,
  output  wire	         					full					,
  output  reg		[ `SDRM_BUS-1: 0] rd_data
  );

  reg     [  3: 0] 					entries;
  reg     [ `SDRM_BUS-1: 0] entry_0, entry_1, entry_2, entry_3;
  reg     [ `SDRM_BUS-1: 0] entry_4, entry_5, entry_6, entry_7;
  reg     [  2: 0]          rd_address;

  wire    [  1: 0] 					rdwr;
  reg     [  3: 0]         	wr_address;
  
  assign rdwr = {rd, wr};
  assign full = entries == 8;
  assign almost_full = entries >= 4;
  assign empty = entries == 0;
  assign almost_empty = entries <= 4;
  
  always @(entry_0 or entry_1 or entry_2 or entry_3 or entry_4 or entry_5 or entry_6 or entry_7 or rd_address)
    begin
      case (rd_address) // synthesis parallel_case full_case      
          4'd0: begin		rd_data = entry_0;	end // 1'd0       
          4'd1: begin   rd_data = entry_1;  end // 1'd1 
          4'd2: begin		rd_data = entry_2;	end // 1'd2       
          4'd3: begin   rd_data = entry_3;  end // 1'd3 
          4'd4: begin		rd_data = entry_4;	end // 1'd4       
          4'd5: begin   rd_data = entry_5;  end // 1'd5 
          4'd6: begin		rd_data = entry_6;	end // 1'd6       
          4'd7: begin   rd_data = entry_7;  end // 1'd7                           
          default: begin          end // default
      
      endcase // rd_address
    end


  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
        begin
          wr_address <= 0;
          rd_address <= 0;
          entries <= 0;
        end
      else 
        case (rdwr) // synthesis parallel_case full_case
        
            2'd1: begin
                // Write data
                if (full==0)
                  begin
                    entries <= entries + 1;
                    wr_address <= (wr_address == 7) ? 0 : (wr_address + 1);
                  end
            end // 2'd1 
        
            2'd2: begin
                // Read data
                if (empty==0)
                  begin
                    entries <= entries - 1;
                    rd_address <= (rd_address == 7) ? 0 : (rd_address + 1);
                  end
            end // 2'd2 
        
            2'd3: begin
                wr_address <= (wr_address == 7) ? 0 : (wr_address + 1);
                rd_address <= (rd_address == 7) ? 0 : (rd_address + 1);
            end // 2'd3 
        
            default: begin
            end // default
        
        endcase // rdwr
    end


  always @(posedge clk)
    begin
      //Write data
      if (wr & !full)
          case (wr_address) // synthesis parallel_case full_case
          
              4'd0: begin		entry_0 <= wr_data;		end // 1'd0           
              4'd1: begin   entry_1 <= wr_data;   end // 1'd1 
              4'd2: begin		entry_2 <= wr_data;		end // 1'd2 
              4'd3: begin   entry_3 <= wr_data;   end // 1'd3 
              4'd4: begin		entry_4 <= wr_data;		end // 1'd4 
              4'd5: begin   entry_5 <= wr_data;   end // 1'd5 
              4'd6: begin		entry_6 <= wr_data;		end // 1'd6 
              4'd7: begin   entry_7 <= wr_data;   end // 1'd7 
         
              default: begin
              end // default
          
          endcase // wr_address
    end



endmodule