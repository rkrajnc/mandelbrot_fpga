TARGET1=mandelbrot_simple
TARGET2=mandelbrot_fp

CC=gcc
CFLAGS=-Wall -O3 -fopenmp

.PHONY: all
all: $(TARGET1) $(TARGET2)

$(TARGET1): $(TARGET1).c Makefile
	@$(CC) $(CFLAGS) $< -o $@

$(TARGET2): $(TARGET2).c Makefile
	@$(CC) $(CFLAGS) $< -o $@

.PHONY: clean
clean:
	@rm -f $(TARGET1)
	@rm -f $(TARGET2)
	@rm -f mandelbrot.ppm

