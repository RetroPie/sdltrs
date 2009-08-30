# Project: sdltrs

CC   = gcc
OBJ  = blit.o debug.o dis.o error.o load_cmd.o load_hex.o main.o trs_mkdisk.o trs_cassette.o trs_chars.o trs_disk.o trs_hard.o trs_imp_exp.o trs_interrupt.o trs_io.o trs_memory.o trs_printer.o trs_rom1.o trs_rom3.o trs_rom4p.o trs_sdl_gui.o trs_sdl_interface.o trs_sdl_keyboard.o trs_state_save.o trs_uart.o z80.o sdltrs_main.o
LINKOBJ  = blit.o debug.o dis.o error.o load_cmd.o load_hex.o main.o trs_mkdisk.o trs_cassette.o trs_chars.o trs_disk.o trs_hard.o trs_imp_exp.o trs_interrupt.o trs_io.o trs_memory.o trs_printer.o trs_rom1.o trs_rom3.o trs_rom4p.o trs_sdl_gui.o trs_sdl_interface.o trs_sdl_keyboard.o trs_state_save.o  trs_uart.o z80.o sdltrs_main.o
LIBS =  -lSDL   
INCS =  
BIN  = sdltrs
CFLAGS = $(INCS) -g 

.PHONY: all all-before all-after clean clean-custom

all: all-before sdltrs all-after


clean: clean-custom
	rm -f $(OBJ) $(BIN)

$(BIN): $(OBJ)
	$(CC) $(LINKOBJ) -o "sdltrs" $(LIBS)

blit.o: ../blit.c
	$(CC) -c ../blit.c -o blit.o $(CFLAGS)
	
debug.o: ../debug.c
	$(CC) -c ../debug.c -o debug.o $(CFLAGS)

dis.o: ../dis.c
	$(CC) -c ../dis.c -o dis.o $(CFLAGS)

error.o: ../error.c
	$(CC) -c ../error.c -o error.o $(CFLAGS)

load_cmd.o: ../load_cmd.c
	$(CC) -c ../load_cmd.c -o load_cmd.o $(CFLAGS)

load_hex.o: ../load_hex.c
	$(CC) -c ../load_hex.c -o load_hex.o $(CFLAGS)

main.o: ../main.c
	$(CC) -c ../main.c -o main.o $(CFLAGS)

trs_mkdisk.o: ../trs_mkdisk.c
	$(CC) -c ../trs_mkdisk.c -o trs_mkdisk.o $(CFLAGS)

trs_cassette.o: ../trs_cassette.c
	$(CC) -c ../trs_cassette.c -o trs_cassette.o $(CFLAGS)

trs_chars.o: ../trs_chars.c
	$(CC) -c ../trs_chars.c -o trs_chars.o $(CFLAGS)

trs_disk.o: ../trs_disk.c
	$(CC) -c ../trs_disk.c -o trs_disk.o $(CFLAGS)

trs_hard.o: ../trs_hard.c
	$(CC) -c ../trs_hard.c -o trs_hard.o $(CFLAGS)

trs_imp_exp.o: ../trs_imp_exp.c
	$(CC) -c ../trs_imp_exp.c -o trs_imp_exp.o $(CFLAGS)

trs_interrupt.o: ../trs_interrupt.c
	$(CC) -c ../trs_interrupt.c -o trs_interrupt.o $(CFLAGS)

trs_io.o: ../trs_io.c
	$(CC) -c ../trs_io.c -o trs_io.o $(CFLAGS)

trs_memory.o: ../trs_memory.c
	$(CC) -c ../trs_memory.c -o trs_memory.o $(CFLAGS)

trs_printer.o: ../trs_printer.c
	$(CC) -c ../trs_printer.c -o trs_printer.o $(CFLAGS)

trs_rom1.o: ../trs_rom1.c
	$(CC) -c ../trs_rom1.c -o trs_rom1.o $(CFLAGS)

trs_rom3.o: ../trs_rom3.c
	$(CC) -c ../trs_rom3.c -o trs_rom3.o $(CFLAGS)

trs_rom4p.o: ../trs_rom4p.c
	$(CC) -c ../trs_rom4p.c -o trs_rom4p.o $(CFLAGS)

trs_sdl_gui.o: ../trs_sdl_gui.c
	$(CC) -c ../trs_sdl_gui.c -o trs_sdl_gui.o $(CFLAGS)

trs_sdl_interface.o: ../trs_sdl_interface.c
	$(CC) -c ../trs_sdl_interface.c -o trs_sdl_interface.o $(CFLAGS)

trs_sdl_keyboard.o: ../trs_sdl_keyboard.c
	$(CC) -c ../trs_sdl_keyboard.c -o trs_sdl_keyboard.o $(CFLAGS)

trs_state_save.o: ../trs_state_save.c
	$(CC) -c ../trs_state_save.c -o trs_state_save.o $(CFLAGS)

trs_uart.o: ../trs_uart.c
	$(CC) -c ../trs_uart.c -o trs_uart.o $(CFLAGS)

z80.o: ../z80.c
	$(CC) -c ../z80.c -o z80.o $(CFLAGS)

sdltrs_main.o: ../sdltrs_main.c
	$(CC) -c ../sdltrs_main.c -o sdltrs_main.o $(CFLAGS)

