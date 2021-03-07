/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIExceptionTypePopUpViewController.h"

#import <WebKit/WebKit.h>

@interface CUINoScrollingWebView : WKWebView

@end

@implementation CUINoScrollingWebView

- (void)scrollWheel:(NSEvent *)inEvent
{
    [self.nextResponder scrollWheel:inEvent];
}

@end

@interface CUIExceptionTypePopUpViewController () <WKNavigationDelegate>/*<WebFrameLoadDelegate,WebPolicyDelegate>*/
{
    IBOutlet CUINoScrollingWebView * _webView;
    
    NSBundle * _mainBundle;
    
    NSURL * _contentsFileURL;
}

    @property (copy) NSString * exceptionType;

    @property (copy) NSString * exceptionSignal;

@end

@implementation CUIExceptionTypePopUpViewController

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _mainBundle=[NSBundle mainBundle];
    }
    
    return self;
}

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _webView.navigationDelegate=self;
    
    [_webView setValue:@(NO) forKey:@"drawsBackground"];
    
    NSError * tError=nil;
    
    NSString * tHTMLContents=[NSString stringWithContentsOfURL:_contentsFileURL encoding:NSUTF8StringEncoding error:&tError];
    
    if (tHTMLContents==nil)
    {
        NSLog(@"HTML data could not be loaded from file \"%@\".",_contentsFileURL);
        
        return;
    }
    
    [_webView loadHTMLString:tHTMLContents baseURL:_mainBundle.resourceURL];
}

- (NSString *)nibName
{
    return @"CUIExceptionTypePopUpViewController";
}

#pragma mark -

- (void)webView:(WKWebView *)inWebView decidePolicyForNavigationAction:(WKNavigationAction *)inNavigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if (inNavigationAction.navigationType==WKNavigationTypeLinkActivated)
    {
        decisionHandler(WKNavigationActionPolicyCancel);
        
        [[NSWorkspace sharedWorkspace] openURL:inNavigationAction.request.URL];
    }
    else
    {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)webView:(WKWebView *)inWebView didFinishNavigation:(WKNavigation *)inNavigation
{
    if (self.popover==nil)
        return;
    
    __block NSSize tCurrentSize=self.popover.contentSize;
    
    [_webView evaluateJavaScript:@"document.body.scrollHeight;" completionHandler:^(NSString * bResult, NSError * bError) {
        
        tCurrentSize.height=[bResult integerValue];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.popover.contentSize=tCurrentSize;
            
            [self.delegate exceptionTypePopUpViewController:self didComputeSizeOfPopover:self.popover];
        });
    }];
}

#pragma mark -

- (void)setExceptionType:(NSString *)inType signal:(NSString *)inSignal
{
    _contentsFileURL=nil;
    
    if (inType!=nil && inSignal!=nil)
    {
        _contentsFileURL=[_mainBundle URLForResource:[NSString stringWithFormat:@"%@_%@",inType,inSignal] withExtension:@"html"];
    }
    
    if (_contentsFileURL==nil)
    {
        // Use no documentation file
        
        _contentsFileURL=[_mainBundle URLForResource:@"unknown_exception_type" withExtension:@"html"];
    }
    
    if (_webView==nil)
        return;
    
    NSError * tError=nil;
    
    NSString * tHTMLContents=[NSString stringWithContentsOfURL:_contentsFileURL encoding:NSUTF8StringEncoding error:&tError];
    
    if (tHTMLContents==nil)
    {
        // A COMPLETER
        
        return;
    }
    
    [_webView loadHTMLString:tHTMLContents baseURL:_mainBundle.resourceURL];
}

@end
