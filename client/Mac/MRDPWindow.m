
#import <Foundation/Foundation.h>

#import "mfreerdp.h"
#import "MRDPWindow.h"

int mf_AppWindowInit(mfContext* mfc, mfAppWindow* appWindow)
{
    return 1;
}

void mf_DestroyWindow(mfContext* mfc, mfAppWindow* appWindow)
{
}

void mf_MoveWindow(mfContext* mfc, mfAppWindow* appWindow,
                   int x, int y, int width, int height)
{
}

void mf_UpdateWindowArea(mfContext* mfc, mfAppWindow* appWindow,
                         int x, int y, int width, int height)
{
}

void mf_SetWindowVisibilityRects(mfContext* mfc, mfAppWindow* appWindow,
                                 UINT32 rectsOffsetX, UINT32 rectsOffsetY,
                                 RECTANGLE_16* rects, int nrects)
{
}

void mf_SetWindowText(mfContext* mfc, mfAppWindow* appWindow, char* name)
{
}

void mf_ShowWindow(mfContext* mfc, mfAppWindow* appWindow, BYTE state)
{
}
