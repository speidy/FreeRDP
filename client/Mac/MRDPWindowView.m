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

CGContextRef windowview_create_bitmap_context(rdpContext* context)
{
    CGContextRef bitmap_context;
    rdpGdi* gdi = context->gdi;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    if (gdi->bytesPerPixel == 2)
    {
        bitmap_context = CGBitmapContextCreate(gdi->primary_buffer,
                                               gdi->width, gdi->height, 5, gdi->width * gdi->bytesPerPixel,
                                               colorSpace, kCGBitmapByteOrder16Little | kCGImageAlphaNoneSkipFirst);
    }
    else
    {
        bitmap_context = CGBitmapContextCreate(gdi->primary_buffer,
                                               gdi->width, gdi->height, 8, gdi->width * gdi->bytesPerPixel,
                                               colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst);
    }
    
    CGColorSpaceRelease(colorSpace);
    
    return bitmap_context;
}


- (void)init_view: (mfContext*) context
{
    self->mfc = context;
    self->bitmap_context = windowview_create_bitmap_context(&self->mfc->context);
}


- (void) drawRect:(NSRect)rect
{
    if (self->bitmap_context)
    {
        CGContextRef cgContext = [[NSGraphicsContext currentContext] graphicsPort];
        CGImageRef cgImage = CGBitmapContextCreateImage(self->bitmap_context);
        
        CGContextSaveGState(cgContext);
        
        CGContextClipToRect(cgContext, CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height));
        
        CGContextDrawImage(cgContext, [self bounds], cgImage);
        
        CGContextRestoreGState(cgContext);
        
        CGImageRelease(cgImage);
    }
    else
    {
        /* Fill the screen with black */
        [[NSColor blackColor] set];
        NSRectFill([self bounds]);
    }
}

@end
