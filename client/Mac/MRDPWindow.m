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

@implementation MRDPWindow


void windows_to_mac_coord(rdpSettings *rdpSettings, NSRect* r)
{
	r->origin.y = rdpSettings->DesktopHeight - (r->origin.y + r->size.height);
}

void windows_to_apple_coords(MRDPWindowView* view, NSRect* r)
{
	r->origin.y = [view frame].size.height - (r->origin.y + r->size.height);
}

void windows_to_apple_coords_screen(MRDPWindowView* view, NSRect* r)
{
	NSScreen* screen = [NSScreen mainScreen];
	NSRect workAreaFrame = [screen visibleFrame];
	r->origin.y = workAreaFrame.size.height - (r->origin.y + r->size.height);
}

- (void) mf_AppWindowInit: (mfContext*) mfc
{
	WLog_INFO(TAG, "mf_AppWindowInit");
	NSRect rect;
	MRDPWindowView *view = NULL;

	self.mfc = mfc;
	
	rect = NSMakeRect(self.x, self.y, self.width, self.height);
	windows_to_mac_coord(mfc->context.settings, &rect);

	view = [[MRDPWindowView alloc] initWithFrame:rect];
	[view init_view:mfc appWindow:self];

	NSUInteger styleMask = NSBorderlessWindowMask;
	[self initWithContentRect:rect styleMask:styleMask backing:NSBackingStoreBuffered defer:NO];
	[self setTitle: [NSString stringWithUTF8String: self.wnd_title]];
	[self setBackgroundColor:[NSColor blueColor]];
	[self setContentView: view];
}

- (void) mf_DestroyWindow;
{
	WLog_INFO(TAG, "mf_DestroyWindow");
	MRDPWindowView* view;

	view = [self contentView];

	[self orderOut:NSApp];
	[self close];
	[self dealloc];
	[view dealloc];
}

- (void) mf_MoveWindow:(int)x y:(int)y width:(int)width height:(int)height
{
	WLog_INFO(TAG, "mf_MoveWindow x: %d y: %d width: %d height: %d", x, y, width, height);
	MRDPWindowView* view;
	NSRect rect;

	view = [self contentView];

	if ((width * height) < 1)
	{
		return;
	}

	self.x = x;
	self.y = y;
	self.width = width;
	self.height = height;

	rect = NSMakeRect(x, y, width, height);
	windows_to_mac_coord(self.mfc->context.settings, &rect);

	[self setFrame:rect display:YES animate:NO];
	[self mf_UpdateWindowArea:0 y:0 width:width height:height];
}

- (void) mf_UpdateWindowArea:(int)x y:(int)y width:(int)width height:(int)height
{
	WLog_INFO(TAG, "mf_UpdateWindowArea");
	MRDPWindowView *view;
	NSRect rect;

	NSLog(@"mf_UpdateWindowArea x %d y %d width %d height %d", x, y, width, height);

	view = [self contentView];

	rect = NSMakeRect(x, y, width, height);
	windows_to_apple_coords(view, &rect);
	[view setNeedsDisplayInRect:rect];
}

- (void) mf_SetWindowVisibilityRects:(UINT32)rectsOffsetX rectsOffsetY:(UINT32)rectsOffsetY rects:(RECTANGLE_16*)rects nrects:(int)nrects
{
	WLog_INFO(TAG, "mf_SetWindowVisibilityRects");
}

- (void) mf_SetWindowText:(char*) name;
{
	WLog_INFO(TAG, "mf_SetWindowText: %s", name);
	[self setTitle: [NSString stringWithUTF8String: self.wnd_title]];
}

- (void) mf_ShowWindow:(BYTE)state;
{
	WLog_INFO(TAG, "mf_ShowWindow, state: 0x%08x", state);
	switch (state)
	{
		case WINDOW_HIDE:
			[self orderOut:NSApp];
			break;
		case WINDOW_SHOW_MINIMIZED:
			//TODO
			break;
		case WINDOW_SHOW_MAXIMIZED:
			//TODO
			break;
		case WINDOW_SHOW:
			[self makeKeyAndOrderFront:NSApp];
			[NSApp activateIgnoringOtherApps:YES];
			break;
	}
}

@end

