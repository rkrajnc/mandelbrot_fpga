// ============================================================================
// Copyright (c) 2012 by Terasic Technologies Inc.
// ============================================================================
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altera Development 
//   Kits made by Terasic.  Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use 
//   or functionality of this code.
//
// ============================================================================
//           
//  Terasic Technologies Inc
//  9F., No.176, Sec.2, Gongdao 5th Rd, East Dist, Hsinchu City, 30070. Taiwan
//
//
//
//                     web: http://www.terasic.com/
//                     email: support@terasic.com
//
// ============================================================================

/*

Function: 
	ADV7513 Video and Audio Control 
	
I2C Configuration Requirements:
	Master Mode
	I2S, 16-bits
	
Clock:
	input Clock 1.536MHz (48K*Data_Width*Channel_Num)
	
Revision:
	1.0, 10/06/2014, Init by Nick
	
Compatibility:
	Quartus 14.0.2

*/




module AUDIO_IF(
	//
  enable,
	reset_n,
	sclk,
	lrclk,
	i2s,
	clk
);

/*****************************************************************************
 *                           Constant Declarations                           *
 *****************************************************************************/


/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/

	//
output						sclk;	
output 						lrclk;
input 						reset_n;
output	[3:0]				i2s;
input 						clk;
input             enable;

parameter	DATA_WIDTH					=	16;
parameter	SIN_SAMPLE_DATA			=	48;
/*****************************************************************************
 *                 Internal wires and registers Declarations                 *
 *****************************************************************************/

reg    				      lrclk;
reg 	[5:0]					sclk_Count;
reg   [5:0]				   Simple_count;
reg 	[15:0]				Data_Bit;
reg 	[6:0]					Data_Count;
reg	[5:0]				   SIN_Cont;
reg	[3:0]					i2s;
/*****************************************************************************
 *                             Sequential logic                              *
 *****************************************************************************/
assign sclk = clk;

always@(negedge  sclk or negedge reset_n)
begin
	if(!reset_n)
	begin
	  lrclk<=0;
	  sclk_Count<=0;
	end
	
	else if(sclk_Count>=DATA_WIDTH-1)
	begin
	  sclk_Count <= 0;
	  lrclk <= ~lrclk;
	end
	else 
     sclk_Count <= sclk_Count + 1;
end
 
always@(negedge sclk or negedge reset_n)
begin
  if(!reset_n)
  begin
    Data_Count <= 0;
  end
  else
  begin
    if(Data_Count >= DATA_WIDTH-1)
	 begin
      Data_Count <= 0;
    end
	 else 
	 Data_Count <= Data_Count +1;
  end
end

always@(negedge sclk or negedge reset_n)
begin
  if(!reset_n)
  begin
    i2s <= 0;
  end
  else
  begin
    i2s[0] <= Data_Bit[~Data_Count];
	 i2s[1] <= Data_Bit[~Data_Count];
	 i2s[2] <= Data_Bit[~Data_Count];
	 i2s[3] <= Data_Bit[~Data_Count];
  end
end

always@(negedge lrclk or negedge reset_n)
begin
	if(!reset_n)
	  SIN_Cont	<=	0;
	else if (enable)
	begin
		if(SIN_Cont < SIN_SAMPLE_DATA-1 )
		SIN_Cont	<=	SIN_Cont+1;
		else
		SIN_Cont	<=	0;
	end
end

/*****************************************************************************
 *                            Combinational logic                            *
 *****************************************************************************/
always@(SIN_Cont)
begin
	case(SIN_Cont)
    0  :   Data_Bit      <=   0    ;
    1  :   Data_Bit      <=   4    ;
    2  :   Data_Bit      <=   8    ;
    3  :   Data_Bit      <=   12   ;
    4  :   Data_Bit      <=   16   ;
    5  :   Data_Bit      <=   19   ;
    6  :   Data_Bit      <=   23   ;
    7  :   Data_Bit      <=   25   ;
    8  :   Data_Bit      <=   28   ;
    9  :   Data_Bit      <=   30   ;
    10  :  Data_Bit      <=   31   ;
    11  :  Data_Bit      <=   32   ;
    12  :  Data_Bit      <=   32   ;
    13  :  Data_Bit      <=   32   ;
    14  :  Data_Bit      <=   31   ;
    15  :  Data_Bit      <=   30   ;
    16  :  Data_Bit      <=   28   ;
    17  :  Data_Bit      <=   25   ;
    18  :  Data_Bit      <=   23   ;
    19  :  Data_Bit      <=   19   ;
    20  :  Data_Bit      <=   16   ;
    21  :  Data_Bit      <=   12   ;
    22  :  Data_Bit      <=   8    ;
    23  :  Data_Bit      <=   4    ;
    24  :  Data_Bit      <=   0    ;
    25  :  Data_Bit      <=   61   ;
    26  :  Data_Bit      <=   57   ;
    27  :  Data_Bit      <=   52   ;
    28  :  Data_Bit      <=   49   ;
    29  :  Data_Bit      <=   45   ;
    30  :  Data_Bit      <=   42   ;
    31  :  Data_Bit      <=   39   ;
    32  :  Data_Bit      <=   37   ;
    33  :  Data_Bit      <=   35   ;
    34  :  Data_Bit      <=   33   ;
    35  :  Data_Bit      <=   33   ;
    36  :  Data_Bit      <=   32   ;
    37  :  Data_Bit      <=   33   ;
    38  :  Data_Bit      <=   33   ;
    39  :  Data_Bit      <=   35   ;
    40  :  Data_Bit      <=   37   ;
    41  :  Data_Bit      <=   39   ;
    42  :  Data_Bit      <=   42   ;
    43  :  Data_Bit      <=   45   ;
    44  :  Data_Bit      <=   49   ;
    45  :  Data_Bit      <=   52   ;
    46  :  Data_Bit      <=   57   ;
    47  :  Data_Bit      <=   61   ;
	default	:
		   Data_Bit		<=		0		;
	endcase
	
end
endmodule


