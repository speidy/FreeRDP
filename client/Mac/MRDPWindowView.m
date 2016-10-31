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

#import "MRDPWindowView.h"


@implementation MRDPWindowView


- (void)init_view: (mfContext*) context appWindow:(mfAppWindow *)appWindow
{
	self->mfc = context;
	self->mfAppWindow = appWindow;
}

- (void) drawRect:(NSRect)rect
{
	if (self->mfc != NULL)
	{
		CGRect viewWindowRect = [self.window frame];
		int x = viewWindowRect.origin.x + rect.origin.x;
		int y = viewWindowRect.origin.y + rect.origin.y;
		int width = rect.size.width;
		int height = rect.size.height;
		rdpGdi* gdi = self->mfc->context.gdi;
		y = gdi->height - (y + height);
		CGContextRef bitmap_context;
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		int stride_bytes = gdi->width * gdi->bytesPerPixel;
		void* pixels = gdi->primary_buffer + y * stride_bytes + x * gdi->bytesPerPixel;
		if (gdi->bytesPerPixel == 2)
		{
			bitmap_context = CGBitmapContextCreate(pixels,
					width, height, 5, stride_bytes,
					colorSpace, kCGBitmapByteOrder16Little | kCGImageAlphaNoneSkipFirst);
		}
		else
		{
			bitmap_context = CGBitmapContextCreate(pixels,
					width, height, 8, stride_bytes,
					colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst);
		}
		CGColorSpaceRelease(colorSpace);
		CGContextRef cgContext = [[NSGraphicsContext currentContext] graphicsPort];
		CGImageRef cgImage = CGBitmapContextCreateImage(bitmap_context);
		CGContextSaveGState(cgContext);
		CGContextDrawImage(cgContext, rect, cgImage);
		CGContextRestoreGState(cgContext);
		CGImageRelease(cgImage);
		CGContextRelease(bitmap_context);
	}
	else
	{
		/* Fill the screen with black */
		[[NSColor blackColor] set];
		NSRectFill([self bounds]);
	}
}

@end
