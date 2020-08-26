TARGET=mandelbrot_simple

CC=gcc
CFLAGS=-Wall -O3

.PHONY: all
all: $(TARGET)

$(TARGET): $(TARGET).c Makefile
	@$(CC) $(CFLAGS) $< -o $@

.PHONY: clean
clean:
	@rm -f $(TARGET)
	@rm -f mandelbrot.ppm

