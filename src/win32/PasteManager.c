#include "windows.h"

extern int trs_paste_started();

static int charCount = 0;
static unsigned char *pasteString;
static int pasteStringLength = 0;
static HANDLE hClipboardData;

int PasteManagerGetChar(unsigned short *character)
{
	if (charCount) {
		*character = pasteString[pasteStringLength - charCount];
		charCount--;
		if (charCount)
			return(TRUE);
		else {
			GlobalUnlock(hClipboardData);
            CloseClipboard();
			return(FALSE);
			}
		}
	else {
		return(FALSE);
		}
}

int PasteManagerStartPaste(void)
{    
    if (IsClipboardFormatAvailable(CF_TEXT)) {
        if (OpenClipboard(NULL)) {
            hClipboardData = GetClipboardData(CF_TEXT);
            pasteString = (unsigned char *)GlobalLock(hClipboardData);
            charCount = pasteStringLength = strlen(pasteString);
            trs_paste_started();
            return TRUE;
        } else {
            pasteString = NULL;
            charCount = 0;
            return FALSE;
        }
    }
    else {
        pasteString = NULL;
        charCount = 0;
        return FALSE;
    }

}

void PasteManagerStartCopy(char *string)
{
    HANDLE hCopyData;
    char *pchData;

    if (OpenClipboard(NULL)) {
        EmptyClipboard();
        hCopyData = GlobalAlloc(GMEM_DDESHARE, strlen(string)+1);
        pchData = (char *)GlobalLock(hCopyData);
        strcpy(pchData, string);
        GlobalUnlock(hCopyData);
        SetClipboardData(CF_TEXT, hCopyData);
        CloseClipboard();
    }
    trs_end_copy();
}
