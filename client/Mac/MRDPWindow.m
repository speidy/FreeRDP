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
#import "MRDPRail.h"
#import "freerdp/log.h"

#define TAG CLIENT_TAG("mac")

@implementation MRDPWindow

- (BOOL) becomeFirstResponder
{
	return YES;
}

- (BOOL) canBecomeKeyWindow
{
	NSWindow *parent = [self parentWindow];
	if (parent)
	{
		return NO;
	}
	return YES;
}

- (BOOL) canBecomeMainWindow
{
	NSWindow *parent = [self parentWindow];
	if (parent)
	{
		return NO;
	}
	return YES;
}

- (void) windowDidMiniaturize:(NSNotification *)notification
{
	/* shouldn't really happen from borderless local window */
	mac_rail_send_client_system_command(mfc, self.windowId, SC_MINIMIZE);
}

- (void) windowDidDeminiaturize:(NSNotification *)notification
{
	mac_rail_send_client_system_command(mfc, self.windowId, SC_RESTORE);
}

- (void) windowDidResize:(NSNotification *)notification
{
	NSLog(@"Resize, %f %f %f %f", self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
//	mac_rail_send_client_window_move(mfc, self.windowId, self.x, self.y, self.width, self.height);
}

+ (void)windows_to_mac_coord: (rdpSettings *)rdpSettings rect:(NSRect*)r
{
	r->origin.y = rdpSettings->DesktopHeight - (r->origin.y + r->size.height);
}

+ (void)windows_to_apple_coords: (MRDPWindowView*)view rect:(NSRect*)r
{
	r->origin.y = [view frame].size.height - (r->origin.y + r->size.height);
}

+ (void)windows_to_apple_coords_screen: (MRDPWindowView*)view rect:(NSRect*)r
{
	NSScreen* screen = [NSScreen mainScreen];
	NSRect workAreaFrame = [screen visibleFrame];
	r->origin.y = workAreaFrame.size.height - (r->origin.y + r->size.height);
}

-(id) initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
	self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
	return self;
}

- (void) mf_AppWindowInit: (mfContext*) mfctx
{
	WLog_INFO(TAG, "mf_AppWindowInit");
	NSRect rect;
	MRDPWindowView *view = NULL;

	self->mfc = mfctx;
	
	rect = NSMakeRect(self.windowOffsetX, self.windowOffsetY, self.windowWidth, self.windowHeight);
	[MRDPWindow windows_to_mac_coord:mfc->context.settings rect:&rect];

	view = [[MRDPWindowView alloc] initWithFrame:rect];
	[view init_view:mfc appWindow:self];

	[self setTitle: [NSString stringWithUTF8String: self.wnd_title]];
	[self setBackgroundColor:[NSColor clearColor]];
	[self setContentView: view];
	[self setDelegate:self];
	
	/* add only window owners to window menu */
	if (self.canBecomeKeyWindow)
	{
		[NSApp addWindowsItem:self title:[self title] filename:NO];
	}
}

- (void) mf_DestroyWindow;
{
	WLog_INFO(TAG, "mf_DestroyWindow");
	MRDPWindowView* view;

	view = [self contentView];

	[self orderOut:NSApp];
	[self close];
	//[self dealloc];
	//[view dealloc];
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
	[MRDPWindow windows_to_mac_coord:mfc->context.settings rect:&rect];

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
	[MRDPWindow windows_to_apple_coords:view rect:&rect];
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
			[self miniaturize:NSApp];
			break;
		case WINDOW_SHOW_MAXIMIZED:
			[self deminiaturize:NSApp];
			break;
		case WINDOW_SHOW:
			[self makeKeyAndOrderFront:NSApp];
			[NSApp activateIgnoringOtherApps:YES];
			break;
	}
	self.rail_state = state;
}

@end

