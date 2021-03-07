/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLogsSourceSmartEditorPanel.h"

#import "CUICrashLogsSourcesManager.h"

#include <mach/exception_types.h>

@interface CUICrashLogsSourceSmartEditorWindowController : NSWindowController
{
    IBOutlet NSTextField * _nameTextField;
    
    IBOutlet NSTextField * _descriptionTextField;
    
    IBOutlet NSPredicateEditor * _predicatorEditor;
    
    IBOutlet NSButton * _defaultButton;
}

@property (nonatomic) CUICrashLogsSourceSmart * source;

@property (nonatomic,copy) NSString * prompt;

- (IBAction)endDialog:(id)sender;

@end

@implementation CUICrashLogsSourceSmartEditorWindowController

- (NSString *)windowNibName
{
    return @"CUICrashLogsSourceSmartEditorWindowController";
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Row Template 1
    
    NSArray *keyPaths = @[[NSExpression expressionForKeyPath:@"processName"],
                          [NSExpression expressionForKeyPath:@"header.bundleIdentifier"],
                          [NSExpression expressionForKeyPath:@"header.executablePath"],
                          [NSExpression expressionForKeyPath:@"exceptionInformation.crashedThreadName"]];
    
    NSPredicateEditorRowTemplate * tRowTemplate1 = [[NSPredicateEditorRowTemplate alloc] initWithLeftExpressions:keyPaths
                                                                                    rightExpressionAttributeType:NSStringAttributeType
                                                                                                        modifier:NSDirectPredicateModifier
                                                                                                       operators:@[@(NSEqualToPredicateOperatorType),
                                                                                                                   @(NSNotEqualToPredicateOperatorType),
                                                                                                                   @(NSBeginsWithPredicateOperatorType),
                                                                                                                   @(NSEndsWithPredicateOperatorType),
                                                                                                                   @(NSContainsPredicateOperatorType)]
                                                                                                         options:(NSCaseInsensitivePredicateOption |
                                                                                                                  NSDiacriticInsensitivePredicateOption)];
    
    // Row Template 2
    
    NSPredicateEditorRowTemplate * tRowTemplate2 = [[NSPredicateEditorRowTemplate alloc] initWithLeftExpressions:@[[NSExpression expressionForKeyPath:@"dateTime"]]
                                                                                    rightExpressionAttributeType:NSDateAttributeType
                                                                                                        modifier:NSDirectPredicateModifier
                                                                                                       operators:@[@(NSLessThanOrEqualToPredicateOperatorType),
                                                                                                                   @(NSGreaterThanOrEqualToPredicateOperatorType),
                                                                                                                   ]
                                                                                                         options:(NSCaseInsensitivePredicateOption |
                                                                                                                  NSDiacriticInsensitivePredicateOption)];
    
    // Row Template 3
    
    NSPredicateEditorRowTemplate * tRowTemplate3 = [[NSPredicateEditorRowTemplate alloc] initWithLeftExpressions:@[[NSExpression expressionForKeyPath:@"exceptionType"]]
                                                                                                rightExpressions:@[[NSExpression expressionForConstantValue:@"EXC_ARITHMETIC"],
                                                                                                                   [NSExpression expressionForConstantValue:@"EXC_BAD_ACCESS"],
                                                                                                                   [NSExpression expressionForConstantValue:@"EXC_BAD_INSTRUCTION"],
                                                                                                                   [NSExpression expressionForConstantValue:@"EXC_BREAKPOINT"],
                                                                                                                   [NSExpression expressionForConstantValue:@"EXC_CORPSE_NOTIFY"],
                                                                                                                   [NSExpression expressionForConstantValue:@"EXC_CRASH"],
                                                                                                                   [NSExpression expressionForConstantValue:@"EXC_EMULATION"],
                                                                                                                   [NSExpression expressionForConstantValue:@"EXC_GUARD"],
                                                                                                                   [NSExpression expressionForConstantValue:@"EXC_MACH_SYSCALL"],
                                                                                                                   [NSExpression expressionForConstantValue:@"EXC_RESOURCE"],
                                                                                                                   [NSExpression expressionForConstantValue:@"EXC_RPC_ALERT"],
                                                                                                                   [NSExpression expressionForConstantValue:@"EXC_SOFTWARE"],
                                                                                                                   [NSExpression expressionForConstantValue:@"EXC_SYSCALL"]]
                                                                                                        modifier:NSDirectPredicateModifier
                                                                                                       operators:@[@(NSEqualToPredicateOperatorType)]
                                                                                                         options:(NSCaseInsensitivePredicateOption |
                                                                                                                  NSDiacriticInsensitivePredicateOption)];
    
    NSPredicateEditorRowTemplate * tRowTemplate4 = [[NSPredicateEditorRowTemplate alloc] initWithLeftExpressions:@[[NSExpression expressionForKeyPath:@"exceptionSignal"]]
                                                                                                rightExpressions:@[[NSExpression expressionForConstantValue:@"SIGABRT"],
                                                                                                                   [NSExpression expressionForConstantValue:@"SIGBUS"],
                                                                                                                   [NSExpression expressionForConstantValue:@"SIGILL"],
                                                                                                                   [NSExpression expressionForConstantValue:@"SIGKILL"],
                                                                                                                   [NSExpression expressionForConstantValue:@"SIGQUIT"],
                                                                                                                   [NSExpression expressionForConstantValue:@"SIGSEGV"],
                                                                                                                   [NSExpression expressionForConstantValue:@"SIGTRAP"],
                                                                                                                   [NSExpression expressionForConstantValue:@"Code Signature Invalid"],
                                                                                                                   ]
                                                                                                        modifier:NSDirectPredicateModifier
                                                                                                       operators:@[@(NSEqualToPredicateOperatorType)]
                                                                                                         options:(NSCaseInsensitivePredicateOption |
                                                                                                                  NSDiacriticInsensitivePredicateOption)];
    
    // Row Template 4
    
    NSPredicateEditorRowTemplate * tRowTemplate5 = [[NSPredicateEditorRowTemplate alloc] initWithLeftExpressions:@[[NSExpression expressionForKeyPath:@"reportSourceTypeNumber"]]
                                                                                                rightExpressions:@[[NSExpression expressionForConstantValue:@(CUICrashLogReportSourceTypeUser)],
                                                                                                                   [NSExpression expressionForConstantValue:@(CUICrashLogReportSourceTypeSystem)],
                                                                                                                   [NSExpression expressionForConstantValue:@(CUICrashLogReportSourceTypeOther)]]
                                                                                                        modifier:NSDirectPredicateModifier
                                                                                                       operators:@[@(NSEqualToPredicateOperatorType)]
                                                                                                         options:(NSCaseInsensitivePredicateOption |
                                                                                                                  NSDiacriticInsensitivePredicateOption)];
    
    
    NSArray *compoundTypes = @[@(NSAndPredicateType),
                               @(NSOrPredicateType)];
    
    NSPredicateEditorRowTemplate * tRowTemplateCompound = [[NSPredicateEditorRowTemplate alloc] initWithCompoundTypes:compoundTypes];
    
    _predicatorEditor.rowTemplates=@[tRowTemplate1, tRowTemplate2,tRowTemplate3,tRowTemplate4,tRowTemplate5,tRowTemplateCompound];
    
    
    // Default button
    
    if (self.prompt!=nil)
    {
        NSRect tButtonFrame=_defaultButton.frame;
        
        _defaultButton.title=self.prompt;
        
        [_defaultButton sizeToFit];
        
        CGFloat tWidth=NSWidth(_defaultButton.frame);
        
        if (tWidth<CUIAppkitMinimumPushButtonWidth)
            tWidth=CUIAppkitMinimumPushButtonWidth;
        
        tButtonFrame.origin.x=NSMaxX(tButtonFrame)-tWidth;
        tButtonFrame.size.width=tWidth;
        
        _defaultButton.frame=tButtonFrame;
    }
    
    _nameTextField.stringValue=(self.source.name!=nil) ? self.source.name : @"";
    
    _descriptionTextField.stringValue=(self.source.sourceDescription!=nil) ? self.source.sourceDescription : @"";
    
    [_predicatorEditor setObjectValue:self.source.predicate];
}

#pragma mark -

- (void)setSource:(CUICrashLogsSourceSmart *)inSource
{
    if (_source==inSource)
        return;
    
    _source=inSource;
    
    _nameTextField.stringValue=(inSource.name!=nil) ? inSource.name : @"";
    
    _descriptionTextField.stringValue=(inSource.sourceDescription!=nil) ? inSource.sourceDescription : @"";
    
    [_predicatorEditor setObjectValue:inSource.predicate];
}

- (void)setPrompt:(NSString *)inPrompt
{
    _prompt=[inPrompt copy];
    
    if (_defaultButton!=nil && _prompt!=nil)
    {
        NSRect tButtonFrame=_defaultButton.frame;
        
        _defaultButton.title=_prompt;
        
        [_defaultButton sizeToFit];
        
        CGFloat tWidth=NSWidth(_defaultButton.frame);
        
        if (tWidth<CUIAppkitMinimumPushButtonWidth)
            tWidth=CUIAppkitMinimumPushButtonWidth;
        
        tButtonFrame.origin.x=NSMaxX(tButtonFrame)-tWidth;
        tButtonFrame.size.width=tWidth;
        
        _defaultButton.frame=tButtonFrame;
    }
}

#pragma mark -

- (IBAction)endDialog:(NSButton *)sender
{
    if (sender.tag==NSModalResponseOK)
    {
        NSString * tNewName=_nameTextField.stringValue;
        
        // Do not allow empty names
        
        if (tNewName.length==0)
        {
            NSBeep();
            
            _nameTextField.stringValue=_source.name;
            
            return;
        }
        
        // Do not allow a name that is already used
        
        NSMutableArray * tExistingSmartSources=[[[CUICrashLogsSourcesManager sharedManager] sourcesOfType:CUICrashLogsSourceTypeSmart] mutableCopy];
        
        [tExistingSmartSources removeObject:_source];
        
        for(CUICrashLogsSourceSmart * tSmartSource in tExistingSmartSources)
        {
            if ([tSmartSource.name isEqualToString:tNewName]==YES)
            {
                NSAlert * tAlert=[NSAlert new];
                tAlert.alertStyle=NSAlertStyleCritical;
                tAlert.messageText=[NSString stringWithFormat:NSLocalizedString(@"The name \"%@\" is already taken.",@""),tNewName];
                tAlert.informativeText=NSLocalizedString(@"Please choose a different name.",@"");
                
                [tAlert runModal];
                
                return;
            }
        }
        
        _source.name=tNewName;
        
        _source.sourceDescription=_descriptionTextField.stringValue;
        
        _source.predicate=_predicatorEditor.objectValue;
    }
    
    /*NSData *data = [_predicatorEditor performSelector:@selector(_generateFormattingDictionaryStringsFile)];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF16StringEncoding];
    NSLog(@"%@", str);*/
    
    [NSApp endSheet:self.window returnCode:sender.tag];
}

@end

@interface CUICrashLogsSourceSmartEditorPanel ()
{
    CUICrashLogsSourceSmartEditorWindowController * retainedWindowController;
}

- (void)_sheetDidEndSelector:(NSWindow *)inWindow returnCode:(NSInteger)inReturnCode contextInfo:(void *)contextInfo;

@end

@implementation CUICrashLogsSourceSmartEditorPanel

+ (CUICrashLogsSourceSmartEditorPanel *)crashLogsSourceSmartEditorPanel
{
    CUICrashLogsSourceSmartEditorWindowController * tWindowController=[CUICrashLogsSourceSmartEditorWindowController new];
    
    CUICrashLogsSourceSmartEditorPanel * tPanel=(CUICrashLogsSourceSmartEditorPanel *)tWindowController.window;
    tPanel->retainedWindowController=tWindowController;
    
    return tPanel;
}

#pragma mark -

- (CUICrashLogsSourceSmart *)source
{
    return retainedWindowController.source;
}

- (void)setSource:(CUICrashLogsSourceSmart *)inSource
{
    retainedWindowController.source=inSource;
}

- (NSString *)prompt
{
    return retainedWindowController.prompt;
}

- (void)setPrompt:(NSString *)inPrompt
{
    retainedWindowController.prompt=inPrompt;
}

#pragma mark -

- (void)_sheetDidEndSelector:(CUICrashLogsSourceSmartEditorPanel *)inPanel returnCode:(NSInteger)inReturnCode contextInfo:(void *)contextInfo
{
    void(^handler)(NSInteger) = (__bridge_transfer void(^)(NSInteger)) contextInfo;
    
    if (handler!=nil)
        handler(inReturnCode);
    
    inPanel->retainedWindowController=nil;
    
    [inPanel orderOut:self];
}

- (void)beginSheetModalForWindow:(NSWindow *)inWindow completionHandler:(void (^)(NSModalResponse response))handler
{
    [NSApp beginSheet:self
       modalForWindow:inWindow
        modalDelegate:self
       didEndSelector:@selector(_sheetDidEndSelector:returnCode:contextInfo:)
          contextInfo:(__bridge_retained void*)[handler copy]];
}

@end
