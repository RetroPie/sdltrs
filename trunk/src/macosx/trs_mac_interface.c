/* Copyright (c): 2006, Mark Grebe */

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
   Last modified on Wed May 07 09:12:00 MST 2006 by markgrebe
*/

#include <stdlib.h>
#include "SDL/SDL.h"
#include "string.h"
#include "trs.h"
#include "trs_disk.h"
#include "trs_mac_interface.h"
#include "trs_sdl_gui.h"
#include "trs_state_save.h"
#include "trs_uart.h"

extern void PreferencesSaveDefaults(void);

MAC_PREFS mac_prefs;

void trs_handle_mac_events(SDL_Event *event)
{
    char *filename;
    int modelIndex;
    int model;
    int graphics;
    
    switch(event->user.code) {
        case MAC_CHANGE_MODEL_EVENT:
            modelIndex = (int) event->user.data1;
            switch(modelIndex) {
                case 0:
                default:
                    model = 1;
                    break;
                case 1:
                    model = 3;
                    break;
                case 2:
                    model = 4;
                    break;
                case 3:
                    model = 5;
                    break;
            }
            if (model != trs_model) {
                trs_model = model;
                trs_gui_new_machine();
                UpdateMediaManagerInfo();
            }
            break;    
        case MAC_CHANGE_GRAPHICS_EVENT: 
            graphics = (int) event->user.data1;
            if (graphics != grafyx_get_microlabs()) {
                grafyx_set_microlabs(graphics);
                trs_gui_new_machine();
                UpdateMediaManagerInfo();
            }
            break;    
        case MAC_LOAD_STATE_EVENT:
            filename = (char *) event->user.data1;
            trs_state_load(filename);
			free(filename);
            trs_screen_init();
            grafyx_redraw();
            trs_screen_refresh();
            trs_x_flush();
            break;    
        case MAC_SAVE_STATE_EVENT:      
            filename = (char *) event->user.data1;
            trs_state_save(filename);
            break;    
        case MAC_READ_CONFIG_EVENT: 
            filename = (char *) event->user.data1;
            trs_load_config_file(filename);
			free(filename);
            trs_screen_init();
            grafyx_redraw();
            trs_screen_refresh();
            trs_x_flush();
            break;    
        case MAC_WRITE_CONFIG_EVENT:
            filename = (char *) event->user.data1;
            trs_write_config_file(filename);
            break;    
    }
}

static void trs_set_emu_values(MAC_PREFS *mac_prefs)
{
	int i;
	
	// Display Items
	fullscreen = mac_prefs->fullscreen;
	scale_x = mac_prefs->scale_x;
	scale_y = scale_x*2;
	window_border_width = mac_prefs->border_width;
	resize3 = mac_prefs->resize3;
	resize4 = mac_prefs->resize4;
	foreground = mac_prefs->foreground;
	background = mac_prefs->background;
	gui_foreground = mac_prefs->gui_foreground;
	gui_background = mac_prefs->gui_background;
	trs_show_led = mac_prefs->trs_show_led;
	trs_charset1 = mac_prefs->trs_charset1;
	trs_charset3 = mac_prefs->trs_charset3;
	trs_charset4 = mac_prefs->trs_charset4;
	mediaStatusWindowOpen = mac_prefs->mediaStatusWindowOpen;

	// TRS Items
	trs_model = mac_prefs->trs_model;
	grafyx_set_microlabs(mac_prefs->micrographyx);
	trs_kb_bracket(mac_prefs->shiftbracket);
	timer_overclock = mac_prefs->turbo;
	timer_overclock_rate = mac_prefs->turbo_rate;
	stretch_amount = mac_prefs->stretch_amount;
	trs_uart_switches = mac_prefs->switches;
	strcpy(trs_uart_name, mac_prefs->serial_port);
    for (i=0;i<8;i++) {
        if (mac_prefs->disk_sizes[i] == 0) 
            trs_disk_setsize(i,5);
        else
            trs_disk_setsize(i,8);
   }
    trs_disk_doubler = mac_prefs->trs_disk_doubler;
    trs_disk_truedam = mac_prefs->trs_disk_truedam;
    trs_emtsafe = mac_prefs->trs_emtsafe;
	
	// Printer Items
	strcpy(trs_printer_command, mac_prefs->print_command);
	trs_printer = mac_prefs->trs_printer;
	
	// ROM Items
	strcpy(romfile, mac_prefs->romfile);
	strcpy(romfile3, mac_prefs->romfile3);
	strcpy(romfile4p, mac_prefs->romfile4p);
	
	// Dir Items
	strcpy(trs_disk_dir, mac_prefs->trs_disk_dir);
	strcpy(trs_hard_dir, mac_prefs->trs_hard_dir);
	strcpy(trs_cass_dir, mac_prefs->trs_cass_dir);
	strcpy(trs_disk_set_dir, mac_prefs->trs_disk_set_dir);
	strcpy(trs_state_dir, mac_prefs->trs_state_dir);
	strcpy(trs_printer_dir, mac_prefs->trs_printer_dir);
	
	// Joystick Items
	trs_keypad_joystick = mac_prefs->trs_keypad_joystick;
	trs_joystick_num = mac_prefs->trs_joystick_num;
}


static void trs_get_emu_values(MAC_PREFS *mac_prefs)
{
	int i;
	
	// Display Items
	mac_prefs->fullscreen = fullscreen;
	mac_prefs->scale_x = scale_x;
	mac_prefs->border_width = window_border_width;
	mac_prefs->resize3 = resize3;
	mac_prefs->resize4 = resize4;
	mac_prefs->foreground = foreground;
	mac_prefs->background = background;
	mac_prefs->gui_foreground = gui_foreground;
	mac_prefs->gui_background = gui_background;
	mac_prefs->trs_show_led = trs_show_led;
	mac_prefs->trs_charset1 = trs_charset1;
	mac_prefs->trs_charset3 = trs_charset3;
	mac_prefs->trs_charset4 = trs_charset4;
	mac_prefs->mediaStatusWindowOpen = mediaStatusWindowOpen;

	// TRS Items
	mac_prefs->trs_model = trs_model;
	mac_prefs->micrographyx = grafyx_get_microlabs();
	mac_prefs->shiftbracket = trs_kb_bracket_state;
	mac_prefs->turbo = timer_overclock;
	mac_prefs->turbo_rate = timer_overclock_rate;
	mac_prefs->stretch_amount = stretch_amount;
	mac_prefs->switches = trs_uart_switches;
	strcpy(mac_prefs->serial_port,trs_uart_name);
    for (i=0;i<8;i++) {
        if (trs_disk_getsize(i) == 5) 
            mac_prefs->disk_sizes[i] = 0;
        else
            mac_prefs->disk_sizes[i] = 1;
    }
    mac_prefs->trs_disk_doubler = trs_disk_doubler;
    mac_prefs->trs_disk_truedam = trs_disk_truedam;
    mac_prefs->trs_emtsafe = trs_emtsafe;
	
	// Printer Items
	strcpy(mac_prefs->print_command, trs_printer_command);
	mac_prefs->trs_printer = trs_printer;
	
	// ROM Items
	strcpy(mac_prefs->romfile, romfile);
	strcpy(mac_prefs->romfile3, romfile3);
	strcpy(mac_prefs->romfile4p, romfile4p);
	
	// Dir Items
	strcpy(mac_prefs->trs_disk_dir, trs_disk_dir);
	strcpy(mac_prefs->trs_hard_dir, trs_hard_dir);
	strcpy(mac_prefs->trs_cass_dir, trs_cass_dir);
	strcpy(mac_prefs->trs_disk_set_dir, trs_disk_set_dir);
	strcpy(mac_prefs->trs_state_dir, trs_state_dir);
	strcpy(mac_prefs->trs_printer_dir, trs_printer_dir);
	
	// Joystick Items
	mac_prefs->trs_keypad_joystick = trs_keypad_joystick;
	mac_prefs->trs_joystick_num = trs_joystick_num;
}

MAC_PREFS *trs_mac_prefs_location()
{
    return(&mac_prefs);
}

void trs_get_mac_prefs()
{
	GetPreferences();
	trs_set_emu_values(&mac_prefs);
	PrintOutputControllerSelectPrinter(trs_printer);
}

void trs_run_mac_prefs()
{
	int new_machine = 0;
	int new_graphics = 0;
	
    trs_get_emu_values(&mac_prefs);
	RunPreferences();
	if (trs_model != mac_prefs.trs_model) {
		new_machine = 1;
		}
	else if ((trs_charset1 != mac_prefs.trs_charset1) ||
           (trs_charset3 != mac_prefs.trs_charset3) ||
           (trs_charset4 != mac_prefs.trs_charset4) ||
           (scale_x != mac_prefs.scale_x) ||
           (fullscreen != mac_prefs.fullscreen) ||
           (foreground != mac_prefs.foreground) ||
           (background != mac_prefs.background) ||
           (gui_foreground != mac_prefs.gui_foreground) ||
           (gui_background != mac_prefs.gui_background) ||
           (trs_show_led != mac_prefs.trs_show_led) ||
           (resize3 != mac_prefs.resize3) ||
           (resize4 != mac_prefs.resize4) ||
           (window_border_width != mac_prefs.border_width))
		{
		new_graphics = 1;
		}

	trs_set_emu_values(&mac_prefs);
	if (new_machine) {
		trs_gui_new_machine();
		}
	else if (new_graphics) {
		trs_screen_init();
		grafyx_redraw();
		}
	trs_screen_caption(trs_timer_is_turbo());
}

void trs_mac_save_defaults(void)
{
	trs_get_emu_values(&mac_prefs);
	PreferencesSaveDefaults();
}

