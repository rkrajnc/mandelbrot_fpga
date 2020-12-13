// video_text_console.v
// video text console generator
// in regards to video counter inputs, this module will produce its outputs 4 clocks later (so, a latency of 4 clk cycles)
// 2020, Rok Krajnc <rok.krajnc@gmail.com>


module video_text_console #(
  parameter TW  = 80, // console text width in characters
  parameter TH  = 2,  // console text height in characters
  parameter MAW = 8,  // console memory address width
  parameter MDW = 8,  // console memory data width
  parameter HCW = 12, // horizontal counter width
  parameter VCW = 12  // vertical counter width
)(
  // system
  input  wire           clk,          // video clock
  input  wire           clk_en,       // video clock enable
  input  wire           rst,          // video clock reset
  // control
  input  wire           en,           // enable console
  // console ram write interface
  input  wire           con_clk_w,    // console memory write clock
  input  wire           con_clk_en_w, // console memory clock enable
  input  wire           con_we,       // console memory write enable
  input  wire [MAW-1:0] con_adr_w,    // console memory write address
  input  wire [MDW-1:0] con_dat_w,    // console memory write data
  // video counters
  input  wire           a_end,        // video sync active end
  input  wire [HCW-1:0] h_cnt,        // video sync horizontal counter
  input  wire [VCW-1:0] v_cnt,        // video sync vertical counter
  // video output
  output reg            con_active,   // video sync counters are in console area
  output reg            con_pixel     // current console pixel is foreground (font) when 1, background when 0
);


//// local parameters ////
localparam FW     = 8;              // font width in pixels
localparam FH     = 8;              // font height in pixels
localparam CPW    = TW*FW;          // console pixel width
localparam CPH    = TH*FH;          // console pixel height
localparam NCHARS = TW*TH;          // number of chars in text console
localparam CHW    = $clog2(NCHARS); // character counter width


//// delay of h_cnt / v_cnt signals ////
reg  [ HCW-1:0] h_cnt_r_0;
reg  [ HCW-1:0] h_cnt_r_1;
reg  [ HCW-1:0] h_cnt_r_2;
reg  [ VCW-1:0] v_cnt_r_0;
reg  [ VCW-1:0] v_cnt_r_1;
reg  [ VCW-1:0] v_cnt_r_2;

always @ (posedge clk) begin
  h_cnt_r_0 <= #1 h_cnt;
  h_cnt_r_1 <= #1 h_cnt_r_0;
  h_cnt_r_2 <= #1 h_cnt_r_1;
  v_cnt_r_0 <= #1 v_cnt;
  v_cnt_r_1 <= #1 v_cnt_r_0;
  v_cnt_r_2 <= #1 v_cnt_r_1;
end


//// console character memory read ////
wire [   3-1:0] char_h_cnt;
wire [   3-1:0] char_v_cnt;
reg  [ CHW-1:0] char_cnt;
reg  [ CHW-1:0] char_line_cnt;

// since we use 8x8 font, we can just use some lower bits of the input counters
assign char_h_cnt = h_cnt[2:0];
assign char_v_cnt = v_cnt[2:0];

// char_cnt is the index of the current character to be displayed
always @ (posedge clk, posedge rst) begin
  if (rst) begin
    char_cnt <= #1 'd0;
    char_line_cnt <= #1 'd0;
  end else if (clk_en) begin
    if (!en) begin
      char_cnt <= #1 'd0;
      char_line_cnt <= #1 'd0;
    end else if (a_end) begin
      char_cnt <= #1 'd0;
      char_line_cnt <= #1 'd0;
    end else if ((h_cnt < CPW) && (v_cnt < CPH) && (char_h_cnt == (FW-1))) begin
      // last character pixel inside valid coordinates
      if ((char_v_cnt != (FH-1)) && (char_line_cnt == (TW-1))) begin
        // at the last character in line and while inside same character line, reset counter to beginning of same line
        char_cnt <= #1 char_cnt - (TW-1);
        char_line_cnt <= #1 'd0;
      end else if ((char_v_cnt == (FH-1)) && (char_line_cnt == (TW-1)) && (char_cnt < (NCHARS-1))) begin
        // at the last character in line, move to the first character in next line
        char_cnt <= #1 char_cnt + 'd1;
        char_line_cnt <= #1 'd0;
      end else if (char_cnt < (NCHARS-1)) begin
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

assign con_rd = en;
assign con_adr_r = char_cnt;

ram_generic_tp #(
  .MI               (""     ),  // memory initialization file
  .READ_REGISTERED  (0      ),  // when true, read port has an additional register
  .DW               (MDW    ),  // data width
  .MD               (NCHARS ),  // memory depth
  .AW               (CHW    )   // address width
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


//// font memory ////
localparam FONT_MI = "../../roms/font_rom.hex";
localparam FONT_DW = 8;
localparam FONT_MD = 128*8;
localparam FONT_AW = $clog2(FONT_MD);

wire                font_rd;
wire [ FONT_AW-1:0] font_adr;
wire [ FONT_DW-1:0] font_dat_r;
wire                font_pixel;

assign font_rd  = en;
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

// current console pixel value (1=font, 0=background)
assign font_pixel = font_dat_r[h_cnt_r_2[2:0]];


//// outputs ////
always @ (posedge clk) begin
  if (clk_en) begin
    con_active <= #1 en && (h_cnt_r_2 < CPW) && (v_cnt_r_2 < CPH);
    con_pixel <= #1 font_pixel;
  end
end


endmodule

