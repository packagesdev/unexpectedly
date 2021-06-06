#import <Cocoa/Cocoa.h>

#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

#import "CUICrashLogsProvider.h"

#import "CUIThemesManager.h"

#import "CUIApplicationPreferences+Themes.h"
#import "CUIThemeItemsGroup+UI.h"

#import "CUIRawTextTransformation.h"

extern const CFStringRef kQLThumbnailPropertyIconFlavorKey;

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail);

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
    id tCrashLog=[[CUICrashLogsProvider defaultProvider] crashLogWithContentsOfFile:((__bridge NSURL *)url).path error:NULL];
    
    if (tCrashLog==nil)
        return noErr;
    
    [tCrashLog finalizeParsing];
    
    CUIApplicationPreferences * tPreferences=[CUIApplicationPreferences sharedPreferences];
    
    CUIRawTextTransformation * tRawTextTransformation=[CUIRawTextTransformation new];
    
    tRawTextTransformation.displaySettings=tPreferences.defaultTextModeDisplaySettings;
    tRawTextTransformation.fontSizeDelta=0;
    tRawTextTransformation.hyperlinksStyle=CUIHyperlinksNone;
    
    NSAttributedString * tAttributedString=[tRawTextTransformation transformCrashLog:tCrashLog];
    
    CUIThemeItemsGroup * tGroup=[[CUIThemesManager sharedManager].currentTheme itemsGroupWithIdentifier:[CUIApplicationPreferences groupIdentifierForPresentationMode:CUIPresentationModeText]];
    
    NSColor * tBackgroundColor=[tGroup attributesForItem:CUIThemeItemBackground].color;
    
    NSData *tRTFData = [tAttributedString dataFromRange:NSMakeRange(0, tAttributedString.length)
                                     documentAttributes:@{
                                                          NSDocumentTypeDocumentAttribute:NSRTFTextDocumentType,
                                                          NSBackgroundColorDocumentAttribute:tBackgroundColor
                                                          }
                                                  error:NULL];
    
    if (tRTFData==nil)
        return noErr;
    
    NSDictionary * tProperties=@{
                                    (__bridge NSString *)kQLThumbnailPropertyExtensionKey:@"",
                                    (__bridge NSString *)kQLThumbnailPropertyIconFlavorKey:@(9),
                                 };
    
    QLThumbnailRequestSetThumbnailWithDataRepresentation(thumbnail, (__bridge CFDataRef)tRTFData, kUTTypeRTF, NULL,(__bridge CFDictionaryRef)tProperties);
    
    return noErr;
}

void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail)
{
    // Implement only if supported
}
