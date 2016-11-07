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

#ifndef MRDPRail_h
#define MRDPRail_h

#import "freerdp/freerdp.h"
#import "freerdp/channels/channels.h"
#import "freerdp/client/rail.h"

@interface MRDPRail : NSObject
{
@public

}

- (BOOL) mac_window_common :(rdpContext*) context
		oi:(WINDOW_ORDER_INFO*) orderInfo
		ws:(WINDOW_STATE_ORDER*) windowState;
- (BOOL) mac_window_delete :(rdpContext*) context
		oi:(WINDOW_ORDER_INFO*) orderInfo;
- (BOOL) mac_window_icon :(rdpContext*) context
		oi:(WINDOW_ORDER_INFO*) orderInfo
		wi:(WINDOW_ICON_ORDER*) windowIcon;
- (BOOL) mac_window_cached_icon :(rdpContext*) context
		oi:(WINDOW_ORDER_INFO*) orderInfo
		wci:(WINDOW_CACHED_ICON_ORDER*) windowCachedIcon;
- (BOOL) mac_rail_notify_icon_create :(rdpContext*) context
		oi:(WINDOW_ORDER_INFO*) orderInfo
		nis:(NOTIFY_ICON_STATE_ORDER*) notifyIconState;
- (BOOL) mac_rail_notify_icon_update :(rdpContext*) context
		oi:(WINDOW_ORDER_INFO*) orderInfo
		nis:(NOTIFY_ICON_STATE_ORDER*) notifyIconState;
- (BOOL) mac_rail_notify_icon_delete :(rdpContext*) context
		oi:(WINDOW_ORDER_INFO*) orderInfo;
- (BOOL) mac_rail_monitored_desktop:(rdpContext*) context
		oi:(WINDOW_ORDER_INFO*) orderInfo
		md:(MONITORED_DESKTOP_ORDER*) monitoredDesktop;
- (BOOL) mac_rail_non_monitored_desktop:(rdpContext*) context
		oi:(WINDOW_ORDER_INFO*) orderInfo;

- (UINT) mac_rail_server_execute_result:(RailClientContext*) context
		er:(RAIL_EXEC_RESULT_ORDER*) execResult;
- (UINT) mac_rail_server_system_param:(RailClientContext*) context
		sp:(RAIL_SYSPARAM_ORDER*) sysparam;
- (UINT) mac_rail_server_handshake:(RailClientContext*) context
		hs:(RAIL_HANDSHAKE_ORDER*) handshake;
- (UINT) mac_rail_server_handshake_ex:(RailClientContext*) context
		he:(RAIL_HANDSHAKE_EX_ORDER*) handshakeEx;
- (UINT) mac_rail_server_local_move_size:(RailClientContext*) context
		lm:(RAIL_LOCALMOVESIZE_ORDER*) localMoveSize;
- (UINT) mac_rail_server_min_max_info:(RailClientContext*) context
		mm:(RAIL_MINMAXINFO_ORDER*) minMaxInfo;
- (UINT) mac_rail_server_language_bar_info:(RailClientContext*) context
		lb:(RAIL_LANGBAR_INFO_ORDER*) langBarInfo;
- (UINT) mac_rail_server_get_appid_response:(RailClientContext*) context
		ga:(RAIL_GET_APPID_RESP_ORDER*) getAppIdResp;

@end

void mac_rail_init(mfContext* mfc, RailClientContext* rail);
void mac_rail_uninit(mfContext* mfc, RailClientContext* rail);
void mac_rail_paint(mfContext* xfc, INT32 uleft, INT32 utop, UINT32 uright, UINT32 ubottom);
void mac_rail_send_client_system_command(mfContext* mfc, UINT32 windowId, UINT16 command);
void mac_rail_send_client_window_move(mfContext* mfc, UINT32 windowId, UINT16 left, UINT16 top,
		UINT16 right, UINT16 bottom);

#endif /* MRDPRail_h */
