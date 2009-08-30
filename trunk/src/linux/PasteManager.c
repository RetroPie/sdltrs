#include <stdio.h>
#include <limits.h>
#include <X11/Xutil.h>

#include "SDL/SDL.h"
#include "SDL/SDL_syswm.h"

/* forward declarations */
static int init_scrap(void);
static int lost_scrap(void);
static void put_scrap(int srclen, char *src);
static void get_scrap(int *dstlen, char **dst);
/* The system message filter function -- handle clipboard messages */
static int clipboard_filter(const SDL_Event *event);

/* SDL and X variables */
static Display *SDL_Display;
static Window SDL_Window;
static void (*Lock_Display)(void);
static void (*Unlock_Display)(void);
static Atom _atom_CLIPBOARD;
static Atom _atom_SDL;
static Atom _atom_UTF8;
static Atom _atom_TEXT;
static Atom _atom_COMPOUND;
static Time _cliptime = CurrentTime;
static char *clipboard = NULL;

/* Maximum size to send or receive per request. */
#define MIN(a,b) (a<b ? a : b)
#define MAX_CHUNK_SIZE(display)                                    \
    MIN(262144, /* 65536 * 4 */                                    \
        (XExtendedMaxRequestSize (display)) == 0                   \
        ? XMaxRequestSize (display) - 100                          \
        : XExtendedMaxRequestSize (display) - 100)

/* Emulator specific variables */
static int charCount = 0;
static unsigned char *pasteString;
static int pasteStringLength = 0;
static int firstTime = 1;

/* Extern emulator routines */
extern int trs_paste_started();
extern void trs_copy_ended();

static int init_scrap(void)
{
  SDL_SysWMinfo info;
  int retval;

  /* Grab the window manager specific information */
  retval = -1;
  SDL_SetError("SDL is not running on known window manager");

  SDL_VERSION(&info.version);
  if ( SDL_GetWMInfo(&info) )
    {
    /* Save the information for later use */
    if ( info.subsystem == SDL_SYSWM_X11 )
    {
      SDL_Display = info.info.x11.display;
      SDL_Window = info.info.x11.window;
      Lock_Display = info.info.x11.lock_func;
      Unlock_Display = info.info.x11.unlock_func;
      _atom_CLIPBOARD = XInternAtom (SDL_Display, "CLIPBOARD", False);
      _atom_UTF8 = XInternAtom (SDL_Display, "UTF8_STRING", False);
      _atom_TEXT = XInternAtom (SDL_Display, "TEXT", False);
      _atom_COMPOUND = XInternAtom (SDL_Display, "COMPOUND_TEXT", False);
      _atom_SDL = XInternAtom (SDL_Display, "SDL_SELECTION", False);

      /* Enable the special window hook events */
      SDL_EventState(SDL_SYSWMEVENT, SDL_ENABLE);
      SDL_SetEventFilter(clipboard_filter);

      retval = 0;
    }
    else
    {
      SDL_SetError("SDL is not running on X11");
    }

  }
  return(retval);
}

static int lost_scrap(void)
{
  int retval;
  Lock_Display();
  retval = ( XGetSelectionOwner(SDL_Display, _atom_CLIPBOARD) != SDL_Window );
  Unlock_Display();

  return(retval);
}

static void put_scrap(int srclen, char *src)
{
  int dstlen;
  char *dst;
  int result;

  dstlen = srclen;
  dst = (char *)malloc(dstlen);
  strcpy(dst, src);
  if (clipboard)
    free(clipboard);
  clipboard = dst;
  Lock_Display();

  XChangeProperty(SDL_Display, DefaultRootWindow(SDL_Display),
      _atom_CLIPBOARD, XA_STRING, 8, PropModeReplace, dst, dstlen);

  XSync (SDL_Display, False);
  if ( lost_scrap() ) {
    result = XSetSelectionOwner(SDL_Display, _atom_CLIPBOARD, SDL_Window, CurrentTime);
  }
  Unlock_Display();
}

static Window get_scrap_owner (Atom *selection)
{
    int i = 0;
    static Atom buffers[] = { XA_PRIMARY, XA_SECONDARY, XA_CUT_BUFFER0,
                              XA_CUT_BUFFER1, XA_CUT_BUFFER2, XA_CUT_BUFFER3,
                              XA_CUT_BUFFER4, XA_CUT_BUFFER5, XA_CUT_BUFFER6,
                              XA_CUT_BUFFER7 };

    Window owner = XGetSelectionOwner (SDL_Display, *selection);
    if (owner != None)
        return owner;

    owner = XGetSelectionOwner (SDL_Display, _atom_CLIPBOARD);
    if (owner != None)
        return owner;

    while (i < 10)
    {
        owner = XGetSelectionOwner (SDL_Display, buffers[i]);
        if (owner != None)
        {
            *selection = buffers[i];
            return owner;
        }
        i++;
    }
    
    return None;
}

static void get_scrap(int *dstlen, char **dst)
{
  Window owner;
  Atom source;
  Atom selection;
  time_t start;
  Atom sel_type;
  int sel_format;
  unsigned long nbytes;
  unsigned long overflow;
  unsigned char *src;
  unsigned long offset = 0;
  unsigned long chunk = 0;
  char *retval = NULL;
  unsigned long length;
  int step = 1;
  XEvent ev;
  Time timestamp;
  Atom format;

  *dstlen = 0;

  /* If we are the owner, simply return the clip buffer, if it matches
   * the request type.
   */
  if (!lost_scrap ())
  {
    *dstlen = strlen(clipboard);
    *dst = strdup(clipboard);
    if (*dst == NULL)
      *dstlen = 0;
    return;
  }

  Lock_Display();

  /* Find a selection owner. */
  source = _atom_CLIPBOARD;
  owner = get_scrap_owner (&source);
  if (owner == None)
  {
    Unlock_Display ();
    *dstlen = 0;
    *dst = NULL;
    return;
  }

  timestamp =  _cliptime;

  /* Copy and convert the selection into our SDL_SELECTION atom of the
   * window. 
   * Flush afterwards, so we have an immediate effect and do not receive
   * the old buffer anymore.
   */
  XConvertSelection (SDL_Display, source, XA_STRING, _atom_SDL, SDL_Window,
                     timestamp);
  XSync (SDL_Display, False);

  /* Let's wait for the SelectionNotify event from the callee and
   * react upon it as soon as it is received.
   */
  for (start = time (0);;)
  {
      if (XCheckTypedWindowEvent (SDL_Display, SDL_Window,
                                  SelectionNotify, &ev))
          break;
      if (time (0) - start >= 5)
      {
        Unlock_Display ();
        *dstlen = 0;
        *dst = NULL;
        return;
      }
  }

  /* Get any property type and check the sel_type afterwards to decide
   * what to do.
   */
  if (XGetWindowProperty (SDL_Display, ev.xselection.requestor,
                          _atom_SDL, 0, 0, True,
                          AnyPropertyType, &sel_type, &sel_format,
                          &nbytes, &overflow, &src) != Success)
  {
    XFree (src);
    Unlock_Display ();
    *dstlen = 0;
    *dst = NULL;
    return;
  }

  /* Any property type of
   * XA_STRING, UTF8_STRING and TEXT is valid.
   */
  if (sel_type != _atom_UTF8 && sel_type != _atom_TEXT
      && sel_type != XA_STRING)
  {
    /* No matching text type found. Return nothing then. */
    XFree (src);
    *dstlen = 0;
    *dst = NULL;
    return;
  }

  /* Anything is fine, so copy the buffer and return it. */
  switch (sel_format)
  {
    case 16:
      step = sizeof (short) / 2;
      break;
    case 32:
      step = sizeof (long) / 4;
      break;
    case 8:
    default:
      step = sizeof (char);
      length = overflow; /* 8 bit size is already correctly set in nbytes.*/
      break;
    }

  /* X11 guarantees NULL termination, add an extra byte. */
  length = step * overflow;
  retval = malloc (length + 1);
  if (retval)
  {
    unsigned long boffset = 0;
    chunk = MAX_CHUNK_SIZE(SDL_Display);
    memset (retval, 0, (size_t) (length + 1));

    /* Read as long as there is data. */
    while (overflow)
    {
      if (XGetWindowProperty (SDL_Display, ev.xselection.requestor,
                              _atom_SDL, offset, chunk, True,
                              AnyPropertyType, &sel_type, &sel_format,
                              &nbytes, &overflow, &src) != Success)
      {
        break;
      }
            
      offset += nbytes / (32 / sel_format);
      nbytes *= step * sel_format / 8;
      memcpy (retval + boffset, src, nbytes);
      boffset += nbytes;
      XFree (src);
    }
  }
  else
  {
     /* ENOMEM */
    *dstlen = 0;
    *dst = NULL;
    return; 
  }

  Unlock_Display ();
  *dst = retval;
  *dstlen = strlen(retval);
  return;
}

static int clipboard_filter(const SDL_Event *event)
{
  /* Post all non-window manager specific events */
  if ( event->type != SDL_SYSWMEVENT ) {
    return(1);
  }

  /* Handle window-manager specific clipboard events */
  switch (event->syswm.msg->event.xevent.type) {
    /* Copy the selection from clipboard to the requested property */
    case SelectionRequest: {
      XSelectionRequestEvent *req;
      XEvent sevent;
      int seln_format;
      unsigned long nbytes;
      unsigned long overflow;
      unsigned char *seln_data;

      req = &event->syswm.msg->event.xevent.xselectionrequest;
      sevent.xselection.type = SelectionNotify;
      sevent.xselection.display = req->display;
      sevent.xselection.selection = req->selection;
      sevent.xselection.target = None;
      sevent.xselection.property = None;
      sevent.xselection.requestor = req->requestor;
      sevent.xselection.time = req->time;
      if ( XGetWindowProperty(SDL_Display, DefaultRootWindow(SDL_Display),
                              _atom_CLIPBOARD, 0, INT_MAX/4, False, req->target,
                              &sevent.xselection.target, &seln_format,
                              &nbytes, &overflow, &seln_data) == Success )
        {
          if ( sevent.xselection.target == req->target )
            {
              if ( sevent.xselection.target == XA_STRING )
                {
                  if ( seln_data[nbytes-1] == '\0' )
                    --nbytes;
                }
              XChangeProperty(SDL_Display, req->requestor, req->property,
                sevent.xselection.target, seln_format, PropModeReplace,
                                                      seln_data, nbytes);
              sevent.xselection.property = req->property;
            }
          XFree(seln_data);
        }
      XSendEvent(SDL_Display,req->requestor,False,0,&sevent);
      XSync(SDL_Display, False);
    }
    break;
  }

  /* Post the event for X11 clipboard reading above */
  return(1);
}
int PasteManagerGetChar(unsigned short *character)
{
  if (charCount) {
    *character = pasteString[pasteStringLength - charCount];
    charCount--;
    if (charCount)
      return(1);
    else {
      free(pasteString);
      return(0);
    }
  }
  else {
    free(pasteString);
    return(0);
  }
}

int PasteManagerStartPaste(void)
{ 
  int result;

  if (firstTime) {
     result = init_scrap();
     if (result == -1) {
       charCount = 0;
       return 0;
     }
     firstTime = 0;
  }

  get_scrap(&pasteStringLength, (char**) &pasteString);

  charCount = pasteStringLength;
  if (charCount) {
    trs_paste_started();
    return 1;
  } else {
    free(pasteString);
    return 0; 
  }
}

void PasteManagerStartCopy(char *string)
{
  int result;

  if (firstTime) {
     result = init_scrap();
     if (result == -1) {
       trs_end_copy();
       return;
     }
     firstTime = 0;
  }

  put_scrap(strlen(string)+1, string);
  trs_end_copy();
}
