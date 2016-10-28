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

void mac_rail_invalidate_region(mfContext* mfc, REGION16* invalidRegion)
{
	int index;
	int count;
	RECTANGLE_16 updateRect;
	RECTANGLE_16 windowRect;
	ULONG_PTR* pKeys = NULL;
	mfAppWindow* appWindow;
	const RECTANGLE_16* extents;
	REGION16 windowInvalidRegion;

	region16_init(&windowInvalidRegion);

	count = HashTable_GetKeys(mfc->railWindows, &pKeys);

	for (index = 0; index < count; index++)
	{
		appWindow = (mfAppWindow*) HashTable_GetItemValue(mfc->railWindows, (void*) pKeys[index]);

		if (appWindow)
		{
			windowRect.left = MAX(appWindow->x, 0);
			windowRect.top = MAX(appWindow->y, 0);
			windowRect.right = MAX(appWindow->x + appWindow->width, 0);
			windowRect.bottom = MAX(appWindow->y + appWindow->height, 0);

			region16_clear(&windowInvalidRegion);
			region16_intersect_rect(&windowInvalidRegion, invalidRegion, &windowRect);

			if (!region16_is_empty(&windowInvalidRegion))
			{
				extents = region16_extents(&windowInvalidRegion);

				updateRect.left = extents->left - appWindow->x;
				updateRect.top = extents->top - appWindow->y;
				updateRect.right = extents->right - appWindow->x;
				updateRect.bottom = extents->bottom - appWindow->y;

				if (appWindow)
				{
					mf_UpdateWindowArea(mfc, appWindow, updateRect.left, updateRect.top,
							updateRect.right - updateRect.left,
							updateRect.bottom - updateRect.top);
				}
			}
		}
	}

	region16_uninit(&windowInvalidRegion);
}

void mac_rail_paint(mfContext* xfc, INT32 uleft, INT32 utop, UINT32 uright, UINT32 ubottom)
{
	REGION16 invalidRegion;
	RECTANGLE_16 invalidRect;

	invalidRect.left = uleft;
	invalidRect.top = utop;
	invalidRect.right = uright;
	invalidRect.bottom = ubottom;

	region16_init(&invalidRegion);
	region16_union_rect(&invalidRegion, &invalidRegion, &invalidRect);

	mac_rail_invalidate_region(xfc, &invalidRegion);

	region16_uninit(&invalidRegion);
}


BOOL mac_window_common(rdpContext* context, WINDOW_ORDER_INFO* orderInfo, WINDOW_STATE_ORDER* windowState)
{
	mfAppWindow* appWindow = NULL;
	UINT32 fieldFlags = orderInfo->fieldFlags;
	mfContext* mfc = (mfContext*) context;
	BOOL position_or_size_updated = FALSE;

	if (fieldFlags & WINDOW_ORDER_STATE_NEW)
	{
		appWindow = (mfAppWindow*) calloc(1, sizeof(mfAppWindow));
		if (appWindow == NULL)
		{
			return FALSE;
		}
		appWindow->mfc = mfc;
		appWindow->windowId = orderInfo->windowId;
		appWindow->dwStyle = windowState->style;
		appWindow->dwExStyle = windowState->extendedStyle;
		appWindow->x = appWindow->windowOffsetX = windowState->windowOffsetX;
		appWindow->y = appWindow->windowOffsetY = windowState->windowOffsetY;
		appWindow->width = appWindow->windowWidth = windowState->windowWidth;
		appWindow->height = appWindow->windowHeight = windowState->windowHeight;
		/* Ensure window always gets a window title */
		if (fieldFlags & WINDOW_ORDER_FIELD_TITLE)
		{
			char* title = NULL;
			if (windowState->titleInfo.length == 0)
			{
				if (!(title = _strdup("")))
				{
					//WLog_ERR(TAG, "failed to duplicate empty window title string");
					/* error handled below */
				}
			}
			else if (ConvertFromUnicode(CP_UTF8, 0, (WCHAR*) windowState->titleInfo.string,
					windowState->titleInfo.length / 2, &title, 0, NULL, NULL) < 1)
			{
				//WLog_ERR(TAG, "failed to convert window title");
				/* error handled below */
			}
			appWindow->title = title;
		}
		else
		{
			if (!(appWindow->title = _strdup("RdpRailWindow")))
			{
				//WLog_ERR(TAG, "failed to duplicate default window title string");
			}
		}
		if (!appWindow->title)
		{
			free(appWindow);
			return FALSE;
		}
		HashTable_Add(mfc->railWindows, (void*) (UINT_PTR) orderInfo->windowId, (void*) appWindow);
		mf_AppWindowInit(mfc, appWindow);
	}
	else
	{
		appWindow = (mfAppWindow*) HashTable_GetItemValue(mfc->railWindows, (void*) (UINT_PTR) orderInfo->windowId);
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
		appWindow->windowOffsetX = windowState->windowOffsetX;
		appWindow->windowOffsetY = windowState->windowOffsetY;
	}
	if (fieldFlags & WINDOW_ORDER_FIELD_WND_SIZE)
	{
		appWindow->windowWidth = windowState->windowWidth;
		appWindow->windowHeight = windowState->windowHeight;
	}
	if (fieldFlags & WINDOW_ORDER_FIELD_OWNER)
	{
		appWindow->ownerWindowId = windowState->ownerWindowId;
	}
	if (fieldFlags & WINDOW_ORDER_FIELD_STYLE)
	{
		appWindow->dwStyle = windowState->style;
		appWindow->dwExStyle = windowState->extendedStyle;
	}
	if (fieldFlags & WINDOW_ORDER_FIELD_SHOW)
	{
		appWindow->showState = windowState->showState;
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
		free(appWindow->title);
		appWindow->title = title;
	}
	if (fieldFlags & WINDOW_ORDER_FIELD_CLIENT_AREA_OFFSET)
	{
		appWindow->clientOffsetX = windowState->clientOffsetX;
		appWindow->clientOffsetY = windowState->clientOffsetY;
	}
	if (fieldFlags & WINDOW_ORDER_FIELD_CLIENT_AREA_SIZE)
	{
		appWindow->clientAreaWidth = windowState->clientAreaWidth;
		appWindow->clientAreaHeight = windowState->clientAreaHeight;
	}
	if (fieldFlags & WINDOW_ORDER_FIELD_WND_CLIENT_DELTA)
	{
		appWindow->windowClientDeltaX = windowState->windowClientDeltaX;
		appWindow->windowClientDeltaY = windowState->windowClientDeltaY;
	}
	if (fieldFlags & WINDOW_ORDER_FIELD_WND_RECTS)
	{
		if (appWindow->windowRects)
		{
			free(appWindow->windowRects);
			appWindow->windowRects = NULL;
		}
		appWindow->numWindowRects = windowState->numWindowRects;
		if (appWindow->numWindowRects)
		{
			appWindow->windowRects = (RECTANGLE_16*) calloc(appWindow->numWindowRects, sizeof(RECTANGLE_16));
			if (appWindow->windowRects == NULL)
			{
				return FALSE;
			}
			CopyMemory(appWindow->windowRects, windowState->windowRects,
					   appWindow->numWindowRects * sizeof(RECTANGLE_16));
		}
	}
	if (fieldFlags & WINDOW_ORDER_FIELD_VIS_OFFSET)
	{
		appWindow->visibleOffsetX = windowState->visibleOffsetX;
		appWindow->visibleOffsetY = windowState->visibleOffsetY;
	}
	if (fieldFlags & WINDOW_ORDER_FIELD_VISIBILITY)
	{
		if (appWindow->visibilityRects)
		{
			free(appWindow->visibilityRects);
			appWindow->visibilityRects = NULL;
		}
		appWindow->numVisibilityRects = windowState->numVisibilityRects;
		if (appWindow->numVisibilityRects)
		{
			appWindow->visibilityRects = (RECTANGLE_16*) calloc(appWindow->numVisibilityRects, sizeof(RECTANGLE_16));
			if (appWindow->visibilityRects == NULL)
			{
				return FALSE;
			}
			CopyMemory(appWindow->visibilityRects, windowState->visibilityRects,
					   appWindow->numVisibilityRects * sizeof(RECTANGLE_16));
		}
	}
	/* Update Window */
	if (fieldFlags & WINDOW_ORDER_FIELD_STYLE)
	{
	}
	if (fieldFlags & WINDOW_ORDER_FIELD_SHOW)
	{
		mf_ShowWindow(mfc, appWindow, appWindow->showState);
	}
	if (fieldFlags & WINDOW_ORDER_FIELD_TITLE)
	{
		if (appWindow->title != NULL)
		{
			mf_SetWindowText(mfc, appWindow, appWindow->title);
		}
	}
	if (position_or_size_updated)
	{
		UINT32 visibilityRectsOffsetX =
				(appWindow->visibleOffsetX - (appWindow->clientOffsetX - appWindow->windowClientDeltaX));
		UINT32 visibilityRectsOffsetY =
				(appWindow->visibleOffsetY - (appWindow->clientOffsetY - appWindow->windowClientDeltaY));
		/*
		 * The rail server like to set the window to a small size when it is minimized even though it is hidden
		 * in some cases this can cause the window not to restore back to its original size. Therefore we don't
		 * update our local window when that rail window state is minimized
		 */
		if (appWindow->rail_state != WINDOW_SHOW_MINIMIZED)
		{
			/* Redraw window area if already in the correct position */
			if (appWindow->x == appWindow->windowOffsetX &&
				appWindow->y == appWindow->windowOffsetY &&
				appWindow->width == appWindow->windowWidth &&
				appWindow->height == appWindow->windowHeight)
			{
				mf_UpdateWindowArea(mfc, appWindow, 0, 0, appWindow->windowWidth, appWindow->windowHeight);
			}
			else
			{
				mf_MoveWindow(mfc, appWindow, appWindow->windowOffsetX, appWindow->windowOffsetY,
							  appWindow->windowWidth, appWindow->windowHeight);
			}
			mf_SetWindowVisibilityRects(mfc, appWindow, visibilityRectsOffsetX, visibilityRectsOffsetY,
										appWindow->visibilityRects, appWindow->numVisibilityRects);
		}
	}
	return TRUE;
}

BOOL mac_window_delete(rdpContext* context, WINDOW_ORDER_INFO* orderInfo)
{
	mfAppWindow* appWindow = NULL;
	mfContext* mfc = (mfContext*) context;

	appWindow = (mfAppWindow*) HashTable_GetItemValue(mfc->railWindows, (void*) (UINT_PTR) orderInfo->windowId);
	if (appWindow == NULL)
	{
		return TRUE;
	}
	HashTable_Remove(mfc->railWindows, (void*) (UINT_PTR) orderInfo->windowId);
	mf_DestroyWindow(mfc, appWindow);
	return TRUE;
}

BOOL mac_window_icon(rdpContext* context, WINDOW_ORDER_INFO* orderInfo, WINDOW_ICON_ORDER* window_icon)
{
	return TRUE;
}

BOOL mac_window_cached_icon(rdpContext* context, WINDOW_ORDER_INFO* orderInfo, WINDOW_CACHED_ICON_ORDER* window_cached_icon)
{
	return TRUE;
}

BOOL mac_rail_notify_icon_create(rdpContext* context, WINDOW_ORDER_INFO* orderInfo, NOTIFY_ICON_STATE_ORDER* notify_icon_state)
{
	return TRUE;
}

BOOL mac_rail_notify_icon_update(rdpContext* context, WINDOW_ORDER_INFO* orderInfo, NOTIFY_ICON_STATE_ORDER* notify_icon_state)
{
	return TRUE;
}

BOOL mac_rail_notify_icon_delete(rdpContext* context, WINDOW_ORDER_INFO* orderInfo)
{
	return TRUE;
}

BOOL mac_rail_monitored_desktop(rdpContext* context, WINDOW_ORDER_INFO* orderInfo, MONITORED_DESKTOP_ORDER* monitored_desktop)
{
	return TRUE;
}

BOOL mac_rail_non_monitored_desktop(rdpContext* context, WINDOW_ORDER_INFO* orderInfo)
{
	return TRUE;
}

static UINT mac_rail_server_execute_result(RailClientContext* context, RAIL_EXEC_RESULT_ORDER* execResult)
{
	return CHANNEL_RC_OK;
}

static UINT mac_rail_server_system_param(RailClientContext* context, RAIL_SYSPARAM_ORDER* sysparam)
{
	return CHANNEL_RC_OK;
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
}

void mac_rail_uninit(mfContext* mfc, RailClientContext* rail)
{
	HashTable_Free(mfc->railWindows);
	rail->custom = NULL;
	mfc->rail = NULL;
	mfc->railWindows = NULL;
}



