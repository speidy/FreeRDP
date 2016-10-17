//
//  MRDPRail.m
//  FreeRDP
//
//  Created by Idan on 10/17/16.
//
//

#import "mfreerdp.h"

#import <Foundation/Foundation.h>
#import "MRDPRail.h"


BOOL mac_window_create(rdpContext* context, WINDOW_ORDER_INFO* orderInfo, WINDOW_STATE_ORDER* window_state)
{
    return TRUE;
}

BOOL mac_window_update(rdpContext* context, WINDOW_ORDER_INFO* orderInfo, WINDOW_STATE_ORDER* window_state)
{
    return TRUE;
}

BOOL mac_window_delete(rdpContext* context, WINDOW_ORDER_INFO* orderInfo)
{
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
    window->context = &mfc->context;
    window->WindowCreate = mac_window_create;
    window->WindowUpdate = mac_window_update;
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
}

void mac_rail_uninit(mfContext* mfc, RailClientContext* rail)
{
    rail->custom = NULL;
    mfc->rail = NULL;
}



