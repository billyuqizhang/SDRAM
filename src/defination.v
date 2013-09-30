/*
 * File Name:  defination.v
 * Version:  2.1
 * Date:  Sept 22, 2013
 * Description:  MICRO parameter defination
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
`define SDRM_ADDR 13
`define SDRM_DATA 16
`define SDRM_BANK 2 
`define SDRM_DQM	2   
`define SDRM_BUS	33	//(SDRM_ADDR+SDRM_DATA+SDRM_BANK+SDRM_DQM)
               
`define CYCLE     8                   
`define HALF_CYCLE `CYCLE/2                   
                   
        	           
