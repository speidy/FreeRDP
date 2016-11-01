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

#import "mfreerdp.h"

#import "freerdp/freerdp.h"
#import "freerdp/channels/channels.h"
#import "freerdp/client/rail.h"

//typedef struct mf_app_window mfAppWindow;
//
//struct mf_app_window
//{
//	mfContext* mfc;
//
//	int x;
//	int y;
//	int width;
//	int height;
//	char* title;
//
//	UINT32 windowId;
//	UINT32 ownerWindowId;
//
//	UINT32 dwStyle;
//	UINT32 dwExStyle;
//	UINT32 showState;
//
//	INT32 clientOffsetX;
//	INT32 clientOffsetY;
//	UINT32 clientAreaWidth;
//	UINT32 clientAreaHeight;
//
//	INT32 windowOffsetX;
//	INT32 windowOffsetY;
//	INT32 windowClientDeltaX;
//	INT32 windowClientDeltaY;
//	UINT32 windowWidth;
//	UINT32 windowHeight;
//	UINT32 numWindowRects;
//	RECTANGLE_16* windowRects;
//
//	INT32 visibleOffsetX;
//	INT32 visibleOffsetY;
//	UINT32 numVisibilityRects;
//	RECTANGLE_16* visibilityRects;
//
//	UINT32 localWindowOffsetCorrX;
//	UINT32 localWindowOffsetCorrY;
//
//	CGContextRef gc;
//	//int shmid;
//	NSWindow* handle;
//	//Window* xfwin;
//	BOOL fullscreen;
//	BOOL decorations;
//	BOOL is_mapped;
//	BOOL is_transient;
//	//xfLocalMove local_move;
//	BYTE rail_state;
//	BOOL rail_ignore_configure;
//};
//
@interface MRDPWindow : NSWindow
{
	mfContext *mfc;
	freerdp *instance;
	DWORD kbdModFlags;
}

@property (nonatomic) int x;
@property (nonatomic) int y;
@property (nonatomic) int width;
@property (nonatomic) int height;
@property (nonatomic) char* wnd_title;

@property (nonatomic) UINT32 windowId;
@property (nonatomic) UINT32 ownerWindowId;

@property (nonatomic) UINT32 dwStyle;
@property (nonatomic) UINT32 dwExStyle;
@property (nonatomic) UINT32 showState;

@property (nonatomic) INT32 clientOffsetX;
@property (nonatomic) INT32 clientOffsetY;
@property (nonatomic) UINT32 clientAreaWidth;
@property (nonatomic) UINT32 clientAreaHeight;

@property (nonatomic) INT32 windowOffsetX;
@property (nonatomic) INT32 windowOffsetY;
@property (nonatomic) INT32 windowClientDeltaX;
@property (nonatomic) INT32 windowClientDeltaY;
@property (nonatomic) UINT32 windowWidth;
@property (nonatomic) UINT32 windowHeight;
@property (nonatomic) UINT32 numWindowRects;
@property (nonatomic) RECTANGLE_16* windowRects;

@property (nonatomic) INT32 visibleOffsetX;
@property (nonatomic) INT32 visibleOffsetY;
@property (nonatomic) UINT32 numVisibilityRects;
@property (nonatomic) RECTANGLE_16* visibilityRects;

@property (nonatomic) UINT32 localWindowOffsetCorrX;
@property (nonatomic) UINT32 localWindowOffsetCorrY;

@property (nonatomic) CGContextRef gc;
@property (nonatomic) BOOL fullscreen;
@property (nonatomic) BOOL decorations;
@property (nonatomic) BOOL is_mapped;
@property (nonatomic) BOOL is_transient;
@property (nonatomic) BYTE rail_state;
@property (nonatomic) BOOL rail_ignore_configure;

- (void) mf_AppWindowInit: (mfContext*) mfc;
- (void) mf_DestroyWindow;
- (void) mf_MoveWindow:(int)x y:(int)y width:(int)width height:(int)height;
- (void) mf_UpdateWindowArea:(int)x y:(int)y width:(int)width height:(int)height;
- (void) mf_SetWindowVisibilityRects:(UINT32)rectsOffsetX rectsOffsetY:(UINT32)rectsOffsetY rects:(RECTANGLE_16*)rects nrects:(int)nrects;
- (void) mf_SetWindowText:(char*) name;
- (void) mf_ShowWindow:(BYTE)state;
@end
