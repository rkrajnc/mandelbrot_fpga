// video_text_console.v
// video text console generator
// 2020, Rok Krajnc <rok.krajnc@gmail.com>


module video_text_console #(
  parameter TW  = 80, // console text width in characters
  parameter TH  = 2,  // console text height in characters
  parameter MAW = 8,  // console memory address width
  parameter MDW = 8,  // console memory data width
  parameter HCW = 12, // horizontal counter width
  parameter VCW = 12, // vertical counter width
  parameter CCW = 8   // color component width
)(
  // system
  input  wire           clk,            // video clock
  input  wire           clk_en,         // video clock enable
  input  wire           rst,            // video clock reset
  // control
  input  wire           en,             // enable console
  // console ram write interface
  input  wire           con_clk_w,      // console memory write clock
  input  wire           con_clk_en_w,   // console memory clock enable
  input  wire           con_we,         // console memory write enable
  input  wire [MAW-1:0] con_adr_w,      // console memory write address
  input  wire [MDW-1:0] con_dat_w,      // console memory write data
  // video counters
  input  wire           active,
  input  wire           a_start,
  input  wire           a_end,
  input  wire [HCW-1:0] h_cnt,          // horizontal counter
  input  wire [VCW-1:0] v_cnt,          // vertical counter
  // video output
  output wire [CCW-1:0] con_r,          // video red component
  output wire [CCW-1:0] con_g,          // video green component
  output wire [CCW-1:0] con_b           // video blue component
);


//// local parameters ////
localparam FW  = 8;  // font width in pixels
localparam FH  = 8;  // font height in pixels
localparam CPW    = TW*FW;          // console pixel width
localparam CPH    = TH*FH;          // console pixel height
localparam NCHARS = TW*TH;          // number of chars in text console
localparam CHW    = $clog2(NCHARS); // character counter width


//// console character memory read ////
wire [   3-1:0] char_h_cnt;
wire [   3-1:0] char_v_cnt;
reg  [ CHW-1:0] char_cnt;
reg  [ CHW-1:0] char_line_cnt;

assign char_h_cnt = h_cnt[2:0];
assign char_v_cnt = v_cnt[2:0];

always @ (posedge clk, posedge rst) begin
  if (rst) begin
    char_cnt <= #1 'd0;
    char_line_cnt <= #1 'd0;
  end else if (clk_en) begin
    if (a_end) begin
      char_cnt <= #1 'd0;
      char_line_cnt <= #1 'd0;
    end else if ((h_cnt < CPW) && (v_cnt < CPH) && (char_h_cnt == (FW-1))) begin
      // last character pixel inside valid coordinates
      if ((char_v_cnt != (FH-1)) && (char_line_cnt == (TW-1))) begin
        // at the last character in line and while inside same character line, reset counter to beginning of same line
        char_cnt <= #1 char_cnt - (TW-1);
        char_line_cnt <= #1 'd0;
      end else if ((char_v_cnt == (FH-1)) && (char_line_cnt == (TW-1))) begin
        // at the last character in line, move to the first character in next line
        char_cnt <= #1 char_cnt + 'd1;
        char_line_cnt <= #1 'd0;
      end else begin
        // in all other cases, increment character counter to next character in line (and also to the first character in next line!)
        char_cnt <= #1 char_cnt + 'd1;
        char_line_cnt <= #1 char_line_cnt + 'd1;
      end
    end
  end
end


//// console character memory ////
wire            con_rd;     // video ram read enable
wire [ MAW-1:0] con_adr_r;  // video ram read address
wire [ MDW-1:0] con_dat_r;  // video ram read data

assign con_rd = 1'b1;
assign con_adr_r = char_cnt;

ram_generic_tp #(
  .MI               (""),     // memory initialization file
  .READ_REGISTERED  (0),      // when true, read port has an additional register
  .DW               (MDW),    // data width
  .MD               (NCHARS), // memory depth
  .AW               (CHW)     // address width
) console_text_ram (
  .clk_w    (con_clk_w    ),  // write clock
  .clk_en_w (con_clk_en_w ),  // write clock enable
  .we       (con_we       ),  // write enable
  .adr_w    (con_adr_w    ),  // write address
  .dat_w    (con_dat_w    ),  // write data
  .clk_r    (clk          ),  // read clock
  .clk_en_r (clk_en       ),  // read clock enable
  .rd       (con_rd       ),  // read enable
  .adr_r    (con_adr_r    ),  // read address
  .dat_r    (con_dat_r    )   // read data
);

integer i;
initial begin
  //for (i=0; i<NCHARS; i++) console_text_ram.mem[i] = i+32;
  for (i=0; i<NCHARS; i++) console_text_ram.mem[i] = 0;
  console_text_ram.mem[0] = "x";
  console_text_ram.mem[1] = "=";
  console_text_ram.mem[2] = "2";
  console_text_ram.mem[3] = ".";
  console_text_ram.mem[4] = "6";
  console_text_ram.mem[5] = "8";
  console_text_ram.mem[6] = "3";
  console_text_ram.mem[7] = "8";
  console_text_ram.mem[8] = "3";
  console_text_ram.mem[9] = "1";
  console_text_ram.mem[10] = "7";
  console_text_ram.mem[11] = "7";
  console_text_ram.mem[12] = "4";
  console_text_ram.mem[13] = "3";
  console_text_ram.mem[14] = "2";
  console_text_ram.mem[15] = "5";
  console_text_ram.mem[16] = "6";
  console_text_ram.mem[17] = "7";
  console_text_ram.mem[18] = "8";
  console_text_ram.mem[19] = "0";
  console_text_ram.mem[20] = "1";
  console_text_ram.mem[80+0] = "y";
  console_text_ram.mem[80+1] = "=";
  console_text_ram.mem[80+2] = "1";
  console_text_ram.mem[80+3] = ".";
  console_text_ram.mem[80+4] = "4";
  console_text_ram.mem[80+5] = "7";
  console_text_ram.mem[80+6] = "6";
  console_text_ram.mem[80+7] = "3";
  console_text_ram.mem[80+8] = "7";
  console_text_ram.mem[80+9] = "3";
  console_text_ram.mem[80+10] = "2";
  console_text_ram.mem[80+11] = "5";
  console_text_ram.mem[80+12] = "7";
  console_text_ram.mem[80+13] = "4";
  console_text_ram.mem[80+14] = "2";
  console_text_ram.mem[80+15] = "7";
  console_text_ram.mem[80+16] = "9";
  console_text_ram.mem[80+17] = "2";
  console_text_ram.mem[80+18] = "6";
  console_text_ram.mem[80+19] = "7";
  console_text_ram.mem[80+20] = "1";

end


//// font memory ////
localparam FONT_MI = "../../roms/font_rom.hex";
localparam FONT_DW = 8;
localparam FONT_MD = 128*8;
localparam FONT_AW = $clog2(FONT_MD);

reg  [     HCW-1:0] h_cnt_r_0;
reg  [     HCW-1:0] h_cnt_r_1;
reg  [     HCW-1:0] h_cnt_r_2;
reg  [     VCW-1:0] v_cnt_r_0;
reg  [     VCW-1:0] v_cnt_r_1;
reg  [     VCW-1:0] v_cnt_r_2;
wire                font_rd;
wire [ FONT_AW-1:0] font_adr;
wire [ FONT_DW-1:0] font_dat_r;
wire                font_pixel;

always @ (posedge clk) begin
  h_cnt_r_0 <= #1 h_cnt;
  h_cnt_r_1 <= #1 h_cnt_r_0;
  h_cnt_r_2 <= #1 h_cnt_r_1;
  v_cnt_r_0 <= #1 v_cnt;
  v_cnt_r_1 <= #1 v_cnt_r_0;
  v_cnt_r_2 <= #1 v_cnt_r_1;
end

assign font_rd  = 1'b1;
assign font_adr = {con_dat_r[7-1:0], v_cnt_r_1[2:0]};

rom_generic_sp #(
  .MI (FONT_MI),  // memory initialization file
  .DW (FONT_DW),  // data width
  .MD (FONT_MD),  // memory depth
  .AW (FONT_AW)   // address width
) font_rom (
  .clk    (clk        ), // clock
  .clk_en (clk_en     ), // clock enable
  .rd     (font_rd    ), // read enable
  .adr    (font_adr   ), // read address
  .dat_r  (font_dat_r )  // read data
);

assign font_pixel = font_dat_r[h_cnt_r_2[2:0]];

assign con_r = font_pixel && (h_cnt_r_2 < CPW) && (v_cnt_r_2 < CPH) ? 8'hff : 8'h00;
assign con_g = font_pixel && (h_cnt_r_2 < CPW) && (v_cnt_r_2 < CPH) ? 8'hff : 8'h00;
assign con_b = font_pixel && (h_cnt_r_2 < CPW) && (v_cnt_r_2 < CPH) ? 8'hff : 8'h00;


endmodule

