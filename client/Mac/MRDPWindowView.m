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


- (void)init_view: (mfContext*) context appWindow:(MRDPWindow *)appWindow
{
	self->mfc = context;
	self->mfAppWindow = appWindow;
}

- (void) drawRect:(NSRect)rect
{
	rdpGdi* gdi;
	CGRect viewWindowRect;
	CGContextRef bitmap_context;
	CGColorSpaceRef colorSpace;
	CGContextRef cgContext;
	CGImageRef cgImage;
	void* pixels;
	int stride_bytes;
	int x;
	int y;
	int width;
	int height;
	
	if (self->mfc != NULL)
	{
		viewWindowRect = [self.window frame];
		x = viewWindowRect.origin.x + rect.origin.x;
		y = viewWindowRect.origin.y + rect.origin.y;
		width = rect.size.width;
		height = rect.size.height;

		if (x < 0 || y < 0 || width < 0  || height < 0)
		{
			return;
		}
		
		gdi = self->mfc->context.gdi;
		y = gdi->height - (y + height);

		colorSpace = CGColorSpaceCreateDeviceRGB();
		stride_bytes = gdi->width * gdi->bytesPerPixel;
		pixels = gdi->primary_buffer + y * stride_bytes + x * gdi->bytesPerPixel;
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
		cgContext = [[NSGraphicsContext currentContext] graphicsPort];
		cgImage = CGBitmapContextCreateImage(bitmap_context);
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
