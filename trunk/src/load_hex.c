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
   Modified by Timothy Mann, 1996
   Modified by Mark Grebe, 2006
   Last modified on Wed May 07 09:12:00 MST 2006 by markgrebe
*/

#include "z80.h"
#include <stdlib.h>

#define BUFFER_SIZE 256

extern void hex_transfer_address(int address);
extern void hex_data(int address, int value);

static int hex_byte(char *string)
{
    char buf[3];

    buf[0] = string[0];
    buf[1] = string[1];
    buf[2] = '\0';

    return(strtol(buf, (char **)NULL, 16));
}
    
int load_hex(FILE *file)
{
    char buffer[BUFFER_SIZE];
    char *b;
    int num_bytes;
    int address;
    int check;
    int value;
    int high = 0;

    while(fgets(buffer, BUFFER_SIZE, file))
    {
	if(buffer[0] == ':')
	{
	    /* colon */
	    b = buffer + 1;

	    /* number of bytes on the line */
	    num_bytes = hex_byte(b);  b += 2;
	    check = num_bytes;

	    /* the starting address */
	    address = hex_byte(b) << 8;  b += 2;
	    address |= hex_byte(b);  b+= 2;
	    check += (address >> 8) + (address & 0xff);

	    /* a zero? */
	    b += 2;

	    /* the data */
	    if(num_bytes == 0)
	    {
		/* Transfer address */
		hex_transfer_address(address);
	    } else {
		while(num_bytes--)
		{
		    value = hex_byte(b);  b += 2;
		    hex_data(address++, value);
		    check += value;
		}
		if (address > high) high = address;

		/* the checksum */
		value = hex_byte(b);
		if(((0x100 - check) & 0xff) != value)
		{
		    return(-1);
		}
	    }
	}
    }
    return high;
}
