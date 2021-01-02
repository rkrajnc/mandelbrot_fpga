TARGET=mandelbrot_calc_params

CC=gcc
CFLAGS=-Wall -O3 -std=c99

.PHONY: all
all: $(TARGET)

$(TARGET): $(TARGET).c Makefile
	@$(CC) $(CFLAGS) $< -o $@

.PHONY: clean
clean:
	@rm -f $(TARGET)

