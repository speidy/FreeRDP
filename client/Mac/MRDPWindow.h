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

typedef struct mf_app_window mfAppWindow;

struct mf_app_window
{
	mfContext* mfc;

	int x;
	int y;
	int width;
	int height;
	char* title;

	UINT32 windowId;
	UINT32 ownerWindowId;

	UINT32 dwStyle;
	UINT32 dwExStyle;
	UINT32 showState;

	INT32 clientOffsetX;
	INT32 clientOffsetY;
	UINT32 clientAreaWidth;
	UINT32 clientAreaHeight;

	INT32 windowOffsetX;
	INT32 windowOffsetY;
	INT32 windowClientDeltaX;
	INT32 windowClientDeltaY;
	UINT32 windowWidth;
	UINT32 windowHeight;
	UINT32 numWindowRects;
	RECTANGLE_16* windowRects;

	INT32 visibleOffsetX;
	INT32 visibleOffsetY;
	UINT32 numVisibilityRects;
	RECTANGLE_16* visibilityRects;

	UINT32 localWindowOffsetCorrX;
	UINT32 localWindowOffsetCorrY;

	CGContextRef gc;
	//int shmid;
	NSWindow* handle;
	//Window* xfwin;
	BOOL fullscreen;
	BOOL decorations;
	BOOL is_mapped;
	BOOL is_transient;
	//xfLocalMove local_move;
	BYTE rail_state;
	BOOL rail_ignore_configure;
};

int mf_AppWindowInit(mfContext* mfc, mfAppWindow* appWindow);
void mf_DestroyWindow(mfContext* mfc, mfAppWindow* appWindow);
void mf_MoveWindow(mfContext* mfc, mfAppWindow* appWindow,int x, int y, int width, int height);
void mf_UpdateWindowArea(mfContext* mfc, mfAppWindow* appWindow,
		int x, int y, int width, int height);
void mf_SetWindowVisibilityRects(mfContext* mfc, mfAppWindow* appWindow,
		UINT32 rectsOffsetX, UINT32 rectsOffsetY,
		RECTANGLE_16* rects, int nrects);
void mf_SetWindowText(mfContext* mfc, mfAppWindow* appWindow, char* name);
void mf_ShowWindow(mfContext* mfc, mfAppWindow* appWindow, BYTE state);
