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

#import <Foundation/Foundation.h>
#import "MRDPRail.h"
#import "MRDPWindow.h"

static void mac_rail_invalidate_region(mfContext* mfc, REGION16* invalidRegion)
{
	int index;
	int count;
	RECTANGLE_16 updateRect;
	RECTANGLE_16 windowRect;
	ULONG_PTR* pKeys = NULL;
	MRDPWindow* appWindow;
	const RECTANGLE_16* extents;
	REGION16 windowInvalidRegion;

	region16_init(&windowInvalidRegion);

	count = HashTable_GetKeys(mfc->railWindows, &pKeys);

	for (index = 0; index < count; index++)
	{
		appWindow = (MRDPWindow*) HashTable_GetItemValue(mfc->railWindows, (void*) pKeys[index]);

		if (appWindow)
		{
			windowRect.left = MAX(appWindow.x, 0);
			windowRect.top = MAX(appWindow.y, 0);
			windowRect.right = MAX(appWindow.x + appWindow.width, 0);
			windowRect.bottom = MAX(appWindow.y + appWindow.height, 0);

			region16_clear(&windowInvalidRegion);
			region16_intersect_rect(&windowInvalidRegion, invalidRegion, &windowRect);

			if (!region16_is_empty(&windowInvalidRegion))
			{
				extents = region16_extents(&windowInvalidRegion);

				updateRect.left = extents->left - appWindow.x;
				updateRect.top = extents->top - appWindow.y;
				updateRect.right = extents->right - appWindow.x;
				updateRect.bottom = extents->bottom - appWindow.y;

				if (appWindow)
				{
					[appWindow mf_UpdateWindowArea:updateRect.left y:updateRect.top width:updateRect.right - updateRect.left height:updateRect.bottom - updateRect.top];
				}
			}
		}
	}

	region16_uninit(&windowInvalidRegion);
}

void mac_rail_paint(mfContext* mfc, INT32 uleft, INT32 utop, UINT32 uright, UINT32 ubottom)
{
	REGION16 invalidRegion;
	RECTANGLE_16 invalidRect;

	invalidRect.left = uleft;
	invalidRect.top = utop;
	invalidRect.right = uright;
	invalidRect.bottom = ubottom;

	region16_init(&invalidRegion);
	region16_union_rect(&invalidRegion, &invalidRegion, &invalidRect);

	mac_rail_invalidate_region(mfc, &invalidRegion);

	region16_uninit(&invalidRegion);
}

@implementation MRDPRail

- (BOOL) mac_window_common :(rdpContext*) context
		oi:(WINDOW_ORDER_INFO*) orderInfo
		ws:(WINDOW_STATE_ORDER*) windowState
{
	MRDPWindow* appWindow = NULL;
	MRDPWindow* appWindowOwner = NULL;
	UINT32 fieldFlags = orderInfo->fieldFlags;
	mfContext* mfc = (mfContext*) context;
	BOOL position_or_size_updated = FALSE;

	if (fieldFlags & WINDOW_ORDER_STATE_NEW)
	{
		NSRect rect;
		appWindow = [MRDPWindow alloc];
		rect = NSMakeRect(windowState->windowOffsetX, windowState->windowOffsetY,
				windowState->windowWidth, windowState->windowHeight);
		rect.origin.y = mfc->context.settings->DesktopHeight - (rect.origin.y + rect.size.height);
		NSUInteger styleMask = NSBorderlessWindowMask | NSResizableWindowMask;
		appWindow = [appWindow initWithContentRect:rect
				styleMask:styleMask backing:NSBackingStoreBuffered defer:NO];
		appWindowOwner = (MRDPWindow*) HashTable_GetItemValue(mfc->railWindows,
															  (void*) (UINT_PTR) windowState->ownerWindowId);
		if (appWindowOwner != NULL)
		{
			[appWindowOwner addChildWindow:appWindow ordered:NSWindowAbove];
		}
		if (appWindow == NULL)
		{
			return FALSE;
		}
		[appWindow setWindowId:orderInfo->windowId];
		[appWindow setDwStyle:windowState->style];
		[appWindow setDwExStyle:windowState->extendedStyle];
		[appWindow setWindowOffsetX:windowState->windowOffsetX];
		[appWindow setX:windowState->windowOffsetX];
		[appWindow setWindowOffsetY:windowState->windowOffsetY];
		[appWindow setY:windowState->windowOffsetY];
		[appWindow setWindowWidth:windowState->windowWidth];
		[appWindow setWidth:windowState->windowWidth];
		[appWindow setWindowHeight:windowState->windowHeight];
		[appWindow setHeight:windowState->windowHeight];

		/* Ensure window always gets a window title */
		if (fieldFlags & WINDOW_ORDER_FIELD_TITLE)
		{
			char* title = NULL;
			if (windowState->titleInfo.length == 0)
			{
				if (!(title = _strdup("")))
				{
					/* error handled below */
				}
			}
			else if (ConvertFromUnicode(CP_UTF8, 0, (WCHAR*) windowState->titleInfo.string,
					windowState->titleInfo.length / 2, &title, 0, NULL, NULL) < 1)
			{
				/* error handled below */
			}
			[appWindow setWnd_title:title];
		}
		else
		{
			[appWindow setWnd_title: _strdup("RdpRailWindow")];
		}
		if (!appWindow.wnd_title)
		{
			[appWindow dealloc];
			return FALSE;
		}
		HashTable_Add(mfc->railWindows, (void*) (UINT_PTR) orderInfo->windowId, (void*) appWindow);
		[appWindow mf_AppWindowInit:mfc];
	}
	else
	{
		appWindow = (MRDPWindow*) HashTable_GetItemValue(mfc->railWindows,
				(void*) (UINT_PTR) orderInfo->windowId);
	}
	if (appWindow == NULL)
	{
		return FALSE;
	}
	/* Keep track of any position/size update so that we can force a refresh of the window */
	if ((fieldFlags & WINDOW_ORDER_FIELD_WND_OFFSET) ||
		(fieldFlags & WINDOW_ORDER_FIELD_WND_SIZE) ||
		(fieldFlags & WINDOW_ORDER_FIELD_CLIENT_AREA_OFFSET) ||
		(fieldFlags & WINDOW_ORDER_FIELD_CLIENT_AREA_SIZE) ||
		(fieldFlags & WINDOW_ORDER_FIELD_WND_CLIENT_DELTA) ||
		(fieldFlags & WINDOW_ORDER_FIELD_VIS_OFFSET) ||
		(fieldFlags & WINDOW_ORDER_FIELD_VISIBILITY))
	{
		position_or_size_updated = TRUE;
	}
	/* Update Parameters */
	if (fieldFlags & WINDOW_ORDER_FIELD_WND_OFFSET)
	{
		[appWindow setWindowOffsetX: windowState->windowOffsetX];
		[appWindow setWindowOffsetY: windowState->windowOffsetY];
	}
	if (fieldFlags & WINDOW_ORDER_FIELD_WND_SIZE)
	{
		[appWindow setWindowWidth:windowState->windowWidth];
		[appWindow setWindowHeight:windowState->windowHeight];
	}
	if (fieldFlags & WINDOW_ORDER_FIELD_OWNER)
	{
		[appWindow setOwnerWindowId:windowState->ownerWindowId];
	}
	if (fieldFlags & WINDOW_ORDER_FIELD_STYLE)
	{
		[appWindow setDwStyle:windowState->style];
		[appWindow setDwExStyle:windowState->extendedStyle];
	}
	if (fieldFlags & WINDOW_ORDER_FIELD_SHOW)
	{
		[appWindow setShowState:windowState->showState];
	}
	if (fieldFlags & WINDOW_ORDER_FIELD_TITLE)
	{
		char* title = NULL;
		if (windowState->titleInfo.length == 0)
		{
			if (!(title = _strdup("")))
			{
				//WLog_ERR(TAG, "failed to duplicate empty window title string");
				return FALSE;
			}
		}
		else if (ConvertFromUnicode(CP_UTF8, 0, (WCHAR*) windowState->titleInfo.string,
				windowState->titleInfo.length / 2, &title, 0, NULL, NULL) < 1)
		{
			//WLog_ERR(TAG, "failed to convert window title");
			return FALSE;
		}
		free(appWindow.wnd_title);
		[appWindow setWnd_title:title];
	}
	if (fieldFlags & WINDOW_ORDER_FIELD_CLIENT_AREA_OFFSET)
	{
		[appWindow setWindowOffsetX: windowState->windowOffsetX];
		[appWindow setWindowOffsetY: windowState->windowOffsetY];

	}
	if (fieldFlags & WINDOW_ORDER_FIELD_CLIENT_AREA_SIZE)
	{
		[appWindow setClientAreaWidth:windowState->clientAreaWidth];
		[appWindow setClientAreaHeight:windowState->clientAreaHeight];
	}
	if (fieldFlags & WINDOW_ORDER_FIELD_WND_CLIENT_DELTA)
	{
		[appWindow setWindowClientDeltaX:windowState->windowClientDeltaX];
		[appWindow setWindowClientDeltaY:windowState->windowClientDeltaY];
	}
	if (fieldFlags & WINDOW_ORDER_FIELD_WND_RECTS)
	{
		if (appWindow.windowRects)
		{
			free(appWindow.windowRects);
			[appWindow setWindowRects:NULL];
		}
		[appWindow setNumWindowRects:windowState->numWindowRects];
		if (appWindow.numWindowRects)
		{
			[appWindow setWindowRects:(RECTANGLE_16*)
					calloc(appWindow.numWindowRects, sizeof(RECTANGLE_16))];
			if (appWindow.windowRects == NULL)
			{
				return FALSE;
			}
			CopyMemory(appWindow.windowRects, windowState->windowRects,
					   appWindow.numWindowRects * sizeof(RECTANGLE_16));
		}
	}
	if (fieldFlags & WINDOW_ORDER_FIELD_VIS_OFFSET)
	{
		[appWindow setVisibleOffsetX:windowState->visibleOffsetX];
		[appWindow setVisibleOffsetY:windowState->visibleOffsetY];
	}
	if (fieldFlags & WINDOW_ORDER_FIELD_VISIBILITY)
	{
		if (appWindow.visibilityRects)
		{
			free(appWindow.visibilityRects);
			[appWindow setVisibilityRects: NULL];
		}
		[appWindow setNumVisibilityRects:windowState->numVisibilityRects];
		if (appWindow.numVisibilityRects)
		{
			[appWindow setVisibilityRects:(RECTANGLE_16*)
					calloc(appWindow.numVisibilityRects, sizeof(RECTANGLE_16))];
			if (appWindow.visibilityRects == NULL)
			{
				return FALSE;
			}
			CopyMemory(appWindow.visibilityRects, windowState->visibilityRects,
					   appWindow.numVisibilityRects * sizeof(RECTANGLE_16));
		}
	}
	/* Update Window */
	if (fieldFlags & WINDOW_ORDER_FIELD_STYLE)
	{
	}
	if (fieldFlags & WINDOW_ORDER_FIELD_SHOW)
	{
		[appWindow mf_ShowWindow:appWindow.showState];
	}
	if (fieldFlags & WINDOW_ORDER_FIELD_TITLE)
	{
		if (appWindow.wnd_title != NULL)
		{
			[appWindow mf_SetWindowText:appWindow.wnd_title];
		}
	}
	if (position_or_size_updated)
	{
		UINT32 visibilityRectsOffsetX =
		(appWindow.visibleOffsetX - (appWindow.clientOffsetX - appWindow.windowClientDeltaX));
		UINT32 visibilityRectsOffsetY =
		(appWindow.visibleOffsetY - (appWindow.clientOffsetY - appWindow.windowClientDeltaY));
		/*
		 * The rail server like to set the window to a small size when it is minimized even though it is hidden
		 * in some cases this can cause the window not to restore back to its original size. Therefore we don't
		 * update our local window when that rail window state is minimized
		 */
		if (appWindow.rail_state != WINDOW_SHOW_MINIMIZED)
		{
			/* Redraw window area if already in the correct position */
			if (appWindow.x == appWindow.windowOffsetX &&
				appWindow.y == appWindow.windowOffsetY &&
				appWindow.width == appWindow.windowWidth &&
				appWindow.height == appWindow.windowHeight)
			{
				[appWindow mf_UpdateWindowArea:0 y:0
						width:appWindow.windowWidth height:appWindow.windowHeight];
			}
			else
			{
				[appWindow mf_MoveWindow:appWindow.windowOffsetX y:appWindow.windowOffsetY
						width:appWindow.windowWidth height:appWindow.windowHeight];
			}
			[appWindow mf_SetWindowVisibilityRects:visibilityRectsOffsetX
					rectsOffsetY:visibilityRectsOffsetY
					rects:appWindow.visibilityRects
					nrects:appWindow.numVisibilityRects];
		}
	}
	return TRUE;
}

- (BOOL) mac_window_delete :(rdpContext*) context
		oi:(WINDOW_ORDER_INFO*) orderInfo
{
	MRDPWindow* appWindow = NULL;
	mfContext* mfc = (mfContext*) context;

	appWindow = (MRDPWindow*) HashTable_GetItemValue(mfc->railWindows,
			(void*) (UINT_PTR) orderInfo->windowId);
	if (appWindow == NULL)
	{
		return TRUE;
	}
	HashTable_Remove(mfc->railWindows, (void*) (UINT_PTR) orderInfo->windowId);
	[appWindow mf_DestroyWindow];
	return TRUE;
}

- (BOOL) mac_window_icon :(rdpContext*) context
		oi:(WINDOW_ORDER_INFO*) orderInfo
		wi:(WINDOW_ICON_ORDER*) windowIcon
{
	return TRUE;
}

- (BOOL) mac_window_cached_icon :(rdpContext*) context
		oi:(WINDOW_ORDER_INFO*) orderInfo
		wci:(WINDOW_CACHED_ICON_ORDER*) windowCachedIcon;
{
	return TRUE;
}

- (BOOL) mac_rail_notify_icon_create :(rdpContext*) context
		oi:(WINDOW_ORDER_INFO*) orderInfo
		nis:(NOTIFY_ICON_STATE_ORDER*) notifyIconState
{
	return TRUE;
}

- (BOOL) mac_rail_notify_icon_update :(rdpContext*) context
		oi:(WINDOW_ORDER_INFO*) orderInfo
		nis:(NOTIFY_ICON_STATE_ORDER*) notifyIconState
{
	return TRUE;
}

- (BOOL) mac_rail_notify_icon_delete :(rdpContext*) context
		oi:(WINDOW_ORDER_INFO*) orderInfo
		nis:(NOTIFY_ICON_STATE_ORDER*) notifyIconState
{
	return TRUE;
}

- (BOOL) mac_rail_monitored_desktop:(rdpContext*) context
		oi:(WINDOW_ORDER_INFO*) orderInfo
		md:(MONITORED_DESKTOP_ORDER*) monitoredDesktop;
{
	return TRUE;
}

- (UINT) mac_rail_server_execute_result:(RailClientContext*) context
		er:(RAIL_EXEC_RESULT_ORDER*) execResult;
{
	return CHANNEL_RC_OK;
}

- (UINT) mac_rail_server_system_param:(RailClientContext*) context
		sp:(RAIL_SYSPARAM_ORDER*) sysparam;
{
	return CHANNEL_RC_OK;
}

- (void) mac_window_common_sync;
{
	m_rv = [self mac_window_common:m_context oi:m_orderInfo ws:m_windowState];
}

- (void) mac_window_delete_sync;
{
	m_rv = [self mac_window_delete:m_context oi:m_orderInfo];
}

- (void) mac_window_icon_sync;
{
	m_rv = [self mac_window_icon:m_context oi:m_orderInfo wi:m_windowIcon];
}

- (void) mac_window_cached_icon_sync;
{
	m_rv = [self mac_window_cached_icon:m_context oi:m_orderInfo wci:m_windowCachedIcon];
}

- (void) mac_rail_notify_icon_create_sync;
{
	m_rv = [self mac_rail_notify_icon_create:m_context oi:m_orderInfo nis:m_notifyIconState];
}

- (void) mac_rail_notify_icon_update_sync;
{
	m_rv = [self mac_rail_notify_icon_update:m_context oi:m_orderInfo nis:m_notifyIconState];
}

- (void) mac_rail_notify_icon_delete_sync;
{
	m_rv = [self mac_rail_notify_icon_delete:m_context oi:m_orderInfo];
}

- (void) mac_rail_moditored_desktop_sync;
{
	m_rv = [self mac_rail_monitored_desktop:m_context oi:m_orderInfo md:m_monitoredDesktop];
}

- (void) mac_rail_non_moditored_desktop_sync;
{
	m_rv = [self mac_rail_non_monitored_desktop:m_context oi:m_orderInfo];
}

- (void) mac_rail_server_execute_result_sync;
{
	m_rv = [self mac_rail_server_execute_result:m_rail_context er:m_execResult];
}

- (void) mac_rail_server_system_param_sync;
{
	m_rv = [self mac_rail_server_system_param:m_rail_context sp:m_sysparam];
}

@end

void mac_rail_send_client_system_command(mfContext* mfc, UINT32 windowId, UINT16 command)
{
	RAIL_SYSCOMMAND_ORDER syscommand;
	
	syscommand.windowId = windowId;
	syscommand.command = command;
	
	mfc->rail->ClientSystemCommand(mfc->rail, &syscommand);
}

void mac_rail_send_client_window_move(mfContext* mfc, UINT32 windowId, UINT16 left, UINT16 top,
									  UINT16 right, UINT16 bottom)
{
	RAIL_WINDOW_MOVE_ORDER window_move;

	window_move.windowId = windowId;
	window_move.left = left;
	window_move.top = top;
	window_move.right = right;
	window_move.bottom = bottom;
	mfc->rail->ClientWindowMove(mfc->rail, &window_move);
}

static UINT mac_rail_server_handshake(RailClientContext* context, RAIL_HANDSHAKE_ORDER* handshake)
{
	RAIL_EXEC_ORDER exec;
	RAIL_SYSPARAM_ORDER sysparam;
	RAIL_HANDSHAKE_ORDER clientHandshake;
	RAIL_CLIENT_STATUS_ORDER clientStatus;
	RAIL_LANGBAR_INFO_ORDER langBarInfo;
	mfContext* mfc = (mfContext*) context->custom;
	rdpSettings* settings = mfc->context.settings;

	ZeroMemory(&clientHandshake, sizeof(clientHandshake));
	clientHandshake.buildNumber = 0x00001DB0;
	context->ClientHandshake(context, &clientHandshake);

	ZeroMemory(&clientStatus, sizeof(RAIL_CLIENT_STATUS_ORDER));
	clientStatus.flags = RAIL_CLIENTSTATUS_ALLOWLOCALMOVESIZE;
	context->ClientInformation(context, &clientStatus);

	if (settings->RemoteAppLanguageBarSupported)
	{
		ZeroMemory(&langBarInfo, sizeof(langBarInfo));
		langBarInfo.languageBarStatus = 0x00000008; /* TF_SFT_HIDDEN */
		context->ClientLanguageBarInfo(context, &langBarInfo);
	}

	ZeroMemory(&sysparam, sizeof(RAIL_SYSPARAM_ORDER));
	sysparam.params = 0;
	sysparam.params |= SPI_MASK_SET_HIGH_CONTRAST;
	sysparam.highContrast.colorScheme.string = NULL;
	sysparam.highContrast.colorScheme.length = 0;
	sysparam.highContrast.flags = 0x7E;
	sysparam.params |= SPI_MASK_SET_MOUSE_BUTTON_SWAP;
	sysparam.mouseButtonSwap = FALSE;
	sysparam.params |= SPI_MASK_SET_KEYBOARD_PREF;
	sysparam.keyboardPref = FALSE;
	sysparam.params |= SPI_MASK_SET_DRAG_FULL_WINDOWS;
	sysparam.dragFullWindows = FALSE;
	sysparam.params |= SPI_MASK_SET_KEYBOARD_CUES;
	sysparam.keyboardCues = FALSE;
	sysparam.params |= SPI_MASK_SET_WORK_AREA;
	sysparam.workArea.left = 0;
	sysparam.workArea.top = 0;
	sysparam.workArea.right = settings->DesktopWidth;
	sysparam.workArea.bottom = settings->DesktopHeight;
	sysparam.dragFullWindows = FALSE;
	context->ClientSystemParam(context, &sysparam);

	ZeroMemory(&exec, sizeof(RAIL_EXEC_ORDER));
	exec.RemoteApplicationProgram = settings->RemoteApplicationProgram;
	exec.RemoteApplicationWorkingDir = settings->ShellWorkingDirectory;
	exec.RemoteApplicationArguments = settings->RemoteApplicationCmdLine;
	context->ClientExecute(context, &exec);

	return CHANNEL_RC_OK;
}

static UINT mac_rail_server_handshake_ex(RailClientContext* context, RAIL_HANDSHAKE_EX_ORDER* handshakeEx)
{
	return CHANNEL_RC_OK;
}

static UINT mac_rail_server_local_move_size(RailClientContext* context, RAIL_LOCALMOVESIZE_ORDER* localMoveSize)
{
	return CHANNEL_RC_OK;
}

static UINT mac_rail_server_min_max_info(RailClientContext* context, RAIL_MINMAXINFO_ORDER* minMaxInfo)
{
	return CHANNEL_RC_OK;
}

static UINT mac_rail_server_language_bar_info(RailClientContext* context, RAIL_LANGBAR_INFO_ORDER* langBarInfo)
{
	return CHANNEL_RC_OK;
}

static UINT mac_rail_server_get_appid_response(RailClientContext* context, RAIL_GET_APPID_RESP_ORDER* getAppIdResp)
{
	return CHANNEL_RC_OK;
}

BOOL mac_window_common(rdpContext* context, WINDOW_ORDER_INFO* orderInfo, WINDOW_STATE_ORDER* windowState)
{
	mfContext* mfc = (mfContext*)context;
	MRDPRail *rdpRail = (MRDPRail*) (mfc->mrail);
	if ([NSThread isMainThread] == 0)
	{
		rdpRail->m_context = context;
		rdpRail->m_orderInfo = orderInfo;
		rdpRail->m_windowState = windowState;
		[rdpRail performSelectorOnMainThread:@selector(mac_window_common_sync)
				withObject:nil waitUntilDone:YES];
		return rdpRail->m_rv;
	}
	return [rdpRail mac_window_common:context oi:orderInfo ws:windowState];
}

BOOL mac_window_delete(rdpContext* context, WINDOW_ORDER_INFO* orderInfo)
{
	mfContext* mfc = (mfContext*)context;
	MRDPRail *rdpRail = (MRDPRail*) (mfc->mrail);
	if ([NSThread isMainThread] == 0)
	{
		rdpRail->m_context = context;
		rdpRail->m_orderInfo = orderInfo;
		[rdpRail performSelectorOnMainThread:@selector(mac_window_delete_sync)
				withObject:nil waitUntilDone:YES];
		return rdpRail->m_rv;
	}
	return [rdpRail mac_window_delete:context oi:orderInfo];
}

BOOL mac_window_icon(rdpContext* context, WINDOW_ORDER_INFO* orderInfo,
		WINDOW_ICON_ORDER* windowIcon)
{
	mfContext* mfc = (mfContext*)context;
	MRDPRail *rdpRail = (MRDPRail*) (mfc->mrail);
	if ([NSThread isMainThread] == 0)
	{
		rdpRail->m_context = context;
		rdpRail->m_orderInfo = orderInfo;
		rdpRail->m_windowIcon = windowIcon;
		[rdpRail performSelectorOnMainThread:@selector(mac_window_icon_sync)
				withObject:nil waitUntilDone:YES];
		return rdpRail->m_rv;
	}
	return [rdpRail mac_window_icon:context oi:orderInfo wi:windowIcon];
}

BOOL mac_window_cached_icon(rdpContext* context, WINDOW_ORDER_INFO* orderInfo,
		WINDOW_CACHED_ICON_ORDER* windowCachedIcon)
{
	mfContext* mfc = (mfContext*)context;
	MRDPRail *rdpRail = (MRDPRail*) (mfc->mrail);
	if ([NSThread isMainThread] == 0)
	{
		rdpRail->m_context = context;
		rdpRail->m_orderInfo = orderInfo;
		rdpRail->m_windowCachedIcon = windowCachedIcon;
		[rdpRail performSelectorOnMainThread:@selector(mac_window_cached_icon_sync)
				withObject:nil waitUntilDone:YES];
		return rdpRail->m_rv;
	}
	return [rdpRail mac_window_cached_icon:context oi:orderInfo wci:windowCachedIcon];
}

BOOL mac_rail_notify_icon_create(rdpContext* context, WINDOW_ORDER_INFO* orderInfo,
		NOTIFY_ICON_STATE_ORDER* notifyIconState)
{
	mfContext* mfc = (mfContext*)context;
	MRDPRail *rdpRail = (MRDPRail*) (mfc->mrail);
	if ([NSThread isMainThread] == 0)
	{
		rdpRail->m_context = context;
		rdpRail->m_orderInfo = orderInfo;
		rdpRail->m_notifyIconState = notifyIconState;
		[rdpRail performSelectorOnMainThread:@selector(mac_rail_notify_icon_create_sync)
				withObject:nil waitUntilDone:YES];
		return rdpRail->m_rv;
	}
	return [rdpRail mac_rail_notify_icon_create:context oi:orderInfo nis:notifyIconState];
}

BOOL mac_rail_notify_icon_update(rdpContext* context, WINDOW_ORDER_INFO* orderInfo,
		NOTIFY_ICON_STATE_ORDER* notifyIconState)
{
	mfContext* mfc = (mfContext*)context;
	MRDPRail *rdpRail = (MRDPRail*) (mfc->mrail);
	if ([NSThread isMainThread] == 0)
	{
		rdpRail->m_context = context;
		rdpRail->m_orderInfo = orderInfo;
		rdpRail->m_notifyIconState = notifyIconState;
		[rdpRail performSelectorOnMainThread:@selector(mac_rail_notify_icon_update_sync)
				withObject:nil waitUntilDone:YES];
		return rdpRail->m_rv;
	}
	return [rdpRail mac_rail_notify_icon_update:context oi:orderInfo nis:notifyIconState];
}

BOOL mac_rail_notify_icon_delete(rdpContext* context, WINDOW_ORDER_INFO* orderInfo)
{
	mfContext* mfc = (mfContext*)context;
	MRDPRail *rdpRail = (MRDPRail*) (mfc->mrail);
	if ([NSThread isMainThread] == 0)
	{
		rdpRail->m_context = context;
		rdpRail->m_orderInfo = orderInfo;
		[rdpRail performSelectorOnMainThread:@selector(mac_rail_notify_icon_delete_sync)
				withObject:nil waitUntilDone:YES];
		return rdpRail->m_rv;
	}
	return [rdpRail mac_rail_notify_icon_delete:context oi:orderInfo];
}

BOOL mac_rail_monitored_desktop(rdpContext* context, WINDOW_ORDER_INFO* orderInfo,
								MONITORED_DESKTOP_ORDER* monitoredDesktop)
{
	mfContext* mfc = (mfContext*)context;
	MRDPRail *rdpRail = (MRDPRail*) (mfc->mrail);
	if ([NSThread isMainThread] == 0)
	{
		rdpRail->m_context = context;
		rdpRail->m_orderInfo = orderInfo;
		rdpRail->m_monitoredDesktop = monitoredDesktop;
		[rdpRail performSelectorOnMainThread:@selector(mac_rail_monitored_desktop_sync)
				withObject:nil waitUntilDone:YES];
		return rdpRail->m_rv;
	}
	return [rdpRail mac_rail_monitored_desktop:context oi:orderInfo md: monitoredDesktop];
}

BOOL mac_rail_non_monitored_desktop(rdpContext* context, WINDOW_ORDER_INFO* orderInfo)
{
	mfContext* mfc = (mfContext*)context;
	MRDPRail *rdpRail = (MRDPRail*) (mfc->mrail);
	if ([NSThread isMainThread] == 0)
	{
		rdpRail->m_context = context;
		rdpRail->m_orderInfo = orderInfo;
		[rdpRail performSelectorOnMainThread:@selector(mac_rail_non_monitored_desktop_sync)
				withObject:nil waitUntilDone:YES];
		return rdpRail->m_rv;
	}
	return [rdpRail mac_rail_non_monitored_desktop:context oi:orderInfo];
}

UINT mac_rail_server_execute_result(RailClientContext* context, RAIL_EXEC_RESULT_ORDER* execResult)
{
	mfContext* mfc = (mfContext*) (context->custom);
	MRDPRail *rdpRail = (MRDPRail*) (mfc->mrail);
	if ([NSThread isMainThread] == 0)
	{
		rdpRail->m_rail_context = context;
		rdpRail->m_execResult = execResult;
		[rdpRail performSelectorOnMainThread:@selector(mac_rail_server_execute_result_sync)
				withObject:nil waitUntilDone:YES];
		return rdpRail->m_rv;
	}
	return [rdpRail mac_rail_server_execute_result:context er:execResult];
}

UINT mac_rail_server_system_param(RailClientContext* context, RAIL_SYSPARAM_ORDER* sysparam)
{
	mfContext* mfc = (mfContext*) (context->custom);
	MRDPRail *rdpRail = (MRDPRail*) (mfc->mrail);
	if ([NSThread isMainThread] == 0)
	{
		rdpRail->m_rail_context = context;
		rdpRail->m_sysparam = sysparam;
		[rdpRail performSelectorOnMainThread:@selector(mac_rail_server_system_param_sync)
				withObject:nil waitUntilDone:YES];
		return rdpRail->m_rv;
	}
	return [rdpRail mac_rail_server_system_param:context sp:sysparam];
}

void mac_rail_init(mfContext* mfc, RailClientContext* rail)
{
	rdpWindowUpdate* window;

	rail->custom = (void*) mfc;
	mfc->rail = rail;
	window = mfc->context.update->window;
	window->context = &(mfc->context);
	window->WindowCreate = mac_window_common;
	window->WindowUpdate = mac_window_common;
	window->WindowDelete = mac_window_delete;
	window->WindowIcon = mac_window_icon;
	window->WindowCachedIcon = mac_window_cached_icon;
	window->NotifyIconCreate = mac_rail_notify_icon_create;
	window->NotifyIconUpdate = mac_rail_notify_icon_update;
	window->NotifyIconDelete = mac_rail_notify_icon_delete;
	window->MonitoredDesktop = mac_rail_monitored_desktop;
	window->NonMonitoredDesktop = mac_rail_non_monitored_desktop;

	rail->ServerExecuteResult = mac_rail_server_execute_result;
	rail->ServerSystemParam = mac_rail_server_system_param;
	rail->ServerHandshake = mac_rail_server_handshake;
	rail->ServerHandshakeEx = mac_rail_server_handshake_ex;
	rail->ServerLocalMoveSize = mac_rail_server_local_move_size;
	rail->ServerMinMaxInfo = mac_rail_server_min_max_info;
	rail->ServerLanguageBarInfo = mac_rail_server_language_bar_info;
	rail->ServerGetAppIdResponse = mac_rail_server_get_appid_response;

	mfc->railWindows = HashTable_New(TRUE);
	mfc->mrail = [MRDPRail new];
}

void mac_rail_uninit(mfContext* mfc, RailClientContext* rail)
{
	HashTable_Free(mfc->railWindows);
	rail->custom = NULL;
	mfc->rail = NULL;
	mfc->railWindows = NULL;
}
