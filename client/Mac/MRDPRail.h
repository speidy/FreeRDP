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
	rdpContext* m_context;
	WINDOW_ORDER_INFO* m_orderInfo;
	WINDOW_STATE_ORDER* m_windowState;
	WINDOW_ICON_ORDER* m_windowIcon;
	WINDOW_CACHED_ICON_ORDER* m_windowCachedIcon;
	int m_rv;
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

- (void) mac_window_common_sync;
- (void) mac_window_delete_sync;
- (void) mac_window_icon_sync;
- (void) mac_window_cached_icon_sync;

@end

void mac_rail_init(mfContext* mfc, RailClientContext* rail);
void mac_rail_uninit(mfContext* mfc, RailClientContext* rail);
void mac_rail_paint(mfContext* xfc, INT32 uleft, INT32 utop, UINT32 uright, UINT32 ubottom);

#endif /* MRDPRail_h */
