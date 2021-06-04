#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail);

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
    CGContextRef cgContext = QLThumbnailRequestCreateContext(thumbnail, maxSize, false, NULL);
    
    if (cgContext) {
        NSGraphicsContext *_graphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:(void *)_context
                                                                                         flipped:_webView.isFlipped];
        [_webView displayRectIgnoringOpacity:_webView.bounds inContext:_graphicsContext];
        
        QLThumbnailRequestFlushContext(thumbnail, cgContext);
        
        CFRelease(cgContext);
    }
    
    
    // To complete your generator please implement the function GenerateThumbnailForURL in GenerateThumbnailForURL.c
    return noErr;
}

void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail)
{
    // Implement only if supported
}
