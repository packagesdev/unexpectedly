/*
 Copyright (c) 2022, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIReportThemedTransform.h"

#import "CUIApplicationPreferences.h"
#import "CUIApplicationPreferences+Themes.h"

#import "CUIThemeItemsGroup+UI.h"

@interface CUIReportThemedTransform ()

    @property (readwrite) NSDictionary * plainTextAttributes;

    @property (readwrite) NSDictionary * keyAttributes;

    @property (readwrite) NSDictionary * versionAttributes;

    @property (readwrite) NSDictionary * pathAttributes;

    @property (readwrite) NSDictionary * UUIDAttributes;

    @property (readwrite) NSDictionary * crashedThreadLabelAttributes;

    @property (readwrite) NSDictionary * threadLabelAttributes;

    @property (readwrite) NSDictionary * executableCodeAttributes;

    @property (readwrite) NSDictionary * OSCodeAttributes;

    @property (readwrite) NSDictionary * memoryAddressAttributes;


    @property (readwrite) NSDictionary * registerValueAttributes;


    @property (readwrite) NSDictionary * parsingErrorAttributes;

    @property (readwrite) NSColor * underlineColor;

@end

@implementation CUIReportThemedTransform

- (instancetype)initWithThemesProvider:(id <CUIThemesProvider>)inThemesProvider;
{
    self=[super init];
    
    if (self!=nil)
    {
        _themesProvider=inThemesProvider;
        
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
    
    CUIThemeItemsGroup * tItemsGroup=[self.themesProvider.currentTheme itemsGroupWithIdentifier:[CUIApplicationPreferences groupIdentifierForPresentationMode:CUIPresentationModeText]];
    
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
    
    self.plainTextAttributes=tMutableDictionary[CUIThemeItemPlainText];
    
    NSColor * tForegroundColor=self.plainTextAttributes[NSForegroundColorAttributeName];
    self.underlineColor=[tForegroundColor colorWithAlphaComponent:0.35];
    
    self.keyAttributes=tMutableDictionary[CUIThemeItemKey];
    self.threadLabelAttributes=tMutableDictionary[CUIThemeItemThreadLabel];
    self.crashedThreadLabelAttributes=tMutableDictionary[CUIThemeItemCrashedThreadLabel];
    
    self.executableCodeAttributes=tMutableDictionary[CUIThemeItemExecutableCode];
    self.OSCodeAttributes=tMutableDictionary[CUIThemeItemOSCode];
    
    self.versionAttributes=tMutableDictionary[CUIThemeItemVersion];
    self.memoryAddressAttributes=tMutableDictionary[CUIThemeItemMemoryAddress];
    self.pathAttributes=tMutableDictionary[CUIThemeItemPath];
    self.UUIDAttributes=tMutableDictionary[CUIThemeItemUUID];
    self.registerValueAttributes=tMutableDictionary[CUIThemeItemRegisterValue];
    
    
    NSMutableDictionary * tParsingErrorDictionary=[self.plainTextAttributes mutableCopy];
    
    tParsingErrorDictionary[NSForegroundColorAttributeName]=[NSColor redColor];
    
    self.parsingErrorAttributes=[tParsingErrorDictionary copy];
}

#pragma mark -

- (id)processedStackFrameLine:(NSString *)inLine stackFrame:(CUIStackFrame *)inStackFrame
{
    NSScanner * tScanner=[NSScanner scannerWithString:inLine];
    
    if ([tScanner scanInteger:NULL]==NO)
        return nil;
    
    __block NSString * tLine=inLine;
    
    tScanner.charactersToBeSkipped=nil;
    
    [tScanner scanCharactersFromSet:self.whitespaceCharacterSet intoString:NULL];
    
    tScanner.charactersToBeSkipped=self.whitespaceCharacterSet;
    
    NSUInteger tBinaryImageIdentifierStart=tScanner.scanLocation;
    
    if ([tScanner scanUpToString:@"0x" intoString:nil]==NO)
        return nil;
    
    NSRange tBinaryImageIdentifierRange;
    
    if (tScanner.scanLocation==tLine.length)
    {
        // try to find a \t
        
        tScanner.scanLocation=tBinaryImageIdentifierStart;
        
        if ([tScanner scanUpToString:@"\t" intoString:NULL]==NO)
            return [[NSAttributedString alloc] initWithString:tLine attributes:self.parsingErrorAttributes];
        
        if (tScanner.scanLocation==tLine.length)
            return [[NSAttributedString alloc] initWithString:tLine attributes:self.parsingErrorAttributes];
        
        tBinaryImageIdentifierRange=NSMakeRange(tBinaryImageIdentifierStart,tScanner.scanLocation-tBinaryImageIdentifierStart+1);
    }
    else
    {
        tBinaryImageIdentifierRange=NSMakeRange(tBinaryImageIdentifierStart,tScanner.scanLocation-1-tBinaryImageIdentifierStart+1);
    }
    
    NSRange tBinEndRange=[[tLine substringWithRange:tBinaryImageIdentifierRange] rangeOfCharacterFromSet:self.whitespaceCharacterSet.invertedSet options:NSBackwardsSearch];
    
    NSString * tBinaryImageIdentifier=[tLine substringWithRange:NSMakeRange(tBinaryImageIdentifierRange.location, tBinEndRange.location+1)];
    
    tScanner.charactersToBeSkipped=self.whitespaceCharacterSet;
    
    unsigned long long tMachineInstructionAddress=0;
    
    if ([tScanner scanHexLongLong:&tMachineInstructionAddress]==NO)
        return [[NSAttributedString alloc] initWithString:tLine];
    
    BOOL tIsUserCode=NO;
    
    CUICrashLogBinaryImages * tBinaryImages=self.crashlog.binaryImages;
    
    CUIBinaryImage * tBinaryImage=[tBinaryImages binaryImageWithIdentifierOrName:tBinaryImageIdentifier identifier:&tBinaryImageIdentifier];
    
    if (tBinaryImage!=nil)
    {
        tIsUserCode = tBinaryImage.isUserCode;
        
        if (tIsUserCode==NO && [tBinaryImage.path isEqualToString:self.processPath]==YES)
            tIsUserCode=YES;
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
    
    if (self.symbolicationMode==CUISymbolicationModeNone)
        tSymbolicateAutomatically=NO;
    
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
        
        [tTemporaryLine appendString:[self.symbolicationDataFormatter stringForObjectValue:tSymbolicationData]];
        
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
                                                                                                                
                                                                                                                [NSNotificationCenter.defaultCenter postNotificationName:CUIStackFrameSymbolicationDidSucceedNotification
                                                                                                                                                                  object:self.input];
                                                                                                                
                                                                                                                break;
                                                                                                            }
                                                                                                                
                                                                                                            case CUISymbolicationDataLookUpResultFoundInCache:
                                                                                                            {
                                                                                                                inStackFrame.symbolicationData=bSymbolicationData;
                                                                                                                
                                                                                                                NSMutableString * tTemporaryLine=[[tLine substringToIndex:tScanner.scanLocation-tSymbol.length] mutableCopy];
                                                                                                                
                                                                                                                tSavedScanLocation+=(bSymbolicationData.stackFrameSymbol.length-tSymbol.length);
                                                                                                                
                                                                                                                [tTemporaryLine appendString:[self.symbolicationDataFormatter stringForObjectValue:bSymbolicationData]];
                                                                                                                
                                                                                                                tLine=[tTemporaryLine copy];
                                                                                                                
                                                                                                                break;
                                                                                                            }
                                                                                                                
                                                                                                        }
                                                                                                        
                                                                                                    }];
        }
    }
    
#endif
    
    NSMutableAttributedString * tProcessedLine=[[NSMutableAttributedString alloc] initWithString:tLine attributes:self.plainTextAttributes];
    
    NSRange tRange=NSMakeRange(0,tLine.length);
    
    NSDictionary * tDictionary=(tIsUserCode==YES) ? self.executableCodeAttributes : self.OSCodeAttributes;
    
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
                                                            NSUnderlineColorAttributeName:self.underlineColor
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
        [tProcessedLine addAttributes:self.memoryAddressAttributes range:tMemoryAddressRange];
    }
    
    if ((self.displaySettings.visibleStackFrameComponents & CUIStackFrameBinaryNameComponent)==0)
    {
        [tProcessedLine deleteCharactersInRange:tBinaryImageIdentifierRange];
    }
    else
    {
        if (self.hyperlinksStyle!=CUIHyperlinksNone && ((self.displaySettings.visibleSections & CUIDocumentBinaryImagesSection)==CUIDocumentBinaryImagesSection))
        {
            NSString * tCleanedUpIdentifier=[tBinaryImageIdentifier stringByTrimmingCharactersInSet:self.whitespaceCharacterSet];
            
            CUIBinaryImage * tBinaryImage=[tBinaryImages binaryImageWithIdentifier:tBinaryImageIdentifier];
            
            if (tBinaryImage==nil)
            {
                tBinaryImage=[tBinaryImages binaryImageWithIdentifier:tBinaryImageIdentifier];
            }
            
            NSString * tBinaryImageUUID=tBinaryImage.UUID;
            
            if (tBinaryImageUUID!=nil)
            {
                NSURL * tURL=nil;
                
                switch(self.hyperlinksStyle)
                {
                    case CUIHyperlinksInternal:
                        
                        tURL=[NSURL URLWithString:[NSString stringWithFormat:@"bin://%@",tBinaryImageUUID]];
                        
                        break;
                        
                    case CUIHyperlinksHTML:
                        
                        tURL=[NSURL URLWithString:[NSString stringWithFormat:@"sharp://%@",tBinaryImageUUID]];
                        
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

@end
