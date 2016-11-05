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

@interface MRDPWindow : NSWindow <NSWindowDelegate>
{
	mfContext *mfc;
	freerdp *instance;
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
