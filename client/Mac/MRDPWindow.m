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
#import "freerdp/log.h"

#define TAG CLIENT_TAG("mac")

@implementation MRDPWindow

- (BOOL)becomeFirstResponder
{
	return YES;
}

- (BOOL)canBecomeKeyWindow
{
	return YES;
}

- (BOOL)canBecomeMainWindow
{
	return YES;
}

- (void)deminiaturize:(id)sender
{
	NSLog(@"deminiaturize");
	[super deminiaturize:sender];
}

- (void)miniaturize:(id)sender
{
	NSLog(@"miniaturize");
	[super miniaturize:sender];
}

- (void)windowDidMiniaturize:(NSNotification *)notification
{
	NSLog(@"windowDidMiniaturize");
}

-(void)windowDidDeminiaturize:(NSNotification *)notification
{
	NSLog(@"windowDidDeminiaturize");
}

/* mouse stuff */
- (void) send_mouse_position:(UINT16)flags x:(UINT16)x y:(UINT16) y
{
	rdpInput *input = instance->input;
	
	/* convert to window coordinate system */
	y = [self frame].size.height - y;
	input->MouseEvent(input, flags, x + self.windowOffsetX, y + self.windowOffsetY);
}

- (void) mouseMoved:(NSEvent *)event
{
	[super mouseMoved:event];
	
	NSPoint loc = [event locationInWindow];
	int x = (int) loc.x;
	int y = (int) loc.y;
	
	[self send_mouse_position:PTR_FLAGS_MOVE x:x y:y];
}

- (void)mouseDown:(NSEvent *) event
{
	[super mouseDown:event];
	
	NSPoint loc = [event locationInWindow];
	int x = (int) loc.x;
	int y = (int) loc.y;
	
	[self send_mouse_position:PTR_FLAGS_DOWN | PTR_FLAGS_BUTTON1 x:x y:y];
}

- (void) mouseUp:(NSEvent *) event
{
	[super mouseUp:event];
	
	NSPoint loc = [event locationInWindow];
	int x = (int) loc.x;
	int y = (int) loc.y;
	
	[self send_mouse_position:PTR_FLAGS_BUTTON1 x:x y:y];
}

- (void) rightMouseDown:(NSEvent *)event
{
	[super rightMouseDown:event];
	
	NSPoint loc = [event locationInWindow];
	int x = (int) loc.x;
	int y = (int) loc.y;
	
	[self send_mouse_position:PTR_FLAGS_DOWN | PTR_FLAGS_BUTTON2 x:x y:y];
}

- (void) rightMouseUp:(NSEvent *)event
{
	[super rightMouseUp:event];
	
	NSPoint loc = [event locationInWindow];
	int x = (int) loc.x;
	int y = (int) loc.y;
	
	[self send_mouse_position:PTR_FLAGS_BUTTON2 x:x y:y];
}

- (void) otherMouseDown:(NSEvent *)event
{
	[super otherMouseDown:event];
	
	NSPoint loc = [event locationInWindow];
	int x = (int) loc.x;
	int y = (int) loc.y;
	
	[self send_mouse_position:PTR_FLAGS_DOWN | PTR_FLAGS_BUTTON2 x:x y:y];
}

- (void) otherMouseUp:(NSEvent *)event
{
	[super otherMouseUp:event];
	
	NSPoint loc = [event locationInWindow];
	int x = (int) loc.x;
	int y = (int) loc.y;
	
	[self send_mouse_position:PTR_FLAGS_BUTTON3 x:x y:y];
}

- (void) scrollWheel:(NSEvent *)event
{
//TODO
#if 0
	UINT16 flags;
	
	[super scrollWheel:event];
	
	NSPoint loc = [event locationInWindow];
	int x = (int) loc.x;
	int y = (int) loc.y;
	
	flags = PTR_FLAGS_WHEEL;
	
	/* 1 event = 120 units */
	int units = [event deltaY] * 120;
	
	/* send out all accumulated rotations */
	while(units != 0)
	{
		/* limit to maximum value in WheelRotationMask (9bit signed value) */
		int step = MIN(MAX(-256, units), 255);
		
		[self scale_mouse_position:flags | ((UINT16)step & WheelRotationMask) x:x y:y];
		units -= step;
	}
#endif
}

- (void) mouseDragged:(NSEvent *)event
{
//TODO
#if 0
	[super mouseDragged:event];
	
	NSPoint loc = [event locationInWindow];
	int x = (int) loc.x;
	int y = (int) loc.y;
	
	// send mouse motion event to RDP server
	[self scale_mouse_position:PTR_FLAGS_MOVE x:x y:y];
#endif
}

/* keyboard stuff */
+ (DWORD) fixKeyCode: (DWORD)keyCode keyChar: (unichar)keyChar type:(enum APPLE_KEYBOARD_TYPE)type
{
	/**
	 * In 99% of cases, the given key code is truly keyboard independent.
	 * This function handles the remaining 1% of edge cases.
	 *
	 * Hungarian Keyboard: This is 'QWERTZ' and not 'QWERTY'.
	 * The '0' key is on the left of the '1' key, where '~' is on a US keyboard.
	 * A special 'i' letter key with acute is found on the right of the left shift key.
	 * On the hungarian keyboard, the 'i' key is at the left of the 'Y' key
	 * Some international keyboards have a corresponding key which would be at
	 * the left of the 'Z' key when using a QWERTY layout.
	 *
	 * The Apple Hungarian keyboard sends inverted key codes for the '0' and 'i' keys.
	 * When using the US keyboard layout, key codes are left as-is (inverted).
	 * When using the Hungarian keyboard layout, key codes are swapped (non-inverted).
	 * This means that when using the Hungarian keyboard layout with a US keyboard,
	 * the keys corresponding to '0' and 'i' will effectively be inverted.
	 *
	 * To fix the '0' and 'i' key inversion, we use the corresponding output character
	 * provided by OS X and check for a character to key code mismatch: for instance,
	 * when the output character is '0' for the key code corresponding to the 'i' key.
	 */
	
#if 0
	switch (keyChar)
	{
		case '0':
		case 0x00A7: /* section sign */
			if (keyCode == APPLE_VK_ISO_Section)
				keyCode = APPLE_VK_ANSI_Grave;
			break;
			
		case 0x00ED: /* latin small letter i with acute */
		case 0x00CD: /* latin capital letter i with acute */
			if (keyCode == APPLE_VK_ANSI_Grave)
				keyCode = APPLE_VK_ISO_Section;
			break;
	}
#endif
	
	/* Perform keycode correction for all ISO keyboards */
	
	if (type == APPLE_KEYBOARD_TYPE_ISO)
	{
		if (keyCode == APPLE_VK_ANSI_Grave)
			keyCode = APPLE_VK_ISO_Section;
		else if (keyCode == APPLE_VK_ISO_Section)
			keyCode = APPLE_VK_ANSI_Grave;
	}
	
	return keyCode;
}

- (void)keyDown:(NSEvent *)event
{
	DWORD keyCode;
	DWORD keyFlags;
	DWORD vkcode;
	DWORD scancode;
	unichar keyChar;
	NSString* characters;
	
	keyFlags = KBD_FLAGS_DOWN;
	keyCode = [event keyCode];
	
	characters = [event charactersIgnoringModifiers];
	
	if ([characters length] > 0)
	{
		keyChar = [characters characterAtIndex:0];
		keyCode = [MRDPWindow fixKeyCode:keyCode keyChar:keyChar type:mfc->appleKeyboardType];
	}
	
	vkcode = GetVirtualKeyCodeFromKeycode(keyCode + 8, KEYCODE_TYPE_APPLE);
	scancode = GetVirtualScanCodeFromVirtualKeyCode(vkcode, 4);
	keyFlags |= (scancode & KBDEXT) ? KBDEXT : 0;
	scancode &= 0xFF;
	vkcode &= 0xFF;
	
#if 0
	WLog_ERR(TAG,  "keyDown: keyCode: 0x%04X scancode: 0x%04X vkcode: 0x%04X keyFlags: %d name: %s",
			 keyCode, scancode, vkcode, keyFlags, GetVirtualKeyName(vkcode));
#endif
	
	freerdp_input_send_keyboard_event(instance->input, keyFlags, scancode);
}

- (void) keyUp:(NSEvent *) event
{
	DWORD keyCode;
	DWORD keyFlags;
	DWORD vkcode;
	DWORD scancode;
	unichar keyChar;
	NSString* characters;

	keyFlags = KBD_FLAGS_RELEASE;
	keyCode = [event keyCode];
	
	characters = [event charactersIgnoringModifiers];
	
	if ([characters length] > 0)
	{
		keyChar = [characters characterAtIndex:0];
		keyCode = [MRDPWindow fixKeyCode:keyCode keyChar:keyChar type:mfc->appleKeyboardType];
	}
	
	vkcode = GetVirtualKeyCodeFromKeycode(keyCode + 8, KEYCODE_TYPE_APPLE);
	scancode = GetVirtualScanCodeFromVirtualKeyCode(vkcode, 4);
	keyFlags |= (scancode & KBDEXT) ? KBDEXT : 0;
	scancode &= 0xFF;
	vkcode &= 0xFF;
	
#if 0
	WLog_DBG(TAG,  "keyUp: key: 0x%04X scancode: 0x%04X vkcode: 0x%04X keyFlags: %d name: %s",
			 keyCode, scancode, vkcode, keyFlags, GetVirtualKeyName(vkcode));
#endif
	
	freerdp_input_send_keyboard_event(instance->input, keyFlags, scancode);
}


- (void) flagsChanged:(NSEvent*) event
{
	int key;
	DWORD keyFlags;
	DWORD vkcode;
	DWORD scancode;
	DWORD modFlags;
	
	keyFlags = 0;
	key = [event keyCode] + 8;
	modFlags = [event modifierFlags] & NSDeviceIndependentModifierFlagsMask;
	
	vkcode = GetVirtualKeyCodeFromKeycode(key, KEYCODE_TYPE_APPLE);
	scancode = GetVirtualScanCodeFromVirtualKeyCode(vkcode, 4);
	keyFlags |= (scancode & KBDEXT) ? KBDEXT : 0;
	scancode &= 0xFF;
	vkcode &= 0xFF;
	
#if 0
	WLog_DBG(TAG,  "flagsChanged: key: 0x%04X scancode: 0x%04X vkcode: 0x%04X extended: %d name: %s modFlags: 0x%04X",
			 key - 8, scancode, vkcode, keyFlags, GetVirtualKeyName(vkcode), modFlags);
	
	if (modFlags & NSAlphaShiftKeyMask)
		WLog_DBG(TAG,  "NSAlphaShiftKeyMask");
	
	if (modFlags & NSShiftKeyMask)
		WLog_DBG(TAG,  "NSShiftKeyMask");
	
	if (modFlags & NSControlKeyMask)
		WLog_DBG(TAG,  "NSControlKeyMask");
	
	if (modFlags & NSAlternateKeyMask)
		WLog_DBG(TAG,  "NSAlternateKeyMask");
	
	if (modFlags & NSCommandKeyMask)
		WLog_DBG(TAG,  "NSCommandKeyMask");
	
	if (modFlags & NSNumericPadKeyMask)
		WLog_DBG(TAG,  "NSNumericPadKeyMask");
	
	if (modFlags & NSHelpKeyMask)
		WLog_DBG(TAG,  "NSHelpKeyMask");
#endif
	
	if ((modFlags & NSAlphaShiftKeyMask) && !(kbdModFlags & NSAlphaShiftKeyMask))
		freerdp_input_send_keyboard_event(instance->input, keyFlags | KBD_FLAGS_DOWN, scancode);
	else if (!(modFlags & NSAlphaShiftKeyMask) && (kbdModFlags & NSAlphaShiftKeyMask))
		freerdp_input_send_keyboard_event(instance->input, keyFlags | KBD_FLAGS_RELEASE, scancode);
	
	if ((modFlags & NSShiftKeyMask) && !(kbdModFlags & NSShiftKeyMask))
		freerdp_input_send_keyboard_event(instance->input, keyFlags | KBD_FLAGS_DOWN, scancode);
	else if (!(modFlags & NSShiftKeyMask) && (kbdModFlags & NSShiftKeyMask))
		freerdp_input_send_keyboard_event(instance->input, keyFlags | KBD_FLAGS_RELEASE, scancode);
	
	if ((modFlags & NSControlKeyMask) && !(kbdModFlags & NSControlKeyMask))
		freerdp_input_send_keyboard_event(instance->input, keyFlags | KBD_FLAGS_DOWN, scancode);
	else if (!(modFlags & NSControlKeyMask) && (kbdModFlags & NSControlKeyMask))
		freerdp_input_send_keyboard_event(instance->input, keyFlags | KBD_FLAGS_RELEASE, scancode);
	
	if ((modFlags & NSAlternateKeyMask) && !(kbdModFlags & NSAlternateKeyMask))
		freerdp_input_send_keyboard_event(instance->input, keyFlags | KBD_FLAGS_DOWN, scancode);
	else if (!(modFlags & NSAlternateKeyMask) && (kbdModFlags & NSAlternateKeyMask))
		freerdp_input_send_keyboard_event(instance->input, keyFlags | KBD_FLAGS_RELEASE, scancode);
	
	if ((modFlags & NSCommandKeyMask) && !(kbdModFlags & NSCommandKeyMask))
		freerdp_input_send_keyboard_event(instance->input, keyFlags | KBD_FLAGS_DOWN, scancode);
	else if (!(modFlags & NSCommandKeyMask) && (kbdModFlags & NSCommandKeyMask))
		freerdp_input_send_keyboard_event(instance->input, keyFlags | KBD_FLAGS_RELEASE, scancode);
	
	if ((modFlags & NSNumericPadKeyMask) && !(kbdModFlags & NSNumericPadKeyMask))
		freerdp_input_send_keyboard_event(instance->input, keyFlags | KBD_FLAGS_DOWN, scancode);
	else if (!(modFlags & NSNumericPadKeyMask) && (kbdModFlags & NSNumericPadKeyMask))
		freerdp_input_send_keyboard_event(instance->input, keyFlags | KBD_FLAGS_RELEASE, scancode);
	
	if ((modFlags & NSHelpKeyMask) && !(kbdModFlags & NSHelpKeyMask))
		freerdp_input_send_keyboard_event(instance->input, keyFlags | KBD_FLAGS_DOWN, scancode);
	else if (!(modFlags & NSHelpKeyMask) && (kbdModFlags & NSHelpKeyMask))
		freerdp_input_send_keyboard_event(instance->input, keyFlags | KBD_FLAGS_RELEASE, scancode);
	
	kbdModFlags = modFlags;
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
	self->instance = mfc->context.instance;
	
	rect = NSMakeRect(self.windowOffsetX, self.windowOffsetY, self.windowWidth, self.windowHeight);
	[MRDPWindow windows_to_mac_coord:mfc->context.settings rect:&rect];

	view = [[MRDPWindowView alloc] initWithFrame:rect];
	[view init_view:mfc appWindow:self];

	[self setTitle: [NSString stringWithUTF8String: self.wnd_title]];
	[self setBackgroundColor:[NSColor clearColor]];
	[self setContentView: view];
	[self setDelegate:self];
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
}

@end

