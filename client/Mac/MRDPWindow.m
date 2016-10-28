
/**
 * FreeRDP: A Remote Desktop Protocol Implementation
 * MacFreeRDP
 *
 * Copyright 2016 Idan Freiberg <speidy@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>

#import "mfreerdp.h"
#import "MRDPWindow.h"
#import "MRDPWindowView.h"
#import "freerdp/log.h"

#define TAG CLIENT_TAG("mac")

void windows_to_apple_coords(MRDPWindowView* view, NSRect* r)
{
    r->origin.y = [view frame].size.height - (r->origin.y + r->size.height);
}

int mf_AppWindowInit(mfContext* mfc, mfAppWindow* appWindow)
{
	WLog_INFO(TAG, "mf_AppWindowInit");
	NSRect rect;
    NSWindow* window = NULL;
    MRDPWindowView *view = NULL;
    MRDPView *mainView = mfc->view;
    
	rect = NSMakeRect(appWindow->x, appWindow->height - appWindow->y, appWindow->width, appWindow->height);
    
    view = [[MRDPWindowView alloc] initWithFrame:rect];
    [view init_view:mfc];
    
    window = [[[NSWindow alloc] initWithContentRect:rect
                                styleMask:NSBorderlessWindowMask
                                backing:NSBackingStoreBuffered
                                defer:NO] autorelease];
    [window setTitle: [NSString stringWithUTF8String: appWindow->title]];
    [window setBackgroundColor:[NSColor blueColor]];
    [window makeKeyAndOrderFront:NSApp];
    [window setContentView: view];
    
    appWindow->handle = window;
    return 1;
}

void mf_DestroyWindow(mfContext* mfc, mfAppWindow* appWindow)
{
	WLog_INFO(TAG, "mf_DestroyWindow");
    MRDPWindowView* view;
    NSWindow *window;
    
    window = appWindow->handle;
    view = [appWindow->handle contentView];
    
    [view dealloc];
    [window close];
    [window dealloc];
    
    appWindow->handle = NULL;
}

void mf_MoveWindow(mfContext* mfc, mfAppWindow* appWindow,
		int x, int y, int width, int height)
{
	WLog_INFO(TAG, "mf_MoveWindow x: %d y: %d width: %d height: %d", x, y, width, height);
	NSRect rect = [appWindow->handle frame];

	rect.origin.x = x;
	rect.origin.y = height - y;
	rect.size = CGSizeMake(width, height);

	[appWindow->handle setFrame:rect display:YES animate:YES];
}

void mf_UpdateWindowArea(mfContext* mfc, mfAppWindow* appWindow,
						 int x, int y, int width, int height)
{
	WLog_INFO(TAG, "mf_UpdateWindowArea");
	int ax, ay;
	rdpSettings *rdpSettings = mfc->context.settings;
	NSWindow *window = appWindow->handle;
    NSRect rect;

	ax = x + appWindow->windowOffsetX;
	ay = y + appWindow->windowOffsetY;

	if (ax + width > appWindow->windowOffsetX + appWindow->width)
		width = (appWindow->windowOffsetX + appWindow->width - 1) - ax;
	if (ay + height > appWindow->windowOffsetY + appWindow->height)
		height = (appWindow->windowOffsetY + appWindow->height - 1) - ay;

//    xf_lock_x11(mfc, TRUE);

	if (rdpSettings->SoftwareGdi)
	{
//  	  XPutImage(mfc->display, mfc->primary, appWindow->gc, mfc->image,
//  				ax, ay, ax, ay, width, height);
	}

    rect = NSMakeRect(ax, ay, width, height);
    MRDPWindowView *view = [window contentView];
    windows_to_apple_coords(view, &rect);
    [view setNeedsDisplayInRect:rect];
    

//    XCopyArea(mfc->display, mfc->primary, appWindow->handle, appWindow->gc,
//  			ax, ay, width, height, x, y);

//    XFlush(mfc->display);

//    xf_unlock_x11(mfc, TRUE);
}

void mf_SetWindowVisibilityRects(mfContext* mfc, mfAppWindow* appWindow,
		UINT32 rectsOffsetX, UINT32 rectsOffsetY,
		RECTANGLE_16* rects, int nrects)
{
	WLog_INFO(TAG, "mf_SetWindowVisibilityRects");
}

void mf_SetWindowText(mfContext* mfc, mfAppWindow* appWindow, char* name)
{
	WLog_INFO(TAG, "mf_SetWindowText: %s", name);
}

void mf_ShowWindow(mfContext* mfc, mfAppWindow* appWindow, BYTE state)
{
	WLog_INFO(TAG, "mf_ShowWindow, state: 0x%08x", state);
}


