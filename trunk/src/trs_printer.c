/* SDLTRS version Copyright (c): 2006, Mark Grebe */

/* Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
*/
/*
 * Copyright (C) 1992 Clarendon Hill Software.
 *
 * Permission is granted to any individual or institution to use, copy,
 * or redistribute this software, provided this copyright notice is retained. 
 *
 * This software is provided "as is" without any expressed or implied
 * warranty.  If this software brings on any sort of damage -- physical,
 * monetary, emotional, or brain -- too bad.  You've got no one to blame
 * but yourself. 
 *
 * The software may be modified for your own purposes, but modified versions
 * must retain this notice.
 */
/*
   Modified by Mark Grebe, 2006
   Last modified on Wed May 07 09:12:00 MST 2006 by markgrebe
*/

#include "z80.h"
#include "trs.h"
#include <stdlib.h>
#include <sys/stat.h>

#ifdef MACOSX  
extern void PrintOutputControllerPrintChar(unsigned char byte);
#endif  

static FILE *printer = NULL;
static char printer_filename[FILENAME_MAX];
static int printer_open = FALSE;
int trs_printer = NO_PRINTER;

int trs_printer_reset(void)
{
  char command[256 + FILENAME_MAX]; /* 256 for print_command + FILENAME_MAX for spool_file */
  
  if (printer_open) {
    fclose(printer);
    printer_open = FALSE;
    sprintf(command, trs_printer_command, printer_filename);
    system(command);
    return(0);
  } else
    return(-1);
}

void trs_printer_open(void)
{
  int file_num;
  struct stat st;
  
  for (file_num = 0; file_num < 10000; file_num++) {
    sprintf(printer_filename, "trsprn%04d.txt", file_num);
    if (stat(printer_filename, &st) < 0) {
      printer_open = TRUE;
      printer = fopen(printer_filename,"w");
      return;
	}
  }
}

void trs_printer_write(value)
{
  if (trs_printer == TEXT_PRINTER) {
    if (!printer_open)
      trs_printer_open();
  
    if (printer_open) {  
      if(value == 0x0D){
	    fputc('\n',printer);
      } else {
  	  fputc(value,printer);
      }
    }
  }
#ifdef MACOSX  
  else if (trs_printer == EPSON_PRINTER) {
    PrintOutputControllerPrintChar(value);
  }
#endif  
}

int trs_printer_read()
{
    return 0x30;	/* printer selected, ready, with paper, not busy */
}
