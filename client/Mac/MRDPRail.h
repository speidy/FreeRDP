//
//  MRDPRail.h
//  FreeRDP
//
//  Created by Idan on 10/17/16.
//
//

#ifndef MRDPRail_h
#define MRDPRail_h

#import "freerdp/freerdp.h"
#import "freerdp/channels/channels.h"
#import "freerdp/client/rail.h"

void mac_rail_init(mfContext* mfc, RailClientContext* rail);
void mac_rail_uninit(mfContext* mfc, RailClientContext* rail);
void mac_rail_paint(mfContext* xfc, INT32 uleft, INT32 utop, UINT32 uright, UINT32 ubottom);

#endif /* MRDPRail_h */
