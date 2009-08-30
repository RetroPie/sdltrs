# Project: sdltrs
# Makefile created by Dev-C++ 4.9.9.2

CPP  = g++.exe
CC   = gcc.exe
WINDRES = windres.exe
RES  = 
OBJ  = ../win32/debug.o ../win32/dis.o ../win32/error.o ../win32/load_cmd.o ../win32/load_hex.o ../win32/main.o ../win32/trs_cassette.o ../win32/trs_chars.o ../win32/trs_disk.o ../win32/trs_hard.o ../win32/trs_imp_exp.o ../win32/trs_interrupt.o ../win32/trs_io.o ../win32/trs_memory.o ../win32/trs_printer.o ../win32/trs_rom1.o ../win32/trs_rom3.o ../win32/trs_rom4p.o ../win32/trs_sdl_gui.o ../win32/trs_sdl_interface.o ../win32/trs_sdl_keyboard.o ../win32/trs_uart.o ../win32/z80.o ../win32/sdltrs_main.o ../win32/trs_state_save.o ../win32/trs_mkdisk.o ../win32/blit.o ../win32/PasteManager.o $(RES)
LINKOBJ  = ../win32/debug.o ../win32/dis.o ../win32/error.o ../win32/load_cmd.o ../win32/load_hex.o ../win32/main.o ../win32/trs_cassette.o ../win32/trs_chars.o ../win32/trs_disk.o ../win32/trs_hard.o ../win32/trs_imp_exp.o ../win32/trs_interrupt.o ../win32/trs_io.o ../win32/trs_memory.o ../win32/trs_printer.o ../win32/trs_rom1.o ../win32/trs_rom3.o ../win32/trs_rom4p.o ../win32/trs_sdl_gui.o ../win32/trs_sdl_interface.o ../win32/trs_sdl_keyboard.o ../win32/trs_uart.o ../win32/z80.o ../win32/sdltrs_main.o ../win32/trs_state_save.o ../win32/trs_mkdisk.o ../win32/blit.o ../win32/PasteManager.o $(RES)
LIBS =  -L"C:/SDL-1.2.13/lib" -lmingw32 -lSDLmain -lSDL  
INCS =  -I"C:/SDL-1.2.13/include" 
CXXINCS =  -I"C:/Dev-Cpp/include/c++"  -I"C:/Dev-Cpp/include/c++/mingw32"  -I"C:/Dev-Cpp/include/c++/backward"  -I"C:/Dev-Cpp/include" 
BIN  = sdltrs.exe
CXXFLAGS = $(CXXINCS)  
CFLAGS = $(INCS) -g -DWIN32 -mno-cygwin   
RM = rm -f

.PHONY: all all-before all-after clean clean-custom

all: all-before sdltrs.exe all-after


clean: clean-custom
	${RM} $(OBJ) $(BIN)

$(BIN): $(OBJ)
	$(CC) $(LINKOBJ) -o "sdltrs.exe" $(LIBS)

../win32/debug.o: ../debug.c
	$(CC) -c ../debug.c -o ../win32/debug.o $(CFLAGS)

../win32/dis.o: ../dis.c
	$(CC) -c ../dis.c -o ../win32/dis.o $(CFLAGS)

../win32/error.o: ../error.c
	$(CC) -c ../error.c -o ../win32/error.o $(CFLAGS)

../win32/load_cmd.o: ../load_cmd.c
	$(CC) -c ../load_cmd.c -o ../win32/load_cmd.o $(CFLAGS)

../win32/load_hex.o: ../load_hex.c
	$(CC) -c ../load_hex.c -o ../win32/load_hex.o $(CFLAGS)

../win32/main.o: ../main.c
	$(CC) -c ../main.c -o ../win32/main.o $(CFLAGS)

../win32/trs_cassette.o: ../trs_cassette.c
	$(CC) -c ../trs_cassette.c -o ../win32/trs_cassette.o $(CFLAGS)

../win32/trs_chars.o: ../trs_chars.c
	$(CC) -c ../trs_chars.c -o ../win32/trs_chars.o $(CFLAGS)

../win32/trs_disk.o: ../trs_disk.c
	$(CC) -c ../trs_disk.c -o ../win32/trs_disk.o $(CFLAGS)

../win32/trs_hard.o: ../trs_hard.c
	$(CC) -c ../trs_hard.c -o ../win32/trs_hard.o $(CFLAGS)

../win32/trs_imp_exp.o: ../trs_imp_exp.c
	$(CC) -c ../trs_imp_exp.c -o ../win32/trs_imp_exp.o $(CFLAGS)

../win32/trs_interrupt.o: ../trs_interrupt.c
	$(CC) -c ../trs_interrupt.c -o ../win32/trs_interrupt.o $(CFLAGS)

../win32/trs_io.o: ../trs_io.c
	$(CC) -c ../trs_io.c -o ../win32/trs_io.o $(CFLAGS)

../win32/trs_memory.o: ../trs_memory.c
	$(CC) -c ../trs_memory.c -o ../win32/trs_memory.o $(CFLAGS)

../win32/trs_printer.o: ../trs_printer.c
	$(CC) -c ../trs_printer.c -o ../win32/trs_printer.o $(CFLAGS)

../win32/trs_rom1.o: ../trs_rom1.c
	$(CC) -c ../trs_rom1.c -o ../win32/trs_rom1.o $(CFLAGS)

../win32/trs_rom3.o: ../trs_rom3.c
	$(CC) -c ../trs_rom3.c -o ../win32/trs_rom3.o $(CFLAGS)

../win32/trs_rom4p.o: ../trs_rom4p.c
	$(CC) -c ../trs_rom4p.c -o ../win32/trs_rom4p.o $(CFLAGS)

../win32/trs_sdl_gui.o: ../trs_sdl_gui.c
	$(CC) -c ../trs_sdl_gui.c -o ../win32/trs_sdl_gui.o $(CFLAGS)

../win32/trs_sdl_interface.o: ../trs_sdl_interface.c
	$(CC) -c ../trs_sdl_interface.c -o ../win32/trs_sdl_interface.o $(CFLAGS)

../win32/trs_sdl_keyboard.o: ../trs_sdl_keyboard.c
	$(CC) -c ../trs_sdl_keyboard.c -o ../win32/trs_sdl_keyboard.o $(CFLAGS)

../win32/trs_uart.o: ../trs_uart.c
	$(CC) -c ../trs_uart.c -o ../win32/trs_uart.o $(CFLAGS)

../win32/z80.o: ../z80.c
	$(CC) -c ../z80.c -o ../win32/z80.o $(CFLAGS)

../win32/sdltrs_main.o: ../sdltrs_main.c
	$(CC) -c ../sdltrs_main.c -o ../win32/sdltrs_main.o $(CFLAGS)

../win32/trs_state_save.o: ../trs_state_save.c
	$(CC) -c ../trs_state_save.c -o ../win32/trs_state_save.o $(CFLAGS)

../win32/trs_mkdisk.o: ../trs_mkdisk.c
	$(CC) -c ../trs_mkdisk.c -o ../win32/trs_mkdisk.o $(CFLAGS)

../win32/blit.o: ../blit.c
	$(CC) -c ../blit.c -o ../win32/blit.o $(CFLAGS)
        
../win32/PasteManager.o: ../win32/PasteManager.c
	$(CC) -c ../win32/PasteManager.c -o ../win32/PasteManager.o $(CFLAGS)

