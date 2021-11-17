/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashDataTransform.h"

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

@interface CUICrashLog (Private)

    // Sections ranges

    @property (readonly) NSRange headerRange;

    @property (readonly) NSRange exceptionInformationRange;
    @property (readonly) NSRange diagnosticMessagesRange;

    @property (readonly) NSRange backtracesRange;

    @property (readonly) NSRange threadStateRange;

    @property (readonly) NSRange binaryImagesRange;

@end

@interface CUIDataTransform (Private)

- (void)setOutput:(NSAttributedString *)inOutput;

@end

@interface CUICrashDataTransform ()
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
    

    @property (copy) NSString * processPath;

@end

@implementation CUICrashDataTransform

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

- (BOOL)transform
{
    if ([super transform]==NO)
        return NO;
    
    CUICrashLog * tCrashLog=self.input;
    
    if ([tCrashLog isKindOfClass:[CUIRawCrashLog class]]==NO)
    {
        // A COMPLETER
        
        return NO;
    }
    
    [self updatesCachedAttributes];
    
    if ([tCrashLog isMemberOfClass:[CUIRawCrashLog class]]==YES)
    {
        NSAttributedString * tAttributedString=[[NSAttributedString alloc] initWithString:tCrashLog.rawText
                                                                               attributes:_cachedPlainTextAttributes];
        
        self.output=tAttributedString;
        
        return YES;
    }
    
    if ([tCrashLog isMemberOfClass:[CUICrashLog class]]==YES)
    {
        self.processPath=tCrashLog.header.executablePath;
        
        NSMutableArray * tLines=[NSMutableArray array];
        
        [tCrashLog.rawText enumerateLinesUsingBlock:^(NSString * bLine, BOOL * bOutStop) {
            
            [tLines addObject:bLine];
        }];
        
        NSMutableArray * tMutableArray=[tLines mutableCopy];
        
        
        if (tCrashLog.binaryImagesRange.location!=NSNotFound)
        {
            if ((self.displaySettings.visibleSections & CUIDocumentBinaryImagesSection)==0)
            {
                [tMutableArray removeObjectsInRange:tCrashLog.binaryImagesRange];
            }
            else
            {
                NSArray * tBacktracesLines=[tLines subarrayWithRange:tCrashLog.binaryImagesRange];
                
                NSArray * tFilteredLines=[self processedBinaryImagesSectionLines:tBacktracesLines reportVersion:tCrashLog.reportVersion error:NULL];
                
                [tMutableArray removeObjectsInRange:tCrashLog.binaryImagesRange];
                
                [tMutableArray insertObjects:tFilteredLines atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(tCrashLog.binaryImagesRange.location,tFilteredLines.count)]];
            }
        }
        
        if (tCrashLog.threadStateRange.location!=NSNotFound)
        {
            if ((self.displaySettings.visibleSections & CUIDocumentThreadStateSection)==0)
            {
                [tMutableArray removeObjectsInRange:tCrashLog.threadStateRange];
            }
            else
            {
                NSArray * tThreadStateLines=[tLines subarrayWithRange:tCrashLog.threadStateRange];
                
                NSArray * tFilteredLines=[self processedThreadStateSectionLines:tThreadStateLines error:NULL];
                
                [tMutableArray removeObjectsInRange:tCrashLog.threadStateRange];
                
                [tMutableArray insertObjects:tFilteredLines atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(tCrashLog.threadStateRange.location,tFilteredLines.count)]];
            }
        }
        
        if (tCrashLog.backtracesRange.location!=NSNotFound)
        {
            if ((self.displaySettings.visibleSections & CUIDocumentBacktracesSection)==0)
            {
                [tMutableArray removeObjectsInRange:tCrashLog.backtracesRange];
            }
            else
            {
                NSArray * tBacktracesLines=[tLines subarrayWithRange:tCrashLog.backtracesRange];
                
                NSArray * tFilteredLines=[self processedBacktracesSectionLines:tBacktracesLines error:NULL];
                
                [tMutableArray removeObjectsInRange:tCrashLog.backtracesRange];
                
                [tMutableArray insertObjects:tFilteredLines atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(tCrashLog.backtracesRange.location,tFilteredLines.count)]];
            }
        }
        
        
        if (tCrashLog.diagnosticMessagesRange.location!=NSNotFound)
        {
            if ((self.displaySettings.visibleSections & CUIDocumentDiagnosticMessagesSection)==0)
            {
                [tMutableArray removeObjectsInRange:tCrashLog.diagnosticMessagesRange];
            }
            else
            {
                NSArray * tDiagnosticMessagesLines=[tLines subarrayWithRange:tCrashLog.diagnosticMessagesRange];
                
                NSArray * tFilteredLines=[self processedDiagnosticMessagesSectionLines:tDiagnosticMessagesLines error:NULL];
                
                [tMutableArray removeObjectsInRange:tCrashLog.diagnosticMessagesRange];
                
                [tMutableArray insertObjects:tFilteredLines atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(tCrashLog.diagnosticMessagesRange.location,tFilteredLines.count)]];
            }
        }
        
        
        if (tCrashLog.exceptionInformationRange.location!=NSNotFound)
        {
            if ((self.displaySettings.visibleSections & CUIDocumentExceptionInformationSection)==0)
            {
                [tMutableArray removeObjectsInRange:tCrashLog.exceptionInformationRange];
            }
            else
            {
                NSArray * tExceptionInformationLines=[tLines subarrayWithRange:tCrashLog.exceptionInformationRange];
                
                NSArray * tFilteredLines=[self processedExceptionInformationSectionLines:tExceptionInformationLines error:NULL];
                
                [tMutableArray removeObjectsInRange:tCrashLog.exceptionInformationRange];
                
                [tMutableArray insertObjects:tFilteredLines atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(tCrashLog.exceptionInformationRange.location,tFilteredLines.count)]];
            }
        }
        
        
        if (tCrashLog.isHeaderAvailable==YES)
        {
            if ((self.displaySettings.visibleSections & CUIDocumentHeaderSection)==0)
            {
                [tMutableArray removeObjectsInRange:tCrashLog.headerRange];
            }
            else
            {
                NSArray * HeaderLines=[tLines subarrayWithRange:tCrashLog.headerRange];
                
                NSArray * tFilteredLines=[self processedHeaderSectionLines:HeaderLines error:NULL];
                
                [tMutableArray removeObjectsInRange:tCrashLog.headerRange];
                
                [tMutableArray insertObjects:tFilteredLines atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(tCrashLog.headerRange.location,tFilteredLines.count)]];
            }
        }
        
        self.output=[self joinLines:tMutableArray withString:@"\n"];
        
        return YES;
    }
    
    // A COMPLETER
    
    return NO;
}

#pragma mark - Header

- (NSArray *)processedHeaderSectionLines:(NSArray *)inLines error:(NSError **)outError
{
    if (inLines.count==0)
        return inLines;
    
    NSMutableArray * tProcessedLines=[NSMutableArray array];
    
    [inLines enumerateObjectsUsingBlock:^(NSString * bLine, NSUInteger bLineNumber, BOOL * bOutStop) {
        
        NSUInteger tLineLength=bLine.length;
        
        // Skip Blank lines
        
        if (tLineLength==0)
        {
            [tProcessedLines addObject:bLine];
            return;
        }
        
        // Find Key and Value
        
        NSScanner * tScanner=[NSScanner scannerWithString:bLine];
        
        NSString * tKey;
        
        if ([tScanner scanUpToString:@":" intoString:&tKey]==NO)
        {
            [tProcessedLines addObject:bLine];
            
            *bOutStop=YES;
            return;
        }
        
        NSRange tKeyRange=NSMakeRange(0,tScanner.scanLocation+1);
        
        tScanner.scanLocation=tScanner.scanLocation+1;
        
        tScanner.charactersToBeSkipped=nil;
        
        [tScanner scanCharactersFromSet:self->_whitespaceCharacterSet intoString:NULL];
        
        NSRange tValueRange=NSMakeRange(tScanner.scanLocation,bLine.length-1-tScanner.scanLocation+1);
        
        
        NSMutableAttributedString * tProcessedLine=[[NSMutableAttributedString alloc] initWithString:bLine attributes:self->_cachedPlainTextAttributes];
        
        if (bLineNumber==0)
        {
            NSDictionary * tJumpAnchorAttributes=@{
                                                   CUISectionAnchorAttributeName:@"section:Header"
                                                   };
            
            [tProcessedLine addAttributes:tJumpAnchorAttributes range:NSMakeRange(0,bLine.length)];
        }
        
        
        [tProcessedLine addAttributes:self->_cachedKeyAttributes range:tKeyRange];
        
        
        if ([tKey isEqualToString:@"Path"]==YES)
        {
            [tProcessedLine addAttributes:self->_cachedPathAttributes range:tValueRange];
        }
        else if ([tKey isEqualToString:@"Version"]==YES ||
                 [tKey isEqualToString:@"OS Version"]==YES)
        {
            [tProcessedLine addAttributes:self->_cachedVersionAttributes range:tValueRange];
        }
        else if ([tKey isEqualToString:@"Anonymous UUID"]==YES ||
                 [tKey isEqualToString:@"Sleep/Wake UUID"]==YES)
        {
            [tProcessedLine addAttributes:self->_cachedUUIDAttributes range:tValueRange];
        }
        
        [tProcessedLines addObject:tProcessedLine];
    }];
    
    return [tProcessedLines copy];
}

#pragma mark - Exception Information

- (NSArray *)processedExceptionInformationSectionLines:(NSArray *)inLines error:(NSError **)outError
{
    if (inLines.count==0)
        return inLines;
    
    NSMutableArray * tProcessedLines=[NSMutableArray array];
    
    [inLines enumerateObjectsUsingBlock:^(NSString * bLine, NSUInteger bLineNumber, BOOL * bOutStop) {
        
        NSUInteger tLineLength=bLine.length;
        
        // Skip Blank lines
        
        if (tLineLength==0)
        {
            [tProcessedLines addObject:bLine];
            return;
        }
        
        // Find Key and Value
        
        NSScanner * tScanner=[NSScanner scannerWithString:bLine];
        
        NSString * tKey;
        
        if ([tScanner scanUpToString:@":" intoString:&tKey]==NO ||
            tScanner.scanLocation==tLineLength)
        {
            [tProcessedLines addObject:bLine];
            
            return;
        }
        
        NSRange tKeyRange=NSMakeRange(0,tScanner.scanLocation+1);
        
        
        tScanner.scanLocation=tScanner.scanLocation+1;
        
        tScanner.charactersToBeSkipped=nil;
        
        [tScanner scanCharactersFromSet:self->_whitespaceCharacterSet intoString:NULL];
        
        
        
        
        
        NSRange tValueRange=NSMakeRange(tScanner.scanLocation,bLine.length-1-tScanner.scanLocation+1);
        
        
        
        NSMutableAttributedString * tProcessedLine=[[NSMutableAttributedString alloc] initWithString:bLine attributes:self->_cachedPlainTextAttributes];
        
        [tProcessedLine addAttributes:self->_cachedKeyAttributes range:tKeyRange];
        
        if (bLineNumber==0)
        {
            NSDictionary * tJumpAnchorAttributes=@{
                                                   CUISectionAnchorAttributeName:@"section:Exception Information"
                                                   };
            
            [tProcessedLine addAttributes:tJumpAnchorAttributes range:NSMakeRange(0,bLine.length)];
        }
        
        if ([tKey isEqualToString:@"Exception Type"]==YES)
        {
            switch(self.hyperlinksStyle)
            {
                case CUIHyperlinksInternal:
                    
                    //if (self.displaySettings.highlightSyntax==YES)
                {
                    [tProcessedLine addAttributes:@{
                                                    NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle|NSUnderlineStylePatternDash)
                                                    }
                     
                                            range:tValueRange];
                }
                    
                    [tProcessedLine addAttributes:@{
                                                    NSLinkAttributeName:[NSURL URLWithString:@"a://exception_type"]
                                                    }
                                            range:tValueRange];
                    
                    break;
                    
                default:
                    
                    break;
            }
        }
        
        if ([tKey isEqualToString:@"Crashed Thread"]==YES)
        {
            if ((self.displaySettings.visibleSections & CUIDocumentBacktracesSection)==CUIDocumentBacktracesSection &&
                ((CUICrashLog *)self.input).backtraces.threads.count>0)
            {
                switch(self.hyperlinksStyle)
                {
                    case CUIHyperlinksInternal:
                        
                        [tProcessedLine addAttributes:@{
                                                        NSLinkAttributeName:[NSURL URLWithString:@"a://crashed_thread"]
                                                        }
                                                range:tKeyRange];
                        
                        break;
                        
                    case CUIHyperlinksHTML:
                        
                        [tProcessedLine addAttributes:@{
                                                        NSLinkAttributeName:[NSURL URLWithString:@"sharp://crashed_thread"]
                                                        }
                                                range:tKeyRange];
                        
                        break;
                        
                    default:
                        
                        break;
                }
            }
            
            [tProcessedLine addAttributes:self->_cachedCrashedThreadLabelAttributes range:tValueRange];
        }
        
        [tProcessedLines addObject:tProcessedLine];
    }];
    
    
    return tProcessedLines;
}

#pragma mark - Diagnostic Messages

- (NSArray *)processedDiagnosticMessagesSectionLines:(NSArray *)inLines error:(NSError **)outError
{
    if (inLines.count==0)
        return inLines;
    
    NSMutableArray * tProcessedLines=[NSMutableArray array];
    
    // First line
    
    NSDictionary * tJumpAnchorAttributes=@{
                                           CUISectionAnchorAttributeName:@"section:Diagnostic Messages"
                                           };
    
    NSMutableAttributedString * tAttributedString=[[NSMutableAttributedString alloc] initWithString:inLines.firstObject attributes:tJumpAnchorAttributes];
    
    NSDictionary * tFirstLineAttributes=_cachedKeyAttributes;
    
    [tAttributedString addAttributes:tFirstLineAttributes range:NSMakeRange(0,tAttributedString.length)];
    
    [tProcessedLines addObject:tAttributedString];
    
    // Other Lines
    
    NSRange tOtherLinesRange=NSMakeRange(1,inLines.count-1);
    
    [inLines enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:tOtherLinesRange]
                               options:0
                            usingBlock:^(NSString * bLine, NSUInteger bLineNumber, BOOL * bOutStop) {
                                
                                id tObject=bLine;
                                
                                NSUInteger tLineLength=bLine.length;
                                
                                if (tLineLength==0)
                                {
                                    [tProcessedLines addObject:bLine];
                                    
                                    return;
                                }
                                
                                if ([bLine characterAtIndex:tLineLength-1]==':')
                                {
                                    if ([bLine isEqualToString:@"Application Specific Information:"]==YES ||
                                        [bLine isEqualToString:@"Dyld Error Message:"]==YES ||
                                        [bLine isEqualToString:@"Application Specific Signatures:"]==YES ||
                                        [bLine isEqualToString:@"CreationBacktrace:"]==YES ||
                                        [bLine isEqualToString:@" Ordered grouping begin/end backtraces:"]==YES)
                                    {
                                        NSAttributedString * tLineAttributedString=[[NSAttributedString alloc] initWithString:bLine attributes:self->_cachedKeyAttributes];
                                        
                                        tObject=tLineAttributedString;
                                    }
                                }
                                
                                [tProcessedLines addObject:tObject];
                                
                            }];
    
    return tProcessedLines;
}

#pragma mark - Backtraces

- (NSArray *)processedBacktracesSectionLines:(NSArray *)inLines error:(NSError **)outError
{
    if (inLines.count==0)
        return inLines;
    
    NSMutableArray * tProcessedLines=[NSMutableArray array];
    
    __block NSInteger tThreadEntityLineStart=0;
    __block NSInteger tThreadEntityLineEnd=0;
    
    [inLines enumerateObjectsUsingBlock:^(NSString * bLine, NSUInteger bLineNumber, BOOL *bOutStop) {
        
        // Retrieve thread number, crashed status and dispatch queue name
        
        if (bLine.length!=0)
            return;
        
        tThreadEntityLineEnd=bLineNumber;   // Keep the blank line
        
        NSRange tThreadRange=NSMakeRange(tThreadEntityLineStart, tThreadEntityLineEnd-tThreadEntityLineStart+1);
        
        NSError * tError;
        
        NSArray * tFilteredThreadLines=[self processedThreadBacktraceLines:[inLines subarrayWithRange:tThreadRange] error:&tError];
        
        [tProcessedLines addObjectsFromArray:tFilteredThreadLines];
        
        tThreadEntityLineStart=bLineNumber+1;
    }];
    
    NSMutableAttributedString * tMutableAttributedString=tProcessedLines.firstObject;
    
    NSDictionary * tJumpAnchorAttributes=@{
                                           CUISectionAnchorAttributeName:@"section:Backtraces"
                                           };
    
    [tMutableAttributedString addAttributes:tJumpAnchorAttributes
                                      range:NSMakeRange(0, tMutableAttributedString.length)];
    
    return tProcessedLines;
}

- (NSArray *)processedThreadBacktraceLines:(NSArray *)inLines error:(NSError **)outError
{
    if (inLines.count==0)
        return inLines;
    
    NSString * tHeaderLine=inLines.firstObject;
    BOOL tCrashedThread=NO;
    NSString * tName=nil;
    
    if ([tHeaderLine isEqualToString:@"Backtrace not available"]==YES)
    {
        NSMutableAttributedString * tMutableAttributedString=[[NSMutableAttributedString alloc] initWithString:tHeaderLine attributes:_cachedPlainTextAttributes];
        
        NSMutableArray * tProcessedLines=[NSMutableArray arrayWithObject:tMutableAttributedString];
        
        NSRange tOtherLinesRange=NSMakeRange(1,inLines.count-1);
        
        [inLines enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:tOtherLinesRange]
                                   options:0
                                usingBlock:^(NSString * bLine, NSUInteger bLineNumber, BOOL * bOutStop) {
                                    
                                    [tProcessedLines addObject:bLine];
                                }];
        
        return [tProcessedLines copy];
    }
    
    CUICrashLogBacktraces * tBacktraces=((CUICrashLog *)self.input).backtraces;
    
    CUIThread * tThread=nil;
    
    if ([tHeaderLine hasPrefix:@"Application Specific Backtrace"]==YES)
    {
        tName=@"Application Specific Backtrace";
        
        tThread=[tBacktraces threadNamed:tName];
    }
    else
    {
        NSArray * tComponents=[tHeaderLine componentsSeparatedByString:@"::"];
        NSString * tLeftPart;
        
        if (tComponents.count==0)
        {
            // Uh oh
            
            // A COMPLETER
        }
        
        tLeftPart=tComponents.firstObject;
        
        if (tComponents.count!=2)
            tLeftPart=[tLeftPart stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":"]];
        
        NSArray * tThreadNumberComponents=[tLeftPart componentsSeparatedByString:@" "];
        
        if (tThreadNumberComponents.count<2)
        {
            // Uh oh
            
            // A COMPLETER
        }
        
        tName=tThreadNumberComponents[1];   // <- it's actually the number
        
        if (tThreadNumberComponents.count==3)
        {
            if ([tThreadNumberComponents[2] caseInsensitiveCompare:@"Crashed"]==NSOrderedSame)
                tCrashedThread=YES;
        }
        
        if ((self.displaySettings.visibleSections & CUIDocumentBacktraceCrashedThreadSubSection)!=0)
        {
            if (tCrashedThread==NO)
                return @[];
        }
        
        tThread=[tBacktraces threadWithNumber:[tName integerValue]];
    }
    
    
    NSMutableAttributedString * tMutableAttributedString=[[NSMutableAttributedString alloc] initWithString:inLines.firstObject attributes:_cachedPlainTextAttributes];
    
    NSRange tStringRange=NSMakeRange(0, tMutableAttributedString.length);
    
    [tMutableAttributedString addAttributes:@{
                                              CUIThreadAnchorAttributeName:[NSString stringWithFormat:@"thread:%@",tName]
                                              }
                                      range:tStringRange];
    
    
    
    
    if (tCrashedThread==YES)
    {
        switch(self.hyperlinksStyle)
        {
            case CUIHyperlinksInternal:
                
                [tMutableAttributedString addAttributes:@{
                                                          CUIGenericAnchorAttributeName:@"a:crashed_thread"
                                                          }
                                                  range:tStringRange];
                
                break;
                
            case CUIHyperlinksHTML:
            {
                NSURL * tURL=[NSURL URLWithString:@"anchor://crashed_thread"];
                
                if (tURL!=nil)
                    [tMutableAttributedString addAttributes:@{NSLinkAttributeName:tURL}
                                                      range:tStringRange];
                
                break;
            }
            default:
                
                break;
        }
    }
    
    NSDictionary * tAttributes=(tCrashedThread==YES) ? _cachedCrashedThreadLabelAttributes : _cachedThreadLabelAttributes;
    
    [tMutableAttributedString addAttributes:tAttributes
                                      range:tStringRange];
    
    NSMutableArray * tProcessedLines=[NSMutableArray arrayWithObject:tMutableAttributedString];
    
    NSRange tOtherLinesRange=NSMakeRange(1,inLines.count-1);
    
    __block NSUInteger tStackFrameIndex=0;
    
    [inLines enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:tOtherLinesRange]
                               options:0
                            usingBlock:^(NSString * bLine, NSUInteger bLineNumber, BOOL * bOutStop) {
                                
                                if (bLine.length==0)
                                {
                                    [tProcessedLines addObject:bLine];
                                    return;
                                }
                                
                                NSString * tProcessedStackFrameLine=[self processedStackFrameLine:bLine stackFrame:tThread.callStackBacktrace.stackFrames[tStackFrameIndex]];
                                
                                if (tProcessedStackFrameLine!=nil)
                                {
                                    [tProcessedLines addObject:tProcessedStackFrameLine];
                                }
                                else
                                {
                                    NSLog(@"Error transforming line: %@",bLine);
                                    
                                    [tProcessedLines addObject:bLine];
                                }
                                
                                tStackFrameIndex+=1;
                                
                            }];
    
    return tProcessedLines;
}

- (id)processedStackFrameLine:(NSString *)inLine stackFrame:(CUIStackFrame *)inStackFrame
{
    NSScanner * tScanner=[NSScanner scannerWithString:inLine];
    
    if ([tScanner scanInteger:NULL]==NO)
        return nil;
    
    __block NSString * tLine=inLine;
    
    tScanner.charactersToBeSkipped=nil;
    
    [tScanner scanCharactersFromSet:_whitespaceCharacterSet intoString:NULL];
    
    tScanner.charactersToBeSkipped=_whitespaceCharacterSet;
    
    NSUInteger tBinaryImageIdentifierStart=tScanner.scanLocation;
    
    if ([tScanner scanUpToString:@"0x" intoString:nil]==NO)
        return nil;
    
    NSRange tBinaryImageIdentifierRange;
    
    if (tScanner.scanLocation==tLine.length)
    {
        // try to find a \t
        
        tScanner.scanLocation=tBinaryImageIdentifierStart;
        
        if ([tScanner scanUpToString:@"\t" intoString:NULL]==NO)
            return [[NSAttributedString alloc] initWithString:tLine attributes:_cachedParsingErrorAttributes];
        
        if (tScanner.scanLocation==tLine.length)
            return [[NSAttributedString alloc] initWithString:tLine attributes:_cachedParsingErrorAttributes];
        
        tBinaryImageIdentifierRange=NSMakeRange(tBinaryImageIdentifierStart,tScanner.scanLocation-tBinaryImageIdentifierStart+1);
    }
    else
    {
        tBinaryImageIdentifierRange=NSMakeRange(tBinaryImageIdentifierStart,tScanner.scanLocation-1-tBinaryImageIdentifierStart+1);
    }
    
    NSRange tBinEndRange=[[tLine substringWithRange:tBinaryImageIdentifierRange] rangeOfCharacterFromSet:_whitespaceCharacterSet.invertedSet options:NSBackwardsSearch];
    
    NSString * tBinaryImageIdentifier=[tLine substringWithRange:NSMakeRange(tBinaryImageIdentifierRange.location, tBinEndRange.location+1)];
    
    tScanner.charactersToBeSkipped=_whitespaceCharacterSet;
    
    unsigned long long tMachineInstructionAddress=0;
    
    if ([tScanner scanHexLongLong:&tMachineInstructionAddress]==NO)
        return [[NSAttributedString alloc] initWithString:tLine];
    
    BOOL tIsUserCode=NO;
    
    CUICrashLogBinaryImages * tBinaryImages=((CUICrashLog *)self.input).binaryImages;
    
    CUIBinaryImage * tBinaryImage=[tBinaryImages binaryImageWithIdentifierOrName:tBinaryImageIdentifier identifier:&tBinaryImageIdentifier];
    
    if (tBinaryImage!=nil)
    {
        NSString * tPath=tBinaryImage.path;
        
        if (tBinaryImage.isMainImage==YES)
        {
            tIsUserCode=YES;
        }
        else
        {
            if ([tPath isEqualToString:self.processPath]==YES)
                tIsUserCode=YES;
        }
    }
    
    if (tIsUserCode==NO)
        tIsUserCode=[tBinaryImages isUserCodeAtMemoryAddress:tMachineInstructionAddress inBinaryImage:tBinaryImageIdentifier];
    
    NSRange tMemoryAddressRange=NSMakeRange(tBinaryImageIdentifierRange.location+tBinaryImageIdentifierRange.length,tScanner.scanLocation-(tBinaryImageIdentifierRange.location+tBinaryImageIdentifierRange.length)+1);
    
    NSString * tSymbol=nil;
    
    if ([tScanner scanUpToString:@" +" intoString:&tSymbol]==NO)
        return [[NSAttributedString alloc] initWithString:tLine];
    
    __block NSUInteger tSavedScanLocation=tScanner.scanLocation;
    
#ifndef __DISABLE_SYMBOLICATION_
    
    BOOL tSymbolicateAutomatically=[CUIApplicationPreferences sharedPreferences].symbolicateAutomatically;
    
    CUISymbolicationData * tSymbolicationData=nil;
    
    if (tSymbolicateAutomatically==YES)
    {
        tSymbolicationData=inStackFrame.symbolicationData;
    }
    
    if (tSymbolicationData!=nil)
    {
        NSMutableString * tTemporaryLine=[[tLine substringToIndex:tScanner.scanLocation-tSymbol.length] mutableCopy];
        
        if (tSymbolicationData.stackFrameSymbol==nil)
        {
            NSLog(@"Missing stackFrameSymbol");
        }
        
        tSavedScanLocation+=(tSymbolicationData.stackFrameSymbol.length-tSymbol.length);
        
        [tTemporaryLine appendString:[_symbolicationDataFormatter stringForObjectValue:tSymbolicationData]];
        
        tLine=[tTemporaryLine copy];
    }
    else
    {
        if (tSymbolicateAutomatically==YES)
        {
            // Default values
            
            NSUInteger tAddress=tMachineInstructionAddress-tBinaryImage.binaryImageOffset;
            
            [[CUISymbolicationManager sharedSymbolicationManager] lookUpSymbolicationDataForMachineInstructionAddress:tAddress
                                                                                                           binaryUUID:tBinaryImage.UUID
                                                                                                    completionHandler:^(CUISymbolicationDataLookUpResult bLookUpResult, CUISymbolicationData *bSymbolicationData) {
                                                                                                        
                                                                                                        switch(bLookUpResult)
                                                                                                        {
                                                                                                            case CUISymbolicationDataLookUpResultError:
                                                                                                            case CUISymbolicationDataLookUpResultNotFound:
                                                                                                                
                                                                                                                break;
                                                                                                                
                                                                                                            case CUISymbolicationDataLookUpResultFound:
                                                                                                            {
                                                                                                                inStackFrame.symbolicationData=bSymbolicationData;
                                                                                                                
                                                                                                                [[NSNotificationCenter defaultCenter] postNotificationName:CUIStackFrameSymbolicationDidSucceedNotification
                                                                                                                                                                    object:self.input];
                                                                                                                
                                                                                                                break;
                                                                                                            }
                                                                                                                
                                                                                                            case CUISymbolicationDataLookUpResultFoundInCache:
                                                                                                            {
                                                                                                                inStackFrame.symbolicationData=bSymbolicationData;
                                                                                                                
                                                                                                                NSMutableString * tTemporaryLine=[[tLine substringToIndex:tScanner.scanLocation-tSymbol.length] mutableCopy];
                                                                                                                
                                                                                                                tSavedScanLocation+=(bSymbolicationData.stackFrameSymbol.length-tSymbol.length);
                                                                                                                
                                                                                                                [tTemporaryLine appendString:[self->_symbolicationDataFormatter stringForObjectValue:bSymbolicationData]];
                                                                                                                
                                                                                                                tLine=[tTemporaryLine copy];
                                                                                                                
                                                                                                                break;
                                                                                                            }
                                                                                                                
                                                                                                        }
                                                                                                        
                                                                                                    }];
        }
    }
    
#endif
    
    NSMutableAttributedString * tProcessedLine=[[NSMutableAttributedString alloc] initWithString:tLine attributes:_cachedPlainTextAttributes];
    
    NSRange tRange=NSMakeRange(0,tLine.length);
    
    NSDictionary * tDictionary=(tIsUserCode==YES) ? _cachedExecutableCodeAttributes : _cachedOSCodeAttributes;
    
    [tProcessedLine addAttributes:tDictionary range:tRange];
    
    
    if ((self.displaySettings.visibleStackFrameComponents & CUIStackFrameByteOffsetComponent)==0)
    {
        [tProcessedLine deleteCharactersInRange:NSMakeRange(tSavedScanLocation, tLine.length-1-tSavedScanLocation+1)];
    }
    else
    {
#ifndef __DISABLE_SYMBOLICATION_
        if (tSymbolicationData!=nil)
        {
            NSString * tAbsolutePath=inStackFrame.symbolicationData.sourceFilePath;
            NSString * tLastPathComponent=tAbsolutePath.lastPathComponent;
            
            if (tLastPathComponent!=nil)
            {
                NSRange tRange=[tLine rangeOfString:tLastPathComponent];
                
                if (tRange.location!=0)
                {
                    if ([[NSFileManager defaultManager] fileExistsAtPath:tAbsolutePath]==YES)
                    {
                        NSURLComponents * tURLComponents=[NSURLComponents new];
                        tURLComponents.scheme=[NSString stringWithFormat:@"sourcecode-%lu",inStackFrame.symbolicationData.lineNumber];
                        tURLComponents.path=tAbsolutePath;
                        
                        NSURL * tURL=tURLComponents.URL;
                        
                        if (tURL!=nil)
                        {
                            [tProcessedLine addAttributes:@{
                                                            NSLinkAttributeName:tURL,
                                                            NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle),
                                                            NSUnderlineColorAttributeName:_cachedUnderlineColor
                                                            }
                                                    range:tRange];
                            
                            
                        }
                    }
                }
            }
        }
#endif
    }
    
    
    if ((self.displaySettings.visibleStackFrameComponents & CUIStackFrameMachineInstructionAddressComponent)==0)
    {
        [tProcessedLine deleteCharactersInRange:tMemoryAddressRange];
    }
    else
    {
        [tProcessedLine addAttributes:_cachedMemoryAddressAttributes range:tMemoryAddressRange];
    }
    
    if ((self.displaySettings.visibleStackFrameComponents & CUIStackFrameBinaryNameComponent)==0)
    {
        [tProcessedLine deleteCharactersInRange:tBinaryImageIdentifierRange];
    }
    else
    {
        if (self.hyperlinksStyle!=CUIHyperlinksNone && ((self.displaySettings.visibleSections & CUIDocumentBinaryImagesSection)==CUIDocumentBinaryImagesSection))
        {
            NSString * tCleanedUpIdentifier=[tBinaryImageIdentifier stringByTrimmingCharactersInSet:_whitespaceCharacterSet];
            
            CUIBinaryImage * tBinaryImage=[tBinaryImages binaryImageWithIdentifier:tBinaryImageIdentifier];
            
            if (tBinaryImage==nil)
            {
                tBinaryImage=[tBinaryImages binaryImageWithIdentifier:tBinaryImageIdentifier];
                
                if (tBinaryImage==nil)
                {
                    tBinaryImageIdentifier=[tBinaryImages binaryImageIdentifierForName:tBinaryImageIdentifier];
                }
                else
                {
                    tBinaryImageIdentifier=nil;
                }
            }
            
            if (tBinaryImageIdentifier!=nil)
            {
                NSURL * tURL=nil;
                
                switch(self.hyperlinksStyle)
                {
                    case CUIHyperlinksInternal:
                        
                        tURL=[NSURL URLWithString:[NSString stringWithFormat:@"bin://%@",tBinaryImageIdentifier]];
                        
                        break;
                        
                    case CUIHyperlinksHTML:
                        
                        tURL=[NSURL URLWithString:[NSString stringWithFormat:@"sharp://%@",tBinaryImageIdentifier]];
                        
                        break;
                        
                    default:
                        
                        break;
                }
                
                if (tURL!=nil)
                    [tProcessedLine addAttributes:@{NSLinkAttributeName:tURL} range:NSMakeRange(tBinaryImageIdentifierRange.location,tCleanedUpIdentifier.length)];
                
            }
        }
    }
    
    return tProcessedLine;
}

#pragma mark - Thread State

- (NSArray *)processedThreadStateSectionLines:(NSArray *)inLines error:(NSError **)outError
{
    if (inLines.count==0)
        return inLines;
    
    NSMutableArray * tProcessedLines=[NSMutableArray array];
    
    // First line
    
    NSDictionary * tJumpAnchorAttributes=@{
                                           CUISectionAnchorAttributeName:@"section:Thread State"
                                           };
    
    NSMutableAttributedString * tAttributedString=[[NSMutableAttributedString alloc] initWithString:inLines.firstObject attributes:tJumpAnchorAttributes];
    
    NSDictionary * tFirstLineAttributes=_cachedKeyAttributes;
    
    [tAttributedString addAttributes:tFirstLineAttributes range:NSMakeRange(0,tAttributedString.length)];
    
    
    [tProcessedLines addObject:tAttributedString];
    
    // Other Lines
    
    NSRange tOtherLinesRange=NSMakeRange(1,inLines.count-1);
    
    __block NSUInteger tLastLine=0;
    
    
    
    [inLines enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:tOtherLinesRange]
                               options:0
                            usingBlock:^(NSString * bLine, NSUInteger bLineNumber, BOOL * bOutStop) {
                                
                                NSMutableAttributedString * tMutableAttributedString=[[NSMutableAttributedString alloc] initWithString:bLine attributes:self->_cachedKeyAttributes];
                                
                                if (bLine.length<4)
                                {
                                    tLastLine=bLineNumber+1;
                                    
                                    [tProcessedLines addObject:tMutableAttributedString];
                                    
                                    *bOutStop=YES;
                                    return;
                                }
                                
                                NSScanner * tRegistersScanner=[NSScanner scannerWithString:bLine];
                                
                                tRegistersScanner.charactersToBeSkipped=self->_whitespaceCharacterSet;
                                
                                while (tRegistersScanner.isAtEnd==NO)
                                {
                                    tRegistersScanner.charactersToBeSkipped=nil;
                                    
                                    [tRegistersScanner scanCharactersFromSet:self->_whitespaceCharacterSet intoString:nil];
                                    
                                    NSString * tRegisterName;
                                    
                                    tRegistersScanner.charactersToBeSkipped=self->_whitespaceCharacterSet;
                                    
                                    if ([tRegistersScanner scanUpToString:@":" intoString:&tRegisterName]==NO)
                                        return;
                                    
                                    if ([tRegistersScanner scanString:@": " intoString:NULL]==NO)
                                        return;
                                    
                                    NSRange tValueRange=NSMakeRange(tRegistersScanner.scanLocation, 0);
                                    
                                    if ([tRegistersScanner scanHexLongLong:NULL]==NO)
                                        return;
                                    
                                    tValueRange.length=tRegistersScanner.scanLocation-1-tValueRange.location+1;
                                    
                                    tRegistersScanner.charactersToBeSkipped=nil;
                                    
                                    [tRegistersScanner scanCharactersFromSet:self->_whitespaceCharacterSet intoString:nil];
                                    
                                    [tMutableAttributedString addAttributes:self->_cachedRegisterValueAttributes range:tValueRange];
                                }
                                
                                [tProcessedLines addObject:tMutableAttributedString];
                                
                            }];
    
    // Remaining lines
    
    [inLines enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(tLastLine,inLines.count-1-tLastLine+1)] options:0 usingBlock:^(NSString * bLine, NSUInteger bLineNumber, BOOL * bOutStop) {
        
        NSUInteger tLineLength=bLine.length;
        
        // Skip Blank lines
        
        if (tLineLength==0)
        {
            [tProcessedLines addObject:[[NSAttributedString alloc] initWithString:bLine attributes:self->_cachedPlainTextAttributes]];
            return;
        }
        
        // Find Key and Value
        
        NSScanner * tScanner=[NSScanner scannerWithString:bLine];
        
        NSString * tKey;
        
        if ([tScanner scanUpToString:@":" intoString:&tKey]==NO)
        {
            // A COMPLETER
            
            [tProcessedLines addObject:[[NSAttributedString alloc] initWithString:bLine attributes:self->_cachedPlainTextAttributes]];
            
            return;
        }
        
        NSRange tKeyRange=NSMakeRange(0,tScanner.scanLocation+1);
        
        
        NSMutableAttributedString * tMutableAttributedString=nil;
        
        if (tScanner.scanLocation<bLine.length)
        {
            tScanner.scanLocation=tScanner.scanLocation+1;
            
            tScanner.charactersToBeSkipped=nil;
            
            [tScanner scanCharactersFromSet:self->_whitespaceCharacterSet intoString:NULL];
            
            tMutableAttributedString=[[NSMutableAttributedString alloc] initWithString:[bLine substringWithRange:tKeyRange] attributes:self->_cachedKeyAttributes];
            
            NSAttributedString * tOther=[[NSAttributedString alloc] initWithString:[bLine substringWithRange:NSMakeRange(tKeyRange.length,bLine.length-1-tKeyRange.length+1)] attributes:self->_cachedPlainTextAttributes];
            
            [tMutableAttributedString appendAttributedString:tOther];
        }
        else
        {
            tMutableAttributedString=[[NSMutableAttributedString alloc] initWithString:bLine attributes:self->_cachedPlainTextAttributes];
        }
        
        [tProcessedLines addObject:tMutableAttributedString];
        
    }];
    
    return tProcessedLines;
}


#pragma mark - Binary Images

- (NSArray *)processedBinaryImagesSectionLines:(NSArray *)inLines reportVersion:(NSUInteger)inReportVersion error:(NSError **)outError
{
    if (inLines.count==0)
        return inLines;
    
    NSMutableArray * tProcessedLines=[NSMutableArray array];
    
    // First line
    
    NSDictionary * tJumpAnchorAttributes=@{
                                           CUISectionAnchorAttributeName:@"section:Binary Images"
                                           };
    
    NSMutableAttributedString * tAttributedString=[[NSMutableAttributedString alloc] initWithString:inLines.firstObject attributes:tJumpAnchorAttributes];
    
    NSDictionary * tFirstLineAttributes=_cachedKeyAttributes;
    
    if (tFirstLineAttributes!=nil)
        [tAttributedString addAttributes:tFirstLineAttributes range:NSMakeRange(0,tAttributedString.length)];
    
    [tProcessedLines addObject:tAttributedString];
    
    // Other Lines
    
    NSRange tOtherLinesRange=NSMakeRange(1,inLines.count-1);
    
    [inLines enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:tOtherLinesRange]
                               options:0
                            usingBlock:^(NSString * bLine, NSUInteger bLineNumber, BOOL *bOutStop) {
                                
                                if (bLine.length==0)
                                {
                                    [tProcessedLines addObjectsFromArray:[inLines subarrayWithRange:NSMakeRange(bLineNumber,inLines.count-1-bLineNumber+1)]];
                                    
                                    *bOutStop=YES;
                                    
                                    return;
                                }
                                
                                id tProcessedLine=[self processedBinaryImageLine:bLine reportVersion:inReportVersion];
                                
                                if (tProcessedLine==nil)
                                {
                                    tProcessedLine=[[NSAttributedString alloc] initWithString:bLine attributes:self->_cachedParsingErrorAttributes];
                                    
                                    NSLog(@"Error transforming line: %@",bLine);
                                }
                                
                                [tProcessedLines addObject:tProcessedLine];
                            }];
    
    return tProcessedLines;
}

- (id)processedBinaryImageLine:(NSString *)inLine reportVersion:(NSUInteger)inReportVersion
{
    NSScanner * tScanner=[NSScanner scannerWithString:inLine];
    
    tScanner.charactersToBeSkipped=nil;
    
    [tScanner scanCharactersFromSet:_whitespaceCharacterSet intoString:NULL];
    
    NSUInteger tMinAddressStart=tScanner.scanLocation;
    
    tScanner.charactersToBeSkipped=_whitespaceCharacterSet;
    
    if ([tScanner scanHexLongLong:NULL]==NO)
        return nil;
    
    NSUInteger tMinAddressEnd=tScanner.scanLocation;
    
    [tScanner scanUpToString:@"0x" intoString:NULL];
    
    NSUInteger tMaxAddressStart=tScanner.scanLocation;
    
    if ([tScanner scanHexLongLong:NULL]==NO)
        return nil;
    
    NSUInteger tMaxAddressEnd=tScanner.scanLocation;
    
    tScanner.charactersToBeSkipped=nil;
    
    [tScanner scanCharactersFromSet:_whitespaceCharacterSet intoString:NULL];
    
    NSUInteger tIdentifierStart=tScanner.scanLocation;
    
    NSString * tIdentifier=nil;
    NSString * tOriginalString;
    
    if ([tScanner scanUpToString:@"(" intoString:&tOriginalString]==NO)
        return nil;
    
    if (inReportVersion==6)
    {
        // Remove the version
        
        NSUInteger tLength=tOriginalString.length;
        
        NSRange tRange=[tOriginalString rangeOfCharacterFromSet:_whitespaceCharacterSet options:NSBackwardsSearch range:NSMakeRange(0,tLength-1)];
        
        if (tRange.location==NSNotFound)
            return nil;
        
        tIdentifier=[tOriginalString substringToIndex:tRange.location];
    }
    else
    {
        tIdentifier=tOriginalString;
    }
    
    BOOL tIsUserCode=NO;
    
    tIdentifier=[tIdentifier stringByTrimmingCharactersInSet:_whitespaceCharacterSet];
    
    NSUInteger tIdentifierRealLength=tIdentifier.length;
    
    if ([tIdentifier hasPrefix:@"+"]==YES && tIdentifierRealLength>1)
    {
        // User Code
        
        tIsUserCode=YES;
        
        tIdentifier=[tIdentifier substringFromIndex:1];
    }
    
    NSMutableAttributedString * tNewLine=[[NSMutableAttributedString alloc] initWithString:inLine attributes:_cachedPlainTextAttributes];
    
    switch(self.hyperlinksStyle)
    {
        case CUIHyperlinksHTML:
        {
            NSURL * tURL=[NSURL URLWithString:[NSString stringWithFormat:@"anchor://%@",tIdentifier]];
            
            if (tURL!=nil)
                [tNewLine addAttributes:@{NSLinkAttributeName:tURL}
                                  range:NSMakeRange(0, tNewLine.length)];
            
            break;
        }
            
        default:
            
            [tNewLine addAttributes:@{
                                      CUIBinaryAnchorAttributeName:[NSString stringWithFormat:@"bin:%@",tIdentifier]
                                      }
                              range:NSMakeRange(0, tNewLine.length)];
            
            break;
    }
    
    tScanner.scanLocation=tIdentifierStart+tIdentifierRealLength;
    
    NSRange tIdentifierRange=NSMakeRange(tIdentifierStart, tIdentifierRealLength);
    
    if (inReportVersion==6)
    {
        tScanner.scanLocation+=1;
    }
    else
    {
        if ([tScanner scanUpToString:@"(" intoString:NULL]==NO)
            return nil;
    }
    
    NSUInteger tVersionStart=tScanner.scanLocation;
    
    if ([tScanner scanUpToString:@")" intoString:NULL]==NO)
        return nil;
    
    NSUInteger tVersionEnd=tScanner.scanLocation;
    
    // UUID can be missing // A COMPLETER
    
    tScanner.scanLocation+=2;
    
    NSUInteger tUUIDStart=NSNotFound;
    NSUInteger tUUIDEnd=NSNotFound;
    
    if ([inLine characterAtIndex:tScanner.scanLocation]=='<')
    {
        tUUIDStart=tScanner.scanLocation;
        
        if ([tScanner scanUpToString:@">" intoString:NULL]==NO)
            return nil;
        
        tUUIDEnd=tScanner.scanLocation;
    }
    else
    {
        tScanner.scanLocation-=2;
    }
    
    if ([tScanner scanUpToString:@"/" intoString:NULL]==NO)
        return nil;
    
    NSRange tPathRange=NSMakeRange(tScanner.scanLocation,inLine.length-1-tScanner.scanLocation+1);
    
    NSDictionary * tIdentifierAttributes=_cachedPlainTextAttributes;
    
    if ([CUIThemesManager sharedManager].currentTheme.isMonochrome==NO)
    {
        tIdentifierAttributes=@{
                                NSForegroundColorAttributeName:(tIsUserCode==YES) ? [CUIBinaryImageUtility colorForUserCode]: [CUIBinaryImageUtility colorForIdentifier:tIdentifier]
                                };
    }
    
    [tNewLine addAttributes:tIdentifierAttributes
                      range:tIdentifierRange];
    
    [tNewLine addAttributes:_cachedMemoryAddressAttributes
                      range:NSMakeRange(tMinAddressStart, tMinAddressEnd-tMinAddressStart+1)];
    
    [tNewLine addAttributes:_cachedMemoryAddressAttributes
                      range:NSMakeRange(tMaxAddressStart, tMaxAddressEnd-tMaxAddressStart+1)];
    
    if (tUUIDStart!=NSNotFound)
    {
        [tNewLine addAttributes:_cachedUUIDAttributes
                          range:NSMakeRange(tUUIDStart,tUUIDEnd-tUUIDStart+1)];
    }
    
    [tNewLine addAttributes:_cachedVersionAttributes
                      range:NSMakeRange(tVersionStart,tVersionEnd-tVersionStart+1)];
    
    [tNewLine addAttributes:_cachedPathAttributes
                      range:tPathRange];
    
    return tNewLine;
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