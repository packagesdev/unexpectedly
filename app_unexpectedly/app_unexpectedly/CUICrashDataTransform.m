/*
 Copyright (c) 2020-2022, Stephane Sudre
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

#import "CUICrashLogExceptionInformation+QuickHelp.h"

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

@implementation CUICrashDataTransform

- (CUICrashLog *)crashlog
{
    return self.input;
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
                                                                               attributes:self.plainTextAttributes];
        
        self.output=tAttributedString;
        
        return YES;
    }
    
    if ([tCrashLog isMemberOfClass:[CUICrashLog class]]==NO)
    {
        // A COMPLETER
        
        return NO;
    }
    
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
        
        [tScanner scanCharactersFromSet:self.whitespaceCharacterSet intoString:NULL];
        
        NSRange tValueRange=NSMakeRange(tScanner.scanLocation,bLine.length-1-tScanner.scanLocation+1);
        
        
        NSMutableAttributedString * tProcessedLine=[[NSMutableAttributedString alloc] initWithString:bLine attributes:self.plainTextAttributes];
        
        if (bLineNumber==0)
        {
            NSDictionary * tJumpAnchorAttributes=@{
                                                   CUISectionAnchorAttributeName:@"section:Header"
                                                   };
            
            [tProcessedLine addAttributes:tJumpAnchorAttributes range:NSMakeRange(0,bLine.length)];
        }
        
        
        [tProcessedLine addAttributes:self.keyAttributes range:tKeyRange];
        
        
        if ([tKey isEqualToString:@"Path"]==YES)
        {
            [tProcessedLine addAttributes:self.pathAttributes range:tValueRange];
        }
        else if ([tKey isEqualToString:@"Version"]==YES ||
                 [tKey isEqualToString:@"OS Version"]==YES)
        {
            [tProcessedLine addAttributes:self.versionAttributes range:tValueRange];
        }
        else if ([tKey isEqualToString:@"Anonymous UUID"]==YES ||
                 [tKey isEqualToString:@"Sleep/Wake UUID"]==YES)
        {
            [tProcessedLine addAttributes:self.UUIDAttributes range:tValueRange];
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
        
        [tScanner scanCharactersFromSet:self.whitespaceCharacterSet intoString:NULL];
        
        
        
        
        
        NSRange tValueRange=NSMakeRange(tScanner.scanLocation,bLine.length-1-tScanner.scanLocation+1);
        
        
        
        NSMutableAttributedString * tProcessedLine=[[NSMutableAttributedString alloc] initWithString:bLine attributes:self.plainTextAttributes];
        
        [tProcessedLine addAttributes:self.keyAttributes range:tKeyRange];
        
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
                    
                    [tProcessedLine addAttributes:@{
                                                    NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle|NSUnderlineStylePatternDash)
                                                    }
                     
                                            range:tValueRange];
                    
                    [tProcessedLine addAttributes:@{
                                                    NSLinkAttributeName:[NSURL URLWithString:@"a://exception_type"]
                                                    }
                                            range:tValueRange];
                    
                    break;
                    
                default:
                    
                    break;
            }
        }
        
        if ([tKey isEqualToString:@"Termination Reason"]==YES)
        {
            switch(self.hyperlinksStyle)
            {
                case CUIHyperlinksInternal:
                    
                    if (self.crashlog.exceptionInformation.isQuickHelpAvailableForTerminationReason==YES)
                    {
                        [tProcessedLine addAttributes:@{
                                                        NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle|NSUnderlineStylePatternDash)
                                                        }
                         
                                                range:tValueRange];
                        
                        [tProcessedLine addAttributes:@{
                                                        NSLinkAttributeName:[NSURL URLWithString:@"a://termination_reason"]
                                                        }
                                                range:tValueRange];
                    }
                    
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
            
            [tProcessedLine addAttributes:self.crashedThreadLabelAttributes range:tValueRange];
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
    
    NSDictionary * tFirstLineAttributes=self.keyAttributes;
    
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
                                        NSAttributedString * tLineAttributedString=[[NSAttributedString alloc] initWithString:bLine attributes:self.keyAttributes];
                                        
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
        NSMutableAttributedString * tMutableAttributedString=[[NSMutableAttributedString alloc] initWithString:tHeaderLine attributes:self.plainTextAttributes];
        
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
            
            if (outError!=NULL)
                *outError=[NSError errorWithDomain:CUIDataTransformErrorDomain code:CUIDataTransformUnknownError userInfo:@{}];
            
            return nil;
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
    
    
    NSMutableAttributedString * tMutableAttributedString=[[NSMutableAttributedString alloc] initWithString:inLines.firstObject attributes:self.plainTextAttributes];
    
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
    
    NSDictionary * tAttributes=(tCrashedThread==YES) ? self.crashedThreadLabelAttributes : self.threadLabelAttributes;
    
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
    
    NSDictionary * tFirstLineAttributes=self.keyAttributes;
    
    [tAttributedString addAttributes:tFirstLineAttributes range:NSMakeRange(0,tAttributedString.length)];
    
    
    [tProcessedLines addObject:tAttributedString];
    
    // Other Lines
    
    NSRange tOtherLinesRange=NSMakeRange(1,inLines.count-1);
    
    __block NSUInteger tLastLine=0;
    
    
    
    [inLines enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:tOtherLinesRange]
                               options:0
                            usingBlock:^(NSString * bLine, NSUInteger bLineNumber, BOOL * bOutStop) {
                                
                                NSMutableAttributedString * tMutableAttributedString=[[NSMutableAttributedString alloc] initWithString:bLine attributes:self.keyAttributes];
                                
                                if (bLine.length<4)
                                {
                                    tLastLine=bLineNumber+1;
                                    
                                    [tProcessedLines addObject:tMutableAttributedString];
                                    
                                    *bOutStop=YES;
                                    return;
                                }
                                
                                NSScanner * tRegistersScanner=[NSScanner scannerWithString:bLine];
                                
                                tRegistersScanner.charactersToBeSkipped=self.whitespaceCharacterSet;
                                
                                while (tRegistersScanner.isAtEnd==NO)
                                {
                                    tRegistersScanner.charactersToBeSkipped=nil;
                                    
                                    [tRegistersScanner scanCharactersFromSet:self.whitespaceCharacterSet intoString:nil];
                                    
                                    NSString * tRegisterName;
                                    
                                    tRegistersScanner.charactersToBeSkipped=self.whitespaceCharacterSet;
                                    
                                    if ([tRegistersScanner scanUpToString:@":" intoString:&tRegisterName]==NO)
                                        return;
                                    
                                    if ([tRegistersScanner scanString:@": " intoString:NULL]==NO)
                                        return;
                                    
                                    NSRange tValueRange=NSMakeRange(tRegistersScanner.scanLocation, 0);
                                    
                                    if ([tRegistersScanner scanHexLongLong:NULL]==NO)
                                        return;
                                    
                                    tValueRange.length=tRegistersScanner.scanLocation-1-tValueRange.location+1;
                                    
                                    tRegistersScanner.charactersToBeSkipped=nil;
                                    
                                    [tRegistersScanner scanCharactersFromSet:self.whitespaceCharacterSet intoString:nil];
                                    
                                    [tMutableAttributedString addAttributes:self.registerValueAttributes range:tValueRange];
                                }
                                
                                [tProcessedLines addObject:tMutableAttributedString];
                                
                            }];
    
    // Remaining lines
    
    [inLines enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(tLastLine,inLines.count-1-tLastLine+1)] options:0 usingBlock:^(NSString * bLine, NSUInteger bLineNumber, BOOL * bOutStop) {
        
        NSUInteger tLineLength=bLine.length;
        
        // Skip Blank lines
        
        if (tLineLength==0)
        {
            [tProcessedLines addObject:[[NSAttributedString alloc] initWithString:bLine attributes:self.plainTextAttributes]];
            return;
        }
        
        // Find Key and Value
        
        NSScanner * tScanner=[NSScanner scannerWithString:bLine];
        
        NSString * tKey;
        
        if ([tScanner scanUpToString:@":" intoString:&tKey]==NO)
        {
            // A COMPLETER
            
            [tProcessedLines addObject:[[NSAttributedString alloc] initWithString:bLine attributes:self.plainTextAttributes]];
            
            return;
        }
        
        NSRange tKeyRange=NSMakeRange(0,tScanner.scanLocation+1);
        
        
        NSMutableAttributedString * tMutableAttributedString=nil;
        
        if (tScanner.scanLocation<bLine.length)
        {
            tScanner.scanLocation=tScanner.scanLocation+1;
            
            tScanner.charactersToBeSkipped=nil;
            
            [tScanner scanCharactersFromSet:self.whitespaceCharacterSet intoString:NULL];
            
            tMutableAttributedString=[[NSMutableAttributedString alloc] initWithString:[bLine substringWithRange:tKeyRange] attributes:self.keyAttributes];
            
            NSAttributedString * tOther=[[NSAttributedString alloc] initWithString:[bLine substringWithRange:NSMakeRange(tKeyRange.length,bLine.length-1-tKeyRange.length+1)] attributes:self.plainTextAttributes];
            
            [tMutableAttributedString appendAttributedString:tOther];
        }
        else
        {
            tMutableAttributedString=[[NSMutableAttributedString alloc] initWithString:bLine attributes:self.plainTextAttributes];
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
    
    NSDictionary * tFirstLineAttributes=self.keyAttributes;
    
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
                                    tProcessedLine=[[NSAttributedString alloc] initWithString:bLine attributes:self.parsingErrorAttributes];
                                    
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
    
    [tScanner scanCharactersFromSet:self.whitespaceCharacterSet intoString:NULL];
    
    NSUInteger tMinAddressStart=tScanner.scanLocation;
    
    tScanner.charactersToBeSkipped=self.whitespaceCharacterSet;
    
    if ([tScanner scanHexLongLong:NULL]==NO)
        return nil;
    
    NSUInteger tMinAddressEnd=tScanner.scanLocation;
    
    [tScanner scanUpToString:@"0x" intoString:NULL];
    
    NSUInteger tMaxAddressStart=tScanner.scanLocation;
    
    if ([tScanner scanHexLongLong:NULL]==NO)
        return nil;
    
    NSUInteger tMaxAddressEnd=tScanner.scanLocation;
    
    tScanner.charactersToBeSkipped=nil;
    
    [tScanner scanCharactersFromSet:self.whitespaceCharacterSet intoString:NULL];
    
    NSUInteger tIdentifierStart=tScanner.scanLocation;
    
    NSString * tIdentifier=nil;
    NSString * tOriginalString;
    BOOL tIsMissingVersion=NO;
    
    if ([tScanner scanUpToString:@"(" intoString:&tOriginalString]==NO)
    {
        return nil;
    }
    else
    {
        // Maybe only the version is missing
        
        if (tScanner.scanLocation==inLine.length)
        {
            tScanner.scanLocation=tIdentifierStart;
            
            if ([tScanner scanUpToString:@"<" intoString:&tOriginalString]==NO)
                return nil;
            
            tIsMissingVersion=YES;
        }
    }
    
    if (inReportVersion==6)
    {
        // Remove the version
        
        NSUInteger tLength=tOriginalString.length;
        
        NSRange tRange=[tOriginalString rangeOfCharacterFromSet:self.whitespaceCharacterSet options:NSBackwardsSearch range:NSMakeRange(0,tLength-1)];
        
        if (tRange.location==NSNotFound)
            return nil;
        
        tIdentifier=[tOriginalString substringToIndex:tRange.location];
    }
    else
    {
        tIdentifier=tOriginalString;
    }
    
    BOOL tIsUserCode=NO;
    
    tIdentifier=[tIdentifier stringByTrimmingCharactersInSet:self.whitespaceCharacterSet];
    
    NSUInteger tIdentifierRealLength=tIdentifier.length;
    
    if ([tIdentifier hasPrefix:@"+"]==YES && tIdentifierRealLength>1)
    {
        // User Code
        
        tIsUserCode=YES;
    }
    
    NSMutableAttributedString * tNewLine=[[NSMutableAttributedString alloc] initWithString:inLine attributes:self.plainTextAttributes];
    
    tScanner.scanLocation=tIdentifierStart+tIdentifierRealLength;
    
    NSRange tIdentifierRange=NSMakeRange(tIdentifierStart, tIdentifierRealLength);
    
    if (inReportVersion==6)
    {
        tScanner.scanLocation+=1;
    }
    else
    {
        if (tIsMissingVersion==NO)
        {
            if ([tScanner scanUpToString:@"(" intoString:NULL]==NO)
                return nil;
        }
        else
        {
            if ([tScanner scanUpToString:@"<" intoString:NULL]==NO)
                return nil;
        }
    }
    
    // Version
    
    NSUInteger tVersionStart=NSNotFound;
    NSUInteger tVersionEnd=NSNotFound;
    
    if (tIsMissingVersion==NO)
    {
        tVersionStart=tScanner.scanLocation;
        
        if ([tScanner scanUpToString:@")" intoString:NULL]==NO)
            return nil;
        
        tVersionEnd=tScanner.scanLocation;
    }
    
    // UUID can be missing // A COMPLETER
    
    if (tIsMissingVersion==NO)
    {
        tScanner.scanLocation+=2;
    }
    
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
    
    if (tUUIDEnd!=NSNotFound)
    {
        NSString * tBinaryImageUUID=[inLine substringWithRange:NSMakeRange(tUUIDStart+1, tUUIDEnd-tUUIDStart-1)];
        
        switch(self.hyperlinksStyle)
        {
            case CUIHyperlinksHTML:
            {
                NSURL * tURL=[NSURL URLWithString:[NSString stringWithFormat:@"anchor://%@",tBinaryImageUUID]];
                
                if (tURL!=nil)
                    [tNewLine addAttributes:@{NSLinkAttributeName:tURL}
                                      range:NSMakeRange(0, tNewLine.length)];
                
                break;
            }
                
            default:
                
                [tNewLine addAttributes:@{
                                          CUIBinaryAnchorAttributeName:[NSString stringWithFormat:@"bin:%@",tBinaryImageUUID]
                                          }
                                  range:NSMakeRange(0, tNewLine.length)];
                
                break;
        }
    }
    
    NSRange tPathRange=NSMakeRange(tScanner.scanLocation,inLine.length-1-tScanner.scanLocation+1);
    
    NSDictionary * tIdentifierAttributes=self.plainTextAttributes;
    
    if ([CUIThemesManager sharedManager].currentTheme.isMonochrome==NO)
    {
        tIdentifierAttributes=@{
                                NSForegroundColorAttributeName:(tIsUserCode==YES) ? [CUIBinaryImageUtility colorForUserCode]: [CUIBinaryImageUtility colorForIdentifier:tIdentifier]
                                };
    }
    
    [tNewLine addAttributes:tIdentifierAttributes
                      range:tIdentifierRange];
    
    [tNewLine addAttributes:self.memoryAddressAttributes
                      range:NSMakeRange(tMinAddressStart, tMinAddressEnd-tMinAddressStart+1)];
    
    [tNewLine addAttributes:self.memoryAddressAttributes
                      range:NSMakeRange(tMaxAddressStart, tMaxAddressEnd-tMaxAddressStart+1)];
    
    if (tUUIDStart!=NSNotFound)
    {
        [tNewLine addAttributes:self.UUIDAttributes
                          range:NSMakeRange(tUUIDStart,tUUIDEnd-tUUIDStart+1)];
    }
    
    if (tVersionEnd!=NSNotFound && tVersionStart!=NSNotFound)
    {
        [tNewLine addAttributes:self.versionAttributes
                          range:NSMakeRange(tVersionStart,tVersionEnd-tVersionStart+1)];
    }
    
    [tNewLine addAttributes:self.pathAttributes
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
                                                                                   attributes:self.plainTextAttributes];
            
            [tMutableAttributedString appendAttributedString:tAttributedString];
            
            if (bLineNumber<inLines.count)
                [tMutableAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:inNewLineFeed attributes:self.plainTextAttributes]];
            
            return;
        }
        
        if ([bLine isKindOfClass:[NSAttributedString class]]==YES)
        {
            [tMutableAttributedString appendAttributedString:bLine];
            
            if (bLineNumber<inLines.count)
                [tMutableAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:inNewLineFeed attributes:self.plainTextAttributes]];
        }
    }];
    
    return tMutableAttributedString;
}

@end
