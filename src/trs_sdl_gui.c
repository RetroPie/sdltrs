/*  Copyright (c): 2006, Mark Grebe */

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
   Modified by Mark Grebe, 2006
   Last modified on Wed May 07 09:12:00 MST 2006 by markgrebe
*/

#include <SDL/SDL.h>
#include <dirent.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#include "trs.h"
#include "trs_cassette.h"
#include "trs_disk.h"
#include "trs_hard.h"
#include "trs_uart.h"
#include "trs_state_save.h"
#include "trs_mkdisk.h"
#include "trs_sdl_gui.h"
#include "trs_sdl_keyboard.h"
#include "z80.h"

#ifdef _WIN32
#include <windows.h>
#endif

#define LEFT_VERT_LINE      149
#define RIGHT_VERT_LINE     170
#define TOP_HORIZ_LINE      131
#define BOTTOM_HORIZ_LINE   176
#define TOP_LEFT_CORNER     151
#define TOP_RIGHT_CORNER    171
#define BOTTOM_LEFT_CORNER  181
#define BOTTOM_RIGHT_CORNER 186 

#define MENU_NORMAL_TYPE          1
#define MENU_TITLE_TYPE           2
#define MENU_FLOPPY_BROWSE_TYPE   3
#define MENU_HARD_BROWSE_TYPE     4
#define MENU_CASS_BROWSE_TYPE     5

#ifdef MACOSX
#define MENU_MOD KMOD_META
#else
#define MENU_MOD KMOD_ALT
#endif

typedef struct menu_entry_type {
  char title[80];
  int type;
  int value;
} MENU_ENTRY;

static int local_trs_model;
static int local_trs_charset1;
static int local_trs_charset3;
static int local_trs_charset4;
static int local_foreground;
static int local_background;
static int local_gui_foreground;
static int local_gui_background;
static int gui_show_led;
static int gui_resize3;
static int gui_resize4;
static int gui_border_width;
static int gui_joystick_num;
static int gui_keypad_joystick;

extern void trs_gui_write_char(int position, int char_index, int invert);

static void trs_gui_write_text_len(char *text, int len, int x, int y, int invert);
static void trs_gui_write_text(char *text, int x, int y, int invert);
static void trs_gui_write_text_char(char text, int x, int y, int invert);
static void trs_gui_center_text(char *text, int y, int invert);
static void trs_gui_frame(int x, int y, int w, int h);
static void trs_gui_clear_rect(int x, int y, int w, int h);
static void trs_gui_limit_string(char *orig, char *limited, int limit);
static void trs_remove_dir(char *file, char *dir);
static void trs_add_extension(char *filename, char *ext);
static int trs_gui_get_key(void);
static void trs_gui_display_message(char* title, char *message);
static void trs_gui_create_filename_list();
static void trs_gui_add_to_filename_list(char * filename);
static int trs_gui_filename_cmp(char *name1, char *name2);
static void trs_gui_quicksort(char **start, char **end, int (*sort_function) ());
static void trs_gui_delete_filename_list(void);
static int trs_gui_readdirectory(char *path, int browse_dir);
static int trs_gui_input_string(char *title, char* input, char* output, int file);
static int trs_gui_display_popup(char* title, char **entry, 
                          int entry_count, int selection);
static int trs_gui_display_menu(char* title, MENU_ENTRY *entry, int selection);
static void trs_gui_hard_creation(void);
static void trs_gui_disk_creation(void);
static void trs_gui_cassette_creation(void);
static void trs_gui_disk_sizes(void);
#ifdef __linux
static void trs_gui_disk_steps(void);
#endif
static void trs_gui_disk_options(void);
static void trs_gui_display_management(void);
static void trs_gui_joystick_management(void);
static void trs_gui_misc_management(void);
static void trs_gui_printer_management(void);
static void trs_gui_model(void);
static void trs_gui_default_dirs(void);
static void trs_gui_rom_files(void);
static void trs_gui_about_sdltrs(void);
static int trs_gui_config_management(void);


void trs_gui_write_text_len(char *text, int len, int x, int y, int invert)
{
  int position = x + y * 64;
  int i;
  
  for (i=0;i<len;i++)
    trs_gui_write_char(position+i,text[i],invert);
}

void trs_gui_write_text(char *text, int x, int y, int invert)
{
  trs_gui_write_text_len(text, strlen(text), x, y, invert);
}

void trs_gui_write_text_char(char text, int x, int y, int invert)
{
  int position = x + y * 64;
  
  trs_gui_write_char(position,text,invert);
}

void trs_gui_center_text(char *text, int y, int invert)
{
  int position = (64-strlen(text))/2 + y * 64;
  int i;
  
  for (i=0;i<strlen(text);i++)
    trs_gui_write_char(position+i,text[i],invert);
}

void trs_gui_frame(int x, int y, int w, int h)
{
   int i;
   for (i=(x+1)+64*y; i<(x+w-1)+64*y; i++)
    trs_gui_write_char(i,TOP_HORIZ_LINE,0);
   for (i=(x+1)+64*(y+h-1); i<(x+w-1)+64*(y+h-1); i++)
    trs_gui_write_char(i,BOTTOM_HORIZ_LINE,0);
   for (i=x+64*(y+1); i<x+64*(y+h-1); i+=64)
    trs_gui_write_char(i,LEFT_VERT_LINE,0);
   for (i=(x+w-1)+64*(y+1); i<(x+w-1)+64*(y+h-1); i+=64)
    trs_gui_write_char(i,RIGHT_VERT_LINE,0);
   trs_gui_write_char(x+64*y,TOP_LEFT_CORNER,0);
   trs_gui_write_char((x+w-1)+64*y,TOP_RIGHT_CORNER,0);
   trs_gui_write_char(x+64*(y+h-1),BOTTOM_LEFT_CORNER,0);
   trs_gui_write_char((x+w-1)+64*(y+h-1),BOTTOM_RIGHT_CORNER,0);
}

void trs_gui_clear_rect(int x, int y, int w, int h)
{
     char clear[128];
     int i;
     
     for (i=0;i<w;i++)
       clear[i]=' ';
     clear[i] = 0;
     for (i=0;i<h;i++)
        trs_gui_write_text(clear, x, y+i, 0);
}

void trs_gui_limit_string(char *orig, char *limited, int limit)
{
  int len_first_part;
  int pos_second_part;
  
  if (strlen(orig) > limit) {
    len_first_part = (limit-3)/2;
    pos_second_part = strlen(orig) - (limit - len_first_part - 3);
	strncpy(limited, orig, len_first_part);
	limited[len_first_part] = '\0';
	strcat(limited, "...");
	strcat(limited, orig + pos_second_part);
  } else
    strcpy(limited, orig);
}

void trs_expand_dir(char *dir, char *expanded_dir)
{
  int i;

#ifdef _WIN32  
  if (dir[0] == '\\' || dir[1] == ':') {
#else
  if (dir[0] == '/' || dir[1] == ':') {
#endif             
    strcpy(expanded_dir, dir);
    return;
  }
  
  getcwd(expanded_dir,FILENAME_MAX);
#ifdef _WIN32  
  if (strncmp(dir,"..\\",3) == 0) {
#else                           
  if (strncmp(dir,"../",3) == 0) {
#endif
    dir += 3;
    for (i=strlen(expanded_dir)-1;i>0;i--) {
#ifdef _WIN32  
      if (expanded_dir[i] == '\\') {
#else                          
      if (expanded_dir[i] == '/') {
#endif                          
        expanded_dir[i]=0;
          break;
      }
    }  
  }
#ifdef _WIN32  
  else if (strncmp(dir,".\\",2) == 0) {
#else 
  else if (strncmp(dir,"./",2) == 0) {
#endif      
    dir += 2;
  }
  else if (strcmp(dir,".") == 0) {
    dir ++;
  }
#ifdef _WIN32  
  strcat(expanded_dir,"\\");
#else
  strcat(expanded_dir,"/");
#endif  
  strcat(expanded_dir, dir);
}

void trs_remove_dir(char *file, char *dir)
{
  int i;
  
  strcpy(dir, file);
  
    for (i=strlen(dir)-1;i>0;i--) {
#ifdef _WIN32        
      if (dir[i] == '\\') {
#else
      if (dir[i] == '/') {
#endif                 
        dir[i+1]=0;
        break;
      }
    }  
}

void trs_add_extension(char *filename, char *ext)
{
    int flen = strlen(filename);
    int elen = strlen(ext);
    
    if (flen > elen) {
      if (strcmp(&filename[flen - elen],ext) != 0)
         strcat(filename, ext);
    } else {
      strcat(filename, ext);
    }
}

int trs_gui_get_key(void)
{
   SDL_Event event;
   int done = 0;

   do {
     SDL_WaitEvent(&event);
     switch(event.type) {
       case SDL_QUIT:
         trs_exit();
         break;
       case SDL_ACTIVEEVENT:
         break;
       case SDL_KEYDOWN:
         if (event.key.keysym.mod & MENU_MOD)
           {
           switch (event.key.keysym.sym) {
#ifdef MACOSX
           case SDLK_q:
             trs_exit();
             break;
#endif             
#ifdef _WIN32
           case SDLK_F4:
             trs_exit();
             break;
#endif             
           case SDLK_RETURN:
             trs_flip_fullscreen();
             trs_gui_refresh();
             trs_x_flush();
             break;
           case SDLK_1:
             scale_x = 1;
             scale_y = 2;
             trs_screen_init();
             trs_gui_refresh();
             trs_x_flush();
             break;
          case SDLK_EQUALS:
            scale_x++;
            if (scale_x > MAX_SCALE)
              scale_x = 1;
            scale_y = scale_x * 2;
            trs_screen_init();
            trs_gui_refresh();
            trs_x_flush();
            break;
          case SDLK_MINUS:
            scale_x--;
            if (scale_x < 1)
              scale_x = MAX_SCALE;
            scale_y = scale_x * 2;
            trs_screen_init();
            trs_gui_refresh();
            trs_x_flush();
            break;
          default:
             break;
           }
         }
         else if (event.key.keysym.sym == SDLK_F8)
            trs_exit();
         else if (event.key.keysym.sym < 0x100 && 
               event.key.keysym.unicode >= 0x20 && 
               event.key.keysym.unicode <= 0x7E) 
             return(event.key.keysym.unicode);
         else 
           return(event.key.keysym.sym);
         break;
     }
   } while(!done);   
   return(0); 
}

void trs_gui_display_message(char* title, char *message)
{
  int key;
  int done = 0;
  trs_gui_frame(1,6,62,3);   
  trs_gui_clear_rect(2,7,60,1); 
  trs_gui_write_text(title, 3, 6, 0);
  trs_gui_write_text(message, 5, 7, 0);
  trs_x_flush();

  do {
    key = trs_gui_get_key();
    switch(key) {
      case SDLK_ESCAPE:
      case SDLK_RETURN:
        done = 1;
        break;
    }
  } while (!done);
}

void trs_gui_display_pause()
{
  trs_gui_frame(1,6,62,3);   
  trs_gui_clear_rect(2,7,60,1); 
  trs_gui_center_text("Emulation Paused", 7, 0);
  trs_x_flush();
}

static char **filenamelist = NULL;
static int filenamecount = 0;
static int filenamelistsize = 0;

void trs_gui_create_filename_list()
{
   if (filenamelist == NULL) {
      filenamelist = (char **) malloc(256 * sizeof(char *));
      filenamelistsize = 256;
   }
}

void trs_gui_add_to_filename_list(char * filename)
{
  filenamelist[filenamecount++] = filename;
  if (filenamecount == filenamelistsize) {
    filenamelist = (char **) realloc(filenamelist, 2 * 
                                     filenamelistsize * sizeof(char*));
    filenamelistsize *= 2;
  }
}

int trs_gui_filename_cmp(char *name1, char *name2)
{
#ifdef _WIN32
  /* Sort the drive letters last in the list */
  if (name1[0] == '[') {
    if (name2[0] == '[')
      return -1;
    else
      return 1;
  }
  if (name2[0] == '[')
    return -1;
#endif    
  if (name1[0] == '<') {
    if (name2[0] != '<')
      return -1;
    if (name1[1] == '.') {
      if (name2[1] != '.')
        return -1;
    }
    else if (name2[1] == '.')
      return 1;
  }
  else if (name2[0] == '<')
    return 1;

  return strcasecmp(name1, name2);   
}

void trs_gui_quicksort(char **start, char **end, int (*sort_function) ())
{
  while (start + 1 < end) {
	char **left = start + 1;
	char **right = end;
	char *pivot = *start;
	char *tmp;
    while (left < right) {
      if ((*sort_function)(*left, pivot) < 0)
        left++;
      else {
        right--;
        tmp = *left;
        *left = *right;
		*right = tmp;
      }
    }
    left--;
    tmp = *left;
    *left = *start;
    *start = tmp;
    trs_gui_quicksort(start, left, trs_gui_filename_cmp);
    start = right;
  }
}

void trs_gui_delete_filename_list(void)
{
  int i;
  
  for (i=0;i<filenamecount;i++)
    free(filenamelist[i]);
  filenamecount = 0;
}

int trs_gui_readdirectory(char *path, int browse_dir)
{
  DIR *directory = NULL;
  char pathname[FILENAME_MAX];
  int pathlen;
  char *filename;
  char *filename_pos;
  struct dirent *dir_entry;
  struct stat st;
  
  strcpy(pathname, path);
  pathlen = strlen(path);
  filename_pos = pathname + pathlen;
  
  directory = opendir(path);
  if (directory) {
    trs_gui_create_filename_list();
	while (dir_entry = readdir(directory)) {

	  if (strcmp(dir_entry->d_name, ".") == 0)
		continue;

      strcpy(filename_pos, dir_entry->d_name);	
      stat(pathname, &st);
      if (st.st_mode & S_IFDIR) {
        int dirname_len;
        dirname_len = strlen(dir_entry->d_name);
        if ( (filename = (char *) malloc(dirname_len + 3)) ) {
          filename[0] = '<';
          strcpy(filename + 1, dir_entry->d_name);
          filename[dirname_len + 1] = '>';
          filename[dirname_len + 2] = 0;
        } 
      }	else if (browse_dir){
        continue;
      }else {
        filename = (char *) strdup(dir_entry->d_name);
      }
      if (!filename) 
        return(-1);
      trs_gui_add_to_filename_list(filename);
    }
    closedir(directory);
#ifdef _WIN32
    {
	  char letter;
      DWORD drive_mask = GetLogicalDrives();
      for (letter = 'A'; letter <= 'Z'; letter++) {
        if (drive_mask & 1) {
		  static char drive[5] = "[C:]";
            drive[1] = letter;
			trs_gui_add_to_filename_list(strdup(drive));
			}
          drive_mask >>= 1;
		}
    }
#endif
    
    trs_gui_quicksort(filenamelist, filenamelist+filenamecount,
                      trs_gui_filename_cmp);
  }
  return(0);
}

int trs_gui_file_browse(char* path, char* filename, int browse_dir, char* type)
{
  int i,key;
  int selection = 0;
  int current_first = 0;
  int done = 0;
  int drawcount;
  char current_dir[FILENAME_MAX];
  char limited_dir[80];
  char title[64];
  int new_dir_len;
  char *new_dir;
  
  strcpy(current_dir, path);
#ifdef _WIN32  
  if (current_dir[strlen(current_dir)-1] != '\\')
    strcat(current_dir,"\\");
#else
  if (current_dir[strlen(current_dir)-1] != '/')
    strcat(current_dir,"/");
#endif    

  trs_gui_clear_screen();  
  trs_gui_frame(0,0,64,16);
  if (browse_dir) {
    sprintf(title,"Choose%sDirectory",type);
    trs_gui_center_text("Tab selects directory",14,1);
  }
  else
    sprintf(title,"Select%sFile To Load",type);
  trs_gui_write_text(title, 2, 0, 0);
  trs_gui_limit_string(current_dir, limited_dir, 62);
  trs_gui_center_text(limited_dir,1,0);
  trs_gui_readdirectory(current_dir, browse_dir);

  if (filenamecount < 12)
    drawcount = filenamecount;
  else
    drawcount = 12;
  trs_gui_write_text(filenamelist[0],2,2,1);
  for (i=1;i<drawcount;i++)
    trs_gui_write_text(filenamelist[i],2,2+i,0);
  trs_x_flush();

  do {
    key = trs_gui_get_key();
    if (key >= '0' && key <= 'z') {
      for (i=0;i<filenamecount-1;i++) {
        if (tolower(*filenamelist[i]) >= key)
          break;
      }
      if (filenamecount <= 12) {
        current_first = 0;
        selection = i;
      } else if (i + 12 > filenamecount) {
        current_first = filenamecount - 12;
        selection = i - current_first;
      } else {
        current_first = i;
        selection = 0;
      }
      trs_gui_clear_rect(2,2,60,12);
      for (i=0;i<drawcount;i++)
        trs_gui_write_text(filenamelist[current_first+i],2,2+i,0);
      trs_gui_write_text(filenamelist[current_first+selection],2,2+selection,1);
      trs_x_flush();
    } else {
      switch(key) {
        case SDLK_DOWN:
          if (selection < drawcount-1) {
            trs_gui_write_text(filenamelist[current_first + selection], 2, selection+2,0);
            selection ++;
            trs_gui_write_text(filenamelist[current_first + selection], 2, selection+2,1);
            trs_x_flush();
          } else {
            if (current_first < filenamecount-drawcount) {
              current_first++;
              trs_gui_clear_rect(2,2,60,12);
              for (i=0;i<drawcount-1;i++)
                 trs_gui_write_text(filenamelist[current_first+i],2,2+i,0);
              trs_gui_write_text(filenamelist[current_first+i],2,2+i,1);
              trs_x_flush();
            }
          }         
          break;
        case SDLK_UP:
         if (selection > 0) {
            trs_gui_write_text(filenamelist[current_first + selection], 2, selection+2,0);
            selection --;
            trs_gui_write_text(filenamelist[current_first + selection], 2, selection+2,1);
            trs_x_flush();
          }
          else {
            if (current_first > 0) {
              current_first--;
              trs_gui_clear_rect(2,2,60,12);
              trs_gui_write_text(filenamelist[current_first],2,2,1);
              for (i=1;i<drawcount;i++)
                trs_gui_write_text(filenamelist[current_first+i],2,2+i,0);
              trs_x_flush();
            }
          }        
          break;
        case SDLK_RETURN:
          if (*filenamelist[current_first + selection] == '<') {          
            new_dir = filenamelist[current_first + selection];
            new_dir_len = strlen(&new_dir[1]);
            selection = 0;
            current_first = 0;
          
            if (new_dir[1] == '.' && new_dir[2] == '.') {
              for (i=strlen(current_dir)-2;i>0;i--) {
#ifdef _WIN32                  
                if (current_dir[i] == '\\') {
#else
                if (current_dir[i] == '/') {
#endif                                   
                  current_dir[i+1]=0;
                  break;
                }
              }
            } else {
              strcat(current_dir, &new_dir[1]);
#ifdef _WIN32              
              current_dir[strlen(current_dir)-1] = '\\';
#else
              current_dir[strlen(current_dir)-1] = '/';
#endif              
            }

            trs_gui_clear_rect(1,1,62,13);
            trs_gui_limit_string(current_dir, limited_dir, 62);
            trs_gui_center_text(limited_dir,1,0);
            
            trs_gui_delete_filename_list();  
            trs_gui_readdirectory(current_dir, browse_dir);

            if (filenamecount < 12)
              drawcount = filenamecount;
            else
              drawcount = 12;
            trs_gui_write_text(filenamelist[0],2,2,1);
            for (i=1;i<drawcount;i++)
              trs_gui_write_text(filenamelist[i],2,2+i,0);
            trs_x_flush();
          }
#ifdef _WIN32
          /* Select a new drive */
          else if (*filenamelist[current_first + selection] == '[') {
            new_dir = filenamelist[current_first + selection];
            selection = 0;
            current_first = 0;
            current_dir[0] = new_dir[1];
            current_dir[1] = new_dir[2];
            current_dir[2] = '\\';
            current_dir[3] = 0; 
            
            trs_gui_clear_rect(1,1,62,13);
            trs_gui_limit_string(current_dir, limited_dir, 62);
            trs_gui_center_text(limited_dir,1,0);
            
            trs_gui_delete_filename_list();  
            trs_gui_readdirectory(current_dir, browse_dir);

            if (filenamecount < 12)
              drawcount = filenamecount;
            else
              drawcount = 12;
            trs_gui_write_text(filenamelist[0],2,2,1);
            for (i=1;i<drawcount;i++)
              trs_gui_write_text(filenamelist[i],2,2+i,0);
            trs_x_flush();
          }  
#endif              
          else
            done = 1;
          break;
        case SDLK_TAB:
          if (browse_dir) 
            done = 1;
          break;
        case SDLK_ESCAPE:
          done = 1;
          selection = -1;
          break;
      }
    }
  } while (!done);

  if (selection != -1) {
    strcpy(filename, current_dir);
    if (browse_dir) {
      char *new_dir;
      new_dir = filenamelist[current_first + selection];
      
      if (new_dir[1] != '.' && new_dir[2] != '.') {
#ifdef _WIN32
        if (new_dir[0] == '[') {
          filename[0] = new_dir[1];
          filename[1] = new_dir[2];
          filename[2] = '\\';
          filename[3] = 0;
        } else 
#endif  
        {    
        strcat(filename, &new_dir[1]);
#ifdef _WIN32       
        filename[strlen(filename)-1] = '\\';
#else
        filename[strlen(filename)-1] = '/';
#endif   
        }     
      }
      trs_gui_clear_rect(1,14,62,1);
      }
    else
      strcat(filename, filenamelist[current_first + selection]);
    }
  trs_gui_delete_filename_list();
  if (selection == -1)
    return(selection);
  else
    return(current_first + selection);
}

int trs_gui_input_string(char *title, char* input, char* output, int file)
{
  char directory_name[FILENAME_MAX];
  char partial_output[FILENAME_MAX];
  int key,i,ret_code=0;
  int done = 0;
  int pos;
  int input_length;
  int length;
  int first_disp;
  int invert;
 
  strcpy(output, input);
  input_length = strlen(input);
  pos = input_length;
  length = input_length;
  length = pos;
  if (pos > (60-1))
    first_disp = pos-60;
  else
    first_disp = 0;
  
  trs_gui_frame(1,6,62,3);   
  trs_gui_clear_rect(2,7,60,1); 
  trs_gui_write_text(title, 3, 6, 0);

  do {
    trs_gui_clear_rect(2,7,60,1);
    for (i=0;i<60;i++) {
      invert = (first_disp + i == pos);
      if (first_disp + i >= length) 
        trs_gui_write_text_char(' ',2+i,7,invert);
      else
        trs_gui_write_text_char(output[first_disp+i],2+i,7,invert);
    }
    trs_x_flush();
    key = trs_gui_get_key();
    switch(key) {
      case SDLK_LEFT:
        if (pos>0) {
          if (pos == first_disp)
            first_disp--; 
          pos--;
        }
        break;
      case SDLK_RIGHT:
        if (pos<length) {
          if (pos == first_disp + (60 - 1))
            first_disp++;
          pos++;
          }
       break;
      case SDLK_BACKSPACE:
        if (pos>0) {
          for (i=pos;i<length;i++)
            output[i-1] = output[i];
          length--;             
          if (pos == first_disp)
            first_disp--; 
          pos--;
        }
        break;
      case SDLK_DELETE:
        if (pos<length) {
          for (i=pos;i<length-1;i++)
            output[i] = output[i+1];
          length--;             
        }
        break;
      case SDLK_RETURN:
        ret_code = 0;
        done = 1;
        break;
      case SDLK_ESCAPE:
        ret_code = -1;
        done = 1;
        break;
      case SDLK_TAB:
        if (file) {
          strcpy(partial_output, output + input_length);
          trs_gui_file_browse(input, directory_name, 1, " ");
          input_length = strlen(directory_name);
          strcpy(output, directory_name);
          strcat(output, partial_output);
          length = strlen(output);
          pos = length;
          if (pos > (60-1))
            first_disp = pos-60;
          else
            first_disp = 0;
          trs_gui_frame(1,6,62,3);    
          trs_gui_write_text(title, 3, 6, 0);
        }
        break;
      default:
        if (key >= 0x20 && key <= 0xFF) { 
          for (i=length;i>pos;i--)
            output[i] = output[i-1];             
          output[pos] = (char) key;
          if (pos == first_disp + (60 - 1))
            first_disp ++;
          pos++;
          length++;
        }
        break;      
    }
  } while (!done);
  
  output[length] = 0;
  return(ret_code);
}

int trs_gui_display_popup(char* title, char **entry, 
                          int entry_count, int selection)
{
  int num = 0,invert,key;
  int done = 0;
  int max_len = 0;
  int first_x, first_y;
  
  for (num=0;num<entry_count;num++) {
    if (strlen(entry[num]) > max_len)
      max_len = strlen(entry[num]);                 
    }
  first_x = (64-max_len)/2;
  first_y = (16-entry_count)/2;

  trs_gui_frame(first_x-1,first_y-1,max_len+2,entry_count+2);
  trs_gui_write_text(title, first_x+1, first_y-1, 0);
  
  for (num=0;num<entry_count;num++) {
    invert = (num == selection);                 
    trs_gui_write_text(entry[num], first_x, first_y+num,invert);
    }
  trs_x_flush();

  do {
    key = trs_gui_get_key();
    switch(key) {
      case SDLK_DOWN:
        trs_gui_write_text(entry[selection], first_x, selection+first_y,0);
        if (selection < entry_count-1) 
          selection ++;
        else 
          selection = 0;
        trs_gui_write_text(entry[selection], first_x, selection+first_y,1);
        trs_x_flush();
        break;
      case SDLK_UP:
        trs_gui_write_text(entry[selection], first_x, selection+first_y,0);
        if (selection > 0)
          selection --;
        else
          selection = entry_count-1;
        trs_gui_write_text(entry[selection], first_x, selection+first_y,1);
        trs_x_flush();
        break;
      case SDLK_RETURN:
        done = 1;
        break;
      case SDLK_ESCAPE:
        done = 1;
        break;
    }
  } while (!done);
  
  return(selection);
}

int trs_gui_display_menu(char* title, MENU_ENTRY *entry, int selection)
{
  int num = 0,invert,key;
  int done = 0;
  char filename[FILENAME_MAX];
  char browse_dir[FILENAME_MAX];
  
  trs_gui_frame(0,0,64,16);
  trs_gui_write_text(title, 2, 0, 0);
  
  while(entry[num].value != -1)
    {
    invert = (num == selection);                 
    trs_gui_write_text(entry[num].title, 2, num+2,invert);
    num++;
    }
  num--;
  trs_x_flush();

  do {
    key = trs_gui_get_key();
    switch(key) {
      case SDLK_DOWN:
        trs_gui_write_text(entry[selection].title, 2, selection+2,0);
        do {
          if (selection < num) 
            selection ++;
          else 
            selection = 0;
        } while(entry[selection].type == MENU_TITLE_TYPE);
        trs_gui_write_text(entry[selection].title, 2, selection+2,1);
        trs_x_flush();
        break;
      case SDLK_UP:
        trs_gui_write_text(entry[selection].title, 2, selection+2,0);
        do {
          if (selection > 0)
            selection --;
          else
            selection = num;
        } while(entry[selection].type == MENU_TITLE_TYPE);
        trs_gui_write_text(entry[selection].title, 2, selection+2,1);
        trs_x_flush();
        break;
       case SDLK_BACKSPACE:
        if ((entry[selection].type == MENU_FLOPPY_BROWSE_TYPE) ||
            (entry[selection].type == MENU_HARD_BROWSE_TYPE) ||
            (entry[selection].type == MENU_CASS_BROWSE_TYPE)) {
          if (entry[selection].type == MENU_FLOPPY_BROWSE_TYPE) {
            trs_disk_remove(selection);
          } else if (entry[selection].type == MENU_HARD_BROWSE_TYPE)  {
            trs_hard_remove(selection);
          } else {
            trs_cassette_remove();
          }
          trs_gui_clear_rect(2,selection+2,60,1);
          entry[selection].title[0]=' ';
          trs_gui_write_text(entry[selection].title, 2, selection+2,1);
          trs_x_flush();
        }
        done = 1;
        break;
      case SDLK_RETURN:
        if ((entry[selection].type == MENU_FLOPPY_BROWSE_TYPE) ||
            (entry[selection].type == MENU_HARD_BROWSE_TYPE) ||
            (entry[selection].type == MENU_CASS_BROWSE_TYPE)) {
          if (entry[selection].type == MENU_FLOPPY_BROWSE_TYPE) {
            trs_expand_dir(trs_disk_dir, browse_dir);
            if (trs_gui_file_browse(browse_dir, filename,0,
                                    " Floppy Disk Image ") == -1)
              {
              done = 1;
              break;
              }
            trs_disk_insert(selection, filename);
          } else if (entry[selection].type == MENU_HARD_BROWSE_TYPE)  {
            trs_expand_dir(trs_hard_dir, browse_dir);
            if (trs_gui_file_browse(browse_dir, filename,0,
                                    " Hard Disk Image ") == -1)
              {
              done = 1;
              break;
              }
            trs_hard_attach(selection, filename);
          } else {
            trs_expand_dir(trs_cass_dir, browse_dir);
            if (trs_gui_file_browse(browse_dir, filename,0,
                                    " Cassette Image ") == -1)
              {
              done = 1;
              break;
              }
            trs_cassette_insert(filename);
          }
          trs_gui_clear_rect(2,selection+2,60,1);
          trs_gui_write_text(entry[selection].title, 2, selection+2,1);
          trs_x_flush();
          }
        done = 1;
        break;
      case SDLK_SPACE:
        if (entry[selection].type == MENU_FLOPPY_BROWSE_TYPE) {
          if (trs_disk_getwriteprotect(selection))
            trs_protect_disk(selection, 0);
          else
            trs_protect_disk(selection, 1);
        } else if (entry[selection].type == MENU_HARD_BROWSE_TYPE) {
          if (trs_hard_getwriteprotect(selection))
            trs_protect_hard(selection, 0);
          else
            trs_protect_hard(selection, 1);
        }
        done = 1;
        break;
      case SDLK_ESCAPE:
        done = 1;
        selection = -1;
        break;
    }
  } while (!done);
  
  return(selection);
}

void trs_gui_hard_creation(void)
{
  MENU_ENTRY disk_creation_menu[] = 
  {{"Cylinder Count                                              ",MENU_NORMAL_TYPE,1},
   {"Sector Count                                                ",MENU_NORMAL_TYPE,2},
   {"Granularity                                                 ",MENU_NORMAL_TYPE,3},
   {"Directory Sector                                            ",MENU_NORMAL_TYPE,4},
   {"Insert Created Disk Into This Drive                         ",MENU_NORMAL_TYPE,5},
   {"Create Hard Disk Image with Above Parameters",MENU_NORMAL_TYPE,6},
   {"",0,-1}};
   char *drive_choices[5] =      {"    None  "," Drive 1  "," Drive 2  "," Drive 3  ",
                                  " Drive 4  "};
   int selection = 5;
   static int cylinder_count = 202;
   static int sector_count = 256;
   static int granularity = 8;
   static int dir_sector = 1;
   static int drive_insert = 0;
   int done = 0, ret;
   int value;
   char filename[FILENAME_MAX];
   char input[FILENAME_MAX];
   char browse_dir[FILENAME_MAX];

   while(!done) {
     sprintf(&disk_creation_menu[0].title[50],"%8d",cylinder_count);
     sprintf(&disk_creation_menu[1].title[50],"%8d",sector_count);
     sprintf(&disk_creation_menu[2].title[50],"%8d",granularity);
     sprintf(&disk_creation_menu[3].title[50],"%8d",dir_sector);
     strcpy(&disk_creation_menu[4].title[50],drive_choices[drive_insert]);
     trs_gui_clear_screen();
     selection = trs_gui_display_menu("SDLTRS Hard Disk Creation Menu",
                                      disk_creation_menu, selection);
     switch(selection) {
       case 0:
         sprintf(input,"%6d",cylinder_count);
         ret = trs_gui_input_string("Enter Cylinder Count",input,input,0);
         if (!ret) {
           value = atoi(input);
           if (value >=3 && value <= 256) {
             cylinder_count = value;
             if (cylinder_count > 203)
               trs_gui_display_message("Warning",
                   "Cylinder Count > 203 is incompatible with XTRSHARD/DCT");
           } else
             trs_gui_display_message("Error",
                 "Cylinder Count must be between 3 and 256");
         }
         break;
       case 1:
         sprintf(input,"%6d",sector_count);
         ret = trs_gui_input_string("Enter Sector Count",input,input,0);
         if (!ret) {
           value = atoi(input);
           if (value >=4 && value <= 256) {
             sector_count = value;
             if ((sector_count % 32) != 0) {
               trs_gui_display_message("Warning",
                   "Sector not a mult of 32 is incompatible with WD1000/1010");
               if (sector_count > 32) 
                 trs_gui_display_message("Warning",
                     "Sector is incompatible with Matthew Reed's emulators");
               }
           } else
             trs_gui_display_message("Error",
                 "Sector Count must be between 4 and 256");
         }
         break;
       case 2:
         sprintf(input,"%6d",granularity);
         ret = trs_gui_input_string("Enter Granularity",input,input,0);
         if (!ret) {
           value = atoi(input);
           if (value >= 1 && value <= 8) {
                 granularity = value;
           } else
             trs_gui_display_message("Error",
                 "Granularity must be between 1 and 8");
         }
         break;
       case 3:
         sprintf(input,"%6d",dir_sector);
         ret = trs_gui_input_string("Enter Directory Sector",input,input,0);
         if (!ret) {
           value = atoi(input);
           if (value >= 1 && value < cylinder_count) {
                 dir_sector = value;
           } else
             trs_gui_display_message("Error",
                 "Directory Sector must be between 1 and Cylinder Count-1");
         }
         break;
       case 4:
         drive_insert = trs_gui_display_popup("Insert Drive",drive_choices,5,
                                        drive_insert);
         break;
       case 5:
         if (sector_count < granularity) {
             trs_gui_display_message("Error",
                 "Sector Count must be >= Granularity");
             break;
         }
         if ((sector_count % granularity) != 0) {
             trs_gui_display_message("Error",
                 "Sector Count must be multiple of Granularity");
             break;
         }
         if ((sector_count / granularity) > 32) {
             trs_gui_display_message("Error",
                 "Sector Count / Granularity must be <= 32");
             break;
         }
         filename[0] = 0;
         trs_expand_dir(trs_hard_dir, browse_dir);
         ret = trs_gui_input_string("Enter Filename, TAB selects directory", 
                                    browse_dir,filename, 1);
         if (ret)
           break;
         ret = trs_create_blank_hard(filename, cylinder_count, sector_count, 
                                     granularity, dir_sector);
         if (ret)
           trs_gui_display_message("Error","Error creating Hard Disk Image");
         else if (drive_insert)
           trs_hard_attach(drive_insert-1, filename);
         done = 1;
         break;
       case -1:
         done = 1;
         break;
     }
  }
}

void trs_gui_disk_creation(void)
{
  MENU_ENTRY disk_creation_menu[] = 
  {{"Image Type                                                  ",MENU_NORMAL_TYPE,1},
   {"Number of Sides                                             ",MENU_NORMAL_TYPE,2},
   {"Density                                                     ",MENU_NORMAL_TYPE,3},
   {"Physical Size                                               ",MENU_NORMAL_TYPE,4},
   {"Ignore Density Flag                                         ",MENU_NORMAL_TYPE,5},
   {"Insert Created Disk Into This Drive                         ",MENU_NORMAL_TYPE,6},
   {"Create Floppy Image with Above Parameters",MENU_NORMAL_TYPE,7},
   {"",0,-1}};
   char *image_type_choices[3] = {"     JV1  ","     JV3  ","     DMK "};
   char *num_sides_choices[2] =  {"       1  ","       2  "};
   char *density_choices[2] =    {"  Single  ","  Double  "};
   char *size_choices[2] =       {"  5 Inch  ","  8 Inch  "};
   char *ignore_choices[2] =     {"      No  ","     Yes  "};
   char *drive_choices[9] =      {"    None  "," Drive 1  "," Drive 2  "," Drive 3  ",
                                  " Drive 4  "," Drive 5  "," Drive 6  "," Drive 7  ",
                                  " Drive 8  "};
   int selection = 6;
   static int image_type = 1;
   static int num_sides = 1;
   static int density = 1;
   static int eight = 0;
   static int ignore_density = 0;
   static int drive_insert = 0;
   int done = 0, ret;
   char filename[FILENAME_MAX];
   char browse_dir[FILENAME_MAX];
   
   while(!done) {
     strcpy(&disk_creation_menu[0].title[50],image_type_choices[image_type]);
     strcpy(&disk_creation_menu[1].title[50],num_sides_choices[num_sides-1]);
     strcpy(&disk_creation_menu[2].title[50],density_choices[density-1]);
     strcpy(&disk_creation_menu[3].title[50],size_choices[eight]);
     strcpy(&disk_creation_menu[4].title[50],ignore_choices[ignore_density]);
     strcpy(&disk_creation_menu[5].title[50],drive_choices[drive_insert]);
     trs_gui_clear_screen();
     selection = trs_gui_display_menu("SDLTRS Floppy Creation Menu",
                                      disk_creation_menu, selection);
     switch(selection) {
       case 0:
         image_type = trs_gui_display_popup("Type",image_type_choices,3,
                                            image_type);
         break;
       case 1:
         num_sides = trs_gui_display_popup("Sides",num_sides_choices,2,
                                            num_sides - 1) + 1;
         break;
       case 2:
         density = trs_gui_display_popup("Density",density_choices,2,
                                        density - 1) + 1;
         break;
       case 3:
         eight = trs_gui_display_popup("Size",size_choices,2,
                                        eight);
         break;
       case 4:
         ignore_density = trs_gui_display_popup("Ignore",ignore_choices,2,
                                        ignore_density);
         break;
       case 5:
         drive_insert = trs_gui_display_popup("Insert Drive",drive_choices,9,
                                        drive_insert);
         break;
       case 6:
         filename[0] = 0;
         trs_expand_dir(trs_disk_dir, browse_dir);
         ret = trs_gui_input_string("Enter Filename, TAB selects directory", 
                                    browse_dir,filename, 1);
         if (ret)
           break;
         if (image_type == 0)
           ret = trs_create_blank_jv1(filename);
         else if (image_type == 1)
           ret = trs_create_blank_jv3(filename);
         else
           ret = trs_create_blank_dmk(filename, num_sides, density, eight, ignore_density);
         if (ret)
           trs_gui_display_message("Error","Error creating Disk Image");
         else if (drive_insert)
           trs_disk_insert(drive_insert-1, filename);
         done = 1;
         break;
       case -1:
         done = 1;
         break;
     }
  }
}

void trs_gui_cassette_creation(void)
{
  MENU_ENTRY cassette_creation_menu[] = 
  {{"Image Type                                                  ",MENU_NORMAL_TYPE,1},
   {"Insert Created Disk Into Drive                              ",MENU_NORMAL_TYPE,6},
   {"Create Blank Cassette Image with Above Parameters",MENU_NORMAL_TYPE,2},
   {"",0,-1}};
   char *image_type_choices[3] = {"     CAS  ","     CPT  ","     WAV "};
   char *drive_choices[2] =     {"      No  ","     Yes  "};

   int selection = 2;
   static int image_type = 0;
   static int drive_insert = 1;
   int done = 0, ret;
   FILE *cassette_file;
   char filename[FILENAME_MAX];
   char browse_dir[FILENAME_MAX];
   
   while(!done) {
     strcpy(&cassette_creation_menu[0].title[50],image_type_choices[image_type]);
     strcpy(&cassette_creation_menu[1].title[50],drive_choices[drive_insert]);
     trs_gui_clear_screen();
     selection = trs_gui_display_menu("SDLTRS Cassette Creation Menu",
                                      cassette_creation_menu, selection);
     switch(selection) {
       case 0:
         image_type = trs_gui_display_popup("Type",image_type_choices,3,
                                            image_type);
         break;
       case 1:
         drive_insert = trs_gui_display_popup("Insert",drive_choices,2,
                                            drive_insert);
         break;
       case 2:
         filename[0] = 0;
         trs_expand_dir(trs_cass_dir, browse_dir);
         ret = trs_gui_input_string("Enter Filename (without extension), TAB selects directory", 
                                    browse_dir,filename, 1);
         if (ret)
           break;

         if (image_type == 0) {
           trs_add_extension(filename,".cas");
           cassette_file = fopen(filename, "wb");
           if (cassette_file == NULL)
             ret = -1;
           else {
             ret = 0;
             fclose(cassette_file);
             }
           }
         else if (image_type == 1) {
           trs_add_extension(filename,".cpt");
           cassette_file = fopen(filename, "wb");
           if (cassette_file == NULL)
             ret = -1;
           else {
             ret = 0;
             fclose(cassette_file);
             }
           }
         else {
           trs_add_extension(filename,".wav");
           cassette_file = fopen(filename, "wb");
           if (cassette_file == NULL)
             ret = -1;
           else {
             ret = create_wav_header(cassette_file);
             fclose(cassette_file);
             }
           }
         if (ret)
           trs_gui_display_message("Error","Error creating Cassette Image");
         else {
           if (drive_insert)
             trs_cassette_insert(filename);
         }
         done = 1;
         break;
       case -1:
         done = 1;
         break;
     }
  }
}

void trs_gui_disk_sizes(void)
{
  MENU_ENTRY disk_sizes_menu[] = 
  {{"",MENU_NORMAL_TYPE,1},
   {"",MENU_NORMAL_TYPE,2},
   {"",MENU_NORMAL_TYPE,3},
   {"",MENU_NORMAL_TYPE,4},
   {"",MENU_NORMAL_TYPE,5},
   {"",MENU_NORMAL_TYPE,6},
   {"",MENU_NORMAL_TYPE,7},
   {"",MENU_NORMAL_TYPE,8},
   {"",0,-1}};
   int selection = 0;
   int done = 0;
   int gui_disk_sizes[8];
   char *size_choices[2] = {"  5 Inch Disk  ","  8 Inch Disk  "};
   int i, choice, size;

   for (i=0;i<8;i++) {
       gui_disk_sizes[i] = trs_disk_getsize(i);
   }
   
   while(!done) {
     trs_gui_clear_screen();
     for (i=0;i<8;i++) {
       if (gui_disk_sizes[i] == 5)
          choice = 0;
       else
          choice = 1;
       sprintf(disk_sizes_menu[i].title,
               "Floppy Drive Number %d Size                  %s",
                i+1,size_choices[choice]);
     }
     selection = trs_gui_display_menu("SDLTRS Floppy Size Menu",
                                      disk_sizes_menu, selection);
     if (selection == -1)
       done = 1;
     else {
       size = trs_gui_display_popup("Choose size",size_choices,2,
                                    gui_disk_sizes[selection]==8);
       if (size == 0)
         gui_disk_sizes[selection] = 5;
       else
         gui_disk_sizes[selection] = 8;
       trs_disk_setsize(selection, gui_disk_sizes[selection]);
     }
  }
}

#ifdef __linux
void trs_gui_disk_steps(void)
{
  MENU_ENTRY disk_steps_menu[] = 
  {{"",MENU_NORMAL_TYPE,1},
   {"",MENU_NORMAL_TYPE,2},
   {"",MENU_NORMAL_TYPE,3},
   {"",MENU_NORMAL_TYPE,4},
   {"",MENU_NORMAL_TYPE,5},
   {"",MENU_NORMAL_TYPE,6},
   {"",MENU_NORMAL_TYPE,7},
   {"",MENU_NORMAL_TYPE,8},
   {"",0,-1}};
   int selection = 0;
   int done = 0;
   int gui_disk_steps[8];
   char *step_choices[2] = {"       Single  ","       Double  "};
   int i, choice, step;

   for (i=0;i<8;i++) {
       gui_disk_steps[i] = trs_disk_getstep(i);
   }
   
   while(!done) {
     trs_gui_clear_screen();
     for (i=0;i<8;i++) {
       if (gui_disk_steps[i] == 1)
          choice = 0;
       else
          choice = 1;
       sprintf(disk_steps_menu[i].title,
               "Floppy Drive Number %d Step                  %s",
                i+1,step_choices[choice]);
     }
     selection = trs_gui_display_menu("SDLTRS Floppy Size Menu",
                                      disk_steps_menu, selection);
     if (selection == -1)
       done = 1;
     else {
       step = trs_gui_display_popup("Choose step",step_choices,2,
                                    gui_disk_steps[selection]==2);
       if (step == 0)
         gui_disk_steps[selection] = 1;
       else
         gui_disk_steps[selection] = 2;
       trs_disk_setstep(selection, gui_disk_steps[selection]);
     }
  }
}
#endif

void trs_gui_disk_options(void)
{
  MENU_ENTRY disk_menu[] = 
  {{"Doubler Type                                                ",MENU_NORMAL_TYPE,1},
   {"True DAM Emulation                                          ",MENU_NORMAL_TYPE,2},
   {"Set Drive Sizes",MENU_NORMAL_TYPE,3},
#ifdef __linux   
   {"Set Drive Steps",MENU_NORMAL_TYPE,4},
#endif   
   {"",0,-1}};
   char *on_off_choices[2] =     {"     Off ","     On  "};
   char *doubler_choices[4] =     {"    None ","  Percom ","   Tandy ","    Both "};
   int selection = 0;
   int done = 0;
   
   while(!done) {
     sprintf(&disk_menu[0].title[50],"%s",doubler_choices[trs_disk_doubler]);
     sprintf(&disk_menu[1].title[50],"%s",on_off_choices[trs_disk_truedam]);
     trs_gui_clear_screen();
     selection = trs_gui_display_menu("SDLTRS Floppy Options Menu",disk_menu, selection);
     switch(selection) {
       case 0:
         trs_disk_doubler = trs_gui_display_popup("Doubler",doubler_choices,4,
                                                   trs_disk_doubler);
         break;
       case 1:
         trs_disk_truedam = trs_gui_display_popup("Truedam",on_off_choices,2,
                                                   trs_disk_truedam);
         break;
       case 2:
         trs_gui_disk_sizes();
         break;
#ifdef __linux         
       case 3:
         trs_gui_disk_steps();
         break;
#endif         
       case -1:
         done = 1;
         break;
     }
  }
}

void trs_gui_disk_management(void)
{
  MENU_ENTRY disk_menu[] = 
  {{" Disk 1:",MENU_FLOPPY_BROWSE_TYPE,1},
   {" Disk 2:",MENU_FLOPPY_BROWSE_TYPE,2},
   {" Disk 3:",MENU_FLOPPY_BROWSE_TYPE,3},
   {" Disk 4:",MENU_FLOPPY_BROWSE_TYPE,4},
   {" Disk 5:",MENU_FLOPPY_BROWSE_TYPE,5},
   {" Disk 6:",MENU_FLOPPY_BROWSE_TYPE,6},
   {" Disk 7:",MENU_FLOPPY_BROWSE_TYPE,7},
   {" Disk 8:",MENU_FLOPPY_BROWSE_TYPE,8},
   {"Save Disk Set",MENU_NORMAL_TYPE,9},
   {"Load Disk Set",MENU_NORMAL_TYPE,10},
   {"Create Blank Floppy",MENU_NORMAL_TYPE,11},
   {"Disk Drive Options",MENU_NORMAL_TYPE,12},
   {"",0,-1}};
   char filename[FILENAME_MAX];
   char browse_dir[FILENAME_MAX];
   int ret;
   int selection = 0;
   int done = 0;
   int i;
   
   while(!done) {
     for (i=0;i<8;i++) {
       char *diskname;
       
       diskname = trs_disk_getfilename(i);
       if (diskname[0] == 0)
         strcpy(&disk_menu[i].title[8], "Empty");
       else
         trs_gui_limit_string(trs_disk_getfilename(i),&disk_menu[i].title[8],52);
       if (trs_disk_getwriteprotect(i))
         disk_menu[i].title[0]='*';
       else
         disk_menu[i].title[0]=' ';
     }   
     trs_gui_clear_screen();
     selection = trs_gui_display_menu("SDLTRS Floppy Menu",disk_menu, selection);
     switch(selection) {
       case 8:
         filename[0] = 0;
         trs_expand_dir(trs_disk_set_dir, browse_dir);
         ret = trs_gui_input_string("Enter Filename (without extension), TAB selects directory", 
                                    browse_dir,filename, 1);
         if (ret)
           break;
         strcat(filename,".set");
         trs_diskset_save(filename);
         break;
       case 9:
         trs_expand_dir(trs_disk_set_dir,browse_dir);
         ret = trs_gui_file_browse(browse_dir, filename, 0," Disk Set ");
         if (ret == -1)
           break;
         trs_diskset_load(filename);
         break;
       case 10:
         trs_gui_disk_creation();
         break;
       case 11:
         trs_gui_disk_options();
         break;
       case -1:
         done = 1;
         break;
     }
  }
}

void trs_gui_hard_management(void)
{
  MENU_ENTRY hard_menu[] = 
  {{" Hard 1:",MENU_HARD_BROWSE_TYPE,1},
   {" Hard 2:",MENU_HARD_BROWSE_TYPE,2},
   {" Hard 3:",MENU_HARD_BROWSE_TYPE,3},
   {" Hard 4:",MENU_HARD_BROWSE_TYPE,4},
   {"Create Blank Hard Disk",MENU_NORMAL_TYPE,5},
   {"",0,-1}};
   int selection = 0;
   int done = 0;
   int i;
   
   while(!done) {
     for (i=0;i<4;i++) {
         char *diskname;
         
         diskname = trs_hard_getfilename(i);
         if (diskname[0] == 0)
           strcpy(&hard_menu[i].title[8],"Empty");
         else         
           trs_gui_limit_string(diskname,&hard_menu[i].title[8],52);
         if (trs_hard_getwriteprotect(i))
           hard_menu[i].title[0]='*';
         else
           hard_menu[i].title[0]=' ';
     }
   
     trs_gui_clear_screen();
     selection = trs_gui_display_menu("SDLTRS Hard Disk Menu",
                                      hard_menu, selection);
     switch(selection) {
       case 4:
         trs_gui_hard_creation();
         break;
       case -1:
         done = 1;
         break;
     }
  }
}

void trs_gui_cassette_management(void)
{
  MENU_ENTRY cass_menu[] = 
  {{"Cass   :",MENU_CASS_BROWSE_TYPE,1},
   {"Cassette Position                                           ",MENU_NORMAL_TYPE,10},
   {"Create Blank Cassette",MENU_NORMAL_TYPE,3},
   {"",0,-1}};
   char posititon_string[FILENAME_MAX];
   int selection = 0;
   int done = 0;
   int new_position;
   int ret;
      
   while(!done) {
     char *cass_name = trs_cassette_getfilename();
     
     if (cass_name[0] == 0)
       strcpy(&cass_menu[0].title[8],"Empty");
     else
       trs_gui_limit_string(cass_name,&cass_menu[0].title[8],52);
     
     trs_gui_clear_screen();
     sprintf(&cass_menu[1].title[34],"%10d of %10d",trs_get_cassette_position(),trs_get_cassette_length());
     selection = trs_gui_display_menu("SDLTRS Cassette Menu",cass_menu, selection);
     switch(selection) {
       case 1:
         sprintf(posititon_string,"%d",trs_get_cassette_position());
         ret = trs_gui_input_string("Enter Cassette Position in Bytes", 
                                    "",posititon_string, 1);
         if (ret)
           break;
         new_position = atoi(posititon_string);
         if (new_position >= 0 && new_position <= trs_get_cassette_length())
            trs_set_cassette_position(new_position);
         break;
       case 2:
         trs_gui_cassette_creation();
         break;
       case -1:
         done = 1;
         break;
     }
  }
}

void trs_gui_display_management(void)
{
  MENU_ENTRY display_menu[] = 
  {{"Emulator Background Color                                   ",MENU_NORMAL_TYPE,1},
   {"Emulator Foreground Color                                   ",MENU_NORMAL_TYPE,2},
   {"GUI Background Color                                        ",MENU_NORMAL_TYPE,3},
   {"GUI Foreground Color                                        ",MENU_NORMAL_TYPE,4},
   {"Model 1 Character Set                                       ",MENU_NORMAL_TYPE,2},
   {"Model 3 Character Set                                       ",MENU_NORMAL_TYPE,2},
   {"Model 4/4p Character Set                                    ",MENU_NORMAL_TYPE,2},
   {"Border Width                                                ",MENU_NORMAL_TYPE,5},
   {"Resize Window on Mode Change for Model 3                    ",MENU_NORMAL_TYPE,6},
   {"Resize Window on Mode Change for Model 4                    ",MENU_NORMAL_TYPE,7},
   {"Disk LED Display                                            ",MENU_NORMAL_TYPE,8},
   {"",0,-1}};
   char input[FILENAME_MAX];
   int selection = 0;
   int charset1_selection;
   int charset3_selection;
   int charset4_selection;
   int done = 0;
   int ret;
   char *resize_choices[2] = {"      No  ","     Yes  "};
   char *disk_led_choices[2] = {"    Hide  ","    Show  "};
   char *font1_choices[8] =  {"             early  ",
                              "             stock  ",
                              "             lcmod  ",
                              "             wider  ",
                              "             genie  "};
   char *font34_choices[8] =  {"          katakana  ",
                               "     international  ",
                               "              bold  "};
   
   if (local_trs_charset1 == 10)
     charset1_selection = 4;
   else
     charset1_selection = local_trs_charset1;
   charset3_selection = local_trs_charset3 - 4;
   charset4_selection = local_trs_charset4 - 7;
                               
   
   while(!done) {
     trs_gui_clear_screen();
     sprintf(&display_menu[0].title[50],"0x%06X",local_background);
     sprintf(&display_menu[1].title[50],"0x%06X",local_foreground);
     sprintf(&display_menu[2].title[50],"0x%06X",local_gui_background);
     sprintf(&display_menu[3].title[50],"0x%06X",local_gui_foreground);
     strcpy(&display_menu[4].title[40],font1_choices[charset1_selection]);
     strcpy(&display_menu[5].title[40],font34_choices[charset3_selection]);
     strcpy(&display_menu[6].title[40],font34_choices[charset4_selection]);
     sprintf(&display_menu[7].title[50],"%8d",gui_border_width);
     sprintf(&display_menu[8].title[50],"%s",resize_choices[gui_resize3]);
     sprintf(&display_menu[9].title[50],"%s",resize_choices[gui_resize4]);
     sprintf(&display_menu[10].title[50],"%s",disk_led_choices[gui_show_led]);
     selection = trs_gui_display_menu("SDLTRS Display Setting Menu",
                                      display_menu, selection);
     switch(selection) {
       case 0:
         sprintf(input,"%06X",local_background);
         ret = trs_gui_input_string("Enter Background RGB color, in hex, RRGGBB",input,input,0);
         if (!ret)
           local_background = strtol(input, NULL, 16);
         break;
       case 1:
         sprintf(input,"%06X",local_foreground);
         ret = trs_gui_input_string("Enter Foreground RGB color, in hex, RRGGBB",input,input,0);
         if (!ret)
           local_foreground = strtol(input, NULL, 16);
         break;
       case 2:
         sprintf(input,"%06X",local_gui_background);
         ret = trs_gui_input_string("Enter GUI Background RGB color, in hex, RRGGBB",input,input,0);
         if (!ret)
           local_gui_background = strtol(input, NULL, 16);
         break;
       case 3:
         sprintf(input,"%06X",local_gui_foreground);
         ret = trs_gui_input_string("Enter GUI Foreground RGB color, in hex, RRGGBB",input,input,0);
         if (!ret)
           gui_foreground = strtol(input, NULL, 16);
         break;
       case 4:
         charset1_selection = trs_gui_display_popup("Charset",font1_choices,5,
                                                   charset1_selection);
         break;
       case 5:
         charset3_selection = trs_gui_display_popup("Charset",font34_choices,3,
                                                   charset3_selection);
         break;
       case 6:
         charset4_selection = trs_gui_display_popup("Charset",font34_choices,3,
                                                   charset4_selection);
         break;
       case 7:
         sprintf(input,"%d",gui_border_width);
         ret = trs_gui_input_string("Enter Window border width, in pixels",input,input,0);
         if (!ret)
           gui_border_width = atol(input);
         break;
       case 8:
         gui_resize3 = trs_gui_display_popup("Resize 3",resize_choices,2,
                                                   gui_resize3);
         break;
       case 9:
         gui_resize4 = trs_gui_display_popup("Resize 4",resize_choices,2,
                                                   gui_resize4);
         break;
       case 10:
         gui_show_led = trs_gui_display_popup("LED",disk_led_choices,2,
                                                   gui_show_led);
         break;
       case -1:
         done = 1;
         break;
     }
  }
  if (charset1_selection == 4)
    local_trs_charset1 = 10;
  else
    local_trs_charset1 = charset1_selection;
  local_trs_charset3 = charset3_selection+4;
  local_trs_charset4 = charset4_selection+7;
}

void trs_gui_joystick_management(void)
{
  MENU_ENTRY display_menu[] = 
  {{"Use Keypad for Joystick                                     ",MENU_NORMAL_TYPE,1},
   {"USB Joystick/Gamepad                                        ",MENU_NORMAL_TYPE,2},
   {"",0,-1}};
   int selection = 0;
   int done = 0;
   int i, num_joysticks, joy_index;
   char *keypad_choices[2] =     {"      No  ","     Yes  "};
   char *joystick_choices[MAX_JOYSTICKS+1];
   char joystick_strings[MAX_JOYSTICKS+1][64];
   
   for (i=0;i<MAX_JOYSTICKS+1;i++)
     joystick_choices[i] = joystick_strings[i];
   
   while(!done) {
     trs_gui_clear_screen();
     sprintf(&display_menu[0].title[50],"%s",keypad_choices[gui_keypad_joystick]);
     if (gui_joystick_num == -1)
       sprintf(&display_menu[1].title[48],"      None");
     else
       sprintf(&display_menu[1].title[48],"Joystick %1d",gui_joystick_num);
     selection = trs_gui_display_menu("SDLTRS Joystick Setting Menu",
                                      display_menu, selection);
     switch(selection) {
       case 0:
         gui_keypad_joystick = trs_gui_display_popup("Keypad",keypad_choices,2,
                                                   gui_keypad_joystick);
         break;
       case 1:
         num_joysticks = SDL_NumJoysticks();
         if (num_joysticks > MAX_JOYSTICKS)
           num_joysticks = MAX_JOYSTICKS;
         sprintf(joystick_choices[0],"%60s","None");
         for (i=0;i<num_joysticks;i++) {
           sprintf(joystick_choices[i+1],"Joystick %1d - %47s",i,
                   SDL_JoystickName(i));
                   }          
         if ((gui_joystick_num == -1) || (gui_joystick_num >= num_joysticks))
           joy_index = 0;
         else
           joy_index = gui_joystick_num+1;
         joy_index = trs_gui_display_popup("Joystick",joystick_choices,
                                           num_joysticks+1,
                                           joy_index);
         if (joy_index == 0)
           gui_joystick_num = -1;
         else
           gui_joystick_num = joy_index-1;
         break;
       case -1:
         done = 1;
         break;
     }
  }
}

void trs_gui_misc_management(void)
{
  MENU_ENTRY misc_menu[] = 
  {{"Shift Bracket Emulation                                     ",MENU_NORMAL_TYPE,1},
   {"Keystretch Value                                            ",MENU_NORMAL_TYPE,2},
   {"Emtsafe                                                     ",MENU_NORMAL_TYPE,3},
   {"Serial Switches                                             ",MENU_NORMAL_TYPE,4},
   {"Serial Port Name:                                           ",MENU_TITLE_TYPE,5},
   {"                                                            ",MENU_NORMAL_TYPE,6},
   {"",0,-1}};
   char *on_off_choices[2] =     {"     Off ","      On "};
   char input[FILENAME_MAX];
   int selection = 0;
   int done = 0;
   int ret, state;
   
   while(!done) {
     trs_gui_clear_screen();
     sprintf(&misc_menu[0].title[50],"%s",on_off_choices[trs_kb_bracket_state]);
     sprintf(&misc_menu[1].title[48],"%10d",stretch_amount);
     sprintf(&misc_menu[2].title[50],"%s",on_off_choices[trs_emtsafe]);
     sprintf(&misc_menu[3].title[54],"0x%02X",trs_uart_switches);
     trs_gui_limit_string(trs_uart_name,&misc_menu[5].title[2],60);
     selection = trs_gui_display_menu("SDLTRS Misc Settings Menu",
                                      misc_menu, selection);

     switch(selection) {
       case 0:
         state = trs_gui_display_popup("Shift",on_off_choices,2,
                                                   trs_kb_bracket_state);
         trs_kb_bracket(state);                                          
         break;
       case 1:
         sprintf(input,"%d",stretch_amount);
         ret = trs_gui_input_string("Enter Keystretch in cycles",input,input,0);
         if (!ret)
           stretch_amount = atoi(input);
         break;
       case 2:
         state = trs_gui_display_popup("Safe",on_off_choices,2,
                                                   trs_emtsafe);
         trs_emtsafe=state;                                          
         break;
       case 3:
         sprintf(input,"%2X",trs_uart_switches);
         ret = trs_gui_input_string("Enter Serial Switches in Hex, XX",input,input,0);
         if (!ret) {
           trs_uart_switches = strtol(input,NULL,16);
           trs_uart_init(0);
           }
         break;
       case 4:
         strcpy(input,trs_uart_name);
         ret = trs_gui_input_string("Enter Serial Port Name",input,input,0);
         if (!ret) {
           strcpy(trs_uart_name,input);
           trs_uart_init(0);
           }
         break;
       case -1:
         done = 1;
         break;
     }
  }
}

void trs_gui_printer_management(void)
{
  MENU_ENTRY printer_menu[] = 
  {{"Printer Type                                                ",MENU_NORMAL_TYPE,1},
   {"Close and Reopen Printer Output File                        ",MENU_NORMAL_TYPE,2},
   {"Printer Command:                                            ",MENU_TITLE_TYPE,3},
   {"   ",MENU_NORMAL_TYPE,3},
   {"",0,-1}};
#ifdef MACOSX   
   char *printer_choices[3] =     {"    None ","    Text ","   Epson "};
#else
   char *printer_choices[2] =     {"    None ","    Text "};
#endif   
   char input[FILENAME_MAX];
   int selection = 0;
   int done = 0;
   int ret;
   
   while(!done) {
     trs_gui_clear_screen();
     sprintf(&printer_menu[0].title[50],"%s",printer_choices[trs_printer]);
     trs_gui_limit_string(trs_printer_command,&printer_menu[3].title[2],60);
     selection = trs_gui_display_menu("SDLTRS Printer Management Menu",
                                      printer_menu, selection);

     switch(selection) {
       case 0:
#ifdef MACOSX       
         trs_printer = trs_gui_display_popup("Shift",printer_choices,3,
                                                   trs_printer);
#else
         trs_printer = trs_gui_display_popup("Shift",printer_choices,2,
                                                   trs_printer);
#endif                                                   
         break;
       case 1:
         if (trs_printer_reset() != -1)
           trs_gui_display_message("Status","Printer file closed, printer command ran");
         else
           trs_gui_display_message("Warning","No Printer Output in File");
         break;
       case 4:
         strcpy(input,trs_printer_command);
         ret = trs_gui_input_string("Enter Printer Command",input,input,0);
         if (!ret) {
           strcpy(trs_printer_command,input);
           }
         break;
       case -1:
         done = 1;
         break;
     }
  }
}

void trs_gui_model(void)
{
  char *model_choices[4] = {"    TRS-80 Model I  ",
                            "  TRS-80 Model III  ",
                            "    TRS-80 Model 4  ",
                            "   TRS-80 Model 4P  "};
  char *on_off_choices[2] = {"           Off  ","           On   "};
  MENU_ENTRY model_menu[] = 
  {{"Model                                                       ",MENU_NORMAL_TYPE,1},
   {"Microlab Emulation                                          ",MENU_NORMAL_TYPE,3},
   {"",0,-1}};
   int selection = 0;
   int model_selection = 0, last_model_selection;
   int done = 0;
   int state;
   
   while(!done) {
     trs_gui_clear_screen();
     switch(local_trs_model) {
       case 1:
         model_selection = 0;
         break;
       case 3:
       case 4:
         model_selection = local_trs_model-2;
         break;
       case 5:
         model_selection = 3;
         break;
     }
     strcpy(&model_menu[0].title[40],model_choices[model_selection]);
     strcpy(&model_menu[1].title[45],on_off_choices[grafyx_get_microlabs()]);
     
     selection = trs_gui_display_menu("SDLTRS Model Selection Menu",model_menu, selection);
     switch(selection) {
       case -1:
         done = 1;
         break;
       case 0:
         last_model_selection = model_selection;
         model_selection = trs_gui_display_popup("Model",model_choices,4,
                                            model_selection);
         switch(model_selection) {
           case 0:
             local_trs_model = 1;
             break;
           case 1:
             local_trs_model = 3;
             break;
           case 2:
             local_trs_model = 4;
             break;
           case 3:
             local_trs_model = 5;
             break;
         }
         break;
       case 1:
         state = trs_gui_display_popup("Microlabs",on_off_choices,2,
                                                   grafyx_get_microlabs());
         grafyx_set_microlabs(state);
         break;                                          
     }
  }
}

void trs_gui_default_dirs(void)
{
  MENU_ENTRY default_menu[] = 
  {{"Default Floppy Disk Directory:",MENU_TITLE_TYPE,1},
   {"   ",MENU_NORMAL_TYPE,2},
   {"Default Hard Disk Directory:",MENU_TITLE_TYPE,3},
   {"   ",MENU_NORMAL_TYPE,4},
   {"Default Cassette Directory:",MENU_TITLE_TYPE,5},
   {"   ",MENU_NORMAL_TYPE,6},
   {"Default Disk Set Directory:",MENU_TITLE_TYPE,7},
   {"   ",MENU_NORMAL_TYPE,8},
   {"Default State Directory:",MENU_TITLE_TYPE,9},
   {"   ",MENU_NORMAL_TYPE,10},
   {"Default Printer Output Directory:",MENU_TITLE_TYPE,11},
   {"   ",MENU_NORMAL_TYPE,12},
   {"",0,-1}};
   char browse_dir[FILENAME_MAX];
   int selection = 1;
   int done = 0;
   
   while(!done) {
     trs_gui_clear_screen();
     trs_gui_limit_string(trs_disk_dir,&default_menu[1].title[2],59);
     trs_gui_limit_string(trs_hard_dir,&default_menu[3].title[2],59);
     trs_gui_limit_string(trs_cass_dir,&default_menu[5].title[2],59);
     trs_gui_limit_string(trs_disk_set_dir,&default_menu[7].title[2],59);
     trs_gui_limit_string(trs_state_dir,&default_menu[9].title[2],59);
     trs_gui_limit_string(trs_printer_dir,&default_menu[11].title[2],59);
     // print current defaults
     selection = trs_gui_display_menu("SDLTRS Default Directory Menu",default_menu, selection);
     switch(selection) {
       case -1:
         done = 1;
         break;
       case 1:
         trs_expand_dir(trs_disk_dir, browse_dir);
         trs_gui_file_browse(browse_dir, trs_disk_dir, 1," Floppy Disk ");
         break;
       case 3:
         trs_expand_dir(trs_hard_dir, browse_dir);
         trs_gui_file_browse(browse_dir, trs_hard_dir, 1," Hard Disk ");
         break;
       case 5:
         trs_expand_dir(trs_cass_dir, browse_dir);
         trs_gui_file_browse(browse_dir, trs_cass_dir, 1," Cassette ");
         break;
       case 7:
         trs_expand_dir(trs_disk_set_dir, browse_dir);
         trs_gui_file_browse(browse_dir, trs_disk_set_dir, 1," Disk Set ");
         break;
       case 9:
         trs_expand_dir(trs_state_dir, browse_dir);
         trs_gui_file_browse(browse_dir, trs_state_dir, 1," Saved State ");
         break;
       case 11:
         trs_expand_dir(trs_printer_dir, browse_dir);
         trs_gui_file_browse(browse_dir, trs_printer_dir, 1," Printer Output ");
         break;
     }
  }
}

void trs_gui_rom_files(void)
{
  MENU_ENTRY romfile_menu[] = 
  {{"Model 1 Romfile:",MENU_TITLE_TYPE,1},
   {"   ",MENU_NORMAL_TYPE,2},
   {"Model 3 Romfile:",MENU_TITLE_TYPE,3},
   {"   ",MENU_NORMAL_TYPE,4},
   {"Model 4p Romfile:",MENU_TITLE_TYPE,5},
   {"   ",MENU_NORMAL_TYPE,6},
   {"",0,-1}};
   char browse_dir[FILENAME_MAX];
   int selection = 1;
   int done = 0;
   
   while(!done) {
     trs_gui_clear_screen();
     trs_gui_limit_string(romfile,&romfile_menu[1].title[2],60);
     trs_gui_limit_string(romfile3,&romfile_menu[3].title[2],60);
     trs_gui_limit_string(romfile4p,&romfile_menu[5].title[2],60);
     selection = trs_gui_display_menu("SDLTRS ROM File Menu",romfile_menu, selection);
     switch(selection) {
       case -1:
         done = 1;
         break;
       case 1:
         if (romfile[0]==0)
           trs_expand_dir(".",browse_dir);
         else
           trs_remove_dir(romfile, browse_dir);
         trs_gui_file_browse(browse_dir, romfile, 0," Model 1 ROM ");
         break;
       case 3:
         if (romfile3[0]==0)
           trs_expand_dir(".",browse_dir);
         else
           trs_remove_dir(romfile3, browse_dir);
         trs_gui_file_browse(browse_dir, romfile3, 0," Model 3 ROM ");
         break;
       case 5:
         if (romfile4p[0]==0)
           trs_expand_dir(".",browse_dir);
         else
           trs_remove_dir(romfile4p, browse_dir);
         trs_gui_file_browse(browse_dir, romfile4p, 0," Model 4p ROM ");
         break;
     }
  }
}

void trs_gui_about_sdltrs(void)
{
  int key;
  int done = 0;
  
  trs_gui_clear_screen();
  trs_gui_frame(0,0,64,16);
  trs_gui_write_text("About SDLTRS", 2, 0, 0);
  
  trs_gui_center_text("SDLTRS",3,0);
  trs_gui_center_text("Version 0.4",4,0);
  trs_gui_center_text("http://sdltrs.sourceforge.net",5,0);
  trs_gui_center_text("Copyright (C) 2006-2009 Mark Grebe",7,0);
  trs_gui_center_text("Based on xtrs 4.9c",9,0);
  trs_gui_center_text("By Tim Mann",10,0);
  trs_gui_center_text("Which was Based on xtrs 1.0",11,0);
  trs_gui_center_text("Copyright (C) 1992 Clarendon Hill Software",12,0);

  trs_x_flush();

  do {
    key = trs_gui_get_key();
    switch(key) {
      case SDLK_ESCAPE:
      case SDLK_RETURN:
        done = 1;
        break;
    }
  } while (!done);
}

void trs_gui_write_config(void)
{
  char filename[FILENAME_MAX];
  char browse_dir[FILENAME_MAX];
  int ret;

  trs_expand_dir(".",browse_dir);
  ret = trs_gui_input_string("Enter Filename (without extension), TAB selects directory", 
                              browse_dir,filename, 1);
  if (ret)
    return;
  strcat(filename,".t8c");
  trs_write_config_file(filename);
}

int trs_gui_read_config(void)
{
  char filename[FILENAME_MAX];
  char browse_dir[FILENAME_MAX];
  int ret;

  trs_expand_dir(".",browse_dir);
  ret = trs_gui_file_browse(browse_dir, filename, 0," Configuration (.t8c)");
  if (ret == -1)
    return(ret);
  trs_load_config_file(filename);
  trs_gui_new_machine();
  return(0);
}

static int trs_gui_config_management(void)
{
  MENU_ENTRY misc_menu[] =
#ifdef MACOSX
  {{"Save Emulator State      (CMD-S)",MENU_NORMAL_TYPE,1},
   {"Load Emulator State      (CMD-L)",MENU_NORMAL_TYPE,2},
   {"Write Configuration File (CMD-W)",MENU_NORMAL_TYPE,3},
   {"Read Configuration File  (CMD-R)",MENU_NORMAL_TYPE,4},
#else   
  {{"Save Emulator State      (ALT-S)",MENU_NORMAL_TYPE,1},
   {"Load Emulator State      (ALT-L)",MENU_NORMAL_TYPE,2},
   {"Write Configuration File (ALT-W)",MENU_NORMAL_TYPE,3},
   {"Read Configuration File  (ALT-R)",MENU_NORMAL_TYPE,4},
#endif   
   {"",0,-1}};
   int selection = 0;
   int done = 0;
   int ret;
   int read = 0;
   
   while(!done) {
     trs_gui_clear_screen();
     selection = trs_gui_display_menu("SDLTRS Configuration Files Menu",
                                      misc_menu, selection);

     switch(selection) {
       case 0:
         trs_gui_save_state();   
         break;
       case 1:
         trs_gui_load_state();
         trs_screen_init();
         grafyx_redraw();
         done = 1;
         read = 1;   
         break;
       case 2:
         trs_model = local_trs_model;
         trs_charset1 = local_trs_charset1;
         trs_charset3 = local_trs_charset3;
         trs_charset4 = local_trs_charset4;
         foreground = local_foreground;
         background = local_background;
         gui_foreground = local_gui_foreground;
         gui_background = local_gui_background;
         trs_show_led = gui_show_led;
         resize3 = gui_resize3;
         resize4 = gui_resize4;
         window_border_width = gui_border_width;
         trs_joystick_num = gui_joystick_num;
         trs_gui_write_config();
         break;
       case 3:
         ret = trs_gui_read_config();
         if (ret==-1)
           break;
         done = 1;
         read = 1;
         break;
       case -1:
         done = 1;
         break;
     }
  }
  return(read);
}

void trs_gui_save_state(void)
{
  char filename[FILENAME_MAX];
  char browse_dir[FILENAME_MAX];
  int ret;

  filename[0] = 0;
  trs_expand_dir(trs_state_dir, browse_dir);
  ret = trs_gui_input_string("Enter Filename (without extension), TAB selects directory", 
                              browse_dir,filename, 1);
  if (ret)
    return;
  strcat(filename,".t8s");
  trs_state_save(filename);
}

void trs_gui_load_state(void)
{
  char filename[FILENAME_MAX];
  char browse_dir[FILENAME_MAX];
  int ret;

  trs_expand_dir(trs_state_dir,browse_dir);
  ret = trs_gui_file_browse(browse_dir, filename, 0," Saved State (.t8s) ");
  if (ret == -1)
    return;
  trs_state_load(filename);
}

void trs_gui_new_machine(void)
{
  trs_screen_var_reset();
  romin = 0;
  mem_init(); 
  trs_disk_init(0);
  trs_rom_init();
  trs_screen_init();
  screen_init();
  trs_timer_init();
  trs_reset(1);    
}

void trs_gui(void)
{
  MENU_ENTRY main_menu[] = 
  {
#ifdef MACOSX  
   {"Floppy Disk Management (CMD-D)",MENU_NORMAL_TYPE,1},
   {"Hard Disk Management   (SHIFT-CMD-D)",MENU_NORMAL_TYPE,2},
   {"Cassette Management    (CMD-T)",MENU_NORMAL_TYPE,3},
#else
   {"Floppy Disk Management (ALT-D)",MENU_NORMAL_TYPE,1},
   {"Hard Disk Management   (SHIFT-ALT-D)",MENU_NORMAL_TYPE,2},
   {"Cassette Management    (ALT-T)",MENU_NORMAL_TYPE,3},
#endif   
   {"TRS80 Model Selection",MENU_NORMAL_TYPE,4},
   {"Configuration/State File Management",MENU_NORMAL_TYPE,5},
   {"Printer Management",MENU_NORMAL_TYPE,6},
   {"Select Default Directories",MENU_NORMAL_TYPE,7},
   {"Select ROM Files",MENU_NORMAL_TYPE,8},
   {"Display Settings",MENU_NORMAL_TYPE,9},
   {"Joystick Settings",MENU_NORMAL_TYPE,10},
   {"Miscellaneous Settings",MENU_NORMAL_TYPE,11},
   {"About SDLTRS",MENU_NORMAL_TYPE,12},
   {"",0,-1}};
   int selection = 0;
   int done = 0;
   
   local_trs_model = trs_model; 
   local_trs_charset1 = trs_charset1;
   local_trs_charset3 = trs_charset3;
   local_trs_charset4 = trs_charset4;
   local_foreground = foreground;
   local_background = background; 
   local_gui_foreground = gui_foreground;
   local_gui_background = gui_background; 
   gui_show_led = trs_show_led;
   gui_resize3 = resize3;
   gui_resize4 = resize4;
   gui_border_width = window_border_width;
   gui_keypad_joystick = trs_keypad_joystick;
   gui_joystick_num = trs_joystick_num;
   
   while(!done) {
     trs_gui_clear_screen();
     selection = trs_gui_display_menu("SDLTRS Main Menu",main_menu, selection);
     switch(selection) {
       case -1:
         done = 1;
         break;
       case 0:
         trs_gui_disk_management();
         break;
       case 1:
         trs_gui_hard_management();
         break;
       case 2:
         trs_gui_cassette_management();
         break;
       case 3:
         trs_gui_model();
         break;
       case 4:
         if (trs_gui_config_management())
           return;
         break;
       case 5:
         trs_gui_printer_management();
         break;
       case 6:
         trs_gui_default_dirs();
         break;
       case 7:
         trs_gui_rom_files();
         break;
       case 8:
         trs_gui_display_management();
         break;
       case 9:
         trs_gui_joystick_management();
         break;
       case 10:
         trs_gui_misc_management();
         break;
       case 11:
         trs_gui_about_sdltrs();
         break;
     }
  }

  if (trs_keypad_joystick != gui_keypad_joystick) {
    trs_keypad_joystick = gui_keypad_joystick;
    trs_set_keypad_joystick();
  }
 
  if (trs_joystick_num != gui_joystick_num) {
    trs_joystick_num = gui_joystick_num;
    trs_open_joystick();
  }
  
  if (trs_model != local_trs_model) {
    trs_model = local_trs_model;
    trs_charset1 = local_trs_charset1;
    trs_charset3 = local_trs_charset3;
    trs_charset4 = local_trs_charset4;
    foreground = local_foreground;
    background = local_background;
    gui_foreground = local_gui_foreground;
    gui_background = local_gui_background;
    trs_show_led = gui_show_led;
    resize3 = gui_resize3;
    resize4 = gui_resize4;
    window_border_width = gui_border_width;
    trs_gui_new_machine();
  }
  else if ((trs_charset1 != local_trs_charset1) ||
           (trs_charset3 != local_trs_charset3) ||
           (trs_charset4 != local_trs_charset4) ||
           (foreground != local_foreground) ||
           (background != local_background) ||
           (gui_foreground != local_gui_foreground) ||
           (gui_background != local_gui_background) ||
           (gui_show_led != trs_show_led) ||
           (gui_resize3 != resize3) ||
           (gui_resize4 != resize4) ||
           (gui_border_width != window_border_width))
  {
    trs_charset1 = local_trs_charset1;
    trs_charset3 = local_trs_charset3;
    trs_charset4 = local_trs_charset4;
    foreground = local_foreground;
    background = local_background;
    gui_foreground = local_gui_foreground;
    gui_background = local_gui_background;
    trs_show_led = gui_show_led;
    resize3 = gui_resize3;
    resize4 = gui_resize4;
    window_border_width = gui_border_width;
    trs_screen_init();
    grafyx_redraw();
  }
}

