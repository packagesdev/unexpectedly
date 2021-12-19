/*
 Copyright (c) 2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "CUIIPSTransform.h"

#import "IPSDateFormatter.h"

#import "IPSThreadState+RegisterDisplayName.h"
#import "IPSImage+UserCode.h"

#import "CUIApplicationPreferences.h"
#import "CUIApplicationPreferences+Themes.h"

#import "CUICrashLogBinaryImages.h"

#import "CUIBinaryImageUtility.h"

#import "CUIThemesManager.h"
#import "CUIThemeItemsGroup+UI.h"

#ifndef __DISABLE_SYMBOLICATION_
#import "CUIdSYMBundlesManager.h"

#import "CUISymbolicationManager.h"

#import "CUISymbolicationDataFormatter.h"
#endif

#import "CUIStackFrame.h"

@interface CUIDataTransform (Private)

- (void)setOutput:(NSAttributedString *)inOutput;

@end

@interface CUIIPSTransform ()
{
    NSDictionary * _cachedPlainTextAttributes;
    
    NSDictionary * _cachedKeyAttributes;
    
    NSDictionary * _cachedVersionAttributes;
    
    NSDictionary * _cachedPathAttributes;
    
    NSDictionary * _cachedUUIDAttributes;
    
    NSDictionary * _cachedCrashedThreadLabelAttributes;
    
    NSDictionary * _cachedThreadLabelAttributes;
    
    NSDictionary * _cachedExecutableCodeAttributes;
    
    NSDictionary * _cachedOSCodeAttributes;
    
    NSDictionary * _cachedMemoryAddressAttributes;
    
    
    NSDictionary * _cachedRegisterValueAttributes;
    
    
    NSDictionary * _cachedParsingErrorAttributes;
    
    NSColor * _cachedUnderlineColor;
    
    
    NSCharacterSet * _whitespaceCharacterSet;
    
#ifndef __DISABLE_SYMBOLICATION_
    CUISymbolicationDataFormatter * _symbolicationDataFormatter;
#endif
}

- (void)updatesCachedAttributes;

@end

@implementation CUIIPSTransform

+ (NSString *)binaryImageStringForAddress:(NSUInteger)inAddress
{
    NSString * tString=[NSString stringWithFormat:@"0x%lx",inAddress];
    
    NSUInteger tLength=tString.length;
    
    NSString * tSpaceString=@"                  ";
    
    return [[tSpaceString substringFromIndex:tLength] stringByAppendingString:tString];
}

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        
#ifndef __DISABLE_SYMBOLICATION_
        _symbolicationDataFormatter=[CUISymbolicationDataFormatter new];
#endif
        
        _whitespaceCharacterSet=[NSCharacterSet whitespaceCharacterSet];
    }
    
    return self;
}

#pragma mark -

- (void)updatesCachedAttributes
{
    NSFontManager * tFontManager = [NSFontManager sharedFontManager];
    
    CUIThemesManager * tThemesManager=[CUIThemesManager sharedManager];
    
    CUIThemeItemsGroup * tItemsGroup=[tThemesManager.currentTheme itemsGroupWithIdentifier:[CUIApplicationPreferences groupIdentifierForPresentationMode:CUIPresentationModeText]];
    
    NSMutableArray * tItemsNames=[tItemsGroup.itemsNames mutableCopy];
    
    [tItemsNames removeObject:CUIThemeItemBackground];
    [tItemsNames removeObject:CUIThemeItemLineNumber];
    [tItemsNames removeObject:CUIThemeItemSelectionBackground];
    [tItemsNames removeObject:CUIThemeItemSelectionText];
    
    // TabStops settings
    
    NSMutableParagraphStyle * tMutableParagraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    
    tMutableParagraphStyle.tabStops=@[];
    
    [tMutableParagraphStyle setLineSpacing:2.0];
    
    for (NSUInteger tIndex = 1; tIndex <= 20; tIndex++)
    {
        NSTextTab *tabStop = [[NSTextTab alloc] initWithType:NSLeftTabStopType location: 40 * (tIndex)];
        [tMutableParagraphStyle addTabStop:tabStop];
    }
    
    NSMutableDictionary * tMutableDictionary=[NSMutableDictionary dictionary];
    
    for(NSString * tItemName in tItemsNames)
    {
        CUIThemeItemAttributes * tItemAttributes=[tItemsGroup attributesForItem:tItemName];
        
        NSFont * tFont=tItemAttributes.font;
        
        NSFont * tAdjustedFont=nil;
        
        tAdjustedFont=[tFontManager convertFont:tFont toSize:tFont.pointSize + self.fontSizeDelta];
        
        if (tAdjustedFont==nil)
            tAdjustedFont=tFont;
        
        tMutableDictionary[tItemName]=@{
                                        NSFontAttributeName:tAdjustedFont,
                                        NSForegroundColorAttributeName:tItemAttributes.color,
                                        NSParagraphStyleAttributeName:tMutableParagraphStyle
                                        };
    }
    
    _cachedPlainTextAttributes=tMutableDictionary[CUIThemeItemPlainText];
    
    NSColor * tForegroundColor=_cachedPlainTextAttributes[NSForegroundColorAttributeName];
    _cachedUnderlineColor=[tForegroundColor colorWithAlphaComponent:0.35];
    
    _cachedKeyAttributes=tMutableDictionary[CUIThemeItemKey];
    _cachedThreadLabelAttributes=tMutableDictionary[CUIThemeItemThreadLabel];
    _cachedCrashedThreadLabelAttributes=tMutableDictionary[CUIThemeItemCrashedThreadLabel];
    
    _cachedExecutableCodeAttributes=tMutableDictionary[CUIThemeItemExecutableCode];
    _cachedOSCodeAttributes=tMutableDictionary[CUIThemeItemOSCode];
    
    _cachedVersionAttributes=tMutableDictionary[CUIThemeItemVersion];
    _cachedMemoryAddressAttributes=tMutableDictionary[CUIThemeItemMemoryAddress];
    _cachedPathAttributes=tMutableDictionary[CUIThemeItemPath];
    _cachedUUIDAttributes=tMutableDictionary[CUIThemeItemUUID];
    _cachedRegisterValueAttributes=tMutableDictionary[CUIThemeItemRegisterValue];
    
    
    NSMutableDictionary * tParsingErrorDictionary=[_cachedPlainTextAttributes mutableCopy];
    
    tParsingErrorDictionary[NSForegroundColorAttributeName]=[NSColor redColor];
    
    _cachedParsingErrorAttributes=[tParsingErrorDictionary copy];
}

#pragma mark -

- (NSAttributedString *)attributedStringForKey:(NSString *)inString
{
    if (inString==nil)
        return nil;
    
    return [[NSAttributedString alloc] initWithString:inString attributes:_cachedKeyAttributes];
}

- (NSAttributedString *)attributedStringForKeyWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2)
{
    if (format==nil)
        return nil;
    
    va_list args;
    va_start(args, format);
    NSString * tString=[[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    return [[NSAttributedString alloc] initWithString:tString attributes:_cachedKeyAttributes];
}


- (NSAttributedString *)attributedStringForPlainText:(NSString *)inString
{
    if (inString==nil)
        return nil;
        
    return [[NSAttributedString alloc] initWithString:inString attributes:_cachedPlainTextAttributes];
}

- (NSAttributedString *)attributedStringForPlainTextWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2)
{
    if (format==nil)
        return nil;
    
    va_list args;
    va_start(args, format);
    NSString * tString=[[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    return [[NSAttributedString alloc] initWithString:tString attributes:_cachedPlainTextAttributes];
}

- (NSAttributedString *)attributedStringForPath:(NSString *)inString
{
    if (inString==nil)
        return nil;
    
    return [[NSAttributedString alloc] initWithString:inString attributes:_cachedPathAttributes];
}

- (NSAttributedString *)attributedStringForPathWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2)
{
    if (format==nil)
        return nil;
    
    va_list args;
    va_start(args, format);
    NSString * tString=[[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    return [[NSAttributedString alloc] initWithString:tString attributes:_cachedPathAttributes];
}

- (NSAttributedString *)attributedStringForVersion:(NSString *)inString
{
    if (inString==nil)
        return nil;
    
    return [[NSAttributedString alloc] initWithString:inString attributes:_cachedVersionAttributes];
}

- (NSAttributedString *)attributedStringForVersionWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2)
{
    if (format==nil)
        return nil;
    
    va_list args;
    va_start(args, format);
    NSString * tString=[[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    return [[NSAttributedString alloc] initWithString:tString attributes:_cachedVersionAttributes];
}

- (NSAttributedString *)attributedStringForUUID:(NSString *)inString
{
    if (inString==nil)
        return nil;
    
    return [[NSAttributedString alloc] initWithString:inString attributes:_cachedUUIDAttributes];
}

- (NSAttributedString *)attributedStringForUUIDWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2)
{
    if (format==nil)
        return nil;
    
    va_list args;
    va_start(args, format);
    NSString * tString=[[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    return [[NSAttributedString alloc] initWithString:tString attributes:_cachedUUIDAttributes];
}

- (NSAttributedString *)attributedStringForThreadLabel:(NSString *)inString
{
    if (inString==nil)
        return nil;
    
    return [[NSAttributedString alloc] initWithString:inString attributes:_cachedThreadLabelAttributes];
}

- (NSAttributedString *)attributedStringForThreadLabelWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2)
{
    if (format==nil)
        return nil;
    
    va_list args;
    va_start(args, format);
    NSString * tString=[[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    return [[NSAttributedString alloc] initWithString:tString attributes:_cachedThreadLabelAttributes];
}

- (NSAttributedString *)attributedStringForCrashedThreadLabel:(NSString *)inString
{
    if (inString==nil)
        return nil;
    
    return [[NSAttributedString alloc] initWithString:inString attributes:_cachedCrashedThreadLabelAttributes];
}

- (NSAttributedString *)attributedStringForCrashedThreadLabelWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2)
{
    if (format==nil)
        return nil;
    
    va_list args;
    va_start(args, format);
    NSString * tString=[[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    return [[NSAttributedString alloc] initWithString:tString attributes:_cachedCrashedThreadLabelAttributes];
}

- (NSAttributedString *)attributedStringForMemoryAddress:(NSString *)inString
{
    if (inString==nil)
        return nil;
    
    return [[NSAttributedString alloc] initWithString:inString attributes:_cachedMemoryAddressAttributes];
}

- (NSAttributedString *)attributedStringForMemoryAddressWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2)
{
    if (format==nil)
        return nil;
    
    va_list args;
    va_start(args, format);
    NSString * tString=[[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    return [[NSAttributedString alloc] initWithString:tString attributes:_cachedMemoryAddressAttributes];
}

- (NSAttributedString *)attributedStringForUser:(BOOL)inUserCode code:(NSString *)inString
{
    if (inString==nil)
        return nil;
    
    return [[NSAttributedString alloc] initWithString:inString attributes:(inUserCode==YES) ? _cachedExecutableCodeAttributes : _cachedOSCodeAttributes];
}

- (NSAttributedString *)attributedStringForUser:(BOOL)inUserCode codeWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(2,3)
{
    if (format==nil)
        return nil;
    
    va_list args;
    va_start(args, format);
    NSString * tString=[[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    return [[NSAttributedString alloc] initWithString:tString attributes:(inUserCode==YES) ? _cachedExecutableCodeAttributes : _cachedOSCodeAttributes];
}

- (NSAttributedString *)attributedStringForRegisterValueWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2)
{
    if (format==nil)
        return nil;
    
    va_list args;
    va_start(args, format);
    NSString * tString=[[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    return [[NSAttributedString alloc] initWithString:tString attributes:_cachedRegisterValueAttributes];
}

- (NSAttributedString *)attributedStringForUser:(BOOL)inUserCode binaryImageIdentifier:(NSString *)inIdentifier
{
    if (inIdentifier==nil)
        return nil;
    
    NSMutableDictionary * tMutableDictionary=[_cachedPlainTextAttributes mutableCopy];
    tMutableDictionary[NSForegroundColorAttributeName]=(inUserCode==YES) ? [CUIBinaryImageUtility colorForUserCode]: [CUIBinaryImageUtility colorForIdentifier:inIdentifier];
    
    return [[NSAttributedString alloc] initWithString:(inUserCode==NO) ? inIdentifier : [NSString stringWithFormat:@"+%@",inIdentifier]
                                           attributes:tMutableDictionary];
}

#pragma mark -

- (NSArray *)attributedLinesForHeaderOfIncident:(IPSIncident *)inIncident
{
    IPSIncidentHeader * tHeader=inIncident.header;
    
    NSMutableArray * tMutableArray=[NSMutableArray array];
    
    NSMutableAttributedString * tMutableAttributedString=[[self attributedStringForKey:@"Process:"] mutableCopy];
    
    NSDictionary * tJumpAnchorAttributes=@{
                                           CUISectionAnchorAttributeName:@"section:Header"
                                           };
    
    [tMutableAttributedString addAttributes:tJumpAnchorAttributes range:NSMakeRange(0,tMutableAttributedString.length)];
    
    [tMutableAttributedString appendAttributedString:[self attributedStringForPlainTextWithFormat:@"               %@ [%d]",tHeader.processName,tHeader.processID]];
    
    [tMutableArray addObject:tMutableAttributedString];
    
    
    tMutableAttributedString=[[self attributedStringForKey:@"Path:"] mutableCopy];
    [tMutableAttributedString appendAttributedString:[self attributedStringForPlainText:@"                  "]];
    [tMutableAttributedString appendAttributedString:[self attributedStringForPath:tHeader.processPath]];
    
    [tMutableArray addObject:tMutableAttributedString];
    
    
    IPSBundleInfo * tBundleInfo=tHeader.bundleInfo;
    
    tMutableAttributedString=[[self attributedStringForKey:@"Identifier:"] mutableCopy];
    [tMutableAttributedString appendAttributedString:[self attributedStringForPlainTextWithFormat:@"            %@",(tBundleInfo.bundleIdentifier!=nil) ? tBundleInfo.bundleIdentifier : tHeader.processName]];
    
    [tMutableArray addObject:tMutableAttributedString];
    
    
    tMutableAttributedString=[[self attributedStringForKey:@"Version:"] mutableCopy];
    [tMutableAttributedString appendAttributedString:[self attributedStringForPlainText:@"               "]];
    
    [tMutableAttributedString appendAttributedString:[self attributedStringForVersion:(tBundleInfo.bundleShortVersionString!=nil) ? tBundleInfo.bundleShortVersionString : @"???"]];
    
    if (tBundleInfo.bundleVersion!=nil)
        [tMutableAttributedString appendAttributedString:[self attributedStringForVersionWithFormat:@" (%@)",tBundleInfo.bundleVersion]];
    
    [tMutableArray addObject:tMutableAttributedString];
    
    
    tMutableAttributedString=[[self attributedStringForKey:@"Code Type:"] mutableCopy];
    [tMutableAttributedString appendAttributedString:[self attributedStringForPlainTextWithFormat:@"             %@ (%@)",tHeader.cpuType,(tHeader.translated==NO) ? @"Native" : @"Translated"]];
    
    [tMutableArray addObject:tMutableAttributedString];
    
    
    tMutableAttributedString=[[self attributedStringForKey:@"Parent Process:"] mutableCopy];
    [tMutableAttributedString appendAttributedString:[self attributedStringForPlainTextWithFormat:@"        %@ [%d]",tHeader.parentProcessName,tHeader.parentProcessID]];
    
    [tMutableArray addObject:tMutableAttributedString];
    
    if (tHeader.responsibleProcessName!=nil)
    {
        tMutableAttributedString=[[self attributedStringForKey:@"Responsible:"] mutableCopy];
        [tMutableAttributedString appendAttributedString:[self attributedStringForPlainTextWithFormat:@"           %@ [%d]",tHeader.responsibleProcessName,tHeader.responsibleProcessID]];
        
        [tMutableArray addObject:tMutableAttributedString];
    }
    
    tMutableAttributedString=[[self attributedStringForKey:@"User ID:"] mutableCopy];
    [tMutableAttributedString appendAttributedString:[self attributedStringForPlainTextWithFormat:@"               %d",tHeader.userID]];
    
    [tMutableArray addObject:tMutableAttributedString];
    
    [tMutableArray addObject:@""];
    
    tMutableAttributedString=[[self attributedStringForKey:@"Date/Time:"] mutableCopy];
    [tMutableAttributedString appendAttributedString:[self attributedStringForPlainTextWithFormat:@"             %@",[[IPSDateFormatter sharedFormatter] stringFromDate:tHeader.captureTime]]];
    
    [tMutableArray addObject:tMutableAttributedString];
    
    tMutableAttributedString=[[self attributedStringForKey:@"OS Version:"] mutableCopy];
    [tMutableAttributedString appendAttributedString:[self attributedStringForPlainText:@"            "]];
    [tMutableAttributedString appendAttributedString:[self attributedStringForVersionWithFormat:@"%@ (%@)",tHeader.operatingSystemVersion.train,tHeader.operatingSystemVersion.build]];
    
    [tMutableArray addObject:tMutableAttributedString];
    
    tMutableAttributedString=[[self attributedStringForKey:@"Report Version:"] mutableCopy];
    [tMutableAttributedString appendAttributedString:[self attributedStringForPlainText:@"        12"]];
    
    [tMutableArray addObject:tMutableAttributedString];
    
    tMutableAttributedString=[[self attributedStringForKey:@"Anonymous UUID:"] mutableCopy];
    [tMutableAttributedString appendAttributedString:[self attributedStringForPlainText:@"        "]];
    [tMutableAttributedString appendAttributedString:[self attributedStringForUUID:tHeader.crashReporterKey.UUIDString]];
    
    [tMutableArray addObject:tMutableAttributedString];
    
    [tMutableArray addObject:@""];
    
    if (tHeader.sleepWakeUUID!=nil)
    {
        tMutableAttributedString=[[self attributedStringForKey:@"Sleep/Wake UUID:"] mutableCopy];
        [tMutableAttributedString appendAttributedString:[self attributedStringForPlainText:@"       "]];
        [tMutableAttributedString appendAttributedString:[self attributedStringForUUID:tHeader.sleepWakeUUID.UUIDString]];
        
        [tMutableArray addObject:tMutableAttributedString];
    }
    
    tMutableAttributedString=[[self attributedStringForKey:@"Time Awake Since Boot:"] mutableCopy];
    [tMutableAttributedString appendAttributedString:[self attributedStringForPlainTextWithFormat:@" %lu seconds",(unsigned long)tHeader.uptime]];
    
    [tMutableArray addObject:tMutableAttributedString];
    
    [tMutableArray addObject:@""];
    
    tMutableAttributedString=[[self attributedStringForKey:@"System Integrity Protection:"] mutableCopy];
    [tMutableAttributedString appendAttributedString:[self attributedStringForPlainTextWithFormat:@" %@",(tHeader.systemIntegrityProtectionEnable==YES) ? @"enabled" : @"disabled"]];
    
    [tMutableArray addObject:tMutableAttributedString];
    
    [tMutableArray addObject:@""];
    
    return tMutableArray;
}

- (NSArray *)attributedLinesForExceptionInformationOfIncident:(IPSIncident *)inIncident
{
    IPSIncidentExceptionInformation * tExceptionInformation=inIncident.exceptionInformation;
    
    NSMutableArray * tMutableArray=[NSMutableArray array];
    
    NSMutableAttributedString * tMutableAttributedString=[[self attributedStringForKey:@"Crashed Thread:"] mutableCopy];
    
    NSDictionary * tJumpAnchorAttributes=@{
                                           CUISectionAnchorAttributeName:@"section:Exception Information"
                                           };
    
    [tMutableAttributedString addAttributes:tJumpAnchorAttributes range:NSMakeRange(0,tMutableAttributedString.length)];
    
    if ((self.displaySettings.visibleSections & CUIDocumentBacktracesSection)==CUIDocumentBacktracesSection &&
        inIncident.threads.count>0)
    {
        switch(self.hyperlinksStyle)
        {
            case CUIHyperlinksInternal:
                
                [tMutableAttributedString addAttributes:@{
                                                NSLinkAttributeName:[NSURL URLWithString:@"a://crashed_thread"]
                                                }
                                        range:NSMakeRange(0,tMutableAttributedString.length)];
                
                break;
                
            case CUIHyperlinksHTML:
                
                [tMutableAttributedString addAttributes:@{
                                                NSLinkAttributeName:[NSURL URLWithString:@"sharp://crashed_thread"]
                                                }
                                        range:NSMakeRange(0,tMutableAttributedString.length)];
                
                break;
                
            default:
                
                break;
        }
    }
    
    [tMutableAttributedString appendAttributedString:[self attributedStringForPlainText:@"        "]];
    [tMutableAttributedString appendAttributedString:[self attributedStringForCrashedThreadLabelWithFormat:@"%lu",(unsigned long)tExceptionInformation.faultingThread]];
    
    IPSLegacyInfo * tLegacyInfo=tExceptionInformation.legacyInfo;
    
    if (tLegacyInfo.threadTriggered.queue!=nil)
        [tMutableAttributedString appendAttributedString:[self attributedStringForCrashedThreadLabelWithFormat:@"  Dispatch queue: %@",tLegacyInfo.threadTriggered.queue]];
    
    [tMutableArray addObject:tMutableAttributedString];
    
    [tMutableArray addObject:@""];
    
    IPSException * tException=tExceptionInformation.exception;
    
    tMutableAttributedString=[[self attributedStringForKey:@"Exception Type:"] mutableCopy];
    [tMutableAttributedString appendAttributedString:[self attributedStringForPlainText:@"        "]];
    
    NSMutableAttributedString * tValueAttributedString=[[self attributedStringForPlainTextWithFormat:@"%@ (%@)",tException.type,tException.signal] mutableCopy];
    
    switch(self.hyperlinksStyle)
    {
        case CUIHyperlinksInternal:
            
            [tValueAttributedString addAttributes:@{
                                                    NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle|NSUnderlineStylePatternDash)
                                                    }
             
                                            range:NSMakeRange(0, tValueAttributedString.length)];
            
            [tValueAttributedString addAttributes:@{
                                                    NSLinkAttributeName:[NSURL URLWithString:@"a://exception_type"]
                                                    }
                                            range:NSMakeRange(0, tValueAttributedString.length)];
            
            break;
            
        default:
            
            break;
    }
    
    [tMutableAttributedString appendAttributedString:tValueAttributedString];
    
    [tMutableArray addObject:tMutableAttributedString];
    
    tMutableAttributedString=[[self attributedStringForKey:@"Exception Codes:"] mutableCopy];
    [tMutableAttributedString appendAttributedString:[self attributedStringForPlainTextWithFormat:@"       %@",(tException.subtype!=nil) ? tException.subtype : tException.codes]];
    
    [tMutableArray addObject:tMutableAttributedString];
    
    if (tExceptionInformation.isCorpse==YES)
    {
        tMutableAttributedString=[[self attributedStringForKey:@"Exception Note:"] mutableCopy];
        [tMutableAttributedString appendAttributedString:[self attributedStringForPlainText:@"        EXC_CORPSE_NOTIFY"]];
        
        [tMutableArray addObject:tMutableAttributedString];
    }
    
    [tMutableArray addObject:@""];
    
    IPSTermination * tTermination=tExceptionInformation.termination;
    
    if (tTermination!=nil)
    {
        tMutableAttributedString=[[self attributedStringForKey:@"Termination Reason:"] mutableCopy];
        [tMutableAttributedString appendAttributedString:[self attributedStringForPlainTextWithFormat:@"    Namespace %@, Code 0x%lx",tTermination.namespace,(unsigned long)tTermination.code]];
        
        [tMutableArray addObject:tMutableAttributedString];
    
        if (tTermination.byProc!=nil)
        {
            tMutableAttributedString=[[self attributedStringForKey:@"Terminating Process:"] mutableCopy];
            [tMutableAttributedString appendAttributedString:[self attributedStringForPlainTextWithFormat:@"   %@ [%d]",tTermination.byProc,tTermination.byPid]];
        
            [tMutableArray addObject:tMutableAttributedString];
        }
        
        [tMutableArray addObject:@""];
    }
    
    return tMutableArray;
}

- (NSArray *)attributedLinesForDiagnosticMessageOfIncident:(IPSIncident *)inIncident
{
    IPSIncidentDiagnosticMessage * tDiagnosticMessage=inIncident.diagnosticMessage;
    
    NSMutableArray * tMutableArray=[NSMutableArray array];
    
    if (tDiagnosticMessage!=nil)
    {
        if (tDiagnosticMessage.vmregioninfo!=nil)
        {
            NSMutableAttributedString * tMutableAttributedString=[[self attributedStringForKey:@"VM Region Info:"] mutableCopy];
            [tMutableAttributedString appendAttributedString:[self attributedStringForPlainTextWithFormat:@" %@",tDiagnosticMessage.vmregioninfo]];
            
            [tMutableArray addObject:tMutableAttributedString];
            
            [tMutableArray addObject:@""];
        }
        
        if (tDiagnosticMessage.asi!=nil)
        {
            NSMutableAttributedString * tMutableAttributedString=[[self attributedStringForKey:@"Application Specific Information:"] mutableCopy];
            
            [tMutableArray addObject:tMutableAttributedString];
            

            [tDiagnosticMessage.asi.applicationsInformation enumerateKeysAndObjectsUsingBlock:^(NSString * bProcess, NSArray * bInformation, BOOL * bOutStop) {
                
                [bInformation enumerateObjectsUsingBlock:^(NSString * bInformation, NSUInteger bIndex, BOOL * bOutStop2) {
                    
                    [tMutableArray addObject:[self attributedStringForPlainText:bInformation]];
                }];
                
            }];
            
            [tMutableArray addObject:@""];
        }
        
        NSMutableAttributedString * tMutableAttributedString=tMutableArray.firstObject;
        
        if ([tMutableAttributedString isKindOfClass:[NSMutableAttributedString class]]==YES)
        {
            NSDictionary * tJumpAnchorAttributes=@{
                                                   CUISectionAnchorAttributeName:@"section:Diagnostic Messages"
                                                   };
            
            [tMutableAttributedString addAttributes:tJumpAnchorAttributes range:NSMakeRange(0,tMutableAttributedString.length)];
        }
    }
    
    return tMutableArray;
}

- (NSArray *)attributedLinesForBacktracesOfIncident:(IPSIncident *)inIncident
{
    #define BINARYIMAGENAME_AND_SPACE_MAXLEN    34
    
    NSMutableArray * tMutableArray=[NSMutableArray array];
#ifndef __DISABLE_SYMBOLICATION_
    NSArray * tBacktracesThreads=self.crashlog.backtraces.threads;
#endif
    
    NSString * tProcessPath=inIncident.header.processPath;
    
    NSArray * tSortedBinaryImages=[inIncident.binaryImages sortedArrayUsingSelector:@selector(compare:)];
    
    [inIncident.threads enumerateObjectsUsingBlock:^(IPSThread * bThread, NSUInteger bThreadIndex, BOOL * bOutStop) {

#ifndef __DISABLE_SYMBOLICATION_
        CUIThread * tBacktraceThread=tBacktracesThreads[bThreadIndex];
#endif
        NSString * tDispatchQueueString=(bThread.queue!=nil) ? [NSString stringWithFormat:@": Dispatch queue: %@",bThread.queue] : @"";
        
        NSMutableAttributedString * tMutableAttributedString=nil;
        
        if (bThread.triggered==YES)
        {
            tMutableAttributedString=[[self attributedStringForCrashedThreadLabelWithFormat:@"Thread %lu Crashed:%@\n",(unsigned long)bThreadIndex,tDispatchQueueString] mutableCopy];
            
            switch(self.hyperlinksStyle)
            {
                case CUIHyperlinksInternal:
                    
                    [tMutableAttributedString addAttributes:@{
                                                              CUIGenericAnchorAttributeName:@"a:crashed_thread"
                                                              }
                                                      range:NSMakeRange(0, tMutableAttributedString.length)];
                    
                    break;
                    
                case CUIHyperlinksHTML:
                {
                    NSURL * tURL=[NSURL URLWithString:@"anchor://crashed_thread"];
                    
                    if (tURL!=nil)
                        [tMutableAttributedString addAttributes:@{NSLinkAttributeName:tURL}
                                                          range:NSMakeRange(0, tMutableAttributedString.length)];
                    
                    break;
                }
                default:
                    
                    break;
            }
        }
        else
        {
            if ((self.displaySettings.visibleSections & CUIDocumentBacktraceCrashedThreadSubSection)!=0)
                return;
            
            tMutableAttributedString=[[self attributedStringForThreadLabelWithFormat:@"Thread %lu:%@\n",(unsigned long)bThreadIndex,tDispatchQueueString] mutableCopy];
        }
        
        [tMutableAttributedString addAttributes:@{
                                                  CUIThreadAnchorAttributeName:[NSString stringWithFormat:@"thread:%lu",(unsigned long)bThreadIndex]
                                                  }
                                          range:NSMakeRange(0, tMutableAttributedString.length)];
        
        [tMutableArray addObject:tMutableAttributedString];
    
#ifndef __DISABLE_SYMBOLICATION_
        NSArray<CUIStackFrame *> * tStackFrames=tBacktraceThread.callStackBacktrace.stackFrames;
#endif
        
        [bThread.frames enumerateObjectsUsingBlock:^(IPSThreadFrame * bFrame, NSUInteger bFrameIndex, BOOL * _Nonnull stop) {
            
            IPSImage * tBinaryImage=inIncident.binaryImages[bFrame.imageIndex];
            
            BOOL tIsUserCode=tBinaryImage.isUserCode;
            
            if (tIsUserCode==NO)
            {
                if ([tSortedBinaryImages indexOfObjectIdenticalTo:tBinaryImage]==0)
                {
                    tIsUserCode=YES;
                }
                else
                {
                    NSString * tPath=tBinaryImage.path;
            
                    tIsUserCode=(tPath!=nil && [tProcessPath isEqualToString:tPath]==YES);
                }
            }
            
            NSString * tFrameIndexString=[NSString stringWithFormat:@"%lu",(unsigned long)bFrameIndex];
            
            NSString * tIndexSpace=[@"    " substringFromIndex:tFrameIndexString.length];
            
            NSMutableAttributedString * tMutableAttributedString=[[self attributedStringForUser:tIsUserCode code:tFrameIndexString] mutableCopy];
            [tMutableAttributedString appendAttributedString:[self attributedStringForUser:tIsUserCode code:tIndexSpace]];
            
            if ((self.displaySettings.visibleStackFrameComponents & CUIStackFrameBinaryNameComponent)==CUIStackFrameBinaryNameComponent)
            {
                NSString * tBinaryImageIdentifier=(tBinaryImage.bundleIdentifier!=nil) ? tBinaryImage.bundleIdentifier : tBinaryImage.name;
                
                if (tBinaryImageIdentifier==nil)
                    tBinaryImageIdentifier=@"???";
                
                NSUInteger tImageNameLength=tBinaryImageIdentifier.length;
                
                NSMutableAttributedString * tMutableBinaryImageAttributedString=[[self attributedStringForUser:tIsUserCode code:tBinaryImageIdentifier] mutableCopy];
                
                if (self.hyperlinksStyle!=CUIHyperlinksNone && ((self.displaySettings.visibleSections & CUIDocumentBinaryImagesSection)==CUIDocumentBinaryImagesSection))
                {
                    NSURL * tURL=nil;
                    
                    switch(self.hyperlinksStyle)
                    {
                        case CUIHyperlinksInternal:
                            
                            tURL=[NSURL URLWithString:[NSString stringWithFormat:@"bin://%@",tBinaryImage.UUID.UUIDString]];
                            
                            break;
                            
                        case CUIHyperlinksHTML:
                            
                            tURL=[NSURL URLWithString:[NSString stringWithFormat:@"sharp://%@",tBinaryImage.UUID.UUIDString]];
                            
                            break;
                            
                        default:
                            
                            break;
                    }
                    
                    if (tURL!=nil)
                        [tMutableBinaryImageAttributedString addAttributes:@{NSLinkAttributeName:tURL} range:NSMakeRange(0,tMutableBinaryImageAttributedString.length)];
                }
                
                [tMutableAttributedString appendAttributedString:tMutableBinaryImageAttributedString];
                
                if ((tImageNameLength+4)>BINARYIMAGENAME_AND_SPACE_MAXLEN)
                {
                    [tMutableAttributedString appendAttributedString:[self attributedStringForUser:tIsUserCode code:@"    "]];
                }
                else
                {
                    NSString * tImageSpace=[@"                                  " substringFromIndex:tImageNameLength];
                    
                    [tMutableAttributedString appendAttributedString:[self attributedStringForUser:tIsUserCode code:tImageSpace]];
                }
            }
            
            NSUInteger tAddress=tBinaryImage.loadAddress+bFrame.imageOffset;
            
            if ((self.displaySettings.visibleStackFrameComponents & CUIStackFrameMachineInstructionAddressComponent)==CUIStackFrameMachineInstructionAddressComponent)
            {
                [tMutableAttributedString appendAttributedString:[self attributedStringForMemoryAddressWithFormat:@"0x%016lx ",(unsigned long)tAddress]];
            }
            
#ifndef __DISABLE_SYMBOLICATION_
            
            BOOL tSymbolicateAutomatically=[CUIApplicationPreferences sharedPreferences].symbolicateAutomatically;
            CUIStackFrame * tStackFrame=tStackFrames[bFrameIndex];
            CUISymbolicationData * tSymbolicationData=nil;
            
            if (tSymbolicateAutomatically==YES)
            {
                tSymbolicationData=tStackFrame.symbolicationData;
            }
            
            if (tSymbolicationData!=nil)
            {
                if (tSymbolicationData.stackFrameSymbol==nil)
                    NSLog(@"Missing stackFrameSymbol");

                [tMutableAttributedString appendAttributedString:[self attributedStringForUser:tIsUserCode code:[self->_symbolicationDataFormatter stringForObjectValue:tSymbolicationData]]];
            }
            else
            {
                if (tSymbolicateAutomatically==YES)
                {
                    // Default values
                    
                    NSUInteger tImageOffset=bFrame.imageOffset;
                    
                    [[CUISymbolicationManager sharedSymbolicationManager] lookUpSymbolicationDataForMachineInstructionAddress:tImageOffset
                                                                                                                   binaryUUID:tBinaryImage.UUID.UUIDString
                                                                                                            completionHandler:^(CUISymbolicationDataLookUpResult bLookUpResult, CUISymbolicationData *bSymbolicationData) {
                                                                                                                
                                                                                                                switch(bLookUpResult)
                                                                                                                {
                                                                                                                    case CUISymbolicationDataLookUpResultError:
                                                                                                                    case CUISymbolicationDataLookUpResultNotFound:
                                                                                                                        
                                                                                                                        if (bFrame.symbol!=nil)
                                                                                                                        {
                                                                                                                            [tMutableAttributedString appendAttributedString:[self attributedStringForUser:tIsUserCode code:bFrame.symbol]];
                                                                                                                            
                                                                                                                            if ((self.displaySettings.visibleStackFrameComponents & CUIStackFrameByteOffsetComponent)==CUIStackFrameByteOffsetComponent)
                                                                                                                                [tMutableAttributedString appendAttributedString:[self attributedStringForUser:tIsUserCode codeWithFormat:@" + %lu",(unsigned long)bFrame.symbolLocation]];
                                                                                                                        }
                                                                                                                        else
                                                                                                                        {
                                                                                                                            [tMutableAttributedString appendAttributedString:[self attributedStringForUser:tIsUserCode codeWithFormat:@"0x%lx",(unsigned long)tBinaryImage.loadAddress]];
                                                                                                                            
                                                                                                                            if ((self.displaySettings.visibleStackFrameComponents & CUIStackFrameByteOffsetComponent)==CUIStackFrameByteOffsetComponent)
                                                                                                                                [tMutableAttributedString appendAttributedString:[self attributedStringForUser:tIsUserCode codeWithFormat:@" + %lu",(unsigned long)(tAddress-tBinaryImage.loadAddress)]];
                                                                                                                        }
                                                                                                                        
                                                                                                                        if (bFrame.sourceFile!=nil)
                                                                                                                            [tMutableAttributedString appendAttributedString:[self attributedStringForUser:tIsUserCode codeWithFormat:@" (%@:%lu)",bFrame.sourceFile,(unsigned long)bFrame.sourceLine]];
                                                                                                                        
                                                                                                                        break;
                                                                                                                        
                                                                                                                    case CUISymbolicationDataLookUpResultFound:
                                                                                                                    {
                                                                                                                        tStackFrame.symbolicationData=bSymbolicationData;
                                                                                                                        
                                                                                                                        [[NSNotificationCenter defaultCenter] postNotificationName:CUIStackFrameSymbolicationDidSucceedNotification
                                                                                                                                                                            object:self.input];
                                                                                                                        
                                                                                                                        break;
                                                                                                                    }
                                                                                                                        
                                                                                                                    case CUISymbolicationDataLookUpResultFoundInCache:
                                                                                                                    {
                                                                                                                        tStackFrame.symbolicationData=bSymbolicationData;
                                                                                                                        
                                                                                                                        [tMutableAttributedString appendAttributedString:[self attributedStringForUser:tIsUserCode code:[self->_symbolicationDataFormatter stringForObjectValue:bSymbolicationData]]];
                                                                                                                        
                                                                                                                        break;
                                                                                                                    }
                                                                                                                        
                                                                                                                }
                                                                                                                
                                                                                                            }];
                }
            }
            
#endif
            
            [tMutableArray addObject:tMutableAttributedString];
            
        }];
        
        [tMutableArray addObject:@""];
    }];
    
    NSMutableAttributedString * tMutableAttributedString=tMutableArray.firstObject;
    
    if ([tMutableAttributedString isKindOfClass:[NSMutableAttributedString class]]==YES)
    {
        NSDictionary * tJumpAnchorAttributes=@{
                                               CUISectionAnchorAttributeName:@"section:Backtraces"
                                               };
        
        [tMutableAttributedString addAttributes:tJumpAnchorAttributes range:NSMakeRange(0,tMutableAttributedString.length)];
    }
    
    return tMutableArray;
}

- (NSArray *)attributedLinesForThreadStateOfIncident:(IPSIncident *)inIncident
{
    IPSIncidentHeader * tHeader=inIncident.header;
    IPSThreadState * tCrashedThreadState=nil;
    IPSIncidentExceptionInformation * tExceptionInformation=inIncident.exceptionInformation;
    
    NSMutableArray * tMutableArray=[NSMutableArray array];
    
    IPSThreadInstructionState * tCrashThreadInstructionState=nil;
    
    if (tExceptionInformation.faultingThread<inIncident.threads.count)
    {
        IPSThread * tThread=inIncident.threads[tExceptionInformation.faultingThread];
        
        tCrashedThreadState=tThread.threadState;
        
        tCrashThreadInstructionState=tThread.instructionState;
    }
    
    if (tCrashedThreadState!=nil)
    {
        NSDictionary * tCPUFamiliesRegistry=@{
                                              @"X86-64":@"X86",
                                              @"ARM-64":@"ARM"
                                              };
        
        NSString * tCPUFamily=tCPUFamiliesRegistry[tHeader.cpuType];
        
        if (tCPUFamily==nil)
            tCPUFamily=@"-";
        
        NSDictionary * tCPUSizeRegistry=@{
                                          @"X86-64":@"64-bit",
                                          @"ARM-64":@"64-bit"
                                          };
        
        NSString * tCPUSize=tCPUSizeRegistry[tHeader.cpuType];
        
        if (tCPUSize==nil)
            tCPUSize=@"-";
        
        __block NSMutableAttributedString * tMutableAttributedString=[[self attributedStringForKeyWithFormat:@"Thread %lu crashed with %@ Thread State (%@):",tExceptionInformation.faultingThread,tCPUFamily,tCPUSize] mutableCopy];
        
        [tMutableArray addObject:tMutableAttributedString];
        
        
        NSArray * tRegistersOrder=@[];
        
        if ([tCrashedThreadState.flavor isEqualToString:@"x86_THREAD_STATE"]==YES)
        {
            tRegistersOrder=@[@"rax",@"rbx",@"rcx",@"rdx",@"\n",
                              @"rdi",@"rsi",@"rbp",@"rsp",@"\n",
                              @"r8",@"r9",@"r10",@"r11",@"\n",
                              @"r12",@"r13",@"r14",@"r15",@"\n",
                              @"rip",@"rflags",@"cr2",@"\n"
                              ];
        }
        else
        {
            tRegistersOrder=@[@"x0",@"x1",@"x2",@"x3",@"\n",
                              @"x4",@"x5",@"x6",@"x7",@"\n",
                              @"x8",@"x9",@"x10",@"x11",@"\n",
                              @"x12",@"x13",@"x14",@"x15",@"\n",
                              @"x16",@"x17",@"x18",@"x19",@"\n",
                              @"x20",@"x21",@"x22",@"x23",@"\n",
                              @"x24",@"x25",@"x26",@"x27",@"\n",
                              @"x28",@"fp",@"lr",@"\n",
                              @"sp",@"pc",@"cpsr",@"\n",
                              @"far",@"esr",@"\n"
                              ];
        }
        
        tMutableAttributedString=[[NSMutableAttributedString alloc] initWithString:@""];
        
        [tRegistersOrder enumerateObjectsUsingBlock:^(NSString * bRegisterName, NSUInteger bIndex, BOOL * bOutStop) {
            
            if ([bRegisterName isEqualToString:@"\n"]==YES)
            {
                [tMutableArray addObject:tMutableAttributedString];
                
                tMutableAttributedString=[[NSMutableAttributedString alloc] initWithString:@""];
            }
            
            IPSRegisterState * tRegisterState=tCrashedThreadState.registersStates[bRegisterName];
            
            if (tRegisterState!=nil)
            {
                NSMutableString * tMutableString=[NSMutableString string];
                
                NSString * tTranslatedName=[IPSThreadState displayNameForRegisterName:bRegisterName];
                
                if (tTranslatedName.length<5)
                    for(NSUInteger tWhitespace=0;tWhitespace<(5-tTranslatedName.length);tWhitespace++)
                        [tMutableString appendString:@" "];
                
                [tMutableAttributedString appendAttributedString:[self attributedStringForPlainText:tMutableString]];
                
                IPSRegisterState * tRegisterState=tCrashedThreadState.registersStates[bRegisterName];
                
                if (tRegisterState!=nil)
                {
                    [tMutableAttributedString appendAttributedString:[self attributedStringForKey:tTranslatedName]];
                    [tMutableAttributedString appendAttributedString:[self attributedStringForPlainText:@": "]];
                    [tMutableAttributedString appendAttributedString:[self attributedStringForRegisterValueWithFormat:@"0x%016lx",tRegisterState.value]];
                }
            }
        }];
        
        [tMutableArray addObject:@""];
    }
    
    if (tCrashThreadInstructionState!=nil)
    {
        IPSThreadInstructionStream * tStream=tCrashThreadInstructionState.instructionStream;
        
        if (tStream!=nil)
        {
            NSAttributedString * tAttributedString=[self attributedStringForKeyWithFormat:@"Thread %lu instruction stream:",tExceptionInformation.faultingThread];
            
            [tMutableArray addObject:tAttributedString];
            
            uint8_t * tBytes=tStream.bytes;
            NSUInteger tBytesCount=tStream.bytesCount;
            
            NSUInteger tOffset=tStream.offset;
            
            for(NSUInteger tByteIndex=0;tByteIndex<tBytesCount;tByteIndex+=16)
            {
                NSMutableString * tMutableString=[NSMutableString string];
                
                unsigned char tASCIIRepresentation[17];
                memset(tASCIIRepresentation, '.',16);
                tASCIIRepresentation[16]='\0';
                
                // Display line by line
                
                if (tByteIndex==tOffset)
                {
                    [tMutableString appendFormat:@" [%02x]",tBytes[tByteIndex]];
                }
                else
                {
                    [tMutableString appendFormat:@"  %02x ",tBytes[tByteIndex]];
                }
                
                [tMutableString appendFormat:@"%02x %02x %02x %02x %02x %02x %02x",tBytes[tByteIndex+1],tBytes[tByteIndex+2],tBytes[tByteIndex+3],tBytes[tByteIndex+4],tBytes[tByteIndex+5],tBytes[tByteIndex+6],tBytes[tByteIndex+7]];
                
                if ((tByteIndex+8)<tBytesCount)
                {
                    [tMutableString appendFormat:@"-%02x %02x %02x %02x %02x %02x %02x %02x",tBytes[tByteIndex+8],tBytes[tByteIndex+9],tBytes[tByteIndex+10],tBytes[tByteIndex+11],tBytes[tByteIndex+12],tBytes[tByteIndex+13],tBytes[tByteIndex+14],tBytes[tByteIndex+15]];
                }
                
                
                
                for(NSUInteger tASCIIIndex=0;(tByteIndex+tASCIIIndex)<tBytesCount && tASCIIIndex<16;tASCIIIndex++)
                {
                    uint8_t tByteValue=tBytes[tByteIndex+tASCIIIndex];
                    
                    if (tByteValue>=32 && tByteValue<127)
                        tASCIIRepresentation[tASCIIIndex]=tByteValue;
                }
                
                [tMutableString appendFormat:@"  %s",tASCIIRepresentation];
                
                if (tByteIndex==tOffset)
                    [tMutableString appendString:@"    <=="];
                
                tAttributedString=[self attributedStringForPlainText:tMutableString];
                
                [tMutableArray addObject:tAttributedString];
            }
            
            [tMutableArray addObject:@""];
        }
    }
    
    NSMutableAttributedString * tMutableAttributedString=tMutableArray.firstObject;
    
    if ([tMutableAttributedString isKindOfClass:[NSMutableAttributedString class]]==YES)
    {
        NSDictionary * tJumpAnchorAttributes=@{
                                               CUISectionAnchorAttributeName:@"section:Thread State"
                                               };
        
        [tMutableAttributedString addAttributes:tJumpAnchorAttributes range:NSMakeRange(0,tMutableAttributedString.length)];
    }
    
    return tMutableArray;
}

- (NSArray *)attributedLinesForBinaryImagesOfIncident:(IPSIncident *)inIncident
{
    NSMutableArray * tMutableArray=[NSMutableArray array];
    
    __block NSMutableAttributedString * tMutableAttributedString=[[self attributedStringForKey:@"Binary Images:"] mutableCopy];
    
    [tMutableArray addObject:tMutableAttributedString];
    
    BOOL tIsMonochromeTheme=[CUIThemesManager sharedManager].currentTheme.isMonochrome;
    
    [[inIncident.binaryImages sortedArrayUsingSelector:@selector(compare:)] enumerateObjectsUsingBlock:^(IPSImage * bImage, NSUInteger bIndex, BOOL * bOutStop) {
    
        NSString * tSpaceString=@"                  ";
        
        NSString * tAddressString=[NSString stringWithFormat:@"0x%lx",bImage.loadAddress];
        
        NSUInteger tLength=tAddressString.length;
        
        tMutableAttributedString=[[self attributedStringForPlainText:[tSpaceString substringFromIndex:tLength]] mutableCopy];
        
        [tMutableAttributedString appendAttributedString:[self attributedStringForMemoryAddress:tAddressString]];
        
        [tMutableAttributedString appendAttributedString:[[self attributedStringForPlainText:@" - "] mutableCopy]];
        
        tAddressString=[NSString stringWithFormat:@"0x%lx",bImage.loadAddress+bImage.size];
        
        tLength=tAddressString.length;
        
        [tMutableAttributedString appendAttributedString:[self attributedStringForPlainText:[tSpaceString substringFromIndex:tLength]]];
        
        [tMutableAttributedString appendAttributedString:[self attributedStringForMemoryAddress:tAddressString]];
        
        [tMutableAttributedString appendAttributedString:[self attributedStringForPlainText:@" "]];
        
        NSString * tBinaryImageIdentifier=(bImage.bundleIdentifier!=nil) ? bImage.bundleIdentifier : bImage.name;
        
        if (tBinaryImageIdentifier==nil)
            tBinaryImageIdentifier=@"???";
        
        if (tIsMonochromeTheme==YES)
        {
            if (bImage.isUserCode==YES)
                [tMutableAttributedString appendAttributedString:[self attributedStringForPlainText:@"+"]];
            
            [tMutableAttributedString appendAttributedString:[self attributedStringForPlainText:tBinaryImageIdentifier]];
        }
        else
        {
            [tMutableAttributedString appendAttributedString:[self attributedStringForUser:bImage.isUserCode binaryImageIdentifier:tBinaryImageIdentifier]];
        }
        
        [tMutableAttributedString appendAttributedString:[self attributedStringForPlainText:@" "]];
        
        if (bImage.bundleShortVersionString!=nil || bImage.bundleVersion!=nil)
        {
            if (bImage.bundleVersion==nil)
                [tMutableAttributedString appendAttributedString:[self attributedStringForVersionWithFormat:@"(%@)",bImage.bundleShortVersionString]];
            else
                [tMutableAttributedString appendAttributedString:[self attributedStringForVersionWithFormat:@"(%@ - %@)",(bImage.bundleShortVersionString!=nil) ? bImage.bundleShortVersionString : @"???",bImage.bundleVersion]];
        }
        else
        {
            [tMutableAttributedString appendAttributedString:[self attributedStringForVersion:@"(???)"]];
                
        }
             
        [tMutableAttributedString appendAttributedString:[self attributedStringForPlainText:@" "]];
     
        NSString * tUUIDString=bImage.UUID.UUIDString;
        
        [tMutableAttributedString appendAttributedString:[self attributedStringForUUIDWithFormat:@"<%@>",tUUIDString]];
        
        [tMutableAttributedString appendAttributedString:[self attributedStringForPlainText:@" "]];

        [tMutableAttributedString appendAttributedString:[self attributedStringForPath:(bImage.path!=nil) ? bImage.path : @"???"]];
        
        switch(self.hyperlinksStyle)
        {
            case CUIHyperlinksHTML:
            {
                NSURL * tURL=[NSURL URLWithString:[NSString stringWithFormat:@"anchor://%@",tUUIDString]];
                
                if (tURL!=nil)
                    [tMutableAttributedString addAttributes:@{NSLinkAttributeName:tURL}
                                                      range:NSMakeRange(0, tMutableAttributedString.length)];
                
                break;
            }
                
            default:
                
                [tMutableAttributedString addAttributes:@{CUIBinaryAnchorAttributeName:[NSString stringWithFormat:@"bin:%@",tUUIDString]}
                                                  range:NSMakeRange(0, tMutableAttributedString.length)];
                
                break;
        }
        
        
        [tMutableArray addObject:tMutableAttributedString];
        
    }];
    
    [tMutableArray addObject:@""];
    
    // External Modification Summary
    
    if (inIncident.extMods!=nil)
    {
        __auto_type (^processStatistics)(IPSExternalModificationStatistics *) = ^(IPSExternalModificationStatistics * inObject) {
        
            tMutableAttributedString=[[self attributedStringForPlainText:@"    "] mutableCopy];
            [tMutableAttributedString appendAttributedString:[self attributedStringForKey:@"task_for_pid:"]];
            [tMutableAttributedString appendAttributedString:[self attributedStringForPlainText:@" "]];
            [tMutableAttributedString appendAttributedString:[self attributedStringForPlainTextWithFormat:@"%ld",(long)inObject.taskForPid]];
            
            [tMutableArray addObject:tMutableAttributedString];
        
            tMutableAttributedString=[[self attributedStringForPlainText:@"    "] mutableCopy];
            [tMutableAttributedString appendAttributedString:[self attributedStringForKey:@"thread_create:"]];
            [tMutableAttributedString appendAttributedString:[self attributedStringForPlainText:@" "]];
            [tMutableAttributedString appendAttributedString:[self attributedStringForPlainTextWithFormat:@"%ld",(long)inObject.threadCreate]];
            
            [tMutableArray addObject:tMutableAttributedString];
            
            tMutableAttributedString=[[self attributedStringForPlainText:@"    "] mutableCopy];
            [tMutableAttributedString appendAttributedString:[self attributedStringForKey:@"thread_set_state:"]];
            [tMutableAttributedString appendAttributedString:[self attributedStringForPlainText:@" "]];
            [tMutableAttributedString appendAttributedString:[self attributedStringForPlainTextWithFormat:@"%ld",(long)inObject.threadSetState]];
            [tMutableAttributedString appendAttributedString:[self attributedStringForPlainText:@" "]];
            
            [tMutableArray addObject:tMutableAttributedString];
        };
        
        tMutableAttributedString=[[self attributedStringForKey:@"External Modification Summary:"] mutableCopy];
        
        [tMutableArray addObject:tMutableAttributedString];
        
        tMutableAttributedString=[[self attributedStringForKey:@" Calls made by other processes targeting this process:"] mutableCopy];
        
        [tMutableArray addObject:tMutableAttributedString];
        
        processStatistics(inIncident.extMods.targeted);
        
        tMutableAttributedString=[[self attributedStringForKey:@" Calls made by this process:"] mutableCopy];
        
        [tMutableArray addObject:tMutableAttributedString];
        
        processStatistics(inIncident.extMods.caller);
        
        tMutableAttributedString=[[self attributedStringForKey:@" Calls made by all processes on this machine:"] mutableCopy];
        
        [tMutableArray addObject:tMutableAttributedString];
        
        processStatistics(inIncident.extMods.system);
        
        [tMutableArray addObject:@""];
    }
    
    // VM Summary
    
    if (inIncident.vmSummary!=nil)
    {
        tMutableAttributedString=[[self attributedStringForKey:@"VM Region Summary:"] mutableCopy];
        
        [tMutableArray addObject:tMutableAttributedString];
        
        tMutableAttributedString=[[self attributedStringForPlainText:inIncident.vmSummary] mutableCopy];
        
        [tMutableArray addObject:tMutableAttributedString];
    }
    
    tMutableAttributedString=tMutableArray.firstObject;
    
    if ([tMutableAttributedString isKindOfClass:[NSMutableAttributedString class]]==YES)
    {
        NSDictionary * tJumpAnchorAttributes=@{
                                               CUISectionAnchorAttributeName:@"section:Binary Images"
                                               };
        
        [tMutableAttributedString addAttributes:tJumpAnchorAttributes range:NSMakeRange(0,tMutableAttributedString.length)];
    }
    
    return tMutableArray;
}

#pragma mark -

- (BOOL)transform
{
    if ([super transform]==NO)
        return NO;
    
    IPSReport * tReport=(IPSReport *)self.input;
    
    if ([tReport isKindOfClass:[IPSReport class]]==NO)
    {
        // A COMPLETER
        
        return NO;
    }
    
    IPSIncident * tIncident=tReport.incident;
    
    
    [self updatesCachedAttributes];
    
    NSMutableArray * tMutableArray=[NSMutableArray array];
    
    // Header
    
    if ((self.displaySettings.visibleSections & CUIDocumentHeaderSection)==CUIDocumentHeaderSection)
    {
        NSArray * tAttributedLines=[self attributedLinesForHeaderOfIncident:tIncident];
        
        if (tAttributedLines==nil)
            return NO;
        
        [tMutableArray addObjectsFromArray:tAttributedLines];
    }
    
    // Exception Information
    
    if ((self.displaySettings.visibleSections & CUIDocumentExceptionInformationSection)==CUIDocumentExceptionInformationSection)
    {
        NSArray * tAttributedLines=[self attributedLinesForExceptionInformationOfIncident:tIncident];
        
        if (tAttributedLines==nil)
            return NO;
        
        [tMutableArray addObjectsFromArray:tAttributedLines];
    }
    
    // Diagnostic Message
    
    if ((self.displaySettings.visibleSections & CUIDocumentDiagnosticMessagesSection)==CUIDocumentDiagnosticMessagesSection)
    {
        NSArray * tAttributedLines=[self attributedLinesForDiagnosticMessageOfIncident:tIncident];
        
        if (tAttributedLines==nil)
            return NO;
        
        [tMutableArray addObjectsFromArray:tAttributedLines];
    }
    
    // Backtraces
    
    if ((self.displaySettings.visibleSections & CUIDocumentBacktracesSection)==CUIDocumentBacktracesSection)
    {
        NSArray * tAttributedLines=[self attributedLinesForBacktracesOfIncident:tIncident];
        
        if (tAttributedLines==nil)
            return NO;
        
        [tMutableArray addObjectsFromArray:tAttributedLines];
    }
    
    // Thread State
    
    if ((self.displaySettings.visibleSections & CUIDocumentThreadStateSection)==CUIDocumentThreadStateSection)
    {
        NSArray * tAttributedLines=[self attributedLinesForThreadStateOfIncident:tIncident];
        
        if (tAttributedLines==nil)
            return NO;
        
        [tMutableArray addObjectsFromArray:tAttributedLines];
    }
    
    // Binary Images
    
    if ((self.displaySettings.visibleSections & CUIDocumentBinaryImagesSection)==CUIDocumentBinaryImagesSection)
    {
        NSArray * tAttributedLines=[self attributedLinesForBinaryImagesOfIncident:tIncident];
        
        if (tAttributedLines==nil)
            return NO;
        
        [tMutableArray addObjectsFromArray:tAttributedLines];
    }
    
    self.output=[self joinLines:tMutableArray withString:@"\n"];
    
    return YES;
}

#pragma mark -

- (NSAttributedString *)joinLines:(NSArray *)inLines withString:(NSString *)inNewLineFeed
{
    NSMutableAttributedString * tMutableAttributedString=[NSMutableAttributedString new];
    
    [inLines enumerateObjectsUsingBlock:^(id bLine, NSUInteger bLineNumber, BOOL * bOutStop) {
        
        if ([bLine isKindOfClass:[NSString class]]==YES)
        {
            NSAttributedString * tAttributedString=[[NSAttributedString alloc] initWithString:bLine
                                                                                   attributes:self->_cachedPlainTextAttributes];
            
            [tMutableAttributedString appendAttributedString:tAttributedString];
            
            if (bLineNumber<inLines.count)
                [tMutableAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:inNewLineFeed attributes:self->_cachedPlainTextAttributes]];
            
            return;
        }
        
        if ([bLine isKindOfClass:[NSAttributedString class]]==YES)
        {
            [tMutableAttributedString appendAttributedString:bLine];
            
            if (bLineNumber<inLines.count)
                [tMutableAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:inNewLineFeed attributes:self->_cachedPlainTextAttributes]];
        }
    }];
    
    return tMutableAttributedString;
}

@end
