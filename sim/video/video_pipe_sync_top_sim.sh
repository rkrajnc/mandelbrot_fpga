#!/bin/sh

NAME="VIDEO_PIPE_SYNC_TOP_TB"

echo "$NAME BENCH : starting ..."

# dirs
echo "$NAME BENCH : making dirs ..."
rm -rf out/
mkdir -p out/{wav,hex,bin,log,arg}

# build sim
echo "$NAME BENCH : building sim ..."
iverilog -g2012 -I ../../rtl/video/ ../../rtl/memory/rom_generic_sp.v ../../rtl/memory/ram_generic_tp.v ../../rtl/video/video_sync_gen.v ../../rtl/video/video_pipe_sync_top.v ../../tb/video/video_pipe_sync_top_tb.sv -o out/bin/video_pipe_sync_top_tb
if (($? != 0)); then
  echo "$NAME : FAILED building sim, exiting."
  exit 1
fi

# run sim
echo "$NAME BENCH : running sim ..."
vvp out/bin/video_pipe_sync_top_tb -fst
if (($? != 0)); then
  echo "$NAME : FAILED running sim, exiting."
  exit 1
fi

