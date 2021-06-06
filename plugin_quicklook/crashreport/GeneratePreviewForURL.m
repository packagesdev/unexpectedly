#import <Cocoa/Cocoa.h>

#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

#import "CUICrashLogsProvider.h"

#import "CUIRawTextTransformation.h"

#import "CUIThemesManager.h"

#import "CUIApplicationPreferences+Themes.h"
#import "CUIThemeItemsGroup+UI.h"

extern NSString * const CUITextModeDisplaySettingsVisibleSectionKey;

extern NSString * const CUITextModeDisplaySettingsVisibleStackFrameComponentsKey;


OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    @autoreleasepool
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
        
        QLPreviewRequestSetDataRepresentation(preview,
                                              (__bridge CFDataRef)tRTFData,
                                              kUTTypeRTF,
                                              NULL);
    }
    
    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}
