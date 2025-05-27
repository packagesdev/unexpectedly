/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLogTextView.h"

@interface NSView (Private)

- (void)_scrollPoint:(NSPoint *)point fromView:(NSView *)inView;
- (void)_scrollDown:(CGFloat)inOffset;
- (void)_scrollUp:(CGFloat)inOffset;

@end

@implementation CUICrashLogTextView

- (void)CUI_scrollPoint:(NSPoint)inPoint
{
    NSScrollView * tScrollView=self.enclosingScrollView;
    
    NSView * tDocumentView=tScrollView.documentView;
    NSRulerView * tVerticalRulerView=tScrollView.verticalRulerView;
    
    if (self!=tDocumentView ||
        tVerticalRulerView==nil ||
        tScrollView.horizontalScroller.isHidden==YES)
    {
        [self scrollPoint:inPoint];
        
        return;
    }

    // Offset the text view frame to take into account the vertical ruler width
    
    inPoint.x-=NSWidth(tVerticalRulerView.frame);
    
    [self scrollPoint:inPoint];
}

- (void)_scrollUp:(CGFloat)inOffset
{
    NSScrollView * tScrollView=self.enclosingScrollView;
    
    NSView * tDocumentView=tScrollView.documentView;
    NSRulerView * tVerticalRulerView=tScrollView.verticalRulerView;
    
    if (self!=tDocumentView ||
        tVerticalRulerView==nil ||
        tScrollView.horizontalScroller.isHidden==YES)
    {
        [super _scrollUp:inOffset];
        
        return;
    }
    
    NSRect tOldFrame=tDocumentView.frame;
    
    // Offset the text view frame to take into account the vertical ruler width
    
    BOOL dontOffset = ([self.identifier isEqualToString:@"DontOffset"] == YES);
    
    if (dontOffset==YES)
    {
        [super _scrollDown:inOffset];
        
        return;
    }
    
    NSRect tNewFrame=tOldFrame;
    
    tNewFrame.origin.x-=NSWidth(tVerticalRulerView.frame);
    self.frame=tNewFrame;

    [super _scrollUp:inOffset];
    
    // Restore the text view frame
    
    self.frame=tOldFrame;
}

- (void)_scrollDown:(CGFloat)inOffset
{
    NSScrollView * tScrollView=self.enclosingScrollView;
    
    NSView * tDocumentView=tScrollView.documentView;
    NSRulerView * tVerticalRulerView=tScrollView.verticalRulerView;
    
    if (self!=tDocumentView ||
        tVerticalRulerView==nil ||
        tScrollView.horizontalScroller.isHidden==YES)
    {
        [super _scrollDown:inOffset];
        
        return;
    }

    NSRect tOldFrame=tDocumentView.frame;
    
    // Offset the text view frame to take into account the vertical ruler width
    BOOL dontOffset = ([self.identifier isEqualToString:@"DontOffset"] == YES);
    
    if (dontOffset==YES)
    {
        [super _scrollDown:inOffset];
        
        return;
    }
    
    NSRect tNewFrame=tOldFrame;
        
    tNewFrame.origin.x-=NSWidth(tVerticalRulerView.frame);
    self.frame=tNewFrame;
    
    [super _scrollDown:inOffset];
    
    // Restore the text view frame
        
    self.frame=tOldFrame;
}

- (NSPoint)textContainerOrigin
{
    return NSMakePoint(8,8);
}

#pragma mark -

- (void)keyDown:(NSEvent *)inEvent
{
    NSString * tTypedText=inEvent.characters;
    
    NSUInteger tLength=tTypedText.length;
    
    for(NSUInteger tIndex=0;tIndex<tLength;tIndex++)
    {
        unichar tChar=[tTypedText characterAtIndex:tIndex];
        
        switch(tChar)
        {
            case ' ':
                
                [self scrollPageDown:self];
                return;
                
            case 'b':
                
                [self scrollPageUp:self];
                return;
                
            /*case NSDeleteCharacter:   // Jump Back ?
                
                NSBeep();
                return;*/
        }
    }
    
    [super keyDown:inEvent];
}

@end
