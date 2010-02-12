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
#include <SDL/SDL.h>

#define MAC_CHANGE_MODEL_EVENT      1
#define MAC_CHANGE_GRAPHICS_EVENT   2
#define MAC_LOAD_STATE_EVENT        3
#define MAC_SAVE_STATE_EVENT        4
#define MAC_READ_CONFIG_EVENT       5
#define MAC_WRITE_CONFIG_EVENT      6

typedef struct mac_prefs {
	// Display items
	int fullscreen;
	int scale_x;
	int border_width;
	int resize3;
	int resize4;
	int foreground;
	int background;
	int gui_foreground;
	int gui_background;
	int trs_show_led;
	int trs_charset1;
	int trs_charset3;
	int trs_charset4;
	int mediaStatusWindowOpen;
	// TRS items
	int trs_model;
	int micrographyx;
	int shiftbracket;
	int stretch_amount;
	int switches;
	char serial_port[FILENAME_MAX];
    int disk_sizes[8];
    int trs_disk_doubler;
    int trs_disk_truedam;
	int trs_emtsafe;
	int turbo;
	int turbo_rate;
	// Printer Items
	char print_command[256];
	int trs_printer;
	// ROM Items
	char romfile[FILENAME_MAX];
	char romfile3[FILENAME_MAX];
	char romfile4p[FILENAME_MAX];
	// Dir Items
	char trs_disk_dir[FILENAME_MAX];
	char trs_hard_dir[FILENAME_MAX];
	char trs_cass_dir[FILENAME_MAX];
	char trs_disk_set_dir[FILENAME_MAX];
	char trs_state_dir[FILENAME_MAX];
	char trs_printer_dir[FILENAME_MAX];
	// Joystick Itmes
	int trs_keypad_joystick;
	int trs_joystick_num;
	} MAC_PREFS;

extern int mediaStatusWindowOpen;

void trs_handle_mac_events(SDL_Event *event);
void trs_run_mac_prefs();
void trs_get_mac_prefs();
MAC_PREFS *trs_mac_prefs_location();
void trs_mac_save_defaults();

void RunPreferences();
void ReturnPreferences(MAC_PREFS *mac_prefs);
void GetPreferences();

void UpdateMediaManagerInfo();
void MediaManagerRunDiskManagement();
void MediaManagerRunHardManagement();
void MediaManagerRunCassManagement();
void MediaManagerInsertDisk(int diskNum);
void MediaManagerRemoveDisk(int diskNum);
void MediaManagerStatusLed(int diskNo, int on);
void MediaManagerStatusWindowShow(void);

void SetControlManagerModel(int model, int micrographyx);
void SetControlManagerTurboMode(int turbo);
void ControlManagerSaveState();
void ControlManagerLoadState();
void ControlManagerWriteConfig();
void ControlManagerReadConfig();
void ControlManagerPauseEmulator();
void ControlManagerHideApp();
void ControlManagerAboutApp();
void ControlManagerShowHelp();
void ControlManagerMiniturize();

void PrintOutputControllerSelectPrinter(int printer);

void TrsOriginRestore();
void TrsOriginSave();
void TrsOriginSet();
void TrsWindowCreate(int w, int h);
void TrsWindowDisplay();
void TrsWindowResize(int w, int h);
int TrsIsKeyWindow(void);
int TrsWindowMouseInside();
	
